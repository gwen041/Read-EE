-- CreateEnum
CREATE TYPE "MaterialType" AS ENUM ('BUILT_IN', 'TEACHER_CREATED');

-- CreateTable
CREATE TABLE "Teacher" (
    "id" SERIAL NOT NULL,
    "fullName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Teacher_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ClassSection" (
    "id" SERIAL NOT NULL,
    "gradeLevel" INTEGER NOT NULL,
    "sectionName" TEXT NOT NULL,
    "teacherId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ClassSection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Student" (
    "id" SERIAL NOT NULL,
    "fullName" TEXT NOT NULL,
    "classSectionId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Student_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ReadingMaterial" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "passage" TEXT NOT NULL,
    "materialType" "MaterialType" NOT NULL,
    "teacherId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReadingMaterial_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ComprehensionQuestion" (
    "id" SERIAL NOT NULL,
    "readingMaterialId" INTEGER NOT NULL,
    "questionText" TEXT NOT NULL,
    "choiceA" TEXT NOT NULL,
    "choiceB" TEXT NOT NULL,
    "choiceC" TEXT NOT NULL,
    "choiceD" TEXT NOT NULL,
    "correctAnswer" TEXT NOT NULL,
    "questionOrder" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ComprehensionQuestion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Assessment" (
    "id" SERIAL NOT NULL,
    "studentId" INTEGER NOT NULL,
    "readingMaterialId" INTEGER NOT NULL,
    "accuracy" DOUBLE PRECISION NOT NULL,
    "wpm" DOUBLE PRECISION NOT NULL,
    "comprehensionScore" INTEGER NOT NULL,
    "classification" TEXT NOT NULL,
    "accuracyDetails" JSONB,
    "comprehensionDetails" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Assessment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Teacher_email_key" ON "Teacher"("email");

-- CreateIndex
CREATE INDEX "ClassSection_teacherId_idx" ON "ClassSection"("teacherId");

-- CreateIndex
CREATE UNIQUE INDEX "ClassSection_teacherId_gradeLevel_sectionName_key" ON "ClassSection"("teacherId", "gradeLevel", "sectionName");

-- CreateIndex
CREATE INDEX "Student_classSectionId_idx" ON "Student"("classSectionId");

-- CreateIndex
CREATE INDEX "ReadingMaterial_teacherId_idx" ON "ReadingMaterial"("teacherId");

-- CreateIndex
CREATE INDEX "ReadingMaterial_materialType_idx" ON "ReadingMaterial"("materialType");

-- CreateIndex
CREATE INDEX "ComprehensionQuestion_readingMaterialId_idx" ON "ComprehensionQuestion"("readingMaterialId");

-- CreateIndex
CREATE UNIQUE INDEX "ComprehensionQuestion_readingMaterialId_questionOrder_key" ON "ComprehensionQuestion"("readingMaterialId", "questionOrder");

-- CreateIndex
CREATE INDEX "Assessment_studentId_createdAt_idx" ON "Assessment"("studentId", "createdAt");

-- CreateIndex
CREATE INDEX "Assessment_readingMaterialId_idx" ON "Assessment"("readingMaterialId");

-- AddForeignKey
ALTER TABLE "ClassSection" ADD CONSTRAINT "ClassSection_teacherId_fkey" FOREIGN KEY ("teacherId") REFERENCES "Teacher"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Student" ADD CONSTRAINT "Student_classSectionId_fkey" FOREIGN KEY ("classSectionId") REFERENCES "ClassSection"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ReadingMaterial" ADD CONSTRAINT "ReadingMaterial_teacherId_fkey" FOREIGN KEY ("teacherId") REFERENCES "Teacher"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ComprehensionQuestion" ADD CONSTRAINT "ComprehensionQuestion_readingMaterialId_fkey" FOREIGN KEY ("readingMaterialId") REFERENCES "ReadingMaterial"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Assessment" ADD CONSTRAINT "Assessment_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Assessment" ADD CONSTRAINT "Assessment_readingMaterialId_fkey" FOREIGN KEY ("readingMaterialId") REFERENCES "ReadingMaterial"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
