const Salary = require('../models/Salary.js');

const createSalary = async (req, res) => {
    try {
        const salary = new Salary({
            ...req.body,
            userId: req.user.id
        });
        const response = await salary.save();

        console.log('Salary created');
        res.status(201).json(response);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAllSalaries = async (req, res) => {
    try {
        const salaries = await Salary.find({ userId: req.user.id }).populate('employeeId');

        console.log('Salaries fetched');
        res.status(200).json(salaries);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getSalaryById = async (req, res) => {
    try {
        const salary = await Salary.findOne({ _id: req.params.id, userId: req.user.id })
            .populate('employeeId');

        if (!salary) {
            return res.status(404).json({ error: 'Salary not found' });
        }

        res.status(200).json(salary);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const updateSalary = async (req, res) => {
    try {
        const updatedSalary = await Salary.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!updatedSalary) {
            return res.status(404).json({ error: 'Salary not found' });
        }

        console.log('Salary updated');
        res.status(200).json(updatedSalary);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const deleteSalary = async (req, res) => {
    try {
        const deletedSalary = await Salary.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!deletedSalary) {
            return res.status(404).json({ error: 'Salary not found' });
        }

        console.log('Salary deleted');
        res.status(200).json({ message: 'Salary deleted successfully' });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    createSalary,
    getAllSalaries,
    getSalaryById,
    updateSalary,
    deleteSalary
};