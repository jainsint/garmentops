import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../core/ist_utils.dart';

class RegisterCuttingFormWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSave;
  final Map<String, dynamic>? initialData;

  const RegisterCuttingFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterCuttingFormWidget> createState() =>
      _RegisterCuttingFormWidgetState();
}

class _RegisterCuttingFormWidgetState extends State<RegisterCuttingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _consumptionCtrl = TextEditingController();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  static const List<String> _sizes = [
    'S',
    'M',
    'L',
    'XL',
    '2XL',
    '3XL',
    '4XL',
    '5XL',
    '6XL',
  ];
  final Map<String, TextEditingController> _sizeControllers = {
    for (final s in ['S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL'])
      s: TextEditingController(text: '0'),
  };

  int get _total => _sizeControllers.values
      .map((c) => int.tryParse(c.text) ?? 0)
      .fold(0, (a, b) => a + b);

  final DateTime _selectedDate = ISTUtils.today();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Pre-fill for edit mode
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _styleCtrl.text = d['styleNo'] as String? ?? '';
      _colorCtrl.text = d['color'] as String? ?? '';
      _designCtrl.text = d['designNo'] as String? ?? '';
      // avgConsumption stored as "Xm", strip the 'm'
      final cons = d['avgConsumption'] as String? ?? '';
      _consumptionCtrl.text = cons.endsWith('m')
          ? cons.substring(0, cons.length - 1)
          : cons;
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
    _colorCtrl.dispose();
    _designCtrl.dispose();
    _consumptionCtrl.dispose();
    for (final c in _sizeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            _sectionLabel(theme, 'Style Details'),
            const SizedBox(height: 10),
            _buildField(
              _styleCtrl,
              'Style No *',
              'e.g. ST-2401',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _colorCtrl,
                    'Color *',
                    'e.g. Navy Blue',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    _designCtrl,
                    'Design No *',
                    'e.g. D-101',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildField(
              _consumptionCtrl,
              'Avg Consumption (m)',
              'e.g. 1.45',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 20),
            _sectionLabel(theme, 'Size-wise Count'),
            const SizedBox(height: 10),
            _buildSizeMatrix(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pieces',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '$_total pcs',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Cutting Entry'),
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
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
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

  Widget _buildSizeMatrix() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: _sizes
                    .map(
                      (s) => SizedBox(
                        width: 58,
                        child: Center(
                          child: Text(
                            s,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: _sizes.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      width: 52,
                      height: 48,
                      child: TextFormField(
                        controller: _sizeControllers[s],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurfaceLight,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.surfaceVariantLight,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.outlineVariantLight,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final sizeData = {
        for (final s in _sizes) s: int.tryParse(_sizeControllers[s]!.text) ?? 0,
      };
      final data = {
        'orderId': _selectedOrder?['id'],
        'styleNo': _styleCtrl.text.trim(),
        'color': _colorCtrl.text.trim(),
        'designNo': _designCtrl.text.trim(),
        'avgConsumption': _consumptionCtrl.text.trim(),
        ...sizeData,
        'total': _total,
        'date': ISTUtils.todayString(),
      };
      widget.onSave(data);
    }
  }
}
