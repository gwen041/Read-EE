const express = require('express');
const prisma = require('../prisma');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

// Require logged-in teacher for all materials routes
router.use(authMiddleware);

// Helper to normalize grade level input
function parseGrade(grade) {
  if (typeof grade === 'number') return grade;
  const match = String(grade).match(/\d+/);
  return match ? parseInt(match[0], 10) : null;
}

// 1. GET /api/materials - List available materials (with optional ?gradeLevel=4 filter)
router.get('/', async (req, res) => {
  try {
    const { gradeLevel } = req.query;

    const whereClause = {
      OR: [
        { materialType: 'BUILT_IN' },
        { teacherId: req.teacher.id }
      ]
    };

    // If gradeLevel is specified, only return materials for that grade
    if (gradeLevel) {
      const parsed = parseGrade(gradeLevel);
      if (parsed) {
        whereClause.gradeLevel = parsed;
      }
    }

    const materials = await prisma.readingMaterial.findMany({
      where: whereClause,
      include: {
        questions: {
          orderBy: { questionOrder: 'asc' }
        }
      },
      orderBy: [
        { gradeLevel: 'asc' },
        { createdAt: 'desc' }
      ]
    });

    res.json({
      success: true,
      materials
    });
  } catch (error) {
    console.error('Fetch materials error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reading materials.'
    });
  }
});

// 2. GET /api/materials/:id - Get specific material and its 5 questions
router.get('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);

    const material = await prisma.readingMaterial.findFirst({
      where: {
        id,
        OR: [
          { materialType: 'BUILT_IN' },
          { teacherId: req.teacher.id }
        ]
      },
      include: {
        questions: {
          orderBy: { questionOrder: 'asc' }
        }
      }
    });

    if (!material) {
      return res.status(404).json({
        success: false,
        message: 'Reading material not found or unauthorized.'
      });
    }

    res.json({
      success: true,
      material
    });
  } catch (error) {
    console.error('Fetch material error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch reading material.'
    });
  }
});

// 3. POST /api/materials - Create a teacher material with gradeLevel and 5 questions
router.post('/', async (req, res) => {
  try {
    const { title, passage, gradeLevel, questions } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Title is required.'
      });
    }

    if (!passage || !passage.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Reading passage is required.'
      });
    }

    // Validate grade level (4, 5, or 6)
    const grade = parseGrade(gradeLevel);
    if (!grade || ![4, 5, 6].includes(grade)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid grade level. Supported grades are 4, 5, and 6.'
      });
    }

    // Enforce exactly 5 comprehension questions
    if (!Array.isArray(questions) || questions.length !== 5) {
      return res.status(400).json({
        success: false,
        message: 'A reading material must have exactly 5 comprehension questions.'
      });
    }

    // Validate each question and choices
    const validatedQuestions = [];
    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const qText = q.questionText?.trim();
      const cA = q.choiceA?.trim();
      const cB = q.choiceB?.trim();
      const cC = q.choiceC?.trim();
      const cD = q.choiceD?.trim();
      const ans = q.correctAnswer?.trim().toUpperCase();

      if (!qText) {
        return res.status(400).json({
          success: false,
          message: `Question #${i + 1} text is required.`
        });
      }

      if (!cA || !cB || !cC || !cD) {
        return res.status(400).json({
          success: false,
          message: `Question #${i + 1} must have all 4 choices (A, B, C, and D).`
        });
      }

      if (!['A', 'B', 'C', 'D'].includes(ans)) {
        return res.status(400).json({
          success: false,
          message: `Question #${i + 1} correct answer must be A, B, C, or D.`
        });
      }

      validatedQuestions.push({
        questionOrder: i + 1,
        questionText: qText,
        choiceA: cA,
        choiceB: cB,
        choiceC: cC,
        choiceD: cD,
        correctAnswer: ans
      });
    }

    // Save atomically in a Prisma transaction
    const newMaterial = await prisma.$transaction(async (tx) => {
      return await tx.readingMaterial.create({
        data: {
          title: title.trim(),
          passage: passage.trim(),
          gradeLevel: grade,
          materialType: 'TEACHER_CREATED',
          teacherId: req.teacher.id,
          questions: {
            create: validatedQuestions
          }
        },
        include: {
          questions: {
            orderBy: { questionOrder: 'asc' }
          }
        }
      });
    });

    res.status(201).json({
      success: true,
      message: 'Reading material created successfully.',
      material: newMaterial
    });
  } catch (error) {
    console.error('Create material error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create reading material.'
    });
  }
});

// 4. DELETE /api/materials/:id - Delete teacher-created material
router.delete('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);

    const material = await prisma.readingMaterial.findUnique({
      where: { id }
    });

    if (!material) {
      return res.status(404).json({
        success: false,
        message: 'Material not found.'
      });
    }

    // Cannot delete built-in materials
    if (material.materialType === 'BUILT_IN') {
      return res.status(403).json({
        success: false,
        message: 'Built-in reading materials cannot be deleted.'
      });
    }

    // Teachers can only delete their own materials
    if (material.teacherId !== req.teacher.id) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own materials.'
      });
    }

    // Check if any assessments are attached to this material
    const assessmentCount = await prisma.assessment.count({
      where: { readingMaterialId: id }
    });

    if (assessmentCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete material that has existing student assessments.'
      });
    }

    // Delete material (questions cascade automatically)
    await prisma.readingMaterial.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Material deleted successfully.'
    });
  } catch (error) {
    console.error('Delete material error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete reading material.'
    });
  }
});

module.exports = router;