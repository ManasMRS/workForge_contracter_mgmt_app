const express = require('express');
const router = express.Router();

const { jwtAuthMiddleware } = require('../jwt.js');
const {
    createSite,
    getAllSites,
    getSiteById,
    updateSite,
    deleteSite
} = require('../controllers/siteController.js');

router.post('/', jwtAuthMiddleware, createSite);
router.get('/', jwtAuthMiddleware, getAllSites);
router.get('/:id', jwtAuthMiddleware, getSiteById);
router.put('/:id', jwtAuthMiddleware, updateSite);
router.delete('/:id', jwtAuthMiddleware, deleteSite);

module.exports = router;