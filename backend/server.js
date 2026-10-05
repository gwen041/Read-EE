const express = require('express');
const { spawn } = require('child_process');
const multer = require('multer');
const path = require('path');
const cors = require('cors');

const app = express();

app.use(cors());

const upload = multer({
  dest: 'uploads/'
});

app.use(express.json());

const PORT = 3000;

const PYTHON_PATH =
  'C:\\github_projects\\read-ee\\speech-recognition\\.venv\\Scripts\\python.exe';

const PYTHON_SCRIPT =
  'C:\\github_projects\\read-ee\\speech-recognition\\api_assessment.py';

const PYTHON_CWD =
  'C:\\github_projects\\read-ee\\speech-recognition';


app.get('/', (req, res) => {
  res.send('Read-EE Backend is running!');
});


app.get('/api/test', (req, res) => {
  res.json({
    message: 'Read-EE API is working!'
  });
});


/*
 * Initial assessment
 *
 * Flutter sends:
 * - audioFile
 * - expectedText
 * - studentAnswers
 */
app.post(
  '/api/assessment',
  upload.single('audioFile'),
  (req, res) => {

    if (!req.file) {
      return res.status(400).json({
        message: 'Audio file is required.'
      });
    }

    const python = spawn(
      PYTHON_PATH,
      [PYTHON_SCRIPT],
      {
        cwd: PYTHON_CWD
      }
    );

    const assessmentData = {
      action: 'assessment',
      audioFile: path.resolve(req.file.path),
      expectedText: req.body.expectedText,
      studentAnswers: JSON.parse(
        req.body.studentAnswers
      )
    };

    python.stdin.write(
      JSON.stringify(assessmentData)
    );

    python.stdin.end();

    let output = '';

    python.stdout.on('data', (data) => {
      output += data.toString();
    });

    python.stderr.on('data', (data) => {
      console.error(`Python: ${data}`);
    });

    python.on('close', (code) => {

      console.log(
        `Python process exited with code ${code}`
      );

      if (code !== 0) {
        return res.status(500).json({
          message: 'Assessment failed.'
        });
      }

      try {
        const result = JSON.parse(output);

        res.json(result);

      } catch (error) {
        console.error(error);

        res.status(500).json({
          message: 'Invalid response from Python.'
        });
      }
    });
  }
);


/*
 * Finalize assessment after teacher verification
 *
 * Flutter sends:
 * - original accuracy result
 * - WPM result
 * - comprehension result
 * - teacher decisions
 */
app.post('/api/assessment/finalize', (req, res) => {

  const {
    accuracy,
    wpm,
    comprehension,
    decisions
  } = req.body;

  if (
    !accuracy ||
    !wpm ||
    !comprehension ||
    !decisions
  ) {
    return res.status(400).json({
      message: 'Assessment results and teacher decisions are required.'
    });
  }

  const python = spawn(
    PYTHON_PATH,
    [PYTHON_SCRIPT],
    {
      cwd: PYTHON_CWD
    }
  );

  const finalizationData = {
    action: 'finalize',
    accuracy: accuracy,
    wpm: wpm,
    comprehension: comprehension,
    decisions: decisions
  };

  python.stdin.write(
    JSON.stringify(finalizationData)
  );

  python.stdin.end();

  let output = '';

  python.stdout.on('data', (data) => {
    output += data.toString();
  });

  python.stderr.on('data', (data) => {
    console.error(`Python: ${data}`);
  });

  python.on('close', (code) => {

    console.log(
      `Python finalization process exited with code ${code}`
    );

    if (code !== 0) {
      return res.status(500).json({
        message: 'Assessment finalization failed.'
      });
    }

    try {
      const result = JSON.parse(output);

      res.json(result);

    } catch (error) {
      console.error(error);

      res.status(500).json({
        message: 'Invalid response from Python.'
      });
    }
  });
});


app.get('/api/python-test', (req, res) => {

  const python = spawn(
    'python',
    ['python_test.py']
  );

  python.stdout.on('data', (data) => {
    console.log(`Python: ${data}`);
  });

  python.stderr.on('data', (data) => {
    console.error(`Python error: ${data}`);
  });

  python.on('close', (code) => {

    console.log(
      `Python test completed with code ${code}`
    );

    res.json({
      message: 'Python test completed!',
      exitCode: code
    });
  });
});


app.listen(PORT, () => {
  console.log(
    `Server running on http://localhost:${PORT}`
  );
});