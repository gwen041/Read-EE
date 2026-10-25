const express = require('express');
const prisma = require('../prisma');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.use(authMiddleware);

router.get('/', async (req, res) => {
  try {
    const assessments = await prisma.assessment.findMany({
      where: {
        student: {
          classSection: {
            teacherId: req.teacher.id,
          },
        },
      },
      include: {
        student: {
          include: {
            classSection: true,
          },
        },
        readingMaterial: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    res.json({ assessments });
  } catch (error) {
    console.error('Error fetching assessments:', error);
    res.status(500).json({ message: 'Failed to fetch assessments.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const {
      studentId,
      readingMaterialId,
      accuracy,
      wpm,
      comprehensionScore,
      classification,
      accuracyDetails,
      comprehensionDetails,
    } = req.body;

    const parsedStudentId = Number(studentId);
    const parsedMaterialId = Number(readingMaterialId);

    if (!Number.isInteger(parsedStudentId) || !Number.isInteger(parsedMaterialId)) {
      return res.status(400).json({
        message: 'Valid studentId and readingMaterialId are required.',
      });
    }

    const student = await prisma.student.findFirst({
      where: {
        id: parsedStudentId,
        classSection: {
          teacherId: req.teacher.id,
        },
      },
    });

    if (!student) {
      return res.status(404).json({
        message: 'Student not found or access denied.',
      });
    }

    const material = await prisma.readingMaterial.findFirst({
      where: {
        id: parsedMaterialId,
        OR: [
          { materialType: 'BUILT_IN' },
          { teacherId: req.teacher.id },
        ],
      },
    });

    if (!material) {
      return res.status(404).json({
        message: 'Reading material not found or access denied.',
      });
    }

    const assessment = await prisma.assessment.create({
      data: {
        studentId: parsedStudentId,
        readingMaterialId: parsedMaterialId,
        accuracy: Number(accuracy),
        wpm: Number(wpm),
        comprehensionScore: Math.round(Number(comprehensionScore)),
        classification: String(classification),
        accuracyDetails: accuracyDetails || undefined,
        comprehensionDetails: comprehensionDetails || undefined,
      },
      include: {
        student: {
          include: {
            classSection: true,
          },
        },
        readingMaterial: true,
      },
    });

    res.status(201).json({
      message: 'Assessment saved successfully.',
      assessment,
    });
  } catch (error) {
    console.error('Error saving assessment:', error);
    res.status(500).json({ message: 'Failed to save assessment.' });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const assessmentId = Number(req.params.id);

    if (!Number.isInteger(assessmentId)) {
      return res.status(400).json({ message: 'Invalid assessment ID.' });
    }

    const existing = await prisma.assessment.findFirst({
      where: {
        id: assessmentId,
        student: {
          classSection: {
            teacherId: req.teacher.id,
          },
        },
      },
    });

    if (!existing) {
      return res.status(404).json({
        message: 'Assessment not found or access denied.',
      });
    }

    const {
      accuracy,
      wpm,
      comprehensionScore,
      classification,
      accuracyDetails,
      comprehensionDetails,
    } = req.body;

    const updated = await prisma.assessment.update({
      where: { id: assessmentId },
      data: {
        accuracy: accuracy !== undefined ? Number(accuracy) : existing.accuracy,
        wpm: wpm !== undefined ? Number(wpm) : existing.wpm,
        comprehensionScore:
          comprehensionScore !== undefined
            ? Math.round(Number(comprehensionScore))
            : existing.comprehensionScore,
        classification:
          classification !== undefined
            ? String(classification)
            : existing.classification,
        accuracyDetails:
          accuracyDetails !== undefined
            ? accuracyDetails
            : existing.accuracyDetails,
        comprehensionDetails:
          comprehensionDetails !== undefined
            ? comprehensionDetails
            : existing.comprehensionDetails,
      },
      include: {
        student: {
          include: {
            classSection: true,
          },
        },
        readingMaterial: true,
      },
    });

    res.json({
      message: 'Assessment updated successfully.',
      assessment: updated,
    });
  } catch (error) {
    console.error('Error updating assessment:', error);
    res.status(500).json({ message: 'Failed to update assessment.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const assessmentId = Number(req.params.id);

    if (!Number.isInteger(assessmentId)) {
      return res.status(400).json({ message: 'Invalid assessment ID.' });
    }

    const existing = await prisma.assessment.findFirst({
      where: {
        id: assessmentId,
        student: {
          classSection: {
            teacherId: req.teacher.id,
          },
        },
      },
    });

    if (!existing) {
      return res.status(404).json({
        message: 'Assessment not found or access denied.',
      });
    }

    await prisma.assessment.delete({
      where: { id: assessmentId },
    });

    res.json({ message: 'Assessment deleted successfully.' });
  } catch (error) {
    console.error('Error deleting assessment:', error);
    res.status(500).json({ message: 'Failed to delete assessment.' });
  }
});

module.exports = router;
