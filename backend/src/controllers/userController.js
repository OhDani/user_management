const mongoose = require('mongoose');
const User = require('../models/User');
const { updateSchema, registerSchema } = require('../utils/validators');
const cloudinary = require('../config/cloudinary');

const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

exports.getUsers = async (req, res, next) => {
  try {
    const users = await User.find(); // password bị exclude bởi select:false
    res.status(200).json(users);
  } catch (err) {
    next(err);
  }
};

exports.getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ message: 'Invalid user id' });

    const user = await User.findById(id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    res.status(200).json(user);
  } catch (err) {
    next(err);
  }
};

exports.createUser = async (req, res, next) => {
  try {
    const { value, error } = registerSchema.validate(req.body, { abortEarly: false });
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
    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
};

exports.updateUserPut = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ message: 'Invalid user id' });

    // PUT: cho phép cập nhật bất kỳ trường nào trong 4 trường, nhưng phải hợp lệ
    const { value, error } = updateSchema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        message: 'Validation error',
        details: error.details.map((d) => d.message),
      });
    }

    const user = await User.findById(id).select('+password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    // Kiểm tra trùng email/username nếu được cập nhật
    if (value.email && value.email !== user.email) {
      const exists = await User.findOne({ email: value.email });
      if (exists) return res.status(409).json({ message: 'Email already exists' });
    }
    if (value.username && value.username !== user.username) {
      const exists = await User.findOne({ username: value.username });
      if (exists) return res.status(409).json({ message: 'Username already exists' });
    }

    // Gán và save (để hook hash password chạy)
    ['username', 'email', 'password', 'image'].forEach((k) => {
      if (value[k] !== undefined) user[k] = value[k];
    });

    await user.save();
    const safe = await User.findById(id); // lấy lại bản không có password
    res.status(200).json(safe);
  } catch (err) {
    next(err);
  }
};

exports.updateUserPatch = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ message: 'Invalid user id' });

    const { value, error } = updateSchema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        message: 'Validation error',
        details: error.details.map((d) => d.message),
      });
    }

    const user = await User.findById(id).select('+password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (value.email && value.email !== user.email) {
      const exists = await User.findOne({ email: value.email });
      if (exists) return res.status(409).json({ message: 'Email already exists' });
    }
    if (value.username && value.username !== user.username) {
      const exists = await User.findOne({ username: value.username });
      if (exists) return res.status(409).json({ message: 'Username already exists' });
    }

    ['username', 'email', 'password', 'image'].forEach((k) => {
      if (value[k] !== undefined) user[k] = value[k];
    });

    await user.save();
    const safe = await User.findById(id);
    res.status(200).json(safe);
  } catch (err) {
    next(err);
  }
};

exports.deleteUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ message: 'Invalid user id' });

    const deleted = await User.findByIdAndDelete(id);
    if (!deleted) return res.status(404).json({ message: 'User not found' });

    res.status(200).json({ deleted: true });
  } catch (err) {
    next(err);
  }
};

exports.uploadImage = async (req, res, next) => {
  try {
    const { id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ message: 'Invalid user id' });

    // Kiểm tra file từ multer-storage-cloudinary
    if (!req.file) return res.status(400).json({ message: 'No image file provided' });

    const user = await User.findById(id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    // CloudinaryStorage đã upload tự động, chỉ cần lấy URL
    user.image = req.file.path; // CloudinaryStorage trả về đường dẫn qua req.file.path
    await user.save();

    const updatedUser = await User.findById(id);
    res.status(200).json(updatedUser);
  } catch (err) {
    err.status = err.name === 'MulterError' ? 400 : err.status;
    next(err);
  }
};