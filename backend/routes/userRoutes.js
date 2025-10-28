const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const authMiddleware = require('../middleware/auth');

// 1. LOGIN
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user._id,
        username: user.username,
        email: user.email,
        image: user.image
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 2. GET ALL USERS (Protected)
router.get('/users', authMiddleware, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 3. GET USER BY ID (Protected)
router.get('/users/:id', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// 4. CREATE USER (Semi-Protected)
// Nếu chưa có user nào trong DB thì cho phép tạo mà không cần token (để tạo admin đầu tiên)
// Nếu đã có user => yêu cầu authMiddleware
router.post('/users', async (req, res, next) => {
    try {
      const userCount = await User.countDocuments();
  
      // Nếu DB chưa có user nào => bỏ qua authMiddleware
      if (userCount === 0) {
        return next(); // Cho phép chạy tiếp mà không cần xác thực
      }
  
      // Nếu đã có user => chạy qua middleware xác thực
      return authMiddleware(req, res, next);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }, async (req, res) => {
    try {
      const { username, email, password, image } = req.body;
  
      const existingUser = await User.findOne({ $or: [{ email }, { username }] });
      if (existingUser) {
        return res.status(400).json({ message: 'Username or email already exists' });
      }
  
      const user = new User({ username, email, password, image });
      await user.save();
  
      const userResponse = user.toObject();
      delete userResponse.password;
  
      res.status(201).json(userResponse);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  });

// 5. UPDATE USER (Protected)
router.put('/users/:id', authMiddleware, async (req, res) => {
  try {
    const { username, email, password, image } = req.body;
    const updateData = { username, email, image };

    // Nếu có password mới, hash nó
    if (password) {
      const bcrypt = require('bcryptjs');
      updateData.password = await bcrypt.hash(password, 10);
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// 6. DELETE USER (Protected)
router.delete('/users/:id', authMiddleware, async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;