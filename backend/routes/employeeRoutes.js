const express = require('express');
const router = express.Router();

const { jwtAuthMiddleware } = require('../jwt.js');
const {
    createEmployee,
    getAllEmployees,
    getEmployeeById,
    updateEmployee,
    deleteEmployee
} = require('../controllers/employeeController.js');

router.post('/', jwtAuthMiddleware, createEmployee);
router.get('/', jwtAuthMiddleware, getAllEmployees);
router.get('/:id', jwtAuthMiddleware, getEmployeeById);
router.put('/:id', jwtAuthMiddleware, updateEmployee);
router.delete('/:id', jwtAuthMiddleware, deleteEmployee);

module.exports = router;