const User = require('../models/User');
const { generateToken } = require('../jwt');

// SIGNUP
const signup = async (req, res) => {
    try {
        const user = new User(req.body);
        const savedUser = await user.save();

        const payload = {
            id: savedUser._id,
            email: savedUser.email
        };

        const token = generateToken(payload);

        res.status(201).json({
            message: "User registered successfully",
            token
        });
    } catch (err) {
        console.log(err);

        // Duplicate email (Mongo unique index violation)
        if (err.code === 11000) {
            return res.status(409).json({ error: 'An account with this email already exists' });
        }

        res.status(500).json({ error: err.message });
    }
};

// LOGIN
// Note: passport.authenticate('local', { session: false }) runs as
// middleware in the route before this controller executes, so req.user
// is already populated here.
const login = (req, res) => {
    const payload = {
        id: req.user._id,
        email: req.user.email
    };

    const token = generateToken(payload);

    res.status(200).json({
        message: "Login successful",
        token
    });
};

module.exports = { signup, login };