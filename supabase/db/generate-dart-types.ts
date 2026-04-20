#!/usr/bin/env tsx
/**
 * Generate Dart types from database schema
 * Reads the actual database schema and creates typed Dart classes
 */

import { Pool } from 'pg'
import * as dotenv from 'dotenv'
import * as fs from 'fs'
import * as path from 'path'

dotenv.config({ path: '../../.env' })

const OUTPUT_DIR = path.join(__dirname, '../../flutter/lib/data/models/generated')

// Type mappings from Postgres to Dart
const PG_TO_DART: Record<string, string> = {
  'uuid': 'String',
  'text': 'String',
  'character varying': 'String',
  'integer': 'int',
  'bigint': 'int',
  'smallint': 'int',
  'numeric': 'double',
  'double precision': 'double',
  'boolean': 'bool',
  'timestamp with time zone': 'DateTime',
  'timestamp without time zone': 'DateTime',
  'date': 'DateTime',
  'json': 'Map<String, dynamic>',
  'jsonb': 'Map<String, dynamic>',
}

function toCamelCase(str: string): string {
  return str.replace(/_([a-z])/g, (_,  letter) => letter.toUpperCase())
}

function toPascalCase(str: string): string {
  const camel = toCamelCase(str)
  return camel.charAt(0).toUpperCase() + camel.slice(1)
}

function getDartType(pgType: string, isNullable: boolean): string {
  const baseType = PG_TO_DART[pgType.toLowerCase()] || 'dynamic'
  return isNullable ? `${baseType}?` : baseType
}

async function generateDartModels() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL!, ssl: { rejectUnauthorized: false } })

  try {
    console.log('🔍 Fetching schema from database...\n')

    // Get enum types
    const enumsResult = await pool.query(`
      SELECT
        t.typname as enum_name,
        array_agg(e.enumlabel ORDER BY e.enumsortorder) as enum_values
      FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
      WHERE n.nspname = 'public'
      GROUP BY t.typname
    `)

    const enums: Record<string, string[]> = {}
    for (const row of enumsResult.rows) {
      // Postgres returns array as string like "{value1,value2}" or as actual array
      const values = typeof row.enum_values === 'string'
        ? row.enum_values.replace(/[{}]/g, '').split(',')
        : row.enum_values
      enums[row.enum_name] = values
    }

    // Get all tables in public schema
    const tablesResult = await pool.query(`
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        AND table_name NOT LIKE 'drizzle%'
      ORDER BY table_name
    `)

    console.log(`Found ${tablesResult.rows.length} tables:\n`)

    // Ensure output directory exists
    if (!fs.existsSync(OUTPUT_DIR)) {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true })
    }

    for (const { table_name } of tablesResult.rows) {
      console.log(`  📦 Generating ${table_name}...`)

      // Get columns for this table
      const columnsResult = await pool.query(`
        SELECT
          column_name,
          data_type,
          udt_name,
          is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
      `, [table_name])

      const className = toPascalCase(table_name)
      const columns = columnsResult.rows

      // Generate Dart class
      const dartCode = generateDartClass(className, table_name, columns, enums)
      const fileName = `${table_name}.dart`
      const filePath = path.join(OUTPUT_DIR, fileName)

      fs.writeFileSync(filePath, dartCode)
      console.log(`     ✓ ${fileName}`)
    }

    console.log(`\n✅ Generated Dart models in: ${OUTPUT_DIR}\n`)
  } finally {
    await pool.end()
  }
}

function generateDartClass(className: string, tableName: string, columns: any[], enums: Record<string, string[]>): string {
  const fields: string[] = []
  const constructorParams: string[] = []
  const fromJsonLines: string[] = []
  const toJsonLines: string[] = []
  const copyWithParams: string[] = []
  const copyWithArgs: string[] = []
  const usedEnums = new Set<string>()

  for (const col of columns) {
    const fieldName = toCamelCase(col.column_name)
    const isNullable = col.is_nullable === 'YES'

    // Check if it's an enum type
    let dartType: string
    if (col.data_type === 'USER-DEFINED') {
      if (enums[col.udt_name]) {
        const enumName = toPascalCase(col.udt_name)
        dartType = isNullable ? `${enumName}?` : enumName
        usedEnums.add(col.udt_name)
      } else {
        dartType = getDartType(col.udt_name, isNullable)
      }
    } else {
      dartType = getDartType(col.data_type, isNullable)
    }

    const baseType = dartType.replace('?', '')

    fields.push(`  final ${dartType} ${fieldName};`)
    constructorParams.push(`    ${isNullable ? '' : 'required '}this.${fieldName},`)

    // fromJson
    if (baseType === 'DateTime') {
      const parseExpr = `DateTime.parse(json['${col.column_name}'])`
      if (isNullable) {
        fromJsonLines.push(`      ${fieldName}: json['${col.column_name}'] != null ? ${parseExpr} : null,`)
      } else {
        fromJsonLines.push(`      ${fieldName}: ${parseExpr},`)
      }
    } else if (enums[col.udt_name]) {
      const enumName = toPascalCase(col.udt_name)
      if (isNullable) {
        fromJsonLines.push(`      ${fieldName}: json['${col.column_name}'] != null ? ${enumName}.fromString(json['${col.column_name}']) : null,`)
      } else {
        fromJsonLines.push(`      ${fieldName}: ${enumName}.fromString(json['${col.column_name}'])!,`)
      }
    } else {
      const cast = baseType !== 'dynamic' && !isNullable ? ` as ${dartType}` : (baseType !== 'dynamic' ? ` as ${baseType}?` : '')
      fromJsonLines.push(`      ${fieldName}: json['${col.column_name}']${cast},`)
    }

    // toJson
    if (baseType === 'DateTime') {
      if (isNullable) {
        toJsonLines.push(`      '${col.column_name}': ${fieldName}?.toIso8601String(),`)
      } else {
        toJsonLines.push(`      '${col.column_name}': ${fieldName}.toIso8601String(),`)
      }
    } else if (enums[col.udt_name]) {
      if (isNullable) {
        toJsonLines.push(`      '${col.column_name}': ${fieldName}?.value,`)
      } else {
        toJsonLines.push(`      '${col.column_name}': ${fieldName}.value,`)
      }
    } else {
      toJsonLines.push(`      '${col.column_name}': ${fieldName},`)
    }

    // copyWith - for non-nullable types, make parameter nullable but keep original semantics
    if (!isNullable) {
      copyWithParams.push(`    ${dartType}? ${fieldName},`)
    } else {
      copyWithParams.push(`    ${dartType} ${fieldName},`)
    }
    copyWithArgs.push(`      ${fieldName}: ${fieldName} ?? this.${fieldName},`)
  }

  // Generate enum classes using Dart 3.0 enhanced enum syntax
  const enumClasses = Array.from(usedEnums).map(enumName => {
    const enumValues = enums[enumName]
    const dartEnumName = toPascalCase(enumName)
    const cases = enumValues.map(v => `  ${toCamelCase(v)}('${v}')`).join(',\n')

    return `enum ${dartEnumName} {
${cases};

  const ${dartEnumName}(this.value);
  final String value;

  static ${dartEnumName}? fromString(String? value) {
    if (value == null) return null;
    try {
      return ${dartEnumName}.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}
`
  }).join('\n')

  return `// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: ${tableName}

${enumClasses}${enumClasses ? '\n' : ''}class ${className} {
${fields.join('\n')}

  const ${className}({
${constructorParams.join('\n')}
  });

  factory ${className}.fromJson(Map<String, dynamic> json) => ${className}(
${fromJsonLines.join('\n')}
      );

  Map<String, dynamic> toJson() => {
${toJsonLines.join('\n')}
      };

  ${className} copyWith({
${copyWithParams.join('\n')}
  }) => ${className}(
${copyWithArgs.join('\n')}
      );
}
`
}

generateDartModels().catch(console.error)

