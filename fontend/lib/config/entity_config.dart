enum FieldType { text, number, date, boolStatus, dropdown, enumSelect }

class FieldConfig {
  final String key; // JSON key sent to backend
  final String label; // shown to user
  final FieldType type;
  final bool required;

  // For dropdown fields: pull options live from another entity's endpoint.
  final String? dropdownEndpoint; // e.g. '/employees'
  final String? dropdownLabelKey; // e.g. 'name'

  // For enumSelect fields (matches Mongoose `enum`)
  final List<String>? options;

  const FieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.dropdownEndpoint,
    this.dropdownLabelKey,
    this.options,
  });
}

class EntityConfig {
  final String title; // e.g. 'Employees'
  final String endpoint; // e.g. '/employees'
  final String titleKey; // which field to show as the card headline
  final String? subtitleKey; // optional second line on the card
  final List<FieldConfig> fields;

  const EntityConfig({
    required this.title,
    required this.endpoint,
    required this.titleKey,
    this.subtitleKey,
    required this.fields,
  });
}

class EntityConfigs {
  static const employee = EntityConfig(
    title: 'Employees',
    endpoint: '/employees',
    titleKey: 'name',
    subtitleKey: 'role',
    fields: [
      FieldConfig(key: 'name', label: 'Full Name', type: FieldType.text),
      FieldConfig(key: 'phone', label: 'Phone', type: FieldType.text),
      FieldConfig(
          key: 'email', label: 'Email', type: FieldType.text, required: false),
      FieldConfig(key: 'address', label: 'Address', type: FieldType.text),
      FieldConfig(
        key: 'role',
        label: 'Role',
        type: FieldType.enumSelect,
        options: [
          'Mason', 'Helper', 'Carpenter', 'Electrician', 'Plumber',
          'Painter', 'Supervisor', 'Engineer', 'Operator', 'Other'
        ],
      ),
      FieldConfig(
          key: 'experience', label: 'Experience (yrs)', type: FieldType.number),
      FieldConfig(
          key: 'dailySalary', label: 'Daily Salary (₹)', type: FieldType.number),
      FieldConfig(
        key: 'currentSite',
        label: 'Current Site',
        type: FieldType.dropdown,
        required: false,
        dropdownEndpoint: '/sites',
        dropdownLabelKey: 'siteName',
      ),
      FieldConfig(
        key: 'status',
        label: 'Status',
        type: FieldType.enumSelect,
        options: ['Active', 'Inactive'],
        required: false,
      ),
    ],
  );

  static const site = EntityConfig(
    title: 'Sites',
    endpoint: '/sites',
    titleKey: 'siteName',
    subtitleKey: 'status',
    fields: [
      FieldConfig(key: 'siteName', label: 'Site Name', type: FieldType.text),
      FieldConfig(
        key: 'type',
        label: 'Type',
        type: FieldType.enumSelect,
        options: [
          'Home', 'Office', 'Road', 'Bridge', 'School', 'Hospital',
          'Apartment', 'Other'
        ],
      ),
      FieldConfig(key: 'location', label: 'Location', type: FieldType.text),
      FieldConfig(
          key: 'contractorName', label: 'Owner Name', type: FieldType.text),
      FieldConfig(key: 'startDate', label: 'Start Date', type: FieldType.date),
      FieldConfig(
          key: 'expectedEndDate',
          label: 'Expected End Date',
          type: FieldType.date),
      FieldConfig(
        key: 'status',
        label: 'Status',
        type: FieldType.enumSelect,
        options: ['Planning', 'In Progress', 'Completed', 'On Hold'],
        required: false,
      ),
    ],
  );

  static const machine = EntityConfig(
    title: 'Machines',
    endpoint: '/machines',
    titleKey: 'machineName',
    subtitleKey: 'machineType',
    fields: [
      FieldConfig(
          key: 'machineName', label: 'Machine Name', type: FieldType.text),
      FieldConfig(
          key: 'machineType', label: 'Machine Type', type: FieldType.text),
      FieldConfig(key: 'condition', label: 'Condition', type: FieldType.text),
      FieldConfig(
          key: 'available', label: 'Availability', type: FieldType.text),
      FieldConfig(key: 'inUse', label: 'In Use', type: FieldType.boolStatus),
      FieldConfig(
          key: 'underMaintenance',
          label: 'Under Maintenance',
          type: FieldType.boolStatus),
    ],
  );

  static const attendance = EntityConfig(
    title: 'Attendance',
    endpoint: '/attendance',
    titleKey: '_displayEmployee',
    subtitleKey: '_displaySite',
    fields: [
      FieldConfig(
        key: 'employeeId',
        label: 'Employee',
        type: FieldType.dropdown,
        dropdownEndpoint: '/employees',
        dropdownLabelKey: 'name',
      ),
      FieldConfig(
        key: 'siteId',
        label: 'Site',
        type: FieldType.dropdown,
        dropdownEndpoint: '/sites',
        dropdownLabelKey: 'siteName',
      ),
      FieldConfig(key: 'date', label: 'Date', type: FieldType.date),
      FieldConfig(key: 'status', label: 'Present', type: FieldType.boolStatus),
      FieldConfig(
          key: 'workingHours', label: 'Working Hours', type: FieldType.number),
    ],
  );

  static const salary = EntityConfig(
    title: 'Salary Records',
    endpoint: '/salary',
    titleKey: '_displayEmployee',
    subtitleKey: 'month',
    fields: [
      FieldConfig(
        key: 'employeeId',
        label: 'Employee',
        type: FieldType.dropdown,
        dropdownEndpoint: '/employees',
        dropdownLabelKey: 'name',
      ),
      FieldConfig(key: 'month', label: 'Month (e.g. 2026-07)', type: FieldType.text),
      FieldConfig(
          key: 'presentDays', label: 'Present Days', type: FieldType.number),
      FieldConfig(key: 'halfDays', label: 'Half Days', type: FieldType.number),
      FieldConfig(
          key: 'dailySalary', label: 'Daily Salary (₹)', type: FieldType.number),
      FieldConfig(
          key: 'totalSalary', label: 'Total Salary (₹)', type: FieldType.number),
      FieldConfig(
        key: 'paidStatus',
        label: 'Paid Status',
        type: FieldType.enumSelect,
        options: ['Pending', 'Paid'],
        required: false,
      ),
    ],
  );
}
