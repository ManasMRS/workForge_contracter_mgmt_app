const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../models/User.js');
const Employee = require('../models/Employee.js');
const Site = require('../models/Site.js');
const Machine = require('../models/Machine.js');
const Attendance = require('../models/Attendance.js');
const Salary = require('../models/Salary.js');

async function run() {
    const targetEmail = process.argv[2];

    if (!targetEmail) {
        console.error('Usage: node scripts/migrate-add-userid.js user@example.com');
        process.exit(1);
    }

    const mongoURL = process.env.MONGODB_URL_LOCAL || process.env.MONGODB_URL;
    if (!mongoURL) {
        console.error('No MONGODB_URL_LOCAL or MONGODB_URL found in .env');
        process.exit(1);
    }

    await mongoose.connect(mongoURL);
    console.log('Connected to MongoDB');

    const user = await User.findOne({ email: targetEmail.toLowerCase() });
    if (!user) {
        console.error(`No user found with email: ${targetEmail}`);
        await mongoose.disconnect();
        process.exit(1);
    }

    console.log(`Assigning orphaned records to: ${user.email} (${user._id})`);

    const models = [
        { name: 'Employee', model: Employee },
        { name: 'Site', model: Site },
        { name: 'Machine', model: Machine },
        { name: 'Attendance', model: Attendance },
        { name: 'Salary', model: Salary }
    ];

    for (const { name, model } of models) {
        // Match documents where userId is missing or null
        const filter = { $or: [{ userId: { $exists: false } }, { userId: null }] };

        const countBefore = await model.countDocuments(filter);
        if (countBefore === 0) {
            console.log(`${name}: nothing to migrate`);
            continue;
        }

        const result = await model.updateMany(filter, { $set: { userId: user._id } });
        console.log(`${name}: updated ${result.modifiedCount} of ${countBefore} orphaned record(s)`);
    }

    console.log('Migration complete.');
    await mongoose.disconnect();
}

run().catch(async (err) => {
    console.error('Migration failed:', err);
    await mongoose.disconnect();
    process.exit(1);
});