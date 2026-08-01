const mongoose = require('mongoose');

const SalarySchema = new mongoose.Schema(
  {
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

    month: {
      type: String,
      required: true
    },

    presentDays: {
      type: Number,
      required: true,
      default: 0
    },

    halfDays: {
      type: Number,
      required: true,
      default: 0
    },

    dailySalary: {
      type: Number,
      required: true
    },

    totalSalary: {
      type: Number,
      required: true
    },

    paidStatus: {
      type: String,
      enum: ['Pending', 'Paid'],
      default: 'Pending'
    }
  },
  {
    timestamps: true
  }
);

// Prevent duplicate salary records for the same employee and month, per user
SalarySchema.index(
  { userId: 1, employeeId: 1, month: 1 },
  { unique: true }
);

const Salary = mongoose.model('Salary', SalarySchema);

module.exports = Salary;