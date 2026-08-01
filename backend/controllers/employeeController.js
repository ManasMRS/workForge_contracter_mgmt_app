const Employee = require('../models/Employee.js');

const createEmployee = async (req, res) => {
    try {
        const employee = new Employee({
            ...req.body,
            userId: req.user.id
        });
        const response = await employee.save();

        console.log('Employee created');
        res.status(201).json(response);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getAllEmployees = async (req, res) => {
    try {
        const employees = await Employee.find({ userId: req.user.id }).populate('currentSite');

        console.log('Employees fetched');
        res.status(200).json(employees);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const getEmployeeById = async (req, res) => {
    try {
        const employee = await Employee.findOne({
            _id: req.params.id,
            userId: req.user.id
        }).populate('currentSite');

        if (!employee) {
            return res.status(404).json({ error: 'Employee not found' });
        }

        res.status(200).json(employee);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const updateEmployee = async (req, res) => {
    try {
        const updatedEmployee = await Employee.findOneAndUpdate(
            { _id: req.params.id, userId: req.user.id },
            req.body,
            { new: true, runValidators: true }
        );

        if (!updatedEmployee) {
            return res.status(404).json({ error: 'Employee not found' });
        }

        console.log('Employee updated');
        res.status(200).json(updatedEmployee);
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

const deleteEmployee = async (req, res) => {
    try {
        const deletedEmployee = await Employee.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!deletedEmployee) {
            return res.status(404).json({ error: 'Employee not found' });
        }

        console.log('Employee deleted');
        res.status(200).json({ message: 'Employee deleted successfully' });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    createEmployee,
    getAllEmployees,
    getEmployeeById,
    updateEmployee,
    deleteEmployee
};