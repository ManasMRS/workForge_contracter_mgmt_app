const jwt = require('jsonwebtoken');

const jwtAuthMiddleware = (req, res, next) => {
    //first check if the request header hasauthorization or not
    const authorization = req.headers.authorization
    if(!authorization) return res.status(401).json({error: 'Token not found'});

    //Extract the jwt token from the request headers
    const token = req.headers.authorization.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Unauthorize' });
    try {
        //verify the JWT token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        //Attach user information to the request object
        req.user = decoded
        next();
    } catch (err) {
        console.log(err);
        res.status(401).json({ error: 'Invalid token' });

    }

}

//Function to generate JWT Token
const generateToken = (userData) => {
    //Generate a new JWT token using user data
    return jwt.sign(userData, process.env.JWT_SECRET,{expiresIn: 30000});

}
module.exports = { jwtAuthMiddleware, generateToken };