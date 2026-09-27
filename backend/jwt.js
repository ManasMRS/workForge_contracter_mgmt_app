const jwt = require('jsonwebtoken');

const jwtAuthMiddleware = (req, res, next) => {
    const authorization = req.headers.authorization;

    // Check Authorization header
    if (!authorization) {
        return res.status(401).json({
            error: 'Token not found'
        });
    }

    // Expected format: Bearer <token>
    const parts = authorization.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
        return res.status(401).json({
            error: 'Invalid authorization format'
        });
    }

    const token = parts[1];

    try {
        if (!process.env.JWT_SECRET) {
            console.error('JWT_SECRET is not configured');
            return res.status(500).json({
                error: 'JWT configuration error'
            });
        }

        // Verify token
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET
        );

        // Attach decoded user information
        req.user = decoded;

        next();

    } catch (err) {
        console.error('JWT verification error:', err.message);

        return res.status(401).json({
            error: 'Invalid token'
        });
    }
};


// Generate JWT token
const generateToken = (userData) => {

    if (!process.env.JWT_SECRET) {
        throw new Error('JWT_SECRET is not configured');
    }

    return jwt.sign(
        userData,
        process.env.JWT_SECRET,
        {
            expiresIn: '7d'
        }
    );
};


module.exports = {
    jwtAuthMiddleware,
    generateToken
};