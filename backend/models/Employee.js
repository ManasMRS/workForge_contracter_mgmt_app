const mongoose = require('mongoose');
const bcrypt = require('bcrypt');   // <-- was missing

const EmployeeSchema = new mongoose.Schema(
  {
    // NEW: ties this record to the account that created it
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },

    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, required: false, unique: true, lowercase: true, trim: true },
    address: { type: String, required: true },


    role: {
      type: String,
      enum: ['Mason','Helper','Carpenter','Electrician','Plumber','Painter','Supervisor','Engineer','Operator','Other'],
      required: true
    },
    experience: { type: Number, required: true, min: 0 },
    dailySalary: { type: Number, required: true, min: 0 },
    joiningDate: { type: Date, required: true, default: Date.now },
    currentSite: { type: mongoose.Schema.Types.ObjectId, ref: 'Site', default: null },
    status: { type: String, enum: ['Active', 'Inactive'] }
  },
  { timestamps: true }
);

EmployeeSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

EmployeeSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

const Employee = mongoose.model('Employee', EmployeeSchema);
module.exports = Employee;