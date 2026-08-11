import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
import '../../services/odoo_service.dart';

class DynamicFieldConfig {
  const DynamicFieldConfig({
    required this.key,
    required this.label,
    this.type = DynamicFieldType.text,
    this.required = false,
    this.options = const [],
    this.initialValue,
    this.hint,
    this.maxLines = 1,
  });

  final String key;
  final String label;
  final DynamicFieldType type;
  final bool required;
  final List<DynamicFieldOption> options;
  final dynamic initialValue;
  final String? hint;
  final int maxLines;
}

class DynamicFieldOption {
  const DynamicFieldOption({required this.value, required this.label});
  final dynamic value;
  final String label;
}

enum DynamicFieldType { text, multiline, date, select }

class DynamicForm extends StatefulWidget {
  const DynamicForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.submitLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
  });

  final List<DynamicFieldConfig> fields;
  final Future<void> Function(Map<String, dynamic> values) onSubmit;
  final String submitLabel;
  final String cancelLabel;

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      if (f.type == DynamicFieldType.text ||
          f.type == DynamicFieldType.multiline) {
        _controllers[f.key] = TextEditingController(
          text: f.initialValue?.toString() ?? '',
        );
      } else {
        _values[f.key] = f.initialValue;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.fields.map(_buildField),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(widget.cancelLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const AppLoadingIndicator(size: 18)
                      : Text(widget.submitLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(DynamicFieldConfig f) {
    String? requiredValidator(String? value) {
      if (!f.required) return null;
      if (value == null || value.trim().isEmpty) return 'Campo obligatorio';
      return null;
    }

    switch (f.type) {
      case DynamicFieldType.text:
      case DynamicFieldType.multiline:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            controller: _controllers[f.key],
            maxLines: f.type == DynamicFieldType.multiline ? f.maxLines : 1,
            decoration: InputDecoration(labelText: f.label, hintText: f.hint),
            validator: requiredValidator,
          ),
        );
      case DynamicFieldType.select:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<dynamic>(
            initialValue: _values[f.key],
            decoration: InputDecoration(labelText: f.label),
            items: f.options
                .map(
                  (o) => DropdownMenuItem<dynamic>(
                    value: o.value,
                    child: Text(o.label),
                  ),
                )
                .toList(),
            onChanged: (v) => _values[f.key] = v,
            validator: (v) {
              if (!f.required) return null;
              if (v == null) return 'Campo obligatorio';
              return null;
            },
          ),
        );
      case DynamicFieldType.date:
        final dt = _values[f.key] as DateTime?;
        final label = dt == null
            ? f.label
            : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 2),
                  lastDate: DateTime(now.year + 2),
                  initialDate: dt ?? now,
                );
                if (picked != null) setState(() => _values[f.key] = picked);
              },
              icon: Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(label),
            ),
          ),
        );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final payload = <String, dynamic>{};
    for (final f in widget.fields) {
      if (_controllers.containsKey(f.key)) {
        payload[f.key] = _controllers[f.key]!.text.trim();
      } else {
        payload[f.key] = _values[f.key];
      }
    }

    try {
      await widget.onSubmit(payload);
      if (mounted) Navigator.of(context).maybePop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(OdooService.prettyError(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
