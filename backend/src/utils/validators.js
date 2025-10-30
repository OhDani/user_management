const Joi = require('joi');

const registerSchema = Joi.object({
  username: Joi.string().trim().min(3).max(50).required(),
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required(),
  image: Joi.string().uri().allow(null, '').optional(),
}).options({ allowUnknown: false });

const updateSchema = Joi.object({
  username: Joi.string().trim().min(3).max(50),
  email: Joi.string().email(),
  password: Joi.string().min(6),
  image: Joi.string().uri().allow(null, ''),
})
  .min(1)
  .options({ allowUnknown: false });

module.exports = { registerSchema, updateSchema };