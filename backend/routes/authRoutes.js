const express = require('express');
const router = express.Router();

const passport = require('../auth');
const { signup, login } = require('../controllers/authController');

router.post('/signup', signup);
router.post('/login', passport.authenticate('local', { session: false }), login);

module.exports = router;