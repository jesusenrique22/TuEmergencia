import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- USERS ---');
  const users = await prisma.user.findMany({
    select: { id: true, email: true, name: true, role: true }
  });
  console.log(users);

  console.log('\n--- PATIENT PROFILES ---');
  const profiles = await prisma.patientProfile.findMany({
    select: { id: true, userId: true, fullName: true }
  });
  console.log(profiles);

  console.log('\n--- INSURANCE COMPANIES ---');
  const companies = await prisma.insuranceCompany.findMany();
  console.log(companies);

  console.log('\n--- PATIENT POLICIES ---');
  const policies = await prisma.patientPolicy.findMany();
  console.log(policies);
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
