const express = require('express');
const router = express.Router();

const { jwtAuthMiddleware } = require('../jwt.js');
const {
    createAttendance,
    getAllAttendance,
    getAttendanceById,
    updateAttendance,
    deleteAttendance
} = require('../controllers/attendanceController.js');

router.post('/', jwtAuthMiddleware, createAttendance);
router.get('/', jwtAuthMiddleware, getAllAttendance);
router.get('/:id', jwtAuthMiddleware, getAttendanceById);
router.put('/:id', jwtAuthMiddleware, updateAttendance);
router.delete('/:id', jwtAuthMiddleware, deleteAttendance);

module.exports = router;