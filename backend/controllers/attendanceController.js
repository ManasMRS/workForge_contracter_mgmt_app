const Attendance = require('../models/Attendance.js');

const createAttendance = async (req, res) => {
    try {
        const attendance = new Attendance({
            ...req.body,
            userId: req.user.id
        });
        const response = await attendance.save();

        console.log('Attendance saved');
        res.status(201).json(response);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAllAttendance = async (req, res) => {
    try {
        const data = await Attendance.find({ userId: req.user.id })
            .populate('employeeId')
            .populate('siteId');

        console.log('Attendance fetched');
        res.status(200).json(data);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAttendanceById = async (req, res) => {
    try {
        const attendance = await Attendance.findOne({ _id: req.params.id, userId: req.user.id })
            .populate('employeeId')
            .populate('siteId');

        if (!attendance) {
            return res.status(404).json({ error: 'Attendance not found' });
        }

        res.status(200).json(attendance);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const updateAttendance = async (req, res) => {
    try {
        const updatedAttendance = await Attendance.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!updatedAttendance) {
            return res.status(404).json({ error: 'Attendance not found' });
        }

        console.log('Attendance updated');
        res.status(200).json(updatedAttendance);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const deleteAttendance = async (req, res) => {
    try {
        const deletedAttendance = await Attendance.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!deletedAttendance) {
            return res.status(404).json({ error: 'Attendance not found' });
        }

        console.log('Attendance deleted');
        res.status(200).json({ message: 'Attendance deleted successfully' });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    createAttendance,
    getAllAttendance,
    getAttendanceById,
    updateAttendance,
    deleteAttendance
};