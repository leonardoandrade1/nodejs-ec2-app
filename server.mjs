import express from 'express';

const app = express();

app.use(express.json());

router.get('/health', (req, res) => {
  res.send({
    status: 'ok',
  });
});

const router = express.Router();

router.get('/', (req, res) => {
  res.send('Hello GET!\n');
});
router.post('/post', (req, res) => {
  res.send('Hello POST!\n');
});

app.use('/v1', router);

app.listen(3000, () => {
  console.log('Server is running on http://0.0.0.0:3000');
});