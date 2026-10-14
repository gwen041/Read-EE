const express = require('express');
const prisma = require('../prisma');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.use(authMiddleware);

function parseGrade(grade) {
  if (typeof grade === 'number') return grade;
  const match = String(grade).match(/\d+/);
  return match ? parseInt(match[0], 10) : null;
}

router.get('/', async (req, res) => {
  try {
    const classes = await prisma.classSection.findMany({
      where: { teacherId: req.teacher.id },
      include: {
        students: {
          orderBy: { fullName: 'asc' }
        }
      },
      orderBy: [
        { gradeLevel: 'asc' },
        { sectionName: 'asc' }
      ]
    });

    res.json({
      success: true,
      classes
    });
  } catch (error) {
    console.error('Fetch classes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch class sections.'
    });
  }
});

router.post('/', async (req, res) => {
  try {
    const { gradeLevel, sectionName } = req.body;
    const grade = parseGrade(gradeLevel);

    if (!grade || ![4, 5, 6].includes(grade)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid grade level. Supported grade levels are 4, 5, and 6.'
      });
    }

    if (!sectionName || !sectionName.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Section name is required.'
      });
    }

    const trimmedSection = sectionName.trim();

    const existing = await prisma.classSection.findFirst({
      where: {
        teacherId: req.teacher.id,
        gradeLevel: grade,
        sectionName: { equals: trimmedSection, mode: 'insensitive' }
      }
    });

    if (existing) {
      return res.status(409).json({
        success: false,
        message: `Section "${trimmedSection}" already exists for Grade ${grade}.`
      });
    }

    const newSection = await prisma.classSection.create({
      data: {
        teacherId: req.teacher.id,
        gradeLevel: grade,
        sectionName: trimmedSection
      },
      include: {
        students: true
      }
    });

    res.status(201).json({
      success: true,
      message: 'Class section created successfully.',
      classSection: newSection
    });
  } catch (error) {
    console.error('Create class section error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create class section.'
    });
  }
});

router.post('/batch', async (req, res) => {
  try {
    const { sections } = req.body;

    if (!Array.isArray(sections) || sections.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'An array of sections is required.'
      });
    }

    const createdSections = [];

    await prisma.$transaction(async (tx) => {
      for (const item of sections) {
        const grade = parseGrade(item.gradeLevel);
        const trimmedName = item.sectionName?.trim();

        if (!grade || ![4, 5, 6].includes(grade) || !trimmedName) continue;

        const exists = await tx.classSection.findFirst({
          where: {
            teacherId: req.teacher.id,
            gradeLevel: grade,
            sectionName: { equals: trimmedName, mode: 'insensitive' }
          }
        });

        if (!exists) {
          const created = await tx.classSection.create({
            data: {
              teacherId: req.teacher.id,
              gradeLevel: grade,
              sectionName: trimmedName
            },
            include: { students: true }
          });
          createdSections.push(created);
        }
      }
    });

    res.status(201).json({
      success: true,
      message: 'Sections created successfully.',
      sections: createdSections
    });
  } catch (error) {
    console.error('Batch create sections error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create sections in batch.'
    });
  }
});

router.post('/:classId/students', async (req, res) => {
  try {
    const classId = parseInt(req.params.classId, 10);
    const { fullName } = req.body;

    if (!fullName || !fullName.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Student full name is required.'
      });
    }

    const trimmedName = fullName.trim();

    const section = await prisma.classSection.findFirst({
      where: { id: classId, teacherId: req.teacher.id }
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Class section not found or unauthorized.'
      });
    }

    const existingStudent = await prisma.student.findFirst({
      where: {
        classSectionId: classId,
        fullName: { equals: trimmedName, mode: 'insensitive' }
      }
    });

    if (existingStudent) {
      return res.status(409).json({
        success: false,
        message: `Student "${trimmedName}" is already in this class section.`
      });
    }

    const student = await prisma.student.create({
      data: {
        fullName: trimmedName,
        classSectionId: classId
      }
    });

    res.status(201).json({
      success: true,
      message: 'Student added successfully.',
      student
    });
  } catch (error) {
    console.error('Add student error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add student.'
    });
  }
});

router.post('/:classId/students/import', async (req, res) => {
  try {
    const classId = parseInt(req.params.classId, 10);
    const { studentNames } = req.body;

    if (!Array.isArray(studentNames) || studentNames.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'A list of student names is required.'
      });
    }

    const section = await prisma.classSection.findFirst({
      where: { id: classId, teacherId: req.teacher.id }
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Class section not found or unauthorized.'
      });
    }

    const existingStudents = await prisma.student.findMany({
      where: { classSectionId: classId }
    });
    const existingSet = new Set(
      existingStudents.map((s) => s.fullName.trim().toLowerCase())
    );

    const seenInBatch = new Set();
    const studentsToInsert = [];

    for (const rawName of studentNames) {
      const cleanName = String(rawName).trim();
      const lower = cleanName.toLowerCase();

      if (cleanName.length > 0 && !existingSet.has(lower) && !seenInBatch.has(lower)) {
        seenInBatch.add(lower);
        studentsToInsert.push({
          fullName: cleanName,
          classSectionId: classId
        });
      }
    }

    if (studentsToInsert.length > 0) {
      await prisma.student.createMany({
        data: studentsToInsert
      });
    }

    const updatedStudents = await prisma.student.findMany({
      where: { classSectionId: classId },
      orderBy: { fullName: 'asc' }
    });

    res.status(201).json({
      success: true,
      message: `Imported ${studentsToInsert.length} new students.`,
      addedCount: studentsToInsert.length,
      students: updatedStudents
    });
  } catch (error) {
    console.error('Import students error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to import students.'
    });
  }
});

router.delete('/:classId/students/:studentId', async (req, res) => {
  try {
    const classId = parseInt(req.params.classId, 10);
    const studentId = parseInt(req.params.studentId, 10);

    const section = await prisma.classSection.findFirst({
      where: { id: classId, teacherId: req.teacher.id }
    });

    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Class section not found or unauthorized.'
      });
    }

    const student = await prisma.student.findFirst({
      where: { id: studentId, classSectionId: classId }
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found in this class section.'
      });
    }

    await prisma.assessment.deleteMany({
      where: { studentId }
    });

    await prisma.student.delete({
      where: { id: studentId }
    });

    res.json({
      success: true,
      message: 'Student deleted successfully.'
    });
  } catch (error) {
    console.error('Delete student error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete student.'
    });
  }
});

module.exports = router;