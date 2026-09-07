import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/offline_banner_widget.dart';
import '../../core/ist_utils.dart';

class SubcontractorRegisterScreen extends StatefulWidget {
  const SubcontractorRegisterScreen({super.key});

  @override
  State<SubcontractorRegisterScreen> createState() =>
      _SubcontractorRegisterScreenState();
}

class _SubcontractorRegisterScreenState
    extends State<SubcontractorRegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _showForm = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _outbound = [];
  List<Map<String, dynamic>> _inbound = [];
  List<Map<String, dynamic>> _orders = [];

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _styleCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _selectedType = 'Cutting';
  String? _selectedOrderId;
  String _selectedDate = ISTUtils.todayString();

  static const List<String> _subTypes = [
    'Accessories',
    'Cutting',
    'Alteration',
  ];

  static const List<String> _inboundTypes = [
    'Finished Goods',
    'Cutting Return',
    'Alteration',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _styleCtrl.dispose();
    _piecesCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getSubcontractorOutbound(),
        SupabaseService.instance.getSubcontractorInbound(),
        SupabaseService.instance.getClientOrders(),
      ]);
      setState(() {
        _outbound = results[0];
        _inbound = results[1];
        _orders = results[2];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameCtrl.clear();
    _styleCtrl.clear();
    _piecesCtrl.clear();
    _remarksCtrl.clear();
    _selectedType = 'Cutting';
    _selectedOrderId = null;
    _selectedDate = ISTUtils.todayString();
  }

  Future<void> _saveEntry(bool isOutbound) async {
    if (!_formKey.currentState!.validate()) return;

    // Inbound validation: check matching outbound batch exists
    if (!isOutbound) {
      final hasMatch = _outbound.any(
        (o) =>
            o['subcontractor_name'] == _nameCtrl.text.trim() &&
            o['style'] == _styleCtrl.text.trim() &&
            o['sub_type'] == _selectedType &&
            ((_selectedOrderId == null && o['order_id'] == null) ||
                o['order_id'] == _selectedOrderId),
      );
      if (!hasMatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No matching outbound batch found for this Subcontractor + Style + Type combination. '
              'Please log an outbound entry first.',
            ),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'subcontractorName': _nameCtrl.text.trim(),
        'orderId': _selectedOrderId,
        'style': _styleCtrl.text.trim(),
        'subType': _selectedType,
        'noOfPieces': int.tryParse(_piecesCtrl.text.trim()) ?? 0,
        'date': _selectedDate,
        'loggedBy': AuthService.instance.isAdmin ? 'Admin' : 'Staff',
        'remarks': _remarksCtrl.text.trim(),
      };

      if (isOutbound) {
        await SupabaseService.instance.insertSubcontractorOutbound(data);
      } else {
        await SupabaseService.instance.insertSubcontractorInbound(data);
      }

      setState(() {
        _isSaving = false;
        _showForm = false;
      });
      _clearForm();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isOutbound ? 'Outbound' : 'Inbound'} entry saved successfully',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(String table, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
        ),
        content: const Text('Delete this entry? This cannot be undone.'),
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
    if (confirmed != true) return;
    await SupabaseService.instance.deleteSubcontractorEntry(table, id);
    await _loadData();
  }

  // ─── Reconciliation ───────────────────────────────────────────────────────

  // Maps inbound type to the outbound type family it reconciles against
  String _outboundFamilyForInbound(String inboundType) {
    switch (inboundType) {
      case 'Finished Goods':
      case 'Cutting Return':
        return 'Cutting';
      case 'Alteration':
        return 'Alteration';
      case 'Accessories':
        return 'Accessories';
      default:
        return inboundType;
    }
  }

  List<Map<String, dynamic>> get _batches {
    final Map<String, Map<String, dynamic>> batchMap = {};

    for (final o in _outbound) {
      final key =
          '${o['subcontractor_name']}|${o['order_id'] ?? ''}|${o['style']}|${o['sub_type']}';
      batchMap.putIfAbsent(
        key,
        () => {
          'subcontractorName': o['subcontractor_name'],
          'orderId': o['order_id'],
          'style': o['style'],
          'subType': o['sub_type'],
          'totalOut': 0,
          'totalIn': 0,
          'lastInboundDate': null,
          'outboundEntries': <Map<String, dynamic>>[],
          'inboundEntries': <Map<String, dynamic>>[],
        },
      );
      batchMap[key]!['totalOut'] =
          (batchMap[key]!['totalOut'] as int) +
          ((o['no_of_pieces'] as int?) ?? 0);
      (batchMap[key]!['outboundEntries'] as List).add(o);
    }

    for (final i in _inbound) {
      final inboundType = i['sub_type'] as String? ?? '';
      final outboundFamily = _outboundFamilyForInbound(inboundType);
      // Match against outbound family key
      final key =
          '${i['subcontractor_name']}|${i['order_id'] ?? ''}|${i['style']}|$outboundFamily';
      if (batchMap.containsKey(key)) {
        batchMap[key]!['totalIn'] =
            (batchMap[key]!['totalIn'] as int) +
            ((i['no_of_pieces'] as int?) ?? 0);
        (batchMap[key]!['inboundEntries'] as List).add(i);
        final dateStr = i['entry_date'] as String?;
        if (dateStr != null) {
          final existing = batchMap[key]!['lastInboundDate'] as String?;
          if (existing == null || dateStr.compareTo(existing) > 0) {
            batchMap[key]!['lastInboundDate'] = dateStr;
          }
        }
      }
    }

    return batchMap.values.toList();
  }

  bool _isOverdue(Map<String, dynamic> batch) {
    final pending = (batch['totalOut'] as int) - (batch['totalIn'] as int);
    if (pending <= 0) return false;
    final lastDate = batch['lastInboundDate'] as String?;
    if (lastDate == null) {
      // Check oldest outbound
      final entries = batch['outboundEntries'] as List;
      if (entries.isEmpty) return false;
      final oldest =
          entries
              .map((e) => e['entry_date'] as String? ?? '')
              .where((d) => d.isNotEmpty)
              .toList()
            ..sort();
      if (oldest.isEmpty) return false;
      final oldestDate = DateTime.tryParse(oldest.first);
      if (oldestDate == null) return false;
      return ISTUtils.now().difference(oldestDate).inDays > 14;
    }
    final last = DateTime.tryParse(lastDate);
    if (last == null) return false;
    return ISTUtils.now().difference(last).inDays > 14;
  }

  String _orderLabel(String? orderId) {
    if (orderId == null) return '—';
    final order = _orders.where((o) => o['id'] == orderId).firstOrNull;
    if (order == null) return orderId.substring(0, 8);
    return '${order['order_number'] ?? ''} — ${order['client_name'] ?? ''}';
  }

  // ─── Excel Export ─────────────────────────────────────────────────────────

  Future<void> _exportOutbound() async {
    final headers = [
      'Date',
      'Subcontractor',
      'Order',
      'Style',
      'Type',
      'Pieces',
      'Logged By',
      'Remarks',
    ];
    final rows = _outbound
        .map(
          (r) => [
            r['entry_date'] ?? '',
            r['subcontractor_name'] ?? '',
            _orderLabel(r['order_id'] as String?),
            r['style'] ?? '',
            r['sub_type'] ?? '',
            r['no_of_pieces'] ?? 0,
            r['logged_by'] ?? '',
            r['remarks'] ?? '',
          ],
        )
        .toList();
    await ExcelExportService.exportRegisterToExcel(
      registerName: 'Subcontractor_Outbound',
      headers: headers,
      rows: rows,
    );
  }

  Future<void> _exportInbound() async {
    final headers = [
      'Date',
      'Subcontractor',
      'Order',
      'Style',
      'Type',
      'Pieces',
      'Logged By',
      'Remarks',
    ];
    final rows = _inbound
        .map(
          (r) => [
            r['entry_date'] ?? '',
            r['subcontractor_name'] ?? '',
            _orderLabel(r['order_id'] as String?),
            r['style'] ?? '',
            r['sub_type'] ?? '',
            r['no_of_pieces'] ?? 0,
            r['logged_by'] ?? '',
            r['remarks'] ?? '',
          ],
        )
        .toList();
    await ExcelExportService.exportRegisterToExcel(
      registerName: 'Subcontractor_Inbound',
      headers: headers,
      rows: rows,
    );
  }

  Future<void> _exportReconciliation() async {
    final headers = [
      'Subcontractor',
      'Order',
      'Style',
      'Type',
      'Total Sent',
      'Total Received',
      'Pending Balance',
      'Overdue (>14 days)',
    ];
    final rows = _batches
        .map(
          (b) => [
            b['subcontractorName'] ?? '',
            _orderLabel(b['orderId'] as String?),
            b['style'] ?? '',
            b['subType'] ?? '',
            b['totalOut'] as int,
            b['totalIn'] as int,
            (b['totalOut'] as int) - (b['totalIn'] as int),
            _isOverdue(b) ? 'YES' : 'No',
          ],
        )
        .toList();
    await ExcelExportService.exportRegisterToExcel(
      registerName: 'Subcontractor_Reconciliation',
      headers: headers,
      rows: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBannerWidget(),
            // Header row
            Container(
              color: AppTheme.surfaceLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subcontractor Register',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showForm = !_showForm;
                        if (!_showForm) _clearForm();
                      });
                    },
                    icon: Icon(
                      _showForm ? Icons.close_rounded : Icons.add_rounded,
                      size: 18,
                      color: _showForm ? AppTheme.error : AppTheme.primary,
                    ),
                    label: Text(
                      _showForm ? 'Cancel' : 'Add Entry',
                      style: GoogleFonts.ibmPlexSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _showForm ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.onSurfaceLight,
                    ),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              color: AppTheme.surfaceLight,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.mutedText,
                indicatorColor: AppTheme.primary,
                labelStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Outbound'),
                  Tab(text: 'Inbound'),
                  Tab(text: 'Reconciliation'),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _showForm
                  ? _buildForm()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOutboundTab(),
                        _buildInboundTab(),
                        _buildReconciliationTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final isOutboundTab = _tabController.index == 0;
    final types = isOutboundTab ? _subTypes : _inboundTypes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariantLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with "New Entry" label on left, no save button here
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isOutboundTab
                              ? AppTheme.warningContainer
                              : AppTheme.successContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOutboundTab
                              ? 'New Outbound Entry'
                              : 'New Inbound Entry',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isOutboundTab
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subcontractor Name *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedOrderId,
                    decoration: const InputDecoration(
                      labelText: 'Order (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— No Order —'),
                      ),
                      ..._orders.map(
                        (o) => DropdownMenuItem<String?>(
                          value: o['id'] as String?,
                          child: Text(
                            '${o['order_number'] ?? ''} — ${o['client_name'] ?? ''}',
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
                    decoration: const InputDecoration(labelText: 'Style *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: types.contains(_selectedType)
                        ? _selectedType
                        : types.first,
                    decoration: const InputDecoration(labelText: 'Type *'),
                    items: types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedType = v ?? types.first),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _piecesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'No. of Pieces *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.tryParse(_selectedDate) ??
                            ISTUtils.today(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(
                          () => _selectedDate = picked.toString().substring(
                            0,
                            10,
                          ),
                        );
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate,
                            style: GoogleFonts.ibmPlexSans(fontSize: 14),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppTheme.mutedText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Save button at the BOTTOM, visually separated from "New Entry" header at top
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveEntry(isOutboundTab),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutboundTab
                      ? AppTheme.warning
                      : AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isOutboundTab
                            ? 'Save Outbound Entry'
                            : 'Save Inbound Entry',
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

  Widget _buildOutboundTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_outbound.length} entries',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                ),
              ),
              TextButton.icon(
                onPressed: _outbound.isEmpty ? null : _exportOutbound,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Excel'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  textStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _outbound.isEmpty
              ? _buildEmpty('No outbound entries yet')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _outbound.length,
                  itemBuilder: (ctx, i) => _SubcontractorEntryCard(
                    entry: _outbound[i],
                    isOutbound: true,
                    orderLabel: _orderLabel(
                      _outbound[i]['order_id'] as String?,
                    ),
                    onDelete: () => _deleteEntry(
                      'subcontractor_outbound',
                      _outbound[i]['id'] as String,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInboundTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_inbound.length} entries',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                ),
              ),
              TextButton.icon(
                onPressed: _inbound.isEmpty ? null : _exportInbound,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Excel'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  textStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _inbound.isEmpty
              ? _buildEmpty('No inbound entries yet')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: _inbound.length,
                  itemBuilder: (ctx, i) => _SubcontractorEntryCard(
                    entry: _inbound[i],
                    isOutbound: false,
                    orderLabel: _orderLabel(_inbound[i]['order_id'] as String?),
                    onDelete: () => _deleteEntry(
                      'subcontractor_inbound',
                      _inbound[i]['id'] as String,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReconciliationTab() {
    final batches = _batches;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${batches.length} batches',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.mutedText,
                ),
              ),
              TextButton.icon(
                onPressed: batches.isEmpty ? null : _exportReconciliation,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download Excel'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.success,
                  textStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: batches.isEmpty
              ? _buildEmpty('No batches yet. Add outbound entries to start.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: batches.length,
                  itemBuilder: (ctx, i) => _BatchCard(
                    batch: batches[i],
                    isOverdue: _isOverdue(batches[i]),
                    orderLabel: _orderLabel(batches[i]['orderId'] as String?),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: AppTheme.mutedText,
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              color: AppTheme.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Entry Card ───────────────────────────────────────────────────────────────

class _SubcontractorEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isOutbound;
  final String orderLabel;
  final VoidCallback onDelete;

  const _SubcontractorEntryCard({
    required this.entry,
    required this.isOutbound,
    required this.orderLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariantLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isOutbound
                  ? AppTheme.warningContainer
                  : AppTheme.successContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOutbound
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: isOutbound ? AppTheme.warning : AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['subcontractor_name'] ?? '',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry['style'] ?? ''}  •  ${entry['sub_type'] ?? ''}  •  ${entry['no_of_pieces'] ?? 0} pcs',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                if (orderLabel != '—')
                  Text(
                    orderLabel,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry['entry_date'] ?? '',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppTheme.mutedText,
                ),
              ),
              if (AuthService.instance.isAdmin)
                GestureDetector(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Batch / Reconciliation Card ─────────────────────────────────────────────

class _BatchCard extends StatefulWidget {
  final Map<String, dynamic> batch;
  final bool isOverdue;
  final String orderLabel;

  const _BatchCard({
    required this.batch,
    required this.isOverdue,
    required this.orderLabel,
  });

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totalOut = widget.batch['totalOut'] as int;
    final totalIn = widget.batch['totalIn'] as int;
    final pending = totalOut - totalIn;
    final outEntries =
        widget.batch['outboundEntries'] as List<Map<String, dynamic>>;
    final inEntries =
        widget.batch['inboundEntries'] as List<Map<String, dynamic>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOverdue
              ? AppTheme.error.withAlpha(120)
              : pending > 0
              ? AppTheme.warning.withAlpha(100)
              : AppTheme.outlineVariantLight,
          width: widget.isOverdue ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.batch['subcontractorName'] ?? '',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                                if (widget.isOverdue) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'OVERDUE',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.batch['style'] ?? ''}  •  ${widget.batch['subType'] ?? ''}',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: AppTheme.mutedText,
                              ),
                            ),
                            if (widget.orderLabel != '—')
                              Text(
                                widget.orderLabel,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _BatchStat(
                        label: 'Sent Out',
                        value: '$totalOut pcs',
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      _BatchStat(
                        label: 'Received',
                        value: '$totalIn pcs',
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      _BatchStat(
                        label: 'Pending',
                        value: '$pending pcs',
                        color: pending > 0
                            ? (widget.isOverdue
                                  ? AppTheme.error
                                  : AppTheme.warning)
                            : AppTheme.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (outEntries.isNotEmpty) ...[
                    Text(
                      'Outbound Entries',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...outEntries.map(
                      (e) => _EntryRow(
                        date: e['entry_date'] ?? '',
                        pieces: (e['no_of_pieces'] as int?) ?? 0,
                        loggedBy: e['logged_by'] ?? '',
                        isOutbound: true,
                      ),
                    ),
                  ],
                  if (inEntries.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Inbound Entries',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...inEntries.map(
                      (e) => _EntryRow(
                        date: e['entry_date'] ?? '',
                        pieces: (e['no_of_pieces'] as int?) ?? 0,
                        loggedBy: e['logged_by'] ?? '',
                        isOutbound: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BatchStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BatchStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 10,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final String date;
  final int pieces;
  final String loggedBy;
  final bool isOutbound;

  const _EntryRow({
    required this.date,
    required this.pieces,
    required this.loggedBy,
    required this.isOutbound,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isOutbound
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 14,
            color: isOutbound ? AppTheme.warning : AppTheme.success,
          ),
          const SizedBox(width: 6),
          Text(
            date,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$pieces pcs',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          const Spacer(),
          Text(
            loggedBy,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
