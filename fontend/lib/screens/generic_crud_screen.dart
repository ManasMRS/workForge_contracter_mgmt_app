import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/entity_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/gradient_button.dart';

class GenericCrudScreen extends StatefulWidget {
  final EntityConfig config;
  final AppMood mood;
  const GenericCrudScreen({super.key, required this.config, required this.mood});

  @override
  State<GenericCrudScreen> createState() => _GenericCrudScreenState();
}

class _GenericCrudScreenState extends State<GenericCrudScreen> {
  late Repository _repo;
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repo = Repository(context.read<AuthService>());
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.get(widget.config.endpoint);
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Failed to load');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _display(dynamic item, String key) {
    if (key == '_displayEmployee') {
      final v = item['employeeId'];
      if (v is Map) return v['name'] ?? '—';
      return 'Employee';
    }
    if (key == '_displaySite') {
      final v = item['siteId'];
      if (v is Map) return v['siteName'] ?? '—';
      return '';
    }
    final v = item[key];
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    return v.toString();
  }

  Future<void> _delete(dynamic item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Delete record?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.delete('${widget.config.endpoint}/${item['_id']}');
      _fetch();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e is ApiException ? e.message : 'Something went wrong'),
      backgroundColor: Colors.redAccent,
    ));
  }

  Future<void> _openForm({dynamic existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntityFormSheet(
        config: widget.config,
        mood: widget.mood,
        repo: _repo,
        existing: existing,
      ),
    );
    if (result == true) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      mood: widget.mood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(widget.config.title)),
        floatingActionButton: FloatingActionButton(
          backgroundColor: widget.mood.accent.first,
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: _fetch,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _fetch)
                  : _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text('No records yet — tap + to add one',
                                  style: TextStyle(color: Colors.white60)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            final title = _display(item, widget.config.titleKey);
                            final subtitle = widget.config.subtitleKey != null
                                ? _display(item, widget.config.subtitleKey!)
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16)),
                                          if (subtitle != null && subtitle.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(subtitle,
                                                  style: TextStyle(
                                                      color: Colors.white.withOpacity(0.6),
                                                      fontSize: 13)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.white70),
                                      onPressed: () => _openForm(existing: item),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.redAccent),
                                      onPressed: () => _delete(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Bottom-sheet form that renders the correct input widget for each
/// FieldConfig type and POST/PUTs to the entity's endpoint.
class _EntityFormSheet extends StatefulWidget {
  final EntityConfig config;
  final AppMood mood;
  final Repository repo;
  final dynamic existing;
  const _EntityFormSheet(
      {required this.config, required this.mood, required this.repo, this.existing});

  @override
  State<_EntityFormSheet> createState() => _EntityFormSheetState();
}

class _EntityFormSheetState extends State<_EntityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {}; // for bool / date / dropdown / enum
  final Map<String, List<dynamic>> _dropdownOptions = {};
  bool _saving = false;
  bool _loadingOptions = true;

  @override
  void initState() {
    super.initState();
    for (final f in widget.config.fields) {
      final rawValue = widget.existing != null ? widget.existing[f.key] : null;
      switch (f.type) {
        case FieldType.text:
        case FieldType.number:
          _controllers[f.key] =
              TextEditingController(text: rawValue?.toString() ?? '');
          break;
        case FieldType.boolStatus:
          _values[f.key] = rawValue == true;
          break;
        case FieldType.date:
          _values[f.key] = rawValue != null
              ? DateTime.tryParse(rawValue.toString())
              : DateTime.now();
          break;
        case FieldType.dropdown:
          // rawValue may be a populated object {_id, ...} or a raw id string
          _values[f.key] = rawValue is Map ? rawValue['_id'] : rawValue;
          break;
        case FieldType.enumSelect:
          _values[f.key] = rawValue;
          break;
      }
    }
    _loadDropdownOptions();
  }

  Future<void> _loadDropdownOptions() async {
    for (final f in widget.config.fields) {
      if (f.type == FieldType.dropdown && f.dropdownEndpoint != null) {
        try {
          final data = await widget.repo.get(f.dropdownEndpoint!);
          _dropdownOptions[f.key] = data;
        } catch (_) {
          _dropdownOptions[f.key] = [];
        }
      }
    }
    if (mounted) setState(() => _loadingOptions = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      for (final f in widget.config.fields) {
        switch (f.type) {
          case FieldType.text:
            body[f.key] = _controllers[f.key]!.text.trim();
            break;
          case FieldType.number:
            body[f.key] = num.tryParse(_controllers[f.key]!.text.trim()) ?? 0;
            break;
          case FieldType.boolStatus:
            body[f.key] = _values[f.key] ?? false;
            break;
          case FieldType.date:
            final d = _values[f.key] as DateTime? ?? DateTime.now();
            body[f.key] = d.toIso8601String();
            break;
          case FieldType.dropdown:
          case FieldType.enumSelect:
            body[f.key] = _values[f.key];
            break;
        }
      }

      if (widget.existing != null) {
        await widget.repo.put('${widget.config.endpoint}/${widget.existing['_id']}', body);
      } else {
        await widget.repo.post(widget.config.endpoint, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is ApiException ? e.message : 'Save failed'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField(FieldConfig f) {
    switch (f.type) {
      case FieldType.text:
        return TextFormField(
          controller: _controllers[f.key],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: f.label),
          validator: (v) =>
              f.required && (v == null || v.trim().isEmpty) ? 'Required' : null,
        );
      case FieldType.number:
        return TextFormField(
          controller: _controllers[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: f.label),
          validator: (v) {
            if (!f.required) return null;
            if (v == null || v.trim().isEmpty) return 'Required';
            if (num.tryParse(v) == null) return 'Enter a number';
            return null;
          },
        );
      case FieldType.boolStatus:
        return SwitchListTile(
          title: Text(f.label, style: const TextStyle(color: Colors.white)),
          value: _values[f.key] == true,
          activeColor: widget.mood.accent.first,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case FieldType.date:
        final d = _values[f.key] as DateTime?;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label, style: const TextStyle(color: Colors.white70)),
          subtitle: Text(
            d != null ? DateFormat('dd MMM yyyy').format(d) : 'Select date',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          trailing: const Icon(Icons.calendar_today_outlined, color: Colors.white70),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: d ?? DateTime.now(),
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _values[f.key] = picked);
          },
        );
      case FieldType.dropdown:
        final options = _dropdownOptions[f.key] ?? [];
        return DropdownButtonFormField<String>(
          value: _values[f.key],
          dropdownColor: const Color(0xFF1E1E2E),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: f.label),
          items: options
              .map<DropdownMenuItem<String>>((o) => DropdownMenuItem(
                    value: o['_id'] as String,
                    child: Text(
                      (o[f.dropdownLabelKey] ?? 'Unnamed').toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => f.required && v == null ? 'Required' : null,
        );
      case FieldType.enumSelect:
        return DropdownButtonFormField<String>(
          value: _values[f.key],
          dropdownColor: const Color(0xFF1E1E2E),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(labelText: f.label),
          items: (f.options ?? [])
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => f.required && v == null ? 'Required' : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14141F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, top: 12),
        child: _loadingOptions
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit ${widget.config.title}' : 'New ${widget.config.title}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    for (final f in widget.config.fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildField(f),
                      ),
                    const SizedBox(height: 8),
                    GradientButton(
                      label: isEdit ? 'Save Changes' : 'Create',
                      mood: widget.mood,
                      loading: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
