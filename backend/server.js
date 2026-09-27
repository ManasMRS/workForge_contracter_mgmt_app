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
        `[${new Date().toLocaleString()}] Request made to : ${req.originalUrl}`
    );

    next();
};

app.use(logRequest);


// ============================================================
// PASSPORT
// ============================================================

app.use(passport.initialize());

const localAuthMiddleware =
    passport.authenticate(
        'local',
        {
            session: false
        }
    );


// ============================================================
// ROOT ROUTE
// ============================================================

app.get('/', function (req, res) {

    res.send(
        'Welcome to contractor mgmt app'
    );

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
// START SERVER
// ============================================================

app.listen(
    PORT,
    () => {

        console.log(
            `Listening on port ${PORT}`
        );

    }
);