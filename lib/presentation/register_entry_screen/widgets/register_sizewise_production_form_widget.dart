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

class RegisterSizewiseProductionFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> data) onSave;

  const RegisterSizewiseProductionFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterSizewiseProductionFormWidget> createState() =>
      _RegisterSizewiseProductionFormWidgetState();
}

class _RegisterSizewiseProductionFormWidgetState
    extends State<RegisterSizewiseProductionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  DateTime _startDate = ISTUtils.today();
  DateTime _endDate = ISTUtils.today();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  // Size rows: each has a size name and qty controller
  final List<Map<String, TextEditingController>> _sizeRows = [];

  XFile? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _uploadingPhoto = false;

  int get _totalPieces {
    int total = 0;
    for (final row in _sizeRows) {
      total += int.tryParse(row['qty']!.text.trim()) ?? 0;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    final d = widget.initialData;
    if (d != null) {
      _styleCtrl.text = d['styleNo'] ?? '';
      _remarksCtrl.text = d['remarks'] ?? '';
      _existingPhotoUrl = d['photoUrl'] as String?;
      if (d['startDate'] != null) {
        _startDate = DateTime.tryParse(d['startDate']) ?? ISTUtils.today();
      }
      if (d['endDate'] != null) {
        _endDate = DateTime.tryParse(d['endDate']) ?? ISTUtils.today();
      }
      final sizeQtys = d['sizeQuantities'];
      if (sizeQtys is Map) {
        for (final entry in sizeQtys.entries) {
          _sizeRows.add({
            'size': TextEditingController(text: entry.key.toString()),
            'qty': TextEditingController(text: '${entry.value}'),
          });
        }
      }
    }
    if (_sizeRows.isEmpty) {
      _addSizeRow();
    }
  }

  void _addSizeRow() {
    setState(() {
      _sizeRows.add({
        'size': TextEditingController(),
        'qty': TextEditingController(),
      });
    });
  }

  void _removeSizeRow(int index) {
    if (_sizeRows.length <= 1) return;
    _sizeRows[index]['size']!.dispose();
    _sizeRows[index]['qty']!.dispose();
    setState(() => _sizeRows.removeAt(index));
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseService.instance.getClientOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _loadingOrders = false;
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
      if (order != null) _styleCtrl.text = order['garment_type'] ?? '';
    });
  }

  @override
  void dispose() {
    _styleCtrl.dispose();
    _remarksCtrl.dispose();
    for (final row in _sizeRows) {
      row['size']!.dispose();
      row['qty']!.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    } catch (_) {}
  }

  Future<String?> _uploadPhoto() async {
    if (_pickedPhoto == null) return _existingPhotoUrl;
    setState(() => _uploadingPhoto = true);
    try {
      final client = SupabaseService.instance.client;
      final fileName = 'sizewise_${ISTUtils.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'sizewise-production/$fileName';
      if (kIsWeb) {
        final bytes = await _pickedPhoto!.readAsBytes();
        await client.storage
            .from('register-photos')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
            );
      } else {
        await client.storage
            .from('register-photos')
            .upload(
              filePath,
              File(_pickedPhoto!.path),
              fileOptions: FileOptions(upsert: true),
            );
      }
      return client.storage.from('register-photos').getPublicUrl(filePath);
    } catch (_) {
      return _existingPhotoUrl;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final photoUrl = await _uploadPhoto();
    final sizeQtys = <String, int>{};
    for (final row in _sizeRows) {
      final size = row['size']!.text.trim();
      if (size.isNotEmpty) {
        sizeQtys[size] = int.tryParse(row['qty']!.text.trim()) ?? 0;
      }
    }
    widget.onSave({
      'orderId': _selectedOrder?['id'],
      'styleNo': _styleCtrl.text.trim(),
      'startDate': _startDate.toString().substring(0, 10),
      'endDate': _endDate.toString().substring(0, 10),
      'sizeQuantities': sizeQtys,
      'totalPieces': _totalPieces,
      'remarks': _remarksCtrl.text.trim(),
      'photoUrl': photoUrl,
    });
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6A1B9A).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF6A1B9A),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Size-wise Production Register',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Order (Optional)'),
            const SizedBox(height: 10),
            _buildOrderSelector(),
            const SizedBox(height: 16),
            _sectionLabel('Production Details'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _styleCtrl,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppTheme.onSurfaceLight,
              ),
              decoration: _inputDecoration('Style *', Icons.style_rounded),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _startDate.toString().substring(0, 10),
                        ),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          color: AppTheme.onSurfaceLight,
                        ),
                        decoration: _inputDecoration(
                          'Start Date *',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _endDate.toString().substring(0, 10),
                        ),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          color: AppTheme.onSurfaceLight,
                        ),
                        decoration: _inputDecoration(
                          'End Date *',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Size Quantities'),
                TextButton.icon(
                  onPressed: _addSizeRow,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'Add Size',
                    style: GoogleFonts.ibmPlexSans(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outlineVariantLight),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(9),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Size',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Pieces',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                      ],
                    ),
                  ),
                  ..._sizeRows.asMap().entries.map(
                    (e) => Column(
                      children: [
                        Divider(height: 1, color: AppTheme.outlineVariantLight),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: e.value['size'],
                                  decoration: InputDecoration(
                                    hintText: 'e.g. S, M, L',
                                    hintStyle: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      color: AppTheme.mutedText,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: e.value['qty'],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      color: AppTheme.mutedText,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: _sizeRows.length > 1
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: AppTheme.error,
                                        ),
                                        onPressed: () => _removeSizeRow(e.key),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.outlineVariantLight),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pieces',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        Text(
                          '$_totalPieces pcs',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 2,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppTheme.onSurfaceLight,
              ),
              decoration: _inputDecoration(
                'Remarks',
                null,
                hint: 'Optional notes...',
              ),
            ),
            const SizedBox(height: 10),
            _buildPhotoSection(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _uploadingPhoto ? null : _onSave,
              icon: const Icon(Icons.save_rounded),
              label: Text(
                widget.initialData != null
                    ? 'Update Entry'
                    : 'Save Size-wise Production Entry',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhoto = _pickedPhoto != null || _existingPhotoUrl != null;
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: double.infinity,
        height: hasPhoto ? 140 : 70,
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasPhoto
                ? AppTheme.primary.withAlpha(120)
                : AppTheme.outlineVariantLight,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _pickedPhoto != null
                    ? (kIsWeb
                          ? Image.network(
                              _pickedPhoto!.path,
                              fit: BoxFit.cover,
                              semanticLabel: 'Size-wise production photo',
                            )
                          : Image.file(
                              File(_pickedPhoto!.path),
                              fit: BoxFit.cover,
                              semanticLabel: 'Size-wise production photo',
                            ))
                    : Image.network(
                        _existingPhotoUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: 'Size-wise production photo',
                      ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 22,
                    color: AppTheme.mutedText,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add Photo (optional)',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppTheme.mutedText,
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
              '${o['order_number']} — ${o['client_name']}',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
            ),
          ),
        ),
      ],
      onChanged: _onOrderSelected,
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData? icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18) : null,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        color: AppTheme.mutedText,
      ),
      hintStyle: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        color: AppTheme.outlineLight,
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.mutedText,
      ),
    );
  }
}
