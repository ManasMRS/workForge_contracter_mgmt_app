const express = require('express');

const router = express.Router();

const {
    predictSite
} = require('../controllers/aiController');

router.post('/predict', predictSite);

module.exports = router;