import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../core/ist_utils.dart';

class RegisterCheckingFormWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSave;
  final Map<String, dynamic>? initialData;

  const RegisterCheckingFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterCheckingFormWidget> createState() =>
      _RegisterCheckingFormWidgetState();
}

class _RegisterCheckingFormWidgetState
    extends State<RegisterCheckingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _representativeCtrl = TextEditingController();

  DateTime _selectedDate = ISTUtils.today();
  String? _selectedType;

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  static const List<String> _typeOptions = [
    'In-line Check',
    'Final Check',
    'End-line Check',
    'Roving Check',
    'Pre-shipment Check',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _styleCtrl.text = d['styleNo'] as String? ?? '';
      _quantityCtrl.text = (d['quantity'] ?? '').toString();
      _representativeCtrl.text = d['representative'] as String? ?? '';
      _selectedType = d['type'] as String?;
      final dateStr = d['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedDate = DateTime.tryParse(dateStr) ?? ISTUtils.today();
      }
    }
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseService.instance.getClientOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loadingOrders = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _onOrderSelected(Map<String, dynamic>? order) {
    setState(() {
      _selectedOrder = order;
      if (order != null) {
        _styleCtrl.text = order['garment_type'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _styleCtrl.dispose();
    _quantityCtrl.dispose();
    _representativeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave({
        'orderId': _selectedOrder?['id'],
        'date': _formattedDate,
        'styleNo': _styleCtrl.text.trim(),
        'type': _selectedType ?? '',
        'quantity': int.tryParse(_quantityCtrl.text.trim()) ?? 0,
        'representative': _representativeCtrl.text.trim(),
        'status': 'inProgress',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Checking Entry',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order selector
            _FieldLabel(label: 'Order No / Style No'),
            const SizedBox(height: 6),
            _buildOrderSelector(),
            const SizedBox(height: 14),

            // Date
            _FieldLabel(label: 'Date'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.outlineVariantLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formattedDate,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Style
            _FieldLabel(label: 'Style'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _styleCtrl,
              decoration: _inputDecoration(hint: 'e.g. ST-2401'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Style is required' : null,
            ),
            const SizedBox(height: 14),

            // Type
            _FieldLabel(label: 'Type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _inputDecoration(hint: 'Select type'),
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppTheme.onSurfaceLight,
              ),
              items: _typeOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Type is required' : null,
            ),
            const SizedBox(height: 14),

            // Quantity
            _FieldLabel(label: 'Quantity'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _quantityCtrl,
              decoration: _inputDecoration(hint: 'e.g. 120'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Quantity is required';
                }
                if ((int.tryParse(v.trim()) ?? 0) <= 0) {
                  return 'Enter a valid quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Representative
            _FieldLabel(label: 'Representative'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _representativeCtrl,
              decoration: _inputDecoration(hint: 'e.g. Priya K'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Representative is required'
                  : null,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  'Save Checking Entry',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelector() {
    if (_loadingOrders) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outlineVariantLight),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return DropdownButtonFormField<Map<String, dynamic>>(
      initialValue: _selectedOrder,
      decoration: _inputDecoration(hint: 'Select order (optional)'),
      style: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        color: AppTheme.onSurfaceLight,
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem<Map<String, dynamic>>(
          value: null,
          child: Text(
            '— No order —',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              color: AppTheme.mutedText,
            ),
          ),
        ),
        ..._orders.map(
          (o) => DropdownMenuItem<Map<String, dynamic>>(
            value: o,
            child: Text(
              '${o['order_number']}  ·  ${o['client_name']}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
            ),
          ),
        ),
      ],
      onChanged: _onOrderSelected,
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        color: AppTheme.mutedText,
      ),
      filled: true,
      fillColor: AppTheme.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.outlineVariantLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.outlineVariantLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.onSurfaceLight,
      ),
    );
  }
}
