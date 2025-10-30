const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { registerSchema } = require('../utils/validators');

const signToken = (user) =>
  jwt.sign({ sub: user._id }, process.env.JWT_SECRET, { expiresIn: '7d' });

exports.register = async (req, res, next) => {
  try {
    const { value, error } = registerSchema.validate(req.body, {
      abortEarly: false,
    });
    if (error) {
      return res.status(400).json({
        message: 'Validation error',
        details: error.details.map((d) => d.message),
      });
    }

    const emailExists = await User.findOne({ email: value.email });
    if (emailExists) return res.status(409).json({ message: 'Email already exists' });

    const usernameExists = await User.findOne({ username: value.username });
    if (usernameExists) return res.status(409).json({ message: 'Username already exists' });

    const user = new User(value);
    await user.save();
    return res.status(201).json(user); // password đã bị loại ở toJSON
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // Lấy user kèm password để so sánh
    const user = await User.findOne({ email }).select('+password');
    if (!user) return res.status(401).json({ message: 'Invalid email or password' });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ message: 'Invalid email or password' });

    const token = signToken(user);
    const userObj = user.toObject();
    delete userObj.password;

    return res.status(200).json({ token, user: userObj });
  } catch (err) {
    next(err);
  }
};