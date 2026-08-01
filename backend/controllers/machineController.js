const Machine = require('../models/Machine.js');

const createMachine = async (req, res) => {
    try {
        const machine = new Machine({
            ...req.body,
            userId: req.user.id
        });
        const response = await machine.save();

        console.log('Machine created');
        res.status(201).json(response);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAllMachines = async (req, res) => {
    try {
        const machines = await Machine.find({ userId: req.user.id });

        console.log('Machines fetched');
        res.status(200).json(machines);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getMachineById = async (req, res) => {
    try {
        const machine = await Machine.findOne({ _id: req.params.id, userId: req.user.id });

        if (!machine) {
            return res.status(404).json({ error: 'Machine not found' });
        }

        res.status(200).json(machine);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const updateMachine = async (req, res) => {
    try {
        const updatedMachine = await Machine.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!updatedMachine) {
            return res.status(404).json({ error: 'Machine not found' });
        }

        console.log('Machine updated');
        res.status(200).json(updatedMachine);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const deleteMachine = async (req, res) => {
    try {
        const deletedMachine = await Machine.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!deletedMachine) {
            return res.status(404).json({ error: 'Machine not found' });
        }

        console.log('Machine deleted');
        res.status(200).json({ message: 'Machine deleted successfully' });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    createMachine,
    getAllMachines,
    getMachineById,
    updateMachine,
    deleteMachine
};