import { Pool } from 'pg'
import * as dotenv from 'dotenv'

dotenv.config({ path: '../../.env' })

async function testConnection() {
  if (!process.env.DATABASE_URL) {
    console.error('❌ DATABASE_URL environment variable is not set.')
    console.log('\n📝 To get your DATABASE_URL:')
    console.log('1. Go to https://supabase.com/dashboard/project/rezmeajnyabzrdzdlnho/settings/database')
    console.log('2. Scroll to "Connection string" section')
    console.log('3. Use the "Direct connection" string (port 5432)')
    console.log('4. Replace [YOUR-PASSWORD] with your actual database password')
    console.log('5. Add it to .env file as: DATABASE_URL=postgresql://...')
    process.exit(1)
  }

  console.log('Testing database connection...')
  console.log('URL:', process.env.DATABASE_URL.replace(/:[^:@]+@/, ':***@'))

  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  })

  try {
    const result = await pool.query('SELECT version()')
    console.log('✅ Connection successful!')
    console.log('PostgreSQL version:', result.rows[0].version)
    
    // Test if we can create schema
    try {
      await pool.query('CREATE SCHEMA IF NOT EXISTS "drizzle"')
      console.log('✅ Can create drizzle schema')
      await pool.query('DROP SCHEMA IF EXISTS "drizzle"')
    } catch (error: any) {
      console.error('❌ Cannot create drizzle schema:', error.message)
      console.log('\n💡 This might be a permissions issue.')
      console.log('   Make sure you are using the postgres user with full permissions.')
    }
  } catch (error: any) {
    console.error('❌ Connection failed:', error.message)
    console.log('\n💡 Possible issues:')
    console.log('   1. Wrong password in DATABASE_URL')
    console.log('   2. Using connection pooler (port 6543) instead of direct connection (port 5432)')
    console.log('   3. Database credentials have changed')
    console.log('\n📝 Get the correct connection string from:')
    console.log('   https://supabase.com/dashboard/project/rezmeajnyabzrdzdlnho/settings/database')
  } finally {
    await pool.end()
  }
}

testConnection()

