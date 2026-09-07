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

// ─── Data model for a colour block ───────────────────────────────────────────
class _ColourBlock {
  final TextEditingController colourCtrl;
  final List<_SizeField> sizeFields;

  _ColourBlock({required this.colourCtrl, required this.sizeFields});

  void dispose() {
    colourCtrl.dispose();
    for (final s in sizeFields) {
      s.dispose();
    }
  }
}

class _SizeField {
  final TextEditingController sizeCtrl;
  final TextEditingController qtyCtrl;

  _SizeField({required this.sizeCtrl, required this.qtyCtrl});

  void dispose() {
    sizeCtrl.dispose();
    qtyCtrl.dispose();
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class RegisterLayFormWidget extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onSave;
  final Map<String, dynamic>? initialData;

  const RegisterLayFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterLayFormWidget> createState() => _RegisterLayFormWidgetState();
}

class _RegisterLayFormWidgetState extends State<RegisterLayFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _fabricTypeCtrl = TextEditingController();
  final _layLengthCtrl = TextEditingController();
  final _pliesCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  DateTime _selectedDate = ISTUtils.today();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  // Multi-colour blocks
  final List<_ColourBlock> _colourBlocks = [];

  // Photo
  XFile? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _uploadingPhoto = false;

  double get _totalMeters {
    final length = double.tryParse(_layLengthCtrl.text) ?? 0;
    final plies = int.tryParse(_pliesCtrl.text) ?? 0;
    return length * plies;
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _layLengthCtrl.addListener(() => setState(() {}));
    _pliesCtrl.addListener(() => setState(() {}));

    if (widget.initialData != null) {
      final d = widget.initialData!;
      _styleCtrl.text = d['styleNo'] as String? ?? '';
      _fabricTypeCtrl.text = d['fabricType'] as String? ?? '';
      _layLengthCtrl.text = (d['layLength'] ?? '').toString();
      _pliesCtrl.text = (d['noOfPlies'] ?? '').toString();
      _remarksCtrl.text = d['remarks'] as String? ?? '';
      _existingPhotoUrl = d['photoUrl'] as String?;
      final dateStr = d['date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        _selectedDate = DateTime.tryParse(dateStr) ?? ISTUtils.today();
      }

      // Restore colour blocks
      final colours = d['colours'];
      if (colours != null && colours is List && colours.isNotEmpty) {
        for (final c in colours) {
          final block = _ColourBlock(
            colourCtrl: TextEditingController(
              text: c['colour'] as String? ?? '',
            ),
            sizeFields: [],
          );
          final sizes = c['sizes'];
          if (sizes is List && sizes.isNotEmpty) {
            for (final s in sizes) {
              block.sizeFields.add(
                _SizeField(
                  sizeCtrl: TextEditingController(
                    text: s['size'] as String? ?? '',
                  ),
                  qtyCtrl: TextEditingController(text: '${s['qty'] ?? ''}'),
                ),
              );
            }
          } else {
            block.sizeFields.add(
              _SizeField(
                sizeCtrl: TextEditingController(),
                qtyCtrl: TextEditingController(),
              ),
            );
          }
          _colourBlocks.add(block);
        }
      } else {
        _addColourBlock();
      }
    } else {
      _addColourBlock();
    }
  }

  void _addColourBlock() {
    setState(() {
      _colourBlocks.add(
        _ColourBlock(
          colourCtrl: TextEditingController(),
          sizeFields: [
            _SizeField(
              sizeCtrl: TextEditingController(),
              qtyCtrl: TextEditingController(),
            ),
          ],
        ),
      );
    });
  }

  void _removeColourBlock(int index) {
    if (_colourBlocks.length <= 1) return;
    _colourBlocks[index].dispose();
    setState(() => _colourBlocks.removeAt(index));
  }

  void _addSizeField(int blockIndex) {
    setState(() {
      _colourBlocks[blockIndex].sizeFields.add(
        _SizeField(
          sizeCtrl: TextEditingController(),
          qtyCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removeSizeField(int blockIndex, int fieldIndex) {
    if (_colourBlocks[blockIndex].sizeFields.length <= 1) return;
    _colourBlocks[blockIndex].sizeFields[fieldIndex].dispose();
    setState(() => _colourBlocks[blockIndex].sizeFields.removeAt(fieldIndex));
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
    _fabricTypeCtrl.dispose();
    _layLengthCtrl.dispose();
    _pliesCtrl.dispose();
    _remarksCtrl.dispose();
    for (final b in _colourBlocks) {
      b.dispose();
    }
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
      final fileName = 'lay_${ISTUtils.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'lay/$fileName';
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final photoUrl = await _uploadPhoto();

    // Build colours array
    final colours = _colourBlocks.map((b) {
      final sizes = b.sizeFields
          .where((s) => s.sizeCtrl.text.trim().isNotEmpty)
          .map(
            (s) => {
              'size': s.sizeCtrl.text.trim(),
              'qty': int.tryParse(s.qtyCtrl.text.trim()) ?? 0,
            },
          )
          .toList();
      return {'colour': b.colourCtrl.text.trim(), 'sizes': sizes};
    }).toList();

    widget.onSave({
      'orderId': _selectedOrder?['id'],
      'date': _selectedDate.toString().substring(0, 10),
      'styleNo': _styleCtrl.text.trim(),
      'fabricType': _fabricTypeCtrl.text.trim(),
      'layLength': double.tryParse(_layLengthCtrl.text.trim()) ?? 0.0,
      'noOfPlies': int.tryParse(_pliesCtrl.text.trim()) ?? 0,
      'totalMeters': _totalMeters,
      'colours': colours,
      'remarks': _remarksCtrl.text.trim(),
      'photoUrl': photoUrl,
      'status': 'complete',
    });
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1565C0).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.initialData != null
                        ? 'Edit Lay Entry'
                        : 'New Lay Entry',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1565C0),
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

            _FieldLabel(label: 'Style No'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _styleCtrl,
              decoration: _inputDecoration(hint: 'e.g. ST-2401'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Style is required' : null,
            ),
            const SizedBox(height: 14),

            _FieldLabel(label: 'Fabric Type'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fabricTypeCtrl,
              decoration: _inputDecoration(hint: 'e.g. Cotton'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Lay Length (m)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _layLengthCtrl,
                        decoration: _inputDecoration(hint: 'e.g. 12.5'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
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
                      _FieldLabel(label: 'No. of Plies'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pliesCtrl,
                        decoration: _inputDecoration(hint: 'e.g. 40'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.ibmPlexSans(fontSize: 14),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                    'Total Meters',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    '${_totalMeters.toStringAsFixed(2)} m',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Multi-colour blocks ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Colours & Size Ratios',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addColourBlock,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    'Add Colour',
                    style: GoogleFonts.ibmPlexSans(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._colourBlocks.asMap().entries.map(
              (e) => _buildColourBlock(e.key, e.value),
            ),

            const SizedBox(height: 16),

            // Photo
            _FieldLabel(label: 'Photo'),
            const SizedBox(height: 8),
            _buildPhotoSection(),
            const SizedBox(height: 14),

            _FieldLabel(label: 'Remarks'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _remarksCtrl,
              decoration: _inputDecoration(hint: 'Optional notes...'),
              style: GoogleFonts.ibmPlexSans(fontSize: 14),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadingPhoto ? null : _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  widget.initialData != null
                      ? 'Update Lay Entry'
                      : 'Save Lay Entry',
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

  Widget _buildColourBlock(int blockIndex, _ColourBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineVariantLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: block.colourCtrl,
                  decoration: _inputDecoration(hint: 'Colour name (e.g. Navy)'),
                  style: GoogleFonts.ibmPlexSans(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              if (_colourBlocks.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                  onPressed: () => _removeColourBlock(blockIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Size',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Qty per Ply',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          const SizedBox(height: 4),
          ...block.sizeFields.asMap().entries.map(
            (e) => _buildSizeFieldRow(blockIndex, e.key, e.value),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => _addSizeField(blockIndex),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(
              'Add Size',
              style: GoogleFonts.ibmPlexSans(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeFieldRow(int blockIndex, int fieldIndex, _SizeField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: field.sizeCtrl,
              decoration: _inputDecoration(hint: 'e.g. S, M, L'),
              style: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: field.qtyCtrl,
              decoration: _inputDecoration(hint: '0'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 28,
            child: _colourBlocks[blockIndex].sizeFields.length > 1
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.error,
                    ),
                    onPressed: () => _removeSizeField(blockIndex, fieldIndex),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasPhoto = _pickedPhoto != null || _existingPhotoUrl != null;
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        width: double.infinity,
        height: hasPhoto ? 160 : 80,
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
                              semanticLabel: 'Lay register photo',
                            )
                          : Image.file(
                              File(_pickedPhoto!.path),
                              fit: BoxFit.cover,
                              semanticLabel: 'Lay register photo',
                            ))
                    : Image.network(
                        _existingPhotoUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: 'Existing lay register photo',
                      ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_rounded,
                    size: 24,
                    color: AppTheme.mutedText,
                  ),
                  const SizedBox(height: 6),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
