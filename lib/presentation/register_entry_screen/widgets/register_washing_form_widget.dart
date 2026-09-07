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

class RegisterWashingFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final void Function(Map<String, dynamic> data) onSave;

  const RegisterWashingFormWidget({
    required this.onSave,
    this.initialData,
    super.key,
  });

  @override
  State<RegisterWashingFormWidget> createState() =>
      _RegisterWashingFormWidgetState();
}

class _RegisterWashingFormWidgetState extends State<RegisterWashingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _designNoCtrl = TextEditingController();
  final _colourCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _sentQtyCtrl = TextEditingController();
  final _sentDcCtrl = TextEditingController();
  final _receivedQtyCtrl = TextEditingController();
  final _receivedDcCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String _status = 'sent';
  DateTime _sentDate = ISTUtils.today();
  DateTime _receivedDate = ISTUtils.today();

  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedOrder;
  bool _loadingOrders = true;

  XFile? _pickedPhoto;
  String? _existingPhotoUrl;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    final d = widget.initialData;
    if (d != null) {
      _styleCtrl.text = d['styleNo'] ?? '';
      _designNoCtrl.text = d['designNo'] ?? '';
      _colourCtrl.text = d['colour'] ?? '';
      _vendorCtrl.text = d['vendorName'] ?? '';
      _sentQtyCtrl.text = '${d['sentQty'] ?? ''}';
      _sentDcCtrl.text = d['sentDcNo'] ?? '';
      _receivedQtyCtrl.text = '${d['receivedQty'] ?? ''}';
      _receivedDcCtrl.text = d['receivedDcNo'] ?? '';
      _remarksCtrl.text = d['remarks'] ?? '';
      _status = d['status'] ?? 'sent';
      _existingPhotoUrl = d['photoUrl'] as String?;
      if (d['sentDate'] != null) {
        _sentDate = DateTime.tryParse(d['sentDate']) ?? ISTUtils.today();
      }
      if (d['receivedDate'] != null) {
        _receivedDate =
            DateTime.tryParse(d['receivedDate']) ?? ISTUtils.today();
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
    _designNoCtrl.dispose();
    _colourCtrl.dispose();
    _vendorCtrl.dispose();
    _sentQtyCtrl.dispose();
    _sentDcCtrl.dispose();
    _receivedQtyCtrl.dispose();
    _receivedDcCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isSent) async {
    final initial = isSent ? _sentDate : _receivedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isSent) {
          _sentDate = picked;
        } else {
          _receivedDate = picked;
        }
      });
    }
  }

  int get _difference {
    final sent = int.tryParse(_sentQtyCtrl.text) ?? 0;
    final received = int.tryParse(_receivedQtyCtrl.text) ?? 0;
    return sent - received;
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
      final fileName = 'washing_${ISTUtils.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'washing/$fileName';
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
    widget.onSave({
      'orderId': _selectedOrder?['id'],
      'styleNo': _styleCtrl.text.trim(),
      'designNo': _designNoCtrl.text.trim(),
      'colour': _colourCtrl.text.trim(),
      'vendorName': _vendorCtrl.text.trim(),
      'sentQty': int.tryParse(_sentQtyCtrl.text) ?? 0,
      'sentDate': _sentDate.toString().substring(0, 10),
      'sentDcNo': _sentDcCtrl.text.trim(),
      'receivedQty': _status == 'received'
          ? (int.tryParse(_receivedQtyCtrl.text) ?? 0)
          : null,
      'receivedDate': _status == 'received'
          ? _receivedDate.toString().substring(0, 10)
          : null,
      'receivedDcNo': _status == 'received'
          ? _receivedDcCtrl.text.trim()
          : null,
      'remarks': _remarksCtrl.text.trim(),
      'photoUrl': photoUrl,
      'status': _status,
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
            _sectionLabel('Order (Optional)'),
            const SizedBox(height: 10),
            _buildOrderSelector(),
            const SizedBox(height: 20),
            _sectionLabel('Sent Out Details'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _pickDate(true),
              child: AbsorbPointer(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: _sentDate.toString().substring(0, 10),
                  ),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: AppTheme.onSurfaceLight,
                  ),
                  decoration: _inputDecoration(
                    'Sent Date *',
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
            _buildField(_designNoCtrl, 'Design No.', 'e.g. D-001'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(_colourCtrl, 'Colour', 'e.g. Navy Blue'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    _vendorCtrl,
                    'Vendor / Laundry',
                    'Vendor name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    _sentQtyCtrl,
                    'Sent Qty *',
                    '0',
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
                    _sentDcCtrl,
                    'Sent DC No. *',
                    'DC-001',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _sectionLabel('Status'),
                const Spacer(),
                ChoiceChip(
                  label: const Text('Sent Out'),
                  selected: _status == 'sent',
                  onSelected: (_) => setState(() => _status = 'sent'),
                  selectedColor: AppTheme.warning.withAlpha(50),
                  labelStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _status == 'sent'
                        ? AppTheme.warning
                        : AppTheme.mutedText,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Received'),
                  selected: _status == 'received',
                  onSelected: (_) => setState(() => _status = 'received'),
                  selectedColor: AppTheme.success.withAlpha(50),
                  labelStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _status == 'received'
                        ? AppTheme.success
                        : AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            if (_status == 'received') ...[
              const SizedBox(height: 16),
              _sectionLabel('Received Details'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickDate(false),
                child: AbsorbPointer(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _receivedDate.toString().substring(0, 10),
                    ),
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      color: AppTheme.onSurfaceLight,
                    ),
                    decoration: _inputDecoration(
                      'Received Date *',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      _receivedQtyCtrl,
                      'Received Qty *',
                      '0',
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
                      _receivedDcCtrl,
                      'Received DC No. *',
                      'DC-002',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _difference > 0
                      ? AppTheme.warningContainer
                      : AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Difference',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    Text(
                      '$_difference pcs',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _difference > 0
                            ? AppTheme.warning
                            : AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _buildField(
              _remarksCtrl,
              'Remarks',
              'Optional notes...',
              maxLines: 2,
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
                    : 'Save Washing Entry',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF0277BD),
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
                              semanticLabel: 'Washing register photo',
                            )
                          : Image.file(
                              File(_pickedPhoto!.path),
                              fit: BoxFit.cover,
                              semanticLabel: 'Washing register photo',
                            ))
                    : Image.network(
                        _existingPhotoUrl!,
                        fit: BoxFit.cover,
                        semanticLabel: 'Washing register photo',
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
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
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
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
