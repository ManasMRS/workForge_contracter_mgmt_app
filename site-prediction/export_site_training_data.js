

const mongoose = require('mongoose');
const fs = require('fs');

// Adjust these requires to match your actual model file locations
const Site = require('./models/Site');
const Attendance = require('./models/Attendance');
const Employee = require('./models/Employee');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/workforge';

async function exportSiteTrainingData() {
  await mongoose.connect(MONGO_URI);

  // Only completed sites have a real (not just planned) duration and
  // a settled labour cost — in-progress sites would give incomplete numbers.
  const completedSites = await Site.find({ status: 'Completed' }).lean();

  const rows = [];

  for (const site of completedSites) {
    // Pull every attendance record logged against this site
    const attendanceRecords = await Attendance.find({ siteId: site._id })
      .populate('employeeId', 'dailySalary')
      .lean();

    if (attendanceRecords.length === 0) continue; // no labour data for this site, skip

    let labourCost = 0;
    const employeeIds = new Set();

    for (const record of attendanceRecords) {
      if (!record.status || !record.employeeId) continue; // absent or orphaned record
      const dailySalary = record.employeeId.dailySalary || 0;
      employeeIds.add(record.employeeId._id.toString());

      if (record.workingHours >= 8) {
        labourCost += dailySalary;
      } else if (record.workingHours > 0) {
        labourCost += dailySalary / 2;
      }
    }

    // Duration: prefer actualEndDate once you start filling it in;
    // fall back to expectedEndDate for now (less accurate, but usable).
    const endDate = site.actualEndDate || site.expectedEndDate;
    const durationDays = endDate && site.startDate
      ? Math.round((new Date(endDate) - new Date(site.startDate)) / (1000 * 60 * 60 * 24))
      : null;

    rows.push({
      site_id: site._id.toString(),
      site_type: site.type,
      city_tier: site.cityTier || '',              // blank until schema addition is filled in
      quality_tier: site.qualityTier || '',          // blank until schema addition is filled in
      scope_area_sqft: site.scopeMetrics?.areaSqft
        ?? (site.scopeMetrics?.lengthFt && site.scopeMetrics?.widthFt
              ? site.scopeMetrics.lengthFt * site.scopeMetrics.widthFt
              : ''),
      floors: site.scopeMetrics?.floors || 1,
      planned_workers: site.plannedWorkers || employeeIds.size,
      actual_workers: employeeIds.size,
      labour_cost_inr: Math.round(labourCost),
      material_cost_inr: site.materialCost ?? '',    // blank until you start logging it
      duration_days: durationDays ?? '',
    });
  }

  // Write as CSV
  const headers = Object.keys(rows[0] || {});
  const csvLines = [
    headers.join(','),
    ...rows.map(r => headers.map(h => r[h]).join(',')),
  ];
  fs.writeFileSync('real_site_training_data.csv', csvLines.join('\n'));

  console.log(`Exported ${rows.length} completed sites to real_site_training_data.csv`);
  await mongoose.disconnect();
}

exportSiteTrainingData().catch(err => {
  console.error(err);
  process.exit(1);
});
