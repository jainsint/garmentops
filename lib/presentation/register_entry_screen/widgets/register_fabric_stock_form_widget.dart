import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../core/ist_utils.dart';

class RegisterFabricStockFormWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSave;
  final Map<String, dynamic>? initialData;

  const RegisterFabricStockFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterFabricStockFormWidget> createState() =>
      _RegisterFabricStockFormWidgetState();
}

class _RegisterFabricStockFormWidgetState
    extends State<RegisterFabricStockFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _designCtrl = TextEditingController();
  final _colourCtrl = TextEditingController();
  final _totalUsedCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  DateTime _selectedDate = ISTUtils.today();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  final List<TextEditingController> _mtrControllers = [];
  static const int _initialRows = 13;

  XFile? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _totalUsedCtrl.addListener(_recalculate);

    if (widget.initialData != null) {
      final d = widget.initialData!;
      _styleCtrl.text = d['styleNo'] as String? ?? d['style'] as String? ?? '';
      _designCtrl.text = d['design'] as String? ?? '';
      _colourCtrl.text = d['colour'] as String? ?? '';
      _totalUsedCtrl.text = (d['totalUsed'] ?? '').toString();
      _remarksCtrl.text = d['remarks'] as String? ?? '';
      _existingPhotoUrl =
          d['swatchPhotoPath'] as String? ?? d['photoUrl'] as String?;
      final dateStr = d['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedDate = DateTime.tryParse(dateStr) ?? ISTUtils.today();
      }

      final rolls = d['rolls'];
      if (rolls != null && rolls is List && rolls.isNotEmpty) {
        final int rowCount = rolls.length > _initialRows
            ? rolls.length
            : _initialRows;
        for (int i = 0; i < rowCount; i++) {
          final ctrl = TextEditingController();
          ctrl.addListener(_recalculate);
          if (i < rolls.length) {
            final mtrs = rolls[i]['mtrs'];
            ctrl.text = mtrs != null && mtrs != 0 ? mtrs.toString() : '';
          }
          _mtrControllers.add(ctrl);
        }
      } else {
        for (int i = 0; i < _initialRows; i++) {
          final ctrl = TextEditingController();
          ctrl.addListener(_recalculate);
          _mtrControllers.add(ctrl);
        }
      }
    } else {
      for (int i = 0; i < _initialRows; i++) {
        final ctrl = TextEditingController();
        ctrl.addListener(_recalculate);
        _mtrControllers.add(ctrl);
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
          // FIX: Restore selected order when editing
          if (widget.initialData != null) {
            final orderId = widget.initialData!['orderId'];
            if (orderId != null) {
              _selectedOrder = _orders.firstWhere(
                (o) => o['id'].toString() == orderId.toString(),
                orElse: () => <String, dynamic>{},
              );
              if (_selectedOrder != null && _selectedOrder!.isEmpty) {
                _selectedOrder = null;
              }
            }
          }
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

  void _addRow() {
    final ctrl = TextEditingController();
    ctrl.addListener(_recalculate);
    setState(() => _mtrControllers.add(ctrl));
  }

  void _removeLastRow() {
    if (_mtrControllers.length <= 1) return;
    _mtrControllers.last.dispose();
    setState(() => _mtrControllers.removeLast());
  }

  int get _totalRolls => _mtrControllers
      .where((c) => (double.tryParse(c.text.trim()) ?? 0) > 0)
      .length;

  double get _totalMtrs {
    double sum = 0;
    for (final c in _mtrControllers) {
      sum += double.tryParse(c.text.trim()) ?? 0;
    }
    return sum;
  }

  double get _totalUsed => double.tryParse(_totalUsedCtrl.text.trim()) ?? 0;
  double get _balance => _totalMtrs - _totalUsed;

  void _recalculate() => setState(() {});

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

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null) setState(() => _pickedPhoto = photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick photo: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  // FIX item 1: Use isScrollControlled + DraggableScrollableSheet so sheet rises fully
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.55,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            shrinkWrap: true,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariantLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Add Photo',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.primary,
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.ibmPlexSans(fontSize: 14),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primary,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.ibmPlexSans(fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_pickedPhoto != null || _existingPhotoUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: AppTheme.error,
                  ),
                  title: Text(
                    'Remove Photo',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      color: AppTheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedPhoto = null;
                      _existingPhotoUrl = null;
                    });
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto() async {
    if (_pickedPhoto == null) return _existingPhotoUrl;
    setState(() => _uploadingPhoto = true);
    try {
      final client = SupabaseService.instance.client;
      final fileName = 'fabric_${ISTUtils.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'fabric-stock/$fileName';

      if (kIsWeb) {
        final bytes = await _pickedPhoto!.readAsBytes();
        await client.storage
            .from('register-photos')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      } else {
        final file = File(_pickedPhoto!.path);
        await client.storage
            .from('register-photos')
            .upload(
              filePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
      }
      return client.storage.from('register-photos').getPublicUrl(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return _existingPhotoUrl;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String? photoUrl = _existingPhotoUrl;
    if (_pickedPhoto != null) {
      photoUrl = await _uploadPhoto();
    }

    final rolls = <Map<String, dynamic>>[];
    for (int i = 0; i < _mtrControllers.length; i++) {
      final mtrs = double.tryParse(_mtrControllers[i].text.trim()) ?? 0;
      if (mtrs > 0) rolls.add({'rollNo': i + 1, 'mtrs': mtrs});
    }

    widget.onSave({
      'orderId': _selectedOrder?['id'],
      'style': _styleCtrl.text.trim(),
      'date': _selectedDate.toString().substring(0, 10),
      'design': _designCtrl.text.trim(),
      'colour': _colourCtrl.text.trim(),
      'rolls': rolls,
      'totalRolls': _totalRolls,
      'totalMtrs': _totalMtrs,
      'totalUsed': _totalUsed,
      'balance': _balance,
      'remarks': _remarksCtrl.text.trim(),
      'swatchPhotoPath': photoUrl,
      'photoUrl': photoUrl,
    });
  }

  @override
  void dispose() {
    _styleCtrl.dispose();
    _designCtrl.dispose();
    _colourCtrl.dispose();
    _totalUsedCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _mtrControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF00695C).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF00695C),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.initialData != null
                        ? 'Edit Fabric Stock Entry'
                        : 'New Fabric Stock Entry',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Order No / Style No'),
            const SizedBox(height: 6),
            _buildOrderSelector(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Style'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _styleCtrl,
                        decoration: _inputDecoration(hint: 'e.g. ST-2401'),
                        style: GoogleFonts.ibmPlexSans(fontSize: 14),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Date'),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.outlineVariantLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppTheme.mutedText,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formattedDate,
                                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Design'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _designCtrl,
                        decoration: _inputDecoration(hint: 'Design name'),
                        style: GoogleFonts.ibmPlexSans(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Colour'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _colourCtrl,
                        decoration: _inputDecoration(hint: 'e.g. Navy Blue'),
                        style: GoogleFonts.ibmPlexSans(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Swatch Photo'),
            const SizedBox(height: 8),
            _buildSwatchPhotoSection(),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Roll No / MTRs'),
            const SizedBox(height: 8),
            _buildRollTable(),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'Add Row',
                    style: GoogleFonts.ibmPlexSans(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (_mtrControllers.length > 1)
                  TextButton.icon(
                    onPressed: _removeLastRow,
                    icon: const Icon(Icons.remove_rounded, size: 16),
                    label: Text(
                      'Remove Row',
                      style: GoogleFonts.ibmPlexSans(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummarySection(),
            const SizedBox(height: 20),
            _FieldLabel(label: 'Remarks'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _remarksCtrl,
              decoration: _inputDecoration(hint: 'Optional remarks...'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadingPhoto ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _uploadingPhoto
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.initialData != null
                            ? 'Update Entry'
                            : 'Save Fabric Stock Entry',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.outlineVariantLight),
        ),
        child: const Center(
          child: SizedBox(
            height: 16,
            width: 16,
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
        const DropdownMenuItem<Map<String, dynamic>>(
          value: null,
          child: Text('— No order —'),
        ),
        ..._orders.map(
          (o) => DropdownMenuItem<Map<String, dynamic>>(
            value: o,
            child: Text(
              '${o['order_number']} / ${o['client_name']}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _onOrderSelected,
    );
  }

  Widget _buildSwatchPhotoSection() {
    final hasPhoto = _pickedPhoto != null || _existingPhotoUrl != null;
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: double.infinity,
        height: hasPhoto ? 180 : 100,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasPhoto
                ? const Color(0xFF00695C).withAlpha(120)
                : AppTheme.outlineVariantLight,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _pickedPhoto != null
                        ? (kIsWeb
                              ? Image.network(
                                  _pickedPhoto!.path,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Fabric swatch photo preview',
                                )
                              : Image.file(
                                  File(_pickedPhoto!.path),
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Fabric swatch photo preview',
                                ))
                        : Image.network(
                            _existingPhotoUrl!,
                            fit: BoxFit.cover,
                            semanticLabel: 'Existing fabric swatch photo',
                          ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 28,
                    color: AppTheme.mutedText,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photo',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  Text(
                    'Camera or Gallery',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRollTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineVariantLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    'ROLL NO.',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'MTRs',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mtrControllers.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: AppTheme.outlineVariantLight),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _mtrControllers[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: AppTheme.mutedText,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: GoogleFonts.ibmPlexSans(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C).withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00695C).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00695C),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'TOTAL ROLLS:', value: '$_totalRolls'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'TOTAL MTRs:',
            value: _totalMtrs.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'TOTAL USED:',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _totalUsedCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      color: AppTheme.mutedText,
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.outlineVariantLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.outlineVariantLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF00695C),
                        width: 1.5,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                  ),
                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'BALANCE:',
            value: _balance.toStringAsFixed(2),
            valueColor: _balance < 0 ? AppTheme.error : const Color(0xFF00695C),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String hint = ''}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.ibmPlexSans(
        fontSize: 14,
        color: AppTheme.mutedText,
      ),
      filled: true,
      fillColor: AppTheme.surfaceLight,
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
        borderSide: const BorderSide(color: Color(0xFF00695C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.error),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.mutedText,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.outlineVariantLight),
            ),
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurfaceLight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
