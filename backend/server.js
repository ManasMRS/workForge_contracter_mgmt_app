const express = require('express');
const app = express();

require('dotenv').config();

const db = require('./db.js');
const passport = require('./auth.js');


// ============================================================
// PORT
// ============================================================

const PORT = process.env.PORT || 1000;


// ============================================================
// MIDDLEWARE
// ============================================================

// Parse JSON request bodies BEFORE routes
app.use(express.json());

app.use(
    express.urlencoded({
        extended: true
    })
);


// ============================================================
// REQUEST LOGGER
// ============================================================

const logRequest = (req, res, next) => {

    console.log(
        `[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`
    );

    next();
};

app.use(logRequest);


// ============================================================
// PASSPORT
// ============================================================

app.use(passport.initialize());


// ============================================================
// ROOT / HEALTH CHECK
// ============================================================

app.get('/', (req, res) => {

    res.status(200).json({
        success: true,
        message: 'Welcome to Contractor Management App',
        status: 'Server is running',
        environment: process.env.NODE_ENV || 'development'
    });

});


// ============================================================
// HEALTH CHECK FOR RENDER
// ============================================================

app.get('/health', (req, res) => {

    res.status(200).json({
        success: true,
        message: 'WorkForge backend is healthy',
        timestamp: new Date().toISOString()
    });

});


// ============================================================
// ROUTES
// ============================================================

const employeeRoutes =
    require('./routes/employeeRoutes.js');

const attendanceRoutes =
    require('./routes/attendanceRoutes.js');

const salaryRoutes =
    require('./routes/salaryRoutes.js');

const siteRoutes =
    require('./routes/siteRoutes.js');

const machineRoutes =
    require('./routes/machineRoutes.js');

const authRoutes =
    require('./routes/authRoutes.js');

const aiRoutes =
    require('./routes/aiRoutes.js');


// ============================================================
// API ROUTES
// ============================================================

app.use(
    '/auth',
    authRoutes
);

app.use(
    '/employees',
    employeeRoutes
);

app.use(
    '/attendance',
    attendanceRoutes
);

app.use(
    '/salary',
    salaryRoutes
);

app.use(
    '/sites',
    siteRoutes
);

app.use(
    '/machines',
    machineRoutes
);


// ============================================================
// AI / ML ROUTE
// ============================================================

app.use(
    '/ai',
    aiRoutes
);


// ============================================================
// 404 HANDLER
// ============================================================

app.use((req, res) => {

    res.status(404).json({
        success: false,
        message: 'Route not found',
        path: req.originalUrl
    });

});


// ============================================================
// GLOBAL ERROR HANDLER
// ============================================================

app.use((err, req, res, next) => {

    console.error('Server Error:', err);

    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error'
    });

});


// ============================================================
// START SERVER
// ============================================================

app.listen(
    PORT,
    '0.0.0.0',
    () => {

        console.log(
            `========================================`
        );

        console.log(
            `WorkForge Backend Started`
        );

        console.log(
            `Port: ${PORT}`
        );

        console.log(
            `Environment: ${process.env.NODE_ENV || 'development'}`
        );

        console.log(
            `Health: http://localhost:${PORT}/health`
        );

        console.log(
            `AI API: http://localhost:${PORT}/ai`
        );

        console.log(
            `========================================`
        );

    }
);