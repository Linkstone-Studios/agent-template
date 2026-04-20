// Helper script to generate properly URL-encoded DATABASE_URL
// Run with: npx tsx update-env.ts

const readline = require('readline')
const fs = require('fs')
const path = require('path')

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

console.log('🔐 Database Connection String Generator')
console.log('=========================================\n')
console.log('Project: YOUR_PROJECT (rezmeajnyabzrdzdlnho)')
console.log('Region: us-east-1')
console.log('Host: db.rezmeajnyabzrdzdlnho.supabase.co\n')

rl.question('Enter your database password: ', (password: string) => {
  // URL encode the password to handle special characters
  const encodedPassword = encodeURIComponent(password.trim())
  
  const connectionString = `postgresql://postgres.rezmeajnyabzrdzdlnho:${encodedPassword}@db.rezmeajnyabzrdzdlnho.supabase.co:5432/postgres`
  
  const envContent = `# Direct connection (use for migrations, not connection pooler)
DATABASE_URL=${connectionString}
`
  
  const envPath = path.join(__dirname, '../../.env')
  
  fs.writeFileSync(envPath, envContent)
  
  console.log('\n✅ .env file updated!')
  console.log(`\n📝 Connection string: postgresql://postgres.rezmeajnyabzrdzdlnho:***@db.rezmeajnyabzrdzdlnho.supabase.co:5432/postgres`)
  console.log('\n🧪 Test the connection with:')
  console.log('   cd supabase/db && npx tsx test-connection.ts\n')
  
  rl.close()
})

