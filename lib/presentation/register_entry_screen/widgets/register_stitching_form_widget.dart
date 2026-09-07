import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../core/ist_utils.dart';

class RegisterStitchingFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> data) onSave;

  const RegisterStitchingFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterStitchingFormWidget> createState() =>
      _RegisterStitchingFormWidgetState();
}

class _RegisterStitchingFormWidgetState
    extends State<RegisterStitchingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _productionQtyCtrl = TextEditingController();
  final _lineNumberCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  DateTime _selectedDate = ISTUtils.today();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    final d = widget.initialData;
    if (d != null) {
      _styleCtrl.text = d['styleNo'] ?? '';
      _productionQtyCtrl.text = '${d['productionQty'] ?? ''}';
      _lineNumberCtrl.text = d['lineNumber'] ?? '';
      _commentsCtrl.text = d['comments'] ?? '';
      if (d['date'] != null) {
        _selectedDate = DateTime.tryParse(d['date']) ?? ISTUtils.today();
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
    _productionQtyCtrl.dispose();
    _lineNumberCtrl.dispose();
    _commentsCtrl.dispose();
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'orderId': _selectedOrder?['id'],
        'styleNo': _styleCtrl.text.trim(),
        'productionQty': int.tryParse(_productionQtyCtrl.text) ?? 0,
        'lineNumber': _lineNumberCtrl.text.trim(),
        'comments': _commentsCtrl.text.trim(),
        'date': _selectedDate.toString().substring(0, 10),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Order (Optional)'),
            const SizedBox(height: 10),
            _buildOrderSelector(),
            const SizedBox(height: 20),
            _sectionLabel('Stitching Details'),
            const SizedBox(height: 10),
            // Date picker
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _selectedDate.toString().substring(0, 10),
                  ),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: AppTheme.onSurfaceLight,
                  ),
                  decoration: _inputDecoration(
                    'Date *',
                    Icons.calendar_today_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildField(
              _styleCtrl,
              'Style *',
              'e.g. ST-2401',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _productionQtyCtrl,
                    'Production Qty *',
                    '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    _lineNumberCtrl,
                    'Line Number *',
                    'e.g. Line 1',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentsCtrl,
              maxLines: 3,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppTheme.onSurfaceLight,
              ),
              decoration: InputDecoration(
                labelText: 'Comments',
                hintText: 'Optional notes...',
                filled: true,
                fillColor: AppTheme.surfaceVariantLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.outlineVariantLight,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                labelStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                ),
                hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.outlineLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Stitching Entry'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
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
          color: AppTheme.surfaceVariantLight,
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
      decoration: _inputDecoration(
        'Order No / Style No',
        Icons.assignment_outlined,
      ),
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

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.ibmPlexSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.mutedText,
        letterSpacing: 0.8,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppTheme.mutedText),
      filled: true,
      fillColor: AppTheme.surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppTheme.outlineVariantLight,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        color: AppTheme.mutedText,
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        color: AppTheme.onSurfaceLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppTheme.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.outlineVariantLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 13,
          color: AppTheme.mutedText,
        ),
        hintStyle: GoogleFonts.ibmPlexSans(
          fontSize: 13,
          color: AppTheme.outlineLight,
        ),
      ),
    );
  }
}
