import { drizzle } from 'drizzle-orm/node-postgres'
import { migrate } from 'drizzle-orm/node-postgres/migrator'
import { Pool } from 'pg'
import * as dotenv from 'dotenv'

dotenv.config({ path: '../../.env' })

if (!process.env.DATABASE_URL) {
  console.error(`ERROR: DATABASE_URL environment variable is not set.`)
  process.exit(1)
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
})

const db = drizzle(pool)

async function reloadSchemaCache() {
  try {
    await pool.query(`NOTIFY pgrst, 'reload schema'`)
    console.log(`✅ PostgREST schema cache reloaded`)
  } catch (error) {
    console.warn(`⚠️  Failed to reload schema cache:`, error)
  }
}

async function main() {
  console.log(`Running migrations against Supabase...`)
  try {
    await migrate(db, {
      migrationsFolder: `migrations`,
      migrationsTable: `drizzle_migrations`,
      migrationsSchema: `public`,
    })
    console.log(`✅ Migrations completed successfully!`)
    await reloadSchemaCache()
  } catch (error) {
    console.error(`❌ Migration failed:`, error)
    process.exit(1)
  } finally {
    await pool.end()
  }
}

main()
