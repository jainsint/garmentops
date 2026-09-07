import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/app_state_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner_widget.dart';
import './widgets/order_chart_card_widget.dart';
import './widgets/order_metric_card_widget.dart';
import './widgets/order_module_progress_widget.dart';
import './widgets/order_selector_widget.dart';
import '../../services/excel_export_service.dart';
import '../../core/ist_utils.dart';

class OrderData {
  final String id;
  final String orderNo;
  final String buyer;
  final String style;
  final String color;
  final String deliveryDate;
  final int totalQty;
  final String line;
  final int dailyTarget;
  final String startDate;
  final String endDate;
  final String status;
  final int progress;
  final int totalCut;
  final int totalProduced;
  final int totalPacked;
  final int totalIroned;
  final Map<String, int> moduleProgress;

  factory OrderData.fromClientOrder(Map<String, dynamic> m) {
    final deliveryDate = m['delivery_date'] ?? '';
    final orderDate = m['order_date'] ?? '';
    // Use IST-aware delivery countdown
    final daysLeft = ISTUtils.daysUntilDelivery(deliveryDate);
    final String status = daysLeft < 0 ? 'overdue' : (m['status'] ?? 'pending');
    return OrderData(
      id: m['id'] ?? '',
      orderNo: m['order_number'] ?? '',
      buyer: m['client_name'] ?? '',
      style: m['garment_type'] ?? '',
      color: '',
      deliveryDate: deliveryDate,
      totalQty: (m['order_quantity'] as num?)?.toInt() ?? 0,
      line: '',
      dailyTarget: 0,
      startDate: orderDate,
      endDate: deliveryDate,
      status: status,
      progress: 0,
      totalCut: 0,
      totalProduced: 0,
      totalPacked: 0,
      totalIroned: 0,
      moduleProgress: const {},
    );
  }

  const OrderData({
    required this.id,
    required this.orderNo,
    required this.buyer,
    required this.style,
    required this.color,
    required this.deliveryDate,
    required this.totalQty,
    required this.line,
    required this.dailyTarget,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.totalCut,
    required this.totalProduced,
    required this.totalPacked,
    required this.totalIroned,
    required this.moduleProgress,
  });
}

class OrderProgressScreen extends StatefulWidget {
  const OrderProgressScreen({super.key});

  @override
  State<OrderProgressScreen> createState() => _OrderProgressScreenState();
}

class _OrderProgressScreenState extends State<OrderProgressScreen> {
  int _selectedOrderIndex = 0;
  final bool _isResetting = false;
  bool _loading = true;
  final bool _isSaving = false;
  List<OrderData> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    AppStateService.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.getClientOrders(),
        SupabaseService.instance.getCuttingEntries(),
        SupabaseService.instance.getLayEntries(),
        SupabaseService.instance.getButtoningEntries(),
        SupabaseService.instance.getIroningEntries(),
        SupabaseService.instance.getCheckingEntries(),
        SupabaseService.instance.getDailyProductionEntries(),
        SupabaseService.instance.getSizewiseProductionEntries(),
        SupabaseService.instance.getWashingEntries(),
      ]);

      final clientOrders = results[0];
      final cuttingEntries = results[1];
      final layEntries = results[2];
      final buttoningEntries = results[3];
      final ironingEntries = results[4];
      final checkingEntries = results[5];
      final dailyProdEntries = results[6];
      final sizewiseProdEntries = results[7];
      final washingEntries = results[8];

      final orders = clientOrders.map((m) {
        final orderId = m['id']?.toString() ?? '';
        final totalQty = (m['order_quantity'] as num?)?.toInt() ?? 0;

        int sumForOrder(List<Map<String, dynamic>> entries, String qtyField) {
          return entries
              .where((e) => e['order_id']?.toString() == orderId)
              .fold(0, (sum, e) => sum + ((e[qtyField] as num?)?.toInt() ?? 0));
        }

        final totalCut = sumForOrder(cuttingEntries, 'total');
        final totalProduced =
            sumForOrder(dailyProdEntries, 'production_qty') +
            sumForOrder(sizewiseProdEntries, 'total_pieces');
        final totalIroned = sumForOrder(ironingEntries, 'quantity');
        final totalPacked = sumForOrder(checkingEntries, 'quantity');

        // Register-wise progress as percentage of order qty
        int pct(int qty) => totalQty > 0
            ? ((qty / totalQty) * 100).round().clamp(0, 100)
            : (qty > 0 ? 100 : 0);

        final layCount = layEntries
            .where((e) => e['order_id']?.toString() == orderId)
            .length;
        final buttoningCount = sumForOrder(buttoningEntries, 'quantity');
        final washingCount = sumForOrder(washingEntries, 'sent_qty');

        final moduleProgress = {
          'Fabric Stock': 0,
          'Lay Register': layCount > 0 ? 100 : 0,
          'Cutting': pct(totalCut),
          'Production': pct(totalProduced),
          'Buttoning & Button Holing': pct(buttoningCount),
          'Washing': pct(washingCount),
          'Ironing': pct(totalIroned),
          'Checking': pct(totalPacked),
          'Packing': 0,
          'Dispatch': 0,
        };

        final overallProgress = totalQty > 0
            ? ((totalCut / totalQty) * 100).round().clamp(0, 100)
            : 0;

        final deliveryDate = m['delivery_date'] ?? '';
        final orderDate = m['order_date'] ?? '';
        final daysLeft = ISTUtils.daysUntilDelivery(deliveryDate);
        final String status = daysLeft < 0
            ? 'overdue'
            : (m['status'] ?? 'pending');

        return OrderData(
          id: m['id'] ?? '',
          orderNo: m['order_number'] ?? '',
          buyer: m['client_name'] ?? '',
          style: m['garment_type'] ?? '',
          color: '',
          deliveryDate: deliveryDate,
          totalQty: totalQty,
          line: '',
          dailyTarget: 0,
          startDate: orderDate,
          endDate: deliveryDate,
          status: status,
          progress: overallProgress,
          totalCut: totalCut,
          totalProduced: totalProduced,
          totalPacked: totalPacked,
          totalIroned: totalIroned,
          moduleProgress: moduleProgress,
        );
      }).toList();

      setState(() {
        _orders = orders;
        _selectedOrderIndex = 0;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteOrder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text(
          'Are you sure you want to delete this order? This cannot be undone.',
        ),
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
      await SupabaseService.instance.deleteClientOrder(id);
      _loadOrders();
    }
  }

  OrderData? get _current => _orders.isEmpty
      ? null
      : _orders[_selectedOrderIndex.clamp(0, _orders.length - 1)];

  Future<void> _exportOrderExcel() async {
    final order = _current;
    if (order == null) return;

    // Build a summary sheet for the order
    final summaryData = {
      'Order Summary': [
        {'Field': 'Order No', 'Value': order.orderNo},
        {'Field': 'Buyer', 'Value': order.buyer},
        {'Field': 'Style', 'Value': order.style},
        {'Field': 'Total Qty', 'Value': '${order.totalQty} pcs'},
        {'Field': 'Delivery Date', 'Value': order.deliveryDate},
        {'Field': 'Status', 'Value': order.status},
        {'Field': 'Total Cut', 'Value': '${order.totalCut} pcs'},
        {'Field': 'Total Produced', 'Value': '${order.totalProduced} pcs'},
        {'Field': 'Total Ironed', 'Value': '${order.totalIroned} pcs'},
        {'Field': 'Total Packed', 'Value': '${order.totalPacked} pcs'},
      ],
    };

    await ExcelExportService.exportOrderToExcel(
      orderNo: order.orderNo,
      registerData: summaryData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: AuthService.instance.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(
                  '${AppRoutes.orderProgressScreen}/create-order',
                );
                _loadOrders();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Order'),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Column(
        children: [
          const OfflineBannerWidget(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? _buildEmptyState()
                : Stack(
                    children: [
                      SafeArea(
                        top: false,
                        child: CustomScrollView(
                          slivers: [
                            // Page title row
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  8,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Orders',
                                        style: GoogleFonts.ibmPlexSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onSurfaceLight,
                                        ),
                                      ),
                                    ),
                                    if (_current != null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.download_rounded,
                                          color: AppTheme.success,
                                          size: 22,
                                        ),
                                        tooltip: 'Download Excel',
                                        onPressed: _exportOrderExcel,
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        color: AppTheme.onSurfaceLight,
                                      ),
                                      onPressed: _loadOrders,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Order selector
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  0,
                                ),
                                child: OrderSelectorWidget(
                                  orders: _orders
                                      .map(
                                        (o) => (
                                          orderNo: o.orderNo,
                                          buyer: o.buyer,
                                        ),
                                      )
                                      .toList(),
                                  selectedIndex: _selectedOrderIndex.clamp(
                                    0,
                                    _orders.length - 1,
                                  ),
                                  onSelected: (i) =>
                                      setState(() => _selectedOrderIndex = i),
                                ),
                              ),
                            ),
                            if (_current != null) ...[
                              // Order header card
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: _OrderHeaderCard(
                                    order: _current!,
                                    onDelete: () => _deleteOrder(_current!.id),
                                  ),
                                ),
                              ),
                              // Metrics row
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: _buildMetricsRow(),
                                ),
                              ),
                              // Chart
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: OrderChartCardWidget(order: _current!),
                                ),
                              ),
                              // Register progress header
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Register-wise Progress',
                                        style: GoogleFonts.ibmPlexSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.onSurfaceLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    32,
                                  ),
                                  child: OrderModuleProgressWidget(
                                    order: _current!,
                                  ),
                                ),
                              ),
                            ],
                            // Recent Orders list
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  0,
                                ),
                                child: Text(
                                  'All Orders',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    0,
                                  ),
                                  child: _OrderListCard(
                                    order: _orders[i],
                                    isSelected:
                                        i ==
                                        _selectedOrderIndex.clamp(
                                          0,
                                          _orders.length - 1,
                                        ),
                                    onTap: () =>
                                        setState(() => _selectedOrderIndex = i),
                                    onDelete: () => _deleteOrder(_orders[i].id),
                                  ),
                                ),
                                childCount: _orders.length,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
                      if (_isResetting)
                        Container(
                          color: Colors.black.withAlpha(102),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: AppTheme.mutedText.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + New Order to create your first order',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final order = _current!;
    final metrics = [
      (
        label: 'Total Qty',
        value: '${order.totalQty}',
        unit: 'pcs',
        color: AppTheme.primary,
      ),
      (
        label: 'Cut',
        value: '${order.totalCut}',
        unit: 'pcs',
        color: AppTheme.success,
      ),
      (
        label: 'Ironed',
        value: '${order.totalIroned}',
        unit: 'pcs',
        color: AppTheme.warning,
      ),
      (
        label: 'Packed',
        value: '${order.totalPacked}',
        unit: 'pcs',
        color: const Color(0xFF4E342E),
      ),
    ];
    return Row(
      children: List.generate(metrics.length, (i) {
        final m = metrics[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < metrics.length - 1 ? 8 : 0),
            child: OrderMetricCardWidget(
              label: m.label,
              value: m.value,
              unit: m.unit,
              color: m.color,
            ),
          ),
        );
      }),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  final OrderData order;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrderListCard({
    required this.order,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = order.deliveryDate.isNotEmpty
        ? (DateTime.tryParse(
                order.deliveryDate,
              )?.difference(DateTime.now()).inDays ??
              0)
        : 0;
    final isOverdue = daysLeft < 0;
    final isUrgent = !isOverdue && daysLeft <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryContainer : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withAlpha(120)
                : isOverdue
                ? AppTheme.error.withAlpha(80)
                : isUrgent
                ? AppTheme.warning.withAlpha(80)
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
                    '${order.orderNo} — ${order.buyer}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.style}  •  ${order.totalQty} pcs  •  Delivery: ${order.deliveryDate}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppTheme.errorContainer
                    : isUrgent
                    ? AppTheme.warningContainer
                    : AppTheme.successContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOverdue ? 'Overdue' : '$daysLeft d',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isOverdue
                      ? AppTheme.error
                      : isUrgent
                      ? AppTheme.warning
                      : AppTheme.success,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (AuthService.instance.isAdmin)
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
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
                  size: 18,
                  color: AppTheme.mutedText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback onDelete;
  const _OrderHeaderCard({required this.order, required this.onDelete});

  Color get _statusColor {
    switch (order.status) {
      case 'inProgress':
        return AppTheme.warning;
      case 'complete':
        return AppTheme.success;
      case 'overdue':
        return AppTheme.error;
      default:
        return AppTheme.mutedText;
    }
  }

  String get _statusLabel {
    switch (order.status) {
      case 'inProgress':
        return 'In Progress';
      case 'complete':
        return 'Complete';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.orderNo,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '• ${order.style}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(64),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _statusColor.withAlpha(128)),
                    ),
                    child: Text(
                      _statusLabel,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (AuthService.instance.isAdmin)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.buyer,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: '${order.totalQty} pcs',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: order.deliveryDate,
              ),
              if (order.startDate.isNotEmpty) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.play_circle_outline_rounded,
                  label: order.startDate,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: order.progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withAlpha(51),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      order.progress >= 80
                          ? AppTheme.success
                          : order.progress >= 40
                          ? AppTheme.secondary
                          : AppTheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${order.progress}%',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
