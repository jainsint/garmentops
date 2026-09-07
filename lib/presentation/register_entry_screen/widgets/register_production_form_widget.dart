import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../core/ist_utils.dart';

class RegisterProductionFormWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSave;

  const RegisterProductionFormWidget({required this.onSave, super.key});

  @override
  State<RegisterProductionFormWidget> createState() =>
      _RegisterProductionFormWidgetState();
}

class _RegisterProductionFormWidgetState
    extends State<RegisterProductionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _operationCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _achievedCtrl = TextEditingController();
  final _operatorCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  double get _efficiency {
    final target = int.tryParse(_targetCtrl.text) ?? 0;
    final achieved = int.tryParse(_achievedCtrl.text) ?? 0;
    if (target == 0) return 0;
    return (achieved / target) * 100;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseService.instance.getOrders();
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
        _styleCtrl.text = order['style_no'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _styleCtrl.dispose();
    _colorCtrl.dispose();
    _lineCtrl.dispose();
    _operationCtrl.dispose();
    _targetCtrl.dispose();
    _achievedCtrl.dispose();
    _operatorCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effColor = _efficiency >= 95
        ? AppTheme.success
        : _efficiency >= 85
        ? AppTheme.warning
        : _efficiency > 0
        ? AppTheme.error
        : AppTheme.mutedText;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'Order'),
            const SizedBox(height: 10),
            _buildOrderSelector(),
            const SizedBox(height: 20),
            _sectionLabel(theme, 'Production Details'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _styleCtrl,
                    'Style No *',
                    'ST-2401',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    _colorCtrl,
                    'Color *',
                    'Navy Blue',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _lineCtrl,
                    'Line No *',
                    'Line 1',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(_operationCtrl, 'Operation', 'Stitching'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildField(_operatorCtrl, 'Operator Name', 'Ravi Kumar'),
            const SizedBox(height: 20),
            _sectionLabel(theme, 'Target vs Achieved'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _targetCtrl,
                    'Target Qty *',
                    '200',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    _achievedCtrl,
                    'Achieved Qty *',
                    '185',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Efficiency auto-display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: effColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: effColor.withAlpha(77)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 18, color: effColor),
                      const SizedBox(width: 8),
                      Text(
                        'Efficiency',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: effColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_efficiency.toStringAsFixed(1)}%',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: effColor,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildField(_remarksCtrl, 'Remarks', 'Optional notes...'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Production Entry'),
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
      decoration: InputDecoration(
        labelText: 'Order No / Style No',
        hintText: 'Select order (optional)',
        prefixIcon: const Icon(
          Icons.assignment_outlined,
          size: 18,
          color: AppTheme.mutedText,
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 13,
          color: AppTheme.mutedText,
        ),
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
              '${o['order_no']}  ·  ${o['style_no']}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
            ),
          ),
        ),
      ],
      onChanged: _onOrderSelected,
    );
  }

  Widget _sectionLabel(ThemeData theme, String label) {
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
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

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'orderId': _selectedOrder?['id'],
        'styleNo': _styleCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'lineNo': _lineCtrl.text.trim(),
        'operation': _operationCtrl.text.trim(),
        'targetQty': int.tryParse(_targetCtrl.text) ?? 0,
        'achievedQty': int.tryParse(_achievedCtrl.text) ?? 0,
        'efficiency': _efficiency,
        'operatorName': _operatorCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
        'date': ISTUtils.todayString(),
      });
    }
  }
}
