const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');

const {
  getUsers,
  getUserById,
  createUser,
  updateUserPut,
  updateUserPatch,
  deleteUser,
  uploadImage,
} = require('../controllers/userController');

// Các route cần token
router.get('/', auth, getUsers);
router.get('/:id', auth, getUserById);
router.post('/', auth, createUser);
router.put('/:id', auth, updateUserPut);
router.patch('/:id', auth, updateUserPatch);
router.delete('/:id', auth, deleteUser);

// Upload ảnh bằng multipart/form-data (field name: "file")
router.post('/:id/image', auth, upload.single('file'), uploadImage);

module.exports = router;