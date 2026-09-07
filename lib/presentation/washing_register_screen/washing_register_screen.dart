import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../core/ist_utils.dart';

class WashingRegisterScreen extends StatefulWidget {
  const WashingRegisterScreen({super.key});

  @override
  State<WashingRegisterScreen> createState() => _WashingRegisterScreenState();
}

class _WashingRegisterScreenState extends State<WashingRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEntries();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('washing_entries_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'washing_entries',
          callback: (payload) {
            if (mounted) _loadEntries();
          },
        )
        .subscribe();
  }

  Future<void> _loadEntries() async {
    if (!_loading) {
      // Silent refresh for realtime
    } else {
      setState(() => _loading = true);
    }
    try {
      final data = await SupabaseService.instance.getWashingEntries();
      if (mounted) {
        setState(() {
          _entries = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load entries: $e')));
      }
    }
  }

  List<Map<String, dynamic>> get _pendingEntries =>
      _entries.where((e) => e['status'] == 'sent').toList();

  List<Map<String, dynamic>> get _completedEntries =>
      _entries.where((e) => e['status'] == 'received').toList();

  void _showSendOutDialog({Map<String, dynamic>? entry}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WashingEntryForm(entry: entry, onSaved: _loadEntries),
    );
  }

  void _showReceiveDialog(Map<String, dynamic> entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WashingReceiveForm(entry: entry, onSaved: _loadEntries),
    );
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SupabaseService.instance.deleteWashingEntry(id);
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: null,
      body: Column(
        children: [
          // Title bar
          ColoredBox(
            color: AppTheme.surfaceLight,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                    child: Row(
                      children: [
                        Text(
                          'Washing Register',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.success,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showSendOutDialog(),
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          label: Text(
                            'Send Out',
                            style: GoogleFonts.ibmPlexSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.mutedText,
                    indicatorColor: AppTheme.primary,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_laundry_service_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text('Sent Out'),
                            if (_pendingEntries.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_pendingEntries.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text('Received'),
                            if (_completedEntries.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_completedEntries.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [_buildSentList(), _buildReceivedList()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentList() {
    if (_pendingEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_laundry_service_rounded,
              size: 56,
              color: AppTheme.mutedText.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No items sent out yet',
              style: GoogleFonts.ibmPlexSans(
                color: AppTheme.mutedText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap + Send Out to log items',
              style: GoogleFonts.ibmPlexSans(
                color: AppTheme.mutedText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _pendingEntries.length,
        itemBuilder: (_, i) => _WashingEntryCard(
          key: ValueKey(_pendingEntries[i]['id']),
          entry: _pendingEntries[i],
          onReceive: () => _showReceiveDialog(_pendingEntries[i]),
          onEdit: () => _showSendOutDialog(entry: _pendingEntries[i]),
          onDelete: () => _deleteEntry(_pendingEntries[i]['id']),
        ),
      ),
    );
  }

  Widget _buildReceivedList() {
    if (_completedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: AppTheme.mutedText.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              'No received entries yet',
              style: GoogleFonts.ibmPlexSans(
                color: AppTheme.mutedText,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _completedEntries.length,
        itemBuilder: (_, i) => _WashingEntryCard(
          key: ValueKey(_completedEntries[i]['id']),
          entry: _completedEntries[i],
          onReceive: null,
          onEdit: () => _showSendOutDialog(entry: _completedEntries[i]),
          onDelete: () => _deleteEntry(_completedEntries[i]['id']),
        ),
      ),
    );
  }
}

// ─── Entry Card ────────────────────────────────────────────────────────────

class _WashingEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback? onReceive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WashingEntryCard({
    super.key,
    required this.entry,
    required this.onReceive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReceived = entry['status'] == 'received';
    final int? diff = entry['difference'] as int?;
    final bool hasDiff = diff != null && diff != 0;
    final String sentDcNo = entry['sent_dc_no'] ?? '';
    final String receivedDcNo = entry['received_dc_no'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDiff
              ? AppTheme.error.withAlpha(80)
              : AppTheme.outlineVariantLight,
          width: hasDiff ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isReceived
                        ? AppTheme.successContainer
                        : AppTheme.warningContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isReceived ? 'Received' : 'Sent Out',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isReceived ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry['style_no'] ?? '',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(label: 'Colour', value: entry['colour'] ?? '-'),
                    const SizedBox(width: 8),
                    _InfoChip(
                      label: 'Vendor',
                      value: entry['vendor_name'] ?? '-',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      label: 'Sent',
                      value: '${entry['sent_qty'] ?? 0} pcs',
                    ),
                    const SizedBox(width: 8),
                    if (isReceived)
                      _InfoChip(
                        label: 'Received',
                        value: '${entry['received_qty'] ?? 0} pcs',
                      )
                    else
                      _InfoChip(
                        label: 'Sent Date',
                        value: entry['sent_date'] ?? '-',
                      ),
                  ],
                ),
                // DC numbers
                if (sentDcNo.isNotEmpty || receivedDcNo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (sentDcNo.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sent DC/No.',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10,
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sentDcNo,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (sentDcNo.isNotEmpty && receivedDcNo.isNotEmpty)
                        const SizedBox(width: 8),
                      if (receivedDcNo.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Received DC/No.',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10,
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  receivedDcNo,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (hasDiff) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Difference: $diff pcs missing',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (entry['remarks'] != null &&
                    (entry['remarks'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Remarks: ${entry['remarks']}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onReceive != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onReceive,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: const Text('Mark as Received'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.success,
                    side: const BorderSide(color: AppTheme.success),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariantLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Send Out Form ─────────────────────────────────────────────────────────

class _WashingEntryForm extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final VoidCallback onSaved;
  const _WashingEntryForm({this.entry, required this.onSaved});

  @override
  State<_WashingEntryForm> createState() => _WashingEntryFormState();
}

class _WashingEntryFormState extends State<_WashingEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _styleCtrl = TextEditingController();
  final _colourCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  final _sentQtyCtrl = TextEditingController();
  final _sentDcNoCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _sentDate = ISTUtils.today();
  bool _saving = false;
  List<Map<String, dynamic>> _orders = [];
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    if (widget.entry != null) {
      final e = widget.entry!;
      _styleCtrl.text = e['style_no'] ?? '';
      _colourCtrl.text = e['colour'] ?? '';
      _vendorCtrl.text = e['vendor_name'] ?? '';
      _sentQtyCtrl.text = '${e['sent_qty'] ?? ''}';
      _sentDcNoCtrl.text = e['sent_dc_no'] ?? '';
      _remarksCtrl.text = e['remarks'] ?? '';
      _selectedOrderId = e['order_id'];
      if (e['sent_date'] != null) {
        _sentDate = DateTime.tryParse(e['sent_date']) ?? ISTUtils.today();
      }
    }
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await SupabaseService.instance.getClientOrders();
      setState(() => _orders = orders);
    } catch (_) {}
  }

  @override
  void dispose() {
    _styleCtrl.dispose();
    _colourCtrl.dispose();
    _vendorCtrl.dispose();
    _sentQtyCtrl.dispose();
    _sentDcNoCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _sentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'orderId': _selectedOrderId,
        'styleNo': _styleCtrl.text.trim(),
        'colour': _colourCtrl.text.trim(),
        'vendorName': _vendorCtrl.text.trim(),
        'sentQty': int.tryParse(_sentQtyCtrl.text.trim()) ?? 0,
        'sentDate': _sentDate.toString().substring(0, 10),
        'sentDcNo': _sentDcNoCtrl.text.trim(),
        'remarks': _remarksCtrl.text.trim(),
      };
      if (widget.entry != null) {
        await SupabaseService.instance.updateWashingEntry(
          widget.entry!['id'],
          data,
        );
      } else {
        await SupabaseService.instance.insertWashingEntry(data);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.entry == null
                        ? 'Send Out for Washing'
                        : 'Edit Entry',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedOrderId,
                decoration: const InputDecoration(
                  labelText: 'Order (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— None —')),
                  ..._orders.map(
                    (o) => DropdownMenuItem(
                      value: o['id'] as String,
                      child: Text(
                        '${o['order_number']} — ${o['client_name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedOrderId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _styleCtrl,
                decoration: const InputDecoration(labelText: 'Style No *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colourCtrl,
                decoration: const InputDecoration(labelText: 'Colour *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vendorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vendor / Laundry Name *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sentQtyCtrl,
                decoration: const InputDecoration(labelText: 'Quantity Sent *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sentDcNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sent DC/No.',
                  hintText: 'Delivery Challan number',
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Sent Date',
                      suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    ),
                    controller: TextEditingController(
                      text: _sentDate.toString().substring(0, 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.entry == null ? 'Send Out' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Receive Form ──────────────────────────────────────────────────────────

class _WashingReceiveForm extends StatefulWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onSaved;
  const _WashingReceiveForm({required this.entry, required this.onSaved});

  @override
  State<_WashingReceiveForm> createState() => _WashingReceiveFormState();
}

class _WashingReceiveFormState extends State<_WashingReceiveForm> {
  final _formKey = GlobalKey<FormState>();
  final _receivedQtyCtrl = TextEditingController();
  final _receivedDcNoCtrl = TextEditingController();
  DateTime _receivedDate = ISTUtils.today();
  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _receivedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final receivedQty = int.tryParse(_receivedQtyCtrl.text.trim()) ?? 0;
      await SupabaseService.instance.markWashingReceived(
        widget.entry['id'],
        receivedQty,
        _receivedDate.toString().substring(0, 10),
        _receivedDcNoCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _receivedQtyCtrl.dispose();
    _receivedDcNoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sentQty = widget.entry['sent_qty'] ?? 0;
    final sentDcNo = widget.entry['sent_dc_no'] ?? '';
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Mark as Received',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Style: ${widget.entry['style_no']}  •  Sent: $sentQty pcs${sentDcNo.isNotEmpty ? '  •  DC: $sentDcNo' : ''}',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receivedQtyCtrl,
              decoration: const InputDecoration(
                labelText: 'Quantity Received *',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Enter a number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _receivedDcNoCtrl,
              decoration: const InputDecoration(
                labelText: 'Received DC/No.',
                hintText: 'Delivery Challan number for received goods',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Received Date',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  controller: TextEditingController(
                    text: _receivedDate.toString().substring(0, 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
