import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/ist_utils.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Initialize Supabase - call this in main()
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // ─── Orders ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getOrders() async {
    final response = await client
        .from('orders')
        .select(
          'id, order_no, style_no, buyer, description, quantity, delivery_date, status',
        )
        .eq('status', 'active')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertOrder(Map<String, dynamic> data) async {
    await client.from('orders').insert({
      'order_no': data['orderNo'] ?? '',
      'style_no': data['styleNo'] ?? '',
      'buyer': data['buyer'] ?? '',
      'description': data['description'] ?? '',
      'quantity': data['quantity'] ?? 0,
      'delivery_date': data['deliveryDate'],
      'status': 'active',
    });
  }

  // ─── Cutting Register ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCuttingEntries() async {
    final response = await client
        .from('cutting_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertCuttingEntry(Map<String, dynamic> data) async {
    await client.from('cutting_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'color': data['color'] ?? '',
      'design_no': data['designNo'] ?? '',
      'avg_consumption': data['avgConsumption'] ?? '',
      'size_s': data['S'] ?? 0,
      'size_m': data['M'] ?? 0,
      'size_l': data['L'] ?? 0,
      'size_xl': data['XL'] ?? 0,
      'size_2xl': data['2XL'] ?? 0,
      'size_3xl': data['3XL'] ?? 0,
      'size_4xl': data['4XL'] ?? 0,
      'size_5xl': data['5XL'] ?? 0,
      'size_6xl': data['6XL'] ?? 0,
      'total': data['total'] ?? 0,
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Production Register ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProductionEntries() async {
    final response = await client
        .from('production_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertProductionEntry(Map<String, dynamic> data) async {
    await client.from('production_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'color': data['color'] ?? '',
      'line_no': data['lineNo'] ?? '',
      'operation': data['operation'] ?? '',
      'target_qty': data['targetQty'] ?? 0,
      'achieved_qty': data['achievedQty'] ?? 0,
      'efficiency': data['efficiency'] ?? 0.0,
      'operator_name': data['operatorName'] ?? '',
      'remarks': data['remarks'] ?? '',
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Lay Register ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLayEntries() async {
    final response = await client
        .from('lay_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertLayEntry(Map<String, dynamic> data) async {
    await client.from('lay_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'color': data['color'] ?? '',
      'fabric_type': data['fabricType'] ?? '',
      'lay_length': data['layLength'] ?? 0.0,
      'no_of_plies': data['noOfPlies'] ?? 0,
      'total_meters': data['totalMeters'] ?? 0.0,
      'colours': data['colours'] ?? [],
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Ironing Register ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getIroningEntries() async {
    final response = await client
        .from('ironing_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertIroningEntry(Map<String, dynamic> data) async {
    await client.from('ironing_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'iron_type': data['type'] ?? '',
      'quantity': data['quantity'] ?? 0,
      'representative': data['representative'] ?? '',
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Checking Register ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCheckingEntries() async {
    final response = await client
        .from('checking_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertCheckingEntry(Map<String, dynamic> data) async {
    await client.from('checking_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'check_type': data['type'] ?? '',
      'quantity': data['quantity'] ?? 0,
      'representative': data['representative'] ?? '',
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Fabric Stock Register ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getFabricStockEntries() async {
    final response = await client
        .from('fabric_stock_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertFabricStockEntry(Map<String, dynamic> data) async {
    await client.from('fabric_stock_entries').insert({
      'order_id': data['orderId'],
      'style': data['style'] ?? '',
      'entry_date': data['date'] ?? ISTUtils.todayString(),
      'design': data['design'] ?? '',
      'colour': data['colour'] ?? '',
      'rolls': data['rolls'] ?? [],
      'total_rolls': data['totalRolls'] ?? 0,
      'total_mtrs': data['totalMtrs'] ?? 0.0,
      'total_used': data['totalUsed'] ?? 0.0,
      'balance': data['balance'] ?? 0.0,
      'remarks': data['remarks'] ?? '',
      'swatch_photo_path': data['swatchPhotoPath'],
    });
  }

  // ─── Admin: Reset Order Entries ────────────────────────────────────────────

  /// Deletes all register entries linked to [orderId] across every register
  /// table. The order row itself is preserved.
  Future<void> resetOrderEntries(String orderId) async {
    final tables = [
      'fabric_stock_entries',
      'lay_entries',
      'cutting_entries',
      'production_entries',
      'ironing_entries',
      'checking_entries',
      'buttoning_entries',
      'stitching_entries',
      'washing_entries',
      'daily_production_entries',
      'sizewise_production_entries',
      'production_planner_entries',
    ];
    for (final table in tables) {
      await client.from(table).delete().eq('order_id', orderId);
    }
  }

  // ─── Delete a single entry ─────────────────────────────────────────────────

  Future<void> deleteEntry(String module, String id) async {
    final table = _tableForModule(module);
    await client.from(table).delete().eq('id', id);
  }

  // ─── Update a single entry ─────────────────────────────────────────────────

  Future<void> updateEntry(
    String module,
    String id,
    Map<String, dynamic> data,
  ) async {
    final table = _tableForModule(module);
    final payload = _buildUpdatePayload(module, data);
    await client.from(table).update(payload).eq('id', id);
  }

  String _tableForModule(String module) {
    switch (module) {
      case 'cutting':
        return 'cutting_entries';
      case 'lay':
        return 'lay_entries';
      case 'ironing':
        return 'ironing_entries';
      case 'checking':
        return 'checking_entries';
      case 'fabricStock':
        return 'fabric_stock_entries';
      case 'buttoning':
        return 'buttoning_entries';
      case 'stitching':
        return 'stitching_entries';
      case 'washing':
        return 'washing_entries';
      default:
        throw ArgumentError('Unknown module: $module');
    }
  }

  Map<String, dynamic> _buildUpdatePayload(
    String module,
    Map<String, dynamic> data,
  ) {
    switch (module) {
      case 'cutting':
        return {
          'style_no': data['styleNo'] ?? '',
          'color': data['color'] ?? '',
          'design_no': data['designNo'] ?? '',
          'avg_consumption': data['avgConsumption'] ?? '',
          'size_s': data['S'] ?? 0,
          'size_m': data['M'] ?? 0,
          'size_l': data['L'] ?? 0,
          'size_xl': data['XL'] ?? 0,
          'size_2xl': data['2XL'] ?? 0,
          'size_3xl': data['3XL'] ?? 0,
          'size_4xl': data['4XL'] ?? 0,
          'size_5xl': data['5XL'] ?? 0,
          'size_6xl': data['6XL'] ?? 0,
          'total': data['total'] ?? 0,
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'lay':
        return {
          'style_no': data['styleNo'] ?? '',
          'color': data['color'] ?? '',
          'fabric_type': data['fabricType'] ?? '',
          'lay_length': data['layLength'] ?? 0.0,
          'no_of_plies': data['noOfPlies'] ?? 0,
          'total_meters': data['totalMeters'] ?? 0.0,
          'colours': data['colours'] ?? [],
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'ironing':
        return {
          'style_no': data['styleNo'] ?? '',
          'iron_type': data['type'] ?? '',
          'quantity': data['quantity'] ?? 0,
          'representative': data['representative'] ?? '',
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'checking':
        return {
          'style_no': data['styleNo'] ?? '',
          'check_type': data['type'] ?? '',
          'quantity': data['quantity'] ?? 0,
          'representative': data['representative'] ?? '',
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'fabricStock':
        return {
          'style': data['style'] ?? '',
          'entry_date': data['date'] ?? ISTUtils.todayString(),
          'design': data['design'] ?? '',
          'colour': data['colour'] ?? '',
          'rolls': data['rolls'] ?? [],
          'total_rolls': data['totalRolls'] ?? 0,
          'total_mtrs': data['totalMtrs'] ?? 0.0,
          'total_used': data['totalUsed'] ?? 0.0,
          'balance': data['balance'] ?? 0.0,
          'remarks': data['remarks'] ?? '',
          'swatch_photo_path': data['swatchPhotoPath'],
          'photo_url': data['photoUrl'],
        };
      case 'buttoning':
        return {
          'style_no': data['styleNo'] ?? '',
          'design_no': data['designNo'] ?? '',
          'operation': data['operation'] ?? 'Buttoning',
          'quantity': data['quantity'] ?? 0,
          'representative': data['representative'] ?? '',
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'stitching':
        return {
          'style_no': data['styleNo'] ?? '',
          'production_qty': data['productionQty'] ?? 0,
          'line_number': data['lineNumber'] ?? '',
          'comments': data['comments'] ?? '',
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        };
      case 'washing':
        return {
          'style_no': data['styleNo'] ?? '',
          'design_no': data['designNo'] ?? '',
          'colour': data['colour'] ?? '',
          'vendor_name': data['vendorName'] ?? '',
          'sent_qty': data['sentQty'] ?? 0,
          'sent_date': data['sentDate'] ?? ISTUtils.todayString(),
          'sent_dc_no': data['sentDcNo'] ?? '',
          'received_qty': data['receivedQty'],
          'received_date': data['receivedDate'],
          'received_dc_no': data['receivedDcNo'],
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
          'status': data['status'] ?? 'sent',
        };
      default:
        return data;
    }
  }

  // ─── Stats helpers ─────────────────────────────────────────────────────────

  /// Returns total pieces cut today (IST) across all cutting entries
  Future<int> getTodayCuttingTotal() async {
    final today = ISTUtils.todayString();
    final response = await client
        .from('cutting_entries')
        .select('total')
        .eq('entry_date', today);
    final list = List<Map<String, dynamic>>.from(response);
    int total = 0;
    for (final row in list) {
      total += (row['total'] as int?) ?? 0;
    }
    return total;
  }

  /// Returns total achieved qty for production today (IST)
  Future<int> getTodayProductionTotal() async {
    final today = ISTUtils.todayString();
    final response = await client
        .from('daily_production_entries')
        .select('production_qty')
        .eq('entry_date', today);
    final list = List<Map<String, dynamic>>.from(response);
    int total = 0;
    for (final row in list) {
      total += (row['production_qty'] as int?) ?? 0;
    }
    return total;
  }

  /// Returns count of distinct style numbers across all modules
  Future<int> getActiveStylesCount() async {
    final response = await client.from('cutting_entries').select('style_no');
    final list = List<Map<String, dynamic>>.from(response);
    final styles = list.map((r) => r['style_no'] as String).toSet();
    return styles.length;
  }

  // ─── Real-time subscriptions ───────────────────────────────────────────────

  RealtimeChannel subscribeToTable({
    required String table,
    required void Function(Map<String, dynamic> record) onInsert,
  }) {
    return client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
  }

  // ─── Washing Register ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWashingEntries() async {
    final response = await client
        .from('washing_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertWashingEntry(Map<String, dynamic> data) async {
    await client.from('washing_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'colour': data['colour'] ?? '',
      'vendor_name': data['vendorName'] ?? '',
      'sent_qty': data['sentQty'] ?? 0,
      'sent_date': data['sentDate'] ?? ISTUtils.todayString(),
      'sent_dc_no': data['sentDcNo'] ?? '',
      'remarks': data['remarks'] ?? '',
      'status': 'sent',
    });
  }

  Future<void> updateWashingEntry(String id, Map<String, dynamic> data) async {
    await client
        .from('washing_entries')
        .update({
          'order_id': data['orderId'],
          'style_no': data['styleNo'] ?? '',
          'colour': data['colour'] ?? '',
          'vendor_name': data['vendorName'] ?? '',
          'sent_qty': data['sentQty'] ?? 0,
          'sent_date': data['sentDate'] ?? ISTUtils.todayString(),
          'sent_dc_no': data['sentDcNo'] ?? '',
          'remarks': data['remarks'] ?? '',
        })
        .eq('id', id);
  }

  Future<void> markWashingReceived(
    String id,
    int receivedQty,
    String receivedDate,
    String receivedDcNo,
  ) async {
    await client
        .from('washing_entries')
        .update({
          'received_qty': receivedQty,
          'received_date': receivedDate,
          'received_dc_no': receivedDcNo,
          'status': 'received',
        })
        .eq('id', id);
  }

  Future<void> deleteWashingEntry(String id) async {
    await client.from('washing_entries').delete().eq('id', id);
  }

  // ─── Client Orders ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getClientOrders() async {
    final response = await client
        .from('client_orders')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertClientOrder(Map<String, dynamic> data) async {
    await client.from('client_orders').insert({
      'client_name': data['clientName'] ?? '',
      'order_number': data['orderNumber'] ?? '',
      'garment_type': data['garmentType'] ?? '',
      'order_quantity': data['orderQuantity'] ?? 0,
      'order_date': data['orderDate'] ?? ISTUtils.todayString(),
      'delivery_date': data['deliveryDate'] ?? ISTUtils.todayString(),
      'status': 'pending',
    });
  }

  Future<void> deleteClientOrder(String id) async {
    await client.from('client_orders').delete().eq('id', id);
  }

  // ─── Buttoning & Button Holing Register ───────────────────────────────────

  Future<List<Map<String, dynamic>>> getButtoningEntries() async {
    final response = await client
        .from('buttoning_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertButtoningEntry(Map<String, dynamic> data) async {
    await client.from('buttoning_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'design_no': data['designNo'] ?? '',
      'operation': data['operation'] ?? 'Buttoning',
      'quantity': data['quantity'] ?? 0,
      'representative': data['representative'] ?? '',
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Stitching Register ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getStitchingEntries() async {
    final response = await client
        .from('stitching_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertStitchingEntry(Map<String, dynamic> data) async {
    await client.from('stitching_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'production_qty': data['productionQty'] ?? 0,
      'line_number': data['lineNumber'] ?? '',
      'comments': data['comments'] ?? '',
      'entry_date': data['date'] ?? ISTUtils.todayString(),
    });
  }

  // ─── Daily Production Register ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDailyProductionEntries() async {
    final response = await client
        .from('daily_production_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertDailyProductionEntry(Map<String, dynamic> data) async {
    await client.from('daily_production_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'production_qty': data['productionQty'] ?? 0,
      'line_number': data['lineNumber'] ?? '',
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'entry_date': data['date'] ?? ISTUtils.todayString(),
      'logged_by': data['loggedBy'] ?? 'Staff',
    });
  }

  Future<void> updateDailyProductionEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('daily_production_entries')
        .update({
          'order_id': data['orderId'],
          'style_no': data['styleNo'] ?? '',
          'production_qty': data['productionQty'] ?? 0,
          'line_number': data['lineNumber'] ?? '',
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
          'entry_date': data['date'] ?? ISTUtils.todayString(),
        })
        .eq('id', id);
  }

  Future<void> deleteDailyProductionEntry(String id) async {
    await client.from('daily_production_entries').delete().eq('id', id);
  }

  // ─── Size-wise Production Register ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSizewiseProductionEntries() async {
    final response = await client
        .from('sizewise_production_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertSizewiseProductionEntry(Map<String, dynamic> data) async {
    await client.from('sizewise_production_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'start_date': data['startDate'] ?? ISTUtils.todayString(),
      'end_date': data['endDate'] ?? ISTUtils.todayString(),
      'size_quantities': data['sizeQuantities'] ?? {},
      'total_pieces': data['totalPieces'] ?? 0,
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'logged_by': data['loggedBy'] ?? 'Staff',
    });
  }

  Future<void> updateSizewiseProductionEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('sizewise_production_entries')
        .update({
          'order_id': data['orderId'],
          'style_no': data['styleNo'] ?? '',
          'start_date': data['startDate'] ?? ISTUtils.todayString(),
          'end_date': data['endDate'] ?? ISTUtils.todayString(),
          'size_quantities': data['sizeQuantities'] ?? {},
          'total_pieces': data['totalPieces'] ?? 0,
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
        })
        .eq('id', id);
  }

  Future<void> deleteSizewiseProductionEntry(String id) async {
    await client.from('sizewise_production_entries').delete().eq('id', id);
  }

  // ─── Production Planner ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProductionPlannerEntries() async {
    final response = await client
        .from('production_planner_entries')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertProductionPlannerEntry(Map<String, dynamic> data) async {
    await client.from('production_planner_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'design_no': data['designNo'] ?? '',
      'allocations': data['allocations'] ?? [],
      'total_allocated': data['totalAllocated'] ?? 0,
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'logged_by': data['loggedBy'] ?? 'Staff',
    });
  }

  Future<void> updateProductionPlannerEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    await client
        .from('production_planner_entries')
        .update({
          'order_id': data['orderId'],
          'style_no': data['styleNo'] ?? '',
          'design_no': data['designNo'] ?? '',
          'allocations': data['allocations'] ?? [],
          'total_allocated': data['totalAllocated'] ?? 0,
          'remarks': data['remarks'] ?? '',
          'photo_url': data['photoUrl'],
        })
        .eq('id', id);
  }

  Future<void> deleteProductionPlannerEntry(String id) async {
    await client.from('production_planner_entries').delete().eq('id', id);
  }

  // ─── Washing Register (inline form) ───────────────────────────────────────

  Future<void> insertWashingEntryFromForm(Map<String, dynamic> data) async {
    await client.from('washing_entries').insert({
      'order_id': data['orderId'],
      'style_no': data['styleNo'] ?? '',
      'design_no': data['designNo'] ?? '',
      'colour': data['colour'] ?? '',
      'vendor_name': data['vendorName'] ?? '',
      'sent_qty': data['sentQty'] ?? 0,
      'sent_date': data['sentDate'] ?? ISTUtils.todayString(),
      'sent_dc_no': data['sentDcNo'] ?? '',
      'received_qty': data['receivedQty'],
      'received_date': data['receivedDate'],
      'received_dc_no': data['receivedDcNo'],
      'remarks': data['remarks'] ?? '',
      'photo_url': data['photoUrl'],
      'status': data['status'] ?? 'sent',
    });
  }

  // ─── Subcontractor Register ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSubcontractorOutbound() async {
    final response = await client
        .from('subcontractor_outbound')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getSubcontractorInbound() async {
    final response = await client
        .from('subcontractor_inbound')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertSubcontractorOutbound(Map<String, dynamic> data) async {
    await client.from('subcontractor_outbound').insert({
      'subcontractor_name': data['subcontractorName'] ?? '',
      'order_id': data['orderId'],
      'style': data['style'] ?? '',
      'sub_type': data['subType'] ?? 'Cutting',
      'no_of_pieces': data['noOfPieces'] ?? 0,
      'entry_date': data['date'] ?? ISTUtils.todayString(),
      'logged_by': data['loggedBy'] ?? 'Staff',
      'remarks': data['remarks'] ?? '',
    });
  }

  Future<void> insertSubcontractorInbound(Map<String, dynamic> data) async {
    await client.from('subcontractor_inbound').insert({
      'subcontractor_name': data['subcontractorName'] ?? '',
      'order_id': data['orderId'],
      'style': data['style'] ?? '',
      'sub_type': data['subType'] ?? 'Cutting',
      'no_of_pieces': data['noOfPieces'] ?? 0,
      'entry_date': data['date'] ?? ISTUtils.todayString(),
      'logged_by': data['loggedBy'] ?? 'Staff',
      'remarks': data['remarks'] ?? '',
    });
  }

  Future<void> deleteSubcontractorEntry(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  Future<int> getTotalSubcontractorPending() async {
    final outbound = await getSubcontractorOutbound();
    final inbound = await getSubcontractorInbound();
    int totalOut = 0;
    int totalIn = 0;
    for (final r in outbound) {
      totalOut += (r['no_of_pieces'] as int?) ?? 0;
    }
    for (final r in inbound) {
      totalIn += (r['no_of_pieces'] as int?) ?? 0;
    }
    return (totalOut - totalIn).clamp(0, 999999);
  }
}
