const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');

router.post('/register', register); // Body: { username, email, password, image? }
router.post('/login', login);       // Body: { email, password }

module.exports = router;