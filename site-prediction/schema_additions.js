/*
 * ADDITIONS to your existing Site model (models/Site.js or similar).
 * Add these fields inside your existing SiteSchema — do not replace the
 * whole schema; merge these fields into the existing schema object.
 *
 * Why each field exists:
 *  - scopeMetrics: without a size, no cost/duration/machine model can work.
 *    Different site types use different dimensions, so this is an object
 *    rather than a single "size" number — only the relevant sub-fields
 *    are populated depending on type.
 *  - qualityTier / cityTier: same cost drivers used in the house/road
 *    estimator earlier — quality of finish and regional cost differences
 *    swing price by 40-90%, so leaving them out hurts accuracy.
 *  - actualEndDate: expectedEndDate is a plan, not an outcome.
 *    You need the real end date to learn true duration from history.
 *  - materialCost: there is currently no collection tracking material spend.
 *    Without this, total cost can only ever be estimated, not learned.
 *  - plannedWorkers: how many workers you intend to staff the job with
 *    before work begins; separate from attendance records created later.
 */

const siteSchema = new mongoose.Schema({
  // ...your existing site fields...

  scopeMetrics: {
    type: {
      areaSqft: { type: Number, min: 0, default: null },
      floors: { type: Number, min: 1, default: 1 },
      lengthFt: { type: Number, min: 0, default: null },
      widthFt: { type: Number, min: 0, default: null }
    },
    default: {}
  },

  qualityTier: {
    type: String,
    enum: ['basic', 'standard', 'premium'],
    default: 'standard'
  },

  cityTier: {
    type: String,
    enum: ['tier1', 'tier2', 'tier3'],
    default: 'tier2'
  },

  plannedWorkers: {
    type: Number,
    min: 0,
    default: null
  },

  actualEndDate: {
    type: Date,
    default: null
  },

  materialCost: {
    type: Number,
    min: 0,
    default: null
  }
});

/*
 * ADDITIONS to your existing Machine model (models/Machine.js or similar).
 * Mirrors Employee.currentSite — without this, you have no way to know
 * historically which machines were deployed to which site.
 */

const machineSchema = new mongoose.Schema({
  // ...your existing machine fields...

  currentSite: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Site',
    default: null
  }
});