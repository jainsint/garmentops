import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/app_state_service.dart';
import '../../services/offline_queue_service.dart';
import '../../core/ist_utils.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameCtrl = TextEditingController();
  final _orderNumberCtrl = TextEditingController();
  final _garmentTypeCtrl = TextEditingController();
  final _orderQtyCtrl = TextEditingController();
  // Use IST for default order/delivery dates
  DateTime _orderDate = ISTUtils.today();
  DateTime _deliveryDate = ISTUtils.today().add(const Duration(days: 14));
  bool _saving = false;

  List<Map<String, dynamic>> _orders = [];
  bool _loadingOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _orderNumberCtrl.dispose();
    _garmentTypeCtrl.dispose();
    _orderQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final data = await SupabaseService.instance.getClientOrders();
      setState(() {
        _orders = data;
        _loadingOrders = false;
      });
    } catch (_) {
      setState(() => _loadingOrders = false);
    }
  }

  Future<void> _pickOrderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _orderDate = picked);
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final offlineSvc = OfflineQueueService.instance;
    final orderData = {
      'clientName': _clientNameCtrl.text.trim(),
      'orderNumber': _orderNumberCtrl.text.trim(),
      'garmentType': _garmentTypeCtrl.text.trim(),
      'orderQuantity': int.tryParse(_orderQtyCtrl.text.trim()) ?? 0,
      'orderDate': _orderDate.toString().substring(0, 10),
      'deliveryDate': _deliveryDate.toString().substring(0, 10),
    };

    // If offline, queue the write
    if (!offlineSvc.isOnline) {
      await offlineSvc.enqueue(
        QueuedWrite(
          id: 'clientOrder_${ISTUtils.now().millisecondsSinceEpoch}',
          operation: 'insert',
          module: 'clientOrder',
          data: orderData,
          queuedAt: ISTUtils.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You\'re offline — order queued and will sync when reconnected.',
            ),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 4),
          ),
        );
        _clientNameCtrl.clear();
        _orderNumberCtrl.clear();
        _garmentTypeCtrl.clear();
        _orderQtyCtrl.clear();
        setState(() {
          _orderDate = ISTUtils.today();
          _deliveryDate = ISTUtils.today().add(const Duration(days: 14));
        });
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await SupabaseService.instance.insertClientOrder(orderData);
      // Notify cross-screen state
      AppStateService.instance.notifyRegisterWrite(
        register: 'Order',
        styleNo: orderData['garmentType'] as String,
        actor: 'Admin',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        _clientNameCtrl.clear();
        _orderNumberCtrl.clear();
        _garmentTypeCtrl.clear();
        _orderQtyCtrl.clear();
        setState(() {
          _orderDate = ISTUtils.today();
          _deliveryDate = ISTUtils.today().add(const Duration(days: 14));
          _saving = false;
        });
        _loadOrders();
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _save,
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteOrder(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: const Text('Are you sure you want to delete this order?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Create Order',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ),
            // ── Create Form ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outlineVariantLight),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Order',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurfaceLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _clientNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client Name *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orderNumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Order Number *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _garmentTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Garment Type *',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orderQtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Order Quantity *',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickOrderDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Order Date',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: _orderDate.toString().substring(0, 10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDeliveryDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Delivery Date',
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 18,
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: _deliveryDate.toString().substring(
                                    0,
                                    10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_rounded),
                      label: const Text('Create Order'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ── Orders List ──
            Text(
              'All Orders',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingOrders)
              const Center(child: CircularProgressIndicator())
            else if (_orders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: AppTheme.mutedText.withAlpha(100),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No orders yet',
                        style: GoogleFonts.ibmPlexSans(
                          color: AppTheme.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _orders.length,
                itemBuilder: (_, i) =>
                    _OrderCard(order: _orders[i], onDelete: _deleteOrder),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Future<void> Function(String id) onDelete;

  const _OrderCard({required this.order, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final daysLeft = order['delivery_date'] != null
        ? ISTUtils.daysUntilDelivery(order['delivery_date'] as String)
        : 0;
    final isOverdue = daysLeft < 0;
    final isUrgent = daysLeft >= 0 && daysLeft <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppTheme.error.withAlpha(80)
              : isUrgent
              ? AppTheme.warning.withAlpha(80)
              : AppTheme.outlineVariantLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order['client_name'] ?? '',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppTheme.errorContainer
                        : isUrgent
                        ? AppTheme.warningContainer
                        : AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isOverdue
                        ? 'Overdue'
                        : isUrgent
                        ? '$daysLeft days left'
                        : '$daysLeft days left',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
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
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete(order['id']);
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
                    size: 20,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Tag(label: 'Order #', value: order['order_number'] ?? '-'),
                const SizedBox(width: 8),
                _Tag(label: 'Type', value: order['garment_type'] ?? '-'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Tag(
                  label: 'Qty',
                  value: '${order['order_quantity'] ?? 0} pcs',
                ),
                const SizedBox(width: 8),
                _Tag(label: 'Delivery', value: order['delivery_date'] ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final String value;
  const _Tag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.onSurfaceLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
