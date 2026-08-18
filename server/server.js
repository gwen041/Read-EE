import express from 'express';

const app = express();
const PORT  = 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.send('Read-EE server is running!');
});

app.listen(PORT, () => {
  console.log(`Server is running at ${PORT}`);
});