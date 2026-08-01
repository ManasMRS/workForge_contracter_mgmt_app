const express = require('express');
const router = express.Router();

const { jwtAuthMiddleware } = require('../jwt.js');
const {
    createSalary,
    getAllSalaries,
    getSalaryById,
    updateSalary,
    deleteSalary
} = require('../controllers/salaryController.js');

router.post('/', jwtAuthMiddleware, createSalary);
router.get('/', jwtAuthMiddleware, getAllSalaries);
router.get('/:id', jwtAuthMiddleware, getSalaryById);
router.put('/:id', jwtAuthMiddleware, updateSalary);
router.delete('/:id', jwtAuthMiddleware, deleteSalary);

module.exports = router;