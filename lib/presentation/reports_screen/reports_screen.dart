import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/excel_export_service.dart';
import '../../core/ist_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  int _todayCutting = 0;
  int _todayProduction = 0;
  int _activeStyles = 0;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _washingEntries = [];
  List<Map<String, dynamic>> _subOutbound = [];
  List<Map<String, dynamic>> _subInbound = [];

  // null = Master Report, otherwise the selected order id
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getTodayCuttingTotal(),
        SupabaseService.instance.getTodayProductionTotal(),
        SupabaseService.instance.getActiveStylesCount(),
        SupabaseService.instance.getClientOrders(),
        SupabaseService.instance.getWashingEntries(),
        SupabaseService.instance.getSubcontractorOutbound(),
        SupabaseService.instance.getSubcontractorInbound(),
      ]);
      setState(() {
        _todayCutting = results[0] as int;
        _todayProduction = results[1] as int;
        _activeStyles = results[2] as int;
        _orders = results[3] as List<Map<String, dynamic>>;
        _washingEntries = results[4] as List<Map<String, dynamic>>;
        _subOutbound = results[5] as List<Map<String, dynamic>>;
        _subInbound = results[6] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? get _selectedOrder => _selectedOrderId == null
      ? null
      : _orders.where((o) => o['id'] == _selectedOrderId).firstOrNull;

  List<Map<String, dynamic>> get _filteredWashing => _selectedOrderId == null
      ? _washingEntries
      : _washingEntries
            .where((e) => e['order_id'] == _selectedOrderId)
            .toList();

  int get _totalOrders => _orders.length;
  int get _overdueOrders => _orders.where((o) {
    final d = o['delivery_date'] as String?;
    if (d == null || d.isEmpty) return false;
    return ISTUtils.daysUntilDelivery(d) < 0;
  }).length;

  int get _washingSent =>
      _filteredWashing.where((e) => e['status'] == 'sent').length;
  int get _washingReceived =>
      _filteredWashing.where((e) => e['status'] == 'received').length;
  int get _washingDiff => _filteredWashing.fold(0, (sum, e) {
    final diff = (e['difference'] as int?) ?? 0;
    return sum + diff.abs();
  });

  int get _subTotalPending {
    int out = 0;
    int inn = 0;
    for (final r in _subOutbound) {
      out += (r['no_of_pieces'] as int?) ?? 0;
    }
    for (final r in _subInbound) {
      inn += (r['no_of_pieces'] as int?) ?? 0;
    }
    return (out - inn).clamp(0, 999999);
  }

  int get _subTotalOut {
    int out = 0;
    for (final r in _subOutbound) {
      out += (r['no_of_pieces'] as int?) ?? 0;
    }
    return out;
  }

  Future<void> _exportMasterReport() async {
    final date = ISTUtils.todayString();
    final fileName = 'Master_Report_$date.xlsx';

    final registerData = <String, List<Map<String, dynamic>>>{
      'Orders': _orders
          .map(
            (o) => {
              'Order No': o['order_number'] ?? '',
              'Client': o['client_name'] ?? '',
              'Garment Type': o['garment_type'] ?? '',
              'Qty': '${o['order_quantity'] ?? 0}',
              'Order Date': o['order_date'] ?? '',
              'Delivery Date': o['delivery_date'] ?? '',
              'Status': o['status'] ?? '',
            },
          )
          .toList(),
      'Washing': _washingEntries
          .map(
            (e) => {
              'Style No': e['style_no'] ?? '',
              'Vendor': e['vendor_name'] ?? '',
              'Sent Qty': '${e['sent_qty'] ?? 0}',
              'Received Qty': '${e['received_qty'] ?? 0}',
              'Status': e['status'] ?? '',
              'Sent Date': e['sent_date'] ?? '',
            },
          )
          .toList(),
      'Subcontractor Outbound': _subOutbound
          .map(
            (e) => {
              'Date': e['entry_date'] ?? '',
              'Subcontractor': e['subcontractor_name'] ?? '',
              'Style': e['style'] ?? '',
              'Type': e['sub_type'] ?? '',
              'Pieces': '${e['no_of_pieces'] ?? 0}',
            },
          )
          .toList(),
      'Subcontractor Inbound': _subInbound
          .map(
            (e) => {
              'Date': e['entry_date'] ?? '',
              'Subcontractor': e['subcontractor_name'] ?? '',
              'Style': e['style'] ?? '',
              'Type': e['sub_type'] ?? '',
              'Pieces': '${e['no_of_pieces'] ?? 0}',
            },
          )
          .toList(),
    };

    await ExcelExportService.exportOrderToExcel(
      orderNo: 'Master_Report',
      registerData: registerData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reports',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _exportMasterReport,
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
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.onSurfaceLight,
                          ),
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── Order / Report Selector ──────────────────────────
                    _buildReportSelector(),
                    const SizedBox(height: 20),

                    if (_selectedOrderId == null) ...[
                      // ── MASTER REPORT ────────────────────────────────
                      _SectionTitle(title: "Today's Summary"),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Cutting Today',
                              value: '$_todayCutting',
                              unit: 'pcs',
                              icon: Icons.content_cut_rounded,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Production Today',
                              value: '$_todayProduction',
                              unit: 'pcs',
                              icon: Icons.precision_manufacturing_rounded,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Active Styles',
                              value: '$_activeStyles',
                              unit: 'styles',
                              icon: Icons.style_rounded,
                              color: const Color(0xFF6A1B9A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              label: 'Total Orders',
                              value: '$_totalOrders',
                              unit: 'orders',
                              icon: Icons.receipt_long_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Orders Overview'),
                      const SizedBox(height: 10),
                      _OverviewCard(
                        children: [
                          _OverviewRow(
                            label: 'Total Orders',
                            value: '$_totalOrders',
                          ),
                          _OverviewRow(
                            label: 'Overdue Orders',
                            value: '$_overdueOrders',
                            valueColor: _overdueOrders > 0
                                ? AppTheme.error
                                : AppTheme.success,
                          ),
                          _OverviewRow(
                            label: 'On-time Orders',
                            value: '${_totalOrders - _overdueOrders}',
                            valueColor: AppTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Washing Register (All Orders)'),
                      const SizedBox(height: 10),
                      _buildWashingOverview(),
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Subcontractor Summary'),
                      const SizedBox(height: 10),
                      _OverviewCard(
                        children: [
                          _OverviewRow(
                            label: 'Total Pieces Sent Out',
                            value: '$_subTotalOut pcs',
                          ),
                          _OverviewRow(
                            label: 'Pieces Pending Return',
                            value: '$_subTotalPending pcs',
                            valueColor: _subTotalPending > 0
                                ? AppTheme.warning
                                : AppTheme.success,
                          ),
                          _OverviewRow(
                            label: 'Active Subcontractors',
                            value:
                                '${_subOutbound.map((e) => e['subcontractor_name']).toSet().length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'All Orders'),
                      const SizedBox(height: 10),
                      if (_orders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No orders yet',
                              style: GoogleFonts.ibmPlexSans(
                                color: AppTheme.mutedText,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._orders.map((o) => _OrderReportRow(order: o)),
                    ] else ...[
                      // ── PER-ORDER REPORT ─────────────────────────────
                      _buildOrderReport(_selectedOrder!),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReportSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariantLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedOrderId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.primary,
          ),
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceLight,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Master Report — All Operations',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            ..._orders.map((o) {
              final label =
                  '${o['order_number'] ?? ''} — ${o['client_name'] ?? ''}';
              return DropdownMenuItem<String?>(
                value: o['id'] as String?,
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: (val) => setState(() => _selectedOrderId = val),
        ),
      ),
    );
  }

  Widget _buildWashingOverview() {
    return _OverviewCard(
      children: [
        _OverviewRow(label: 'Items Sent Out', value: '$_washingSent'),
        _OverviewRow(label: 'Items Received', value: '$_washingReceived'),
        _OverviewRow(
          label: 'Pending Return',
          value: '${(_washingSent - _washingReceived).clamp(0, 9999)}',
        ),
        _OverviewRow(
          label: 'Total Difference (pcs)',
          value: '$_washingDiff',
          valueColor: _washingDiff > 0 ? AppTheme.error : AppTheme.success,
        ),
      ],
    );
  }

  Widget _buildOrderReport(Map<String, dynamic> order) {
    final daysLeft = order['delivery_date'] != null
        ? ISTUtils.daysUntilDelivery(order['delivery_date'] as String)
        : 0;
    final isOverdue = daysLeft < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order header card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? AppTheme.error.withAlpha(80)
                  : AppTheme.outlineVariantLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order['order_number'] ?? ''} — ${order['client_name'] ?? ''}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.errorContainer
                          : AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue' : '$daysLeft d left',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppTheme.error : AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OverviewCard(
                children: [
                  _OverviewRow(
                    label: 'Garment Type',
                    value: order['garment_type'] ?? '—',
                  ),
                  _OverviewRow(
                    label: 'Order Quantity',
                    value: '${order['order_quantity'] ?? 0} pcs',
                  ),
                  _OverviewRow(
                    label: 'Order Date',
                    value: order['order_date'] ?? '—',
                  ),
                  _OverviewRow(
                    label: 'Delivery Date',
                    value: order['delivery_date'] ?? '—',
                  ),
                  _OverviewRow(
                    label: 'Status',
                    value: (order['status'] ?? 'pending')
                        .toString()
                        .toUpperCase(),
                    valueColor: isOverdue ? AppTheme.error : AppTheme.success,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Washing — This Order'),
        const SizedBox(height: 10),
        _buildWashingOverview(),
        if (_filteredWashing.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._filteredWashing.map((e) => _WashingEntryRow(entry: e)),
        ],
      ],
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurfaceLight,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(31),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 12,
              color: AppTheme.mutedText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final List<Widget> children;
  const _OverviewCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          children.length,
          (i) => Column(
            children: [
              children[i],
              if (i < children.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _OverviewRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppTheme.onSurfaceLight,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderReportRow extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderReportRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final daysLeft = order['delivery_date'] != null
        ? ISTUtils.daysUntilDelivery(order['delivery_date'] as String)
        : 0;
    final isOverdue = daysLeft < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? AppTheme.error.withAlpha(80)
              : AppTheme.outlineVariantLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order['order_number'] ?? ''} — ${order['client_name'] ?? ''}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${order['garment_type'] ?? ''}  •  ${order['order_quantity'] ?? 0} pcs',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppTheme.errorContainer
                  : AppTheme.successContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOverdue ? 'Overdue' : '$daysLeft d left',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOverdue ? AppTheme.error : AppTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WashingEntryRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _WashingEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isReceived = entry['status'] == 'received';
    final sentQty = (entry['sent_qty'] as int?) ?? 0;
    final receivedQty = (entry['received_qty'] as int?) ?? 0;
    final diff = isReceived ? sentQty - receivedQty : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (diff != null && diff > 0)
              ? AppTheme.error.withAlpha(80)
              : AppTheme.outlineVariantLight,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReceived
                ? Icons.check_circle_rounded
                : Icons.local_laundry_service_rounded,
            size: 18,
            color: isReceived ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry['style_no'] ?? ''}  •  DC: ${entry['sent_dc_no'] ?? '—'}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
                Text(
                  isReceived
                      ? 'Sent: $sentQty pcs  →  Received: $receivedQty pcs'
                      : 'Sent: $sentQty pcs  •  Awaiting return',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (diff != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: diff > 0
                    ? AppTheme.errorContainer
                    : AppTheme.successContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                diff > 0 ? '-$diff pcs' : 'OK',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: diff > 0 ? AppTheme.error : AppTheme.success,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
