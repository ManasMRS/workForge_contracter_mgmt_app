const mongoose = require('mongoose');

const SiteSchema = new mongoose.Schema(
  {
    // NEW: ties this record to the account that created it
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },

    siteName: {
      type: String,
      required: true,
      trim: true
    },

    type: {
      type: String,
      enum: ['Home', 'Office', 'Road', 'Bridge', 'School', 'Hospital', 'Apartment', 'Other'],
      required: true
    },

    location: {
      type: String,
      required: true,
    },

    ownerName: {
      type: String,
      required: true,
      trim: true
    },

    startDate: {
      type: Date,
      required: true
    },

    expectedEndDate: {
      type: Date,
      required: true
    },

    status: {
      type: String,
      enum: ['Planning', 'In Progress', 'Completed', 'On Hold'],
      default: 'Planning'
    }
  },
  {
    timestamps: true
  }
);

const Site = mongoose.model('Site', SiteSchema);

module.exports = Site;