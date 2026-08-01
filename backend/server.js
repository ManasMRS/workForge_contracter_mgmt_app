const express = require('express')
const app = express();
const db = require('./db.js'); // Import the database connection
require('dotenv').config(); // Load environment variables from .env file
const passport = require('./auth.js');




// Middleware to parse JSON request bodies
const bodyParser = require('body-parser');
app.use(bodyParser.json()); //req.body
const PORT = process.env.PORT || 1000; // Use the PORT from environment variables or default to 3000




//Middleware Function to log requests
const logRequest = (req, res, next) => {
        console.log(`[${new Date().toLocaleString()}] Request made to : ${req.originalUrl} `);
        next(); //Move to the next middleware or route handler

}
app.use(logRequest); // Apply the logging middleware to all routes




app.use(passport.initialize());
const localAuthMiddleware =  passport.authenticate('local',{session:false});

app.get('/',function (req, res) {
    res.send('Welcome to contractor mgmt app');
});


const employeeRoutes = require('./routes/employeeRoutes.js');
const attendanceRoutes = require('./routes/attendanceRoutes.js');
const salaryRoutes = require('./routes/salaryRoutes.js');
const siteRoutes = require('./routes/siteRoutes');
const machineRoutes = require('./routes/machineRoutes.js');
const authRoutes = require('./routes/authRoutes.js');

app.use('/auth', authRoutes);
app.use('/employees', employeeRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/salary', salaryRoutes);
app.use('/sites', siteRoutes);
app.use('/machines', machineRoutes);


app.listen(PORT, () => {
console.log(`Listening on port ${PORT}`);
})