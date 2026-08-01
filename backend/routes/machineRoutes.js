const express = require('express');
const router = express.Router();

const { jwtAuthMiddleware } = require('../jwt.js');
const {
    createMachine,
    getAllMachines,
    getMachineById,
    updateMachine,
    deleteMachine
} = require('../controllers/machineController.js');

router.post('/', jwtAuthMiddleware, createMachine);
router.get('/', jwtAuthMiddleware, getAllMachines);
router.get('/:id', jwtAuthMiddleware, getMachineById);
router.put('/:id', jwtAuthMiddleware, updateMachine);
router.delete('/:id', jwtAuthMiddleware, deleteMachine);

module.exports = router;