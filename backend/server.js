const express = require('express');
const { spawn } = require('child_process');

const app = express();

app.use(express.json());

const PORT = 3000;

app.get('/', (req, res) => {
  res.send('Read-EE Backend is running!');
});

app.get('/api/test', (req, res) => {
  res.json(
    { message: 'Read-EE API is working!' }
  );
});

app.post('/api/assessment', (req, res) => {

  const python = spawn(
    'C:\\github_projects\\read-ee\\speech-recognition\\.venv\\Scripts\\python.exe',
    ['C:\\github_projects\\read-ee\\speech-recognition\\api_assessment.py'],
    {
      cwd: 'C:\\github_projects\\read-ee\\speech-recognition'
    }
  );

  python.stdin.write(JSON.stringify(req.body));
  python.stdin.end();

  let output = '';

  python.stdout.on('data', (data) => {
    output += data.toString();
  });

  python.stderr.on('data', (data) => {
    console.error(`Python: ${data}`);
  });

  python.on('close', (code) => {

    console.log(`Python process exited with code ${code}`);

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
});

app.get('/api/python-test', (req, res) => {
  const python = spawn('python', ['python_test.py']);

  python.stdout.on('data', (data) => {
    console.log(`Python: ${data}`);
  });

  python.stderr.on('data', (data) => {
    console.error(`Python error: ${data}`);
  });

  python.on('close', (code) => {
    console.log(`Python process exited with code ${code}`);

    res.json({
      message: 'Python test completed!',
      exitCode: code
    });
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});