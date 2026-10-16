-- AlterTable
ALTER TABLE "ReadingMaterial" ADD COLUMN     "gradeLevel" INTEGER;

-- CreateIndex
CREATE INDEX "ReadingMaterial_gradeLevel_idx" ON "ReadingMaterial"("gradeLevel");
