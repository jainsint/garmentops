import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../services/app_state_service.dart';
import '../../../core/ist_utils.dart';

class HomeOrderProgressWidget extends StatefulWidget {
  final void Function(String orderNo) onOrderTap;

  const HomeOrderProgressWidget({required this.onOrderTap, super.key});

  @override
  State<HomeOrderProgressWidget> createState() =>
      _HomeOrderProgressWidgetState();
}

class _HomeOrderProgressWidgetState extends State<HomeOrderProgressWidget> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  DateTime? _lastLoaded;

  @override
  void initState() {
    super.initState();
    _load();
    AppStateService.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    final lastWrite = AppStateService.instance.lastRegisterWrite;
    if (_lastLoaded == null || lastWrite.isAfter(_lastLoaded!)) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.instance.getClientOrders();
      if (mounted) {
        setState(() {
          _orders = data.take(5).toList();
          _loading = false;
          _lastLoaded = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariantLight),
        ),
        child: Center(
          child: Text(
            'No orders yet. Tap Create Order to add one.',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 13,
              color: AppTheme.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: _orders
          .map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrderProgressCard(
                order: order,
                onTap: () => widget.onOrderTap(order['order_number'] ?? ''),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OrderProgressCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderProgressCard({required this.order, required this.onTap});

  int get _daysLeft {
    final d = order['delivery_date'] as String?;
    if (d == null || d.isEmpty) return 0;
    // Use IST-aware delivery countdown
    return ISTUtils.daysUntilDelivery(d);
  }

  Color get _progressColor {
    if (_daysLeft < 0) return AppTheme.error;
    if (_daysLeft <= 3) return AppTheme.warning;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysLeft;
    final isOverdue = days < 0;
    final qty = (order['order_quantity'] as num?)?.toInt() ?? 0;

    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primary.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: _progressColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 6,
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
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            order['order_number'] ?? '',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${order['garment_type'] ?? ''}',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.errorContainer
                          : days <= 3
                          ? AppTheme.warningContainer
                          : AppTheme.successContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue' : '$days d left',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _progressColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['client_name'] ?? '',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurfaceLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: AppTheme.mutedText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        order['delivery_date'] ?? '',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$qty pcs  •  Order Date: ${order['order_date'] ?? ''}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 11,
                  color: AppTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
