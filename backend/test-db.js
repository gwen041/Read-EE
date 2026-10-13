require('dotenv').config();
const prisma = require('./prisma');

async function testConnection() {
  try {
    console.log('Testing connection to PostgreSQL database...');

    const result = await prisma.$queryRaw`SELECT current_database(), current_user;`;
    const dbName = result[0].current_database;
    const user = result[0].current_user;

    console.log(`✓ Successfully connected to database: "${dbName}" as user: "${user}"`);

    const teacherCount = await prisma.teacher.count();
    console.log(`✓ Prisma schema verified (Teacher records: ${teacherCount})`);
    console.log('✓ Stage 8.1 database connection check passed.');
    process.exit(0);
  } catch (error) {
    console.error('✗ Database connection failed:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();