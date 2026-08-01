const mongoose = require('mongoose');

const MachineItemScheema = new mongoose.Schema({
    // NEW: ties this record to the account that created it
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },

    machineName: {
        type: String,
        required: true
    },
    machineType: {
        type: String,
        required: true
    },
    condition: {
        type: String,
        required: true
    },
    available: {
        type: String,
        required: true
    },
    inUse: {
        type: Boolean,
        required: true
    },
    underMaintenance: {
        type: Boolean,
        required: true
    },
});

const MachineItem = mongoose.model('MachineItem', MachineItemScheema);
module.exports = MachineItem;