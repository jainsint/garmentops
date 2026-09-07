import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class OrderSelectorWidget extends StatefulWidget {
  final List<({String orderNo, String buyer})> orders;
  final int selectedIndex;
  final void Function(int) onSelected;

  const OrderSelectorWidget({
    required this.orders,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  @override
  State<OrderSelectorWidget> createState() => _OrderSelectorWidgetState();
}

class _OrderSelectorWidgetState extends State<OrderSelectorWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrderSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to selected item
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    const itemWidth = 160.0;
    final offset = widget.selectedIndex * (itemWidth + 8.0);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 52,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: widget.orders.length,
            itemBuilder: (context, i) {
              final order = widget.orders[i];
              final isSelected = i == widget.selectedIndex;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < widget.orders.length - 1 ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => widget.onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.outlineVariantLight,
                        width: isSelected ? 0 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withAlpha(64),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.orderNo,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            order.buyer,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white70
                                  : AppTheme.mutedText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dot indicators
        if (widget.orders.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.orders.length, (i) {
              final isSelected = i == widget.selectedIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isSelected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariantLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
