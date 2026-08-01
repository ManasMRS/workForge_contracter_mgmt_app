const mongoose = require('mongoose');

const AttendanceItemSchema = new mongoose.Schema({
    // NEW: ties this record to the account that created it
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    employeeId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Employee',
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    siteId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Site',
        required: true
    },
    status: {
        type: Boolean,
        required: true
    },
    workingHours: {
        type: Number,
        required: true
    },
});

// One attendance record per employee, per site, per day, per user's data set
AttendanceItemSchema.index(
    { userId: 1, employeeId: 1, siteId: 1, date: 1 },
    { unique: true }
);

const AttendanceItem = mongoose.model('AttendanceItem', AttendanceItemSchema);
module.exports = AttendanceItem;