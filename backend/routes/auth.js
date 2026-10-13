const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const prisma = require('../prisma');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;

    if (!fullName || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Full name, email, and password are required.'
      });
    }

    const trimmedEmail = email.trim().toLowerCase();
    const trimmedName = fullName.trim();

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long.'
      });
    }

    const existingTeacher = await prisma.teacher.findUnique({
      where: { email: trimmedEmail }
    });

    if (existingTeacher) {
      return res.status(409).json({
        success: false,
        message: 'An account with this email already exists.'
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const teacher = await prisma.teacher.create({
      data: {
        fullName: trimmedName,
        email: trimmedEmail,
        passwordHash: passwordHash
      }
    });

    const token = jwt.sign(
      {
        id: teacher.id,
        email: teacher.email,
        fullName: teacher.fullName
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      token,
      teacher: {
        id: teacher.id,
        fullName: teacher.fullName,
        email: teacher.email
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed due to a server error.'
    });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required.'
      });
    }

    const trimmedEmail = email.trim().toLowerCase();

    const teacher = await prisma.teacher.findUnique({
      where: { email: trimmedEmail }
    });

    if (!teacher) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    const isPasswordValid = await bcrypt.compare(password, teacher.passwordHash);

    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password.'
      });
    }

    const token = jwt.sign(
      {
        id: teacher.id,
        email: teacher.email,
        fullName: teacher.fullName
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      message: 'Login successful.',
      token,
      teacher: {
        id: teacher.id,
        fullName: teacher.fullName,
        email: teacher.email
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed due to a server error.'
    });
  }
});

router.get('/me', authMiddleware, async (req, res) => {
  try {
    const teacher = await prisma.teacher.findUnique({
      where: { id: req.teacher.id },
      select: {
        id: true,
        fullName: true,
        email: true,
        createdAt: true
      }
    });

    if (!teacher) {
      return res.status(404).json({
        success: false,
        message: 'Teacher not found.'
      });
    }

    res.json({
      success: true,
      teacher
    });
  } catch (error) {
    console.error('Fetch profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch teacher profile.'
    });
  }
});

module.exports = router;