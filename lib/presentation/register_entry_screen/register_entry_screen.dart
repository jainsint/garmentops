import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/app_state_service.dart';
import '../../services/auth_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/excel_export_service.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/offline_banner_widget.dart';
import '../subcontractor_register_screen/subcontractor_register_screen.dart';
import './widgets/register_cutting_form_widget.dart';
import './widgets/register_filter_widget.dart';
import './widgets/register_list_item_widget.dart';
import './widgets/register_ironing_form_widget.dart';
import './widgets/register_checking_form_widget.dart';
import './widgets/register_lay_form_widget.dart';
import './widgets/register_fabric_stock_form_widget.dart';
import './widgets/register_buttoning_form_widget.dart';
import './widgets/register_stitching_form_widget.dart';
import './widgets/register_washing_form_widget.dart';
import './widgets/register_daily_production_form_widget.dart';
import './widgets/register_sizewise_production_form_widget.dart';
import './widgets/register_production_planner_form_widget.dart';
import './widgets/fabric_stock_view_screen.dart';
import '../../core/ist_utils.dart';

enum RegisterModule {
  fabricStock,
  lay,
  cutting,
  bundling,
  stitching,
  dailyProduction,
  sizewiseProduction,
  buttoningAndButtonHoling,
  washing,
  checkingAndFinishing,
  ironing,
  packaging,
  subcontractor,
  productionPlanner,
}

extension RegisterModuleExt on RegisterModule {
  String get label {
    switch (this) {
      case RegisterModule.fabricStock:
        return 'Fabric Stock';
      case RegisterModule.lay:
        return 'Lay';
      case RegisterModule.cutting:
        return 'Cutting';
      case RegisterModule.bundling:
        return 'Bundling';
      case RegisterModule.stitching:
        return 'Stitching (Legacy)';
      case RegisterModule.dailyProduction:
        return 'Daily Production';
      case RegisterModule.sizewiseProduction:
        return 'Size-wise Production';
      case RegisterModule.buttoningAndButtonHoling:
        return 'Buttoning & Button Holing';
      case RegisterModule.washing:
        return 'Washing';
      case RegisterModule.checkingAndFinishing:
        return 'Checking & Finishing';
      case RegisterModule.ironing:
        return 'Ironing';
      case RegisterModule.packaging:
        return 'Packaging';
      case RegisterModule.subcontractor:
        return 'Subcontractor';
      case RegisterModule.productionPlanner:
        return 'Production Planner';
    }
  }

  IconData get icon {
    switch (this) {
      case RegisterModule.fabricStock:
        return Icons.inventory_2_rounded;
      case RegisterModule.lay:
        return Icons.layers_rounded;
      case RegisterModule.cutting:
        return Icons.content_cut_rounded;
      case RegisterModule.bundling:
        return Icons.inventory_rounded;
      case RegisterModule.stitching:
        return Icons.settings_input_component_rounded;
      case RegisterModule.dailyProduction:
        return Icons.precision_manufacturing_rounded;
      case RegisterModule.sizewiseProduction:
        return Icons.bar_chart_rounded;
      case RegisterModule.buttoningAndButtonHoling:
        return Icons.radio_button_checked_rounded;
      case RegisterModule.washing:
        return Icons.local_laundry_service_rounded;
      case RegisterModule.checkingAndFinishing:
        return Icons.fact_check_rounded;
      case RegisterModule.ironing:
        return Icons.iron_rounded;
      case RegisterModule.packaging:
        return Icons.archive_rounded;
      case RegisterModule.subcontractor:
        return Icons.people_outline_rounded;
      case RegisterModule.productionPlanner:
        return Icons.calendar_month_rounded;
    }
  }

  String get tableKey {
    switch (this) {
      case RegisterModule.cutting:
        return 'cutting';
      case RegisterModule.lay:
        return 'lay';
      case RegisterModule.ironing:
        return 'ironing';
      case RegisterModule.checkingAndFinishing:
        return 'checking';
      case RegisterModule.fabricStock:
        return 'fabricStock';
      case RegisterModule.buttoningAndButtonHoling:
        return 'buttoning';
      case RegisterModule.stitching:
        return 'stitching';
      case RegisterModule.washing:
        return 'washing';
      case RegisterModule.dailyProduction:
        return 'dailyProduction';
      case RegisterModule.sizewiseProduction:
        return 'sizewiseProduction';
      case RegisterModule.productionPlanner:
        return 'productionPlanner';
      default:
        return '';
    }
  }
}

class RegisterEntryScreen extends StatefulWidget {
  const RegisterEntryScreen({super.key});

  @override
  State<RegisterEntryScreen> createState() => _RegisterEntryScreenState();
}

class _RegisterEntryScreenState extends State<RegisterEntryScreen> {
  RegisterModule _selectedModule = RegisterModule.fabricStock;
  String _selectedStyle = 'All';
  bool _showAddForm = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // For edit mode
  Map<String, dynamic>? _editingEntry;

  List<Map<String, dynamic>> _entries = [];
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _fetchForModule(_selectedModule);
      if (mounted) {
        setState(() {
          _entries = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load entries. Pull to refresh.';
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchForModule(
    RegisterModule module,
  ) async {
    switch (module) {
      case RegisterModule.cutting:
        final rows = await _supabase.getCuttingEntries();
        return rows.map((r) => _mapCuttingRow(r)).toList();
      case RegisterModule.lay:
        final rows = await _supabase.getLayEntries();
        return rows.map((r) => _mapLayRow(r)).toList();
      case RegisterModule.ironing:
        final rows = await _supabase.getIroningEntries();
        return rows.map((r) => _mapIroningRow(r)).toList();
      case RegisterModule.checkingAndFinishing:
        final rows = await _supabase.getCheckingEntries();
        return rows.map((r) => _mapCheckingRow(r)).toList();
      case RegisterModule.fabricStock:
        final rows = await _supabase.getFabricStockEntries();
        return rows.map((r) => _mapFabricStockRow(r)).toList();
      case RegisterModule.buttoningAndButtonHoling:
        final rows = await _supabase.getButtoningEntries();
        return rows.map((r) => _mapButtoningRow(r)).toList();
      case RegisterModule.stitching:
        final rows = await _supabase.getStitchingEntries();
        return rows.map((r) => _mapStitchingRow(r)).toList();
      case RegisterModule.washing:
        final rows = await _supabase.getWashingEntries();
        return rows.map((r) => _mapWashingRow(r)).toList();
      case RegisterModule.dailyProduction:
        final rows = await _supabase.getDailyProductionEntries();
        return rows.map((r) => _mapDailyProductionRow(r)).toList();
      case RegisterModule.sizewiseProduction:
        final rows = await _supabase.getSizewiseProductionEntries();
        return rows.map((r) => _mapSizewiseProductionRow(r)).toList();
      case RegisterModule.productionPlanner:
        final rows = await _supabase.getProductionPlannerEntries();
        return rows.map((r) => _mapProductionPlannerRow(r)).toList();
      default:
        return [];
    }
  }

  Map<String, dynamic> _mapDailyProductionRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'type': 'Line ${r['line_number'] ?? ''}',
    'quantity': r['production_qty'] ?? 0,
    'representative': r['line_number'] ?? '',
    'date': r['entry_date'] ?? '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'lineNumber': r['line_number'] ?? '',
    'productionQty': r['production_qty'] ?? 0,
    'orderId': r['order_id'],
    'status': 'complete',
  };

  Map<String, dynamic> _mapSizewiseProductionRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'type': 'Size-wise',
    'quantity': r['total_pieces'] ?? 0,
    'representative': '',
    'date': r['start_date'] ?? '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'startDate': r['start_date'] ?? '',
    'endDate': r['end_date'] ?? '',
    'sizeQuantities': r['size_quantities'] ?? {},
    'totalPieces': r['total_pieces'] ?? 0,
    'orderId': r['order_id'],
    'status': 'complete',
  };

  Map<String, dynamic> _mapProductionPlannerRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'designNo': r['design_no'] ?? '',
    'type': 'Plan',
    'quantity': r['total_allocated'] ?? 0,
    'representative': '',
    'date': r['created_at'] != null
        ? (r['created_at'] as String).substring(0, 10)
        : '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'allocations': r['allocations'] ?? [],
    'totalAllocated': r['total_allocated'] ?? 0,
    'orderId': r['order_id'],
    'status': 'complete',
  };

  Map<String, dynamic> _mapButtoningRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'designNo': r['design_no'] ?? '',
    'type': r['operation'] ?? '',
    'quantity': r['quantity'] ?? 0,
    'representative': r['representative'] ?? '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'date': r['entry_date'] ?? '',
    'orderId': r['order_id'],
    'status': 'complete',
  };

  Map<String, dynamic> _mapStitchingRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'type': 'Line ${r['line_number'] ?? ''}',
    'quantity': r['production_qty'] ?? 0,
    'representative': r['comments'] ?? '',
    'date': r['entry_date'] ?? '',
    'status': 'complete',
  };

  Map<String, dynamic> _mapWashingRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'designNo': r['design_no'] ?? '',
    'type': r['status'] == 'received' ? 'Received' : 'Sent Out',
    'quantity': r['sent_qty'] ?? 0,
    'representative': r['vendor_name'] ?? '',
    'date': r['sent_date'] ?? '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'orderId': r['order_id'],
    'status': r['status'] == 'received' ? 'complete' : 'inProgress',
  };

  Map<String, dynamic> _mapCuttingRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'color': r['color'] ?? '',
    'designNo': r['design_no'] ?? '',
    'date': r['entry_date'] ?? '',
    'avgConsumption': '${r['avg_consumption'] ?? ''}m',
    'total': r['total'] ?? 0,
    'status': 'complete',
  };

  Map<String, dynamic> _mapLayRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'color': r['color'] ?? '',
    'fabricType': r['fabric_type'] ?? '',
    'layLength': r['lay_length'] ?? 0,
    'noOfPlies': r['no_of_plies'] ?? 0,
    'totalMeters': r['total_meters'] ?? 0,
    'colours': r['colours'] ?? [],
    'date': r['entry_date'] ?? '',
    'remarks': r['remarks'] ?? '',
    'photoUrl': r['photo_url'],
    'orderId': r['order_id'],
    'status': 'complete',
  };

  Map<String, dynamic> _mapIroningRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'type': r['iron_type'] ?? '',
    'quantity': r['quantity'] ?? 0,
    'representative': r['representative'] ?? '',
    'date': r['entry_date'] ?? '',
    'status': 'complete',
  };

  Map<String, dynamic> _mapCheckingRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style_no'] ?? '',
    'type': r['check_type'] ?? '',
    'quantity': r['quantity'] ?? 0,
    'representative': r['representative'] ?? '',
    'date': r['entry_date'] ?? '',
    'status': 'inProgress',
  };

  Map<String, dynamic> _mapFabricStockRow(Map<String, dynamic> r) => {
    'id': r['id'] ?? '',
    'styleNo': r['style'] ?? '',
    'style': r['style'] ?? '',
    'colour': r['colour'] ?? '',
    'design': r['design'] ?? '',
    'totalRolls': r['total_rolls'] ?? 0,
    'totalMtrs': r['total_mtrs'] ?? 0,
    'totalUsed': r['total_used'] ?? 0,
    'balance': r['balance'] ?? 0,
    'swatchPhotoPath': r['swatch_photo_path'],
    'photoUrl': r['photo_url'] ?? r['swatch_photo_path'],
    'rolls': r['rolls'] ?? [],
    'remarks': r['remarks'] ?? '',
    'date': r['entry_date'] ?? '',
    'orderId': r['order_id'],
    'status': 'complete',
  };

  /// Save entry: if online, write directly to Supabase; if offline, queue it.
  Future<void> _saveEntry(String module, Map<String, dynamic> data) async {
    final offlineSvc = OfflineQueueService.instance;

    if (!offlineSvc.isOnline) {
      await offlineSvc.enqueue(
        QueuedWrite(
          id: '${module}_${ISTUtils.now().millisecondsSinceEpoch}',
          operation: _editingEntry != null ? 'update' : 'insert',
          module: module,
          data: data,
          recordId: _editingEntry?['id'] as String?,
          queuedAt: ISTUtils.now(),
        ),
      );
      if (mounted) {
        setState(() {
          _showAddForm = false;
          _editingEntry = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You\'re offline — entry queued and will sync when reconnected.',
            ),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_editingEntry != null) {
        final id = _editingEntry!['id'] as String;
        switch (module) {
          case 'dailyProduction':
            await _supabase.updateDailyProductionEntry(id, data);
            break;
          case 'sizewiseProduction':
            await _supabase.updateSizewiseProductionEntry(id, data);
            break;
          case 'productionPlanner':
            await _supabase.updateProductionPlannerEntry(id, data);
            break;
          default:
            await _supabase.updateEntry(module, id, data);
        }
      } else {
        switch (module) {
          case 'cutting':
            await _supabase.insertCuttingEntry(data);
            break;
          case 'lay':
            await _supabase.insertLayEntry(data);
            break;
          case 'ironing':
            await _supabase.insertIroningEntry(data);
            break;
          case 'checking':
            await _supabase.insertCheckingEntry(data);
            break;
          case 'fabricStock':
            await _supabase.insertFabricStockEntry(data);
            break;
          case 'buttoning':
            await _supabase.insertButtoningEntry(data);
            break;
          case 'stitching':
            await _supabase.insertStitchingEntry(data);
            break;
          case 'washing':
            await _supabase.insertWashingEntryFromForm(data);
            break;
          case 'dailyProduction':
            await _supabase.insertDailyProductionEntry(data);
            break;
          case 'sizewiseProduction':
            await _supabase.insertSizewiseProductionEntry(data);
            break;
          case 'productionPlanner':
            await _supabase.insertProductionPlannerEntry(data);
            break;
        }
      }

      final actor = AuthService.instance.isAdmin ? 'Admin' : 'Staff';
      AppStateService.instance.notifyRegisterWrite(
        register: _selectedModule.label,
        styleNo: data['styleNo'] as String? ?? data['style'] as String? ?? '',
        actor: actor,
        quantity:
            data['quantity'] as int? ??
            data['total'] as int? ??
            data['achievedQty'] as int? ??
            data['productionQty'] as int? ??
            data['totalPieces'] as int? ??
            data['totalAllocated'] as int?,
      );

      if (mounted) {
        setState(() {
          _showAddForm = false;
          _isSaving = false;
          _editingEntry = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingEntry != null
                  ? '${_selectedModule.label} entry updated'
                  : '${_selectedModule.label} entry saved & synced',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadEntries();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveEntry(module, data),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final id = entry['id'] as String?;
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete Entry',
          style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this ${_selectedModule.label} entry? This cannot be undone.',
          style: GoogleFonts.ibmPlexSans(fontSize: 14),
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

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.deleteEntry(_selectedModule.tableKey, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted'),
            backgroundColor: AppTheme.success,
          ),
        );
        await _loadEntries();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _editEntry(Map<String, dynamic> entry) {
    setState(() {
      _editingEntry = entry;
      _showAddForm = true;
    });
  }

  List<String> get _styleOptions {
    final styles = {
      'All',
      ..._entries.map((e) => e['styleNo'] as String? ?? ''),
    };
    return styles.toList();
  }

  List<Map<String, dynamic>> get _filteredEntries {
    if (_selectedStyle == 'All') return _entries;
    return _entries.where((e) => e['styleNo'] == _selectedStyle).toList();
  }

  bool get _isComingSoonModule {
    switch (_selectedModule) {
      case RegisterModule.bundling:
      case RegisterModule.packaging:
        return true;
      default:
        return false;
    }
  }

  // ─── View Entry (item 3) ──────────────────────────────────────────────────
  void _viewEntry(Map<String, dynamic> entry) {
    if (_selectedModule == RegisterModule.fabricStock) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FabricStockViewScreen(entry: entry)),
      );
    }
  }

  // ─── Excel Export ─────────────────────────────────────────────────────────

  Future<void> _exportCurrentRegister() async {
    if (_entries.isEmpty) return;
    final date = ISTUtils.todayString();
    List<String> headers;
    List<List<dynamic>> rows;

    switch (_selectedModule) {
      case RegisterModule.cutting:
        headers = [
          'Date',
          'Style No',
          'Color',
          'Design No',
          'Avg Consumption',
          'Total',
        ];
        rows = _entries
            .map(
              (e) => [
                e['date'] ?? '',
                e['styleNo'] ?? '',
                e['color'] ?? '',
                e['designNo'] ?? '',
                e['avgConsumption'] ?? '',
                e['total'] ?? 0,
              ],
            )
            .toList();
        break;
      case RegisterModule.lay:
        headers = [
          'Date',
          'Style No',
          'Color',
          'Fabric Type',
          'Lay Length',
          'No of Plies',
          'Total Meters',
        ];
        rows = _entries
            .map(
              (e) => [
                e['date'] ?? '',
                e['styleNo'] ?? '',
                e['color'] ?? '',
                e['fabricType'] ?? '',
                e['layLength'] ?? 0,
                e['noOfPlies'] ?? 0,
                e['totalMeters'] ?? 0,
              ],
            )
            .toList();
        break;
      case RegisterModule.fabricStock:
        headers = [
          'Date',
          'Style',
          'Colour',
          'Design',
          'Total Rolls',
          'Total Mtrs',
          'Balance',
        ];
        rows = _entries
            .map(
              (e) => [
                e['date'] ?? '',
                e['styleNo'] ?? '',
                e['colour'] ?? '',
                e['design'] ?? '',
                e['totalRolls'] ?? 0,
                e['totalMtrs'] ?? 0,
                e['balance'] ?? 0,
              ],
            )
            .toList();
        break;
      case RegisterModule.ironing:
      case RegisterModule.checkingAndFinishing:
      case RegisterModule.buttoningAndButtonHoling:
      case RegisterModule.stitching:
        headers = ['Date', 'Style No', 'Type', 'Quantity', 'Representative'];
        rows = _entries
            .map(
              (e) => [
                e['date'] ?? '',
                e['styleNo'] ?? '',
                e['type'] ?? '',
                e['quantity'] ?? 0,
                e['representative'] ?? '',
              ],
            )
            .toList();
        break;
      case RegisterModule.washing:
        headers = ['Date', 'Style No', 'Type', 'Quantity', 'Vendor'];
        rows = _entries
            .map(
              (e) => [
                e['date'] ?? '',
                e['styleNo'] ?? '',
                e['type'] ?? '',
                e['quantity'] ?? 0,
                e['representative'] ?? '',
              ],
            )
            .toList();
        break;
      default:
        return;
    }

    await ExcelExportService.exportRegisterToExcel(
      registerName: _selectedModule.label,
      headers: headers,
      rows: rows,
      dateStr: date,
    );
  }

  // ─── Module Selector Dropdown ─────────────────────────────────────────────

  void _showModuleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Register',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: RegisterModule.values.map((module) {
                  final isSelected = module == _selectedModule;
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        module.icon,
                        size: 18,
                        color: isSelected ? Colors.white : AppTheme.mutedText,
                      ),
                    ),
                    title: Text(
                      module.label,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.onSurfaceLight,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (module == RegisterModule.subcontractor) {
                        setState(() => _selectedModule = module);
                        return;
                      }
                      if (_selectedModule == module) return;
                      setState(() {
                        _selectedModule = module;
                        _selectedStyle = 'All';
                        _showAddForm = false;
                        _editingEntry = null;
                        _entries = [];
                      });
                      _loadEntries();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Subcontractor module renders its own full screen
    if (_selectedModule == RegisterModule.subcontractor) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              const OfflineBannerWidget(),
              // Header with module selector
              ColoredBox(
                color: AppTheme.surfaceLight,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showModuleSelector(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _selectedModule.icon,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedModule.label,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.mutedText,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: SubcontractorRegisterScreen()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBannerWidget(),
            ColoredBox(
              color: AppTheme.surfaceLight,
              child: Row(
                children: [
                  // Module selector button (hamburger style)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showModuleSelector(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedModule.icon,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedModule.label,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurfaceLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.mutedText,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Download Excel button
                  if (!_isComingSoonModule && _entries.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppTheme.success,
                        size: 22,
                      ),
                      tooltip: 'Download Excel',
                      onPressed: _exportCurrentRegister,
                    ),
                  // Add Entry button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAddForm = !_showAddForm;
                        if (!_showAddForm) _editingEntry = null;
                      });
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                        key: ValueKey(_showAddForm),
                        size: 18,
                        color: _showAddForm ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                    label: Text(
                      _showAddForm ? 'Cancel' : 'Add Entry',
                      style: GoogleFonts.ibmPlexSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _showAddForm ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.onSurfaceLight,
                    ),
                    onPressed: _loadEntries,
                  ),
                ],
              ),
            ),
            const SyncStatusWidget(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: RegisterFilterWidget(
                options: _styleOptions,
                selected: _selectedStyle,
                onSelected: (val) => setState(() => _selectedStyle = val),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _showAddForm
                  ? Stack(
                      children: [
                        _buildAddForm(),
                        if (_isSaving)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Saving to Supabase…',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: AppTheme.mutedText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _loadEntries,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEntries,
                      child: _filteredEntries.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text(
                                      _isComingSoonModule
                                          ? '${_selectedModule.label} module coming soon'
                                          : 'No entries for ${_selectedModule.label}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: AppTheme.mutedText),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                100,
                              ),
                              itemCount: _filteredEntries.length,
                              itemBuilder: (context, i) {
                                final entry = _filteredEntries[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: RegisterListItemWidget(
                                    key: ValueKey(entry['id']),
                                    entry: entry,
                                    module: _selectedModule,
                                    onDelete: () => _deleteEntry(entry),
                                    onEdit: () => _editEntry(entry),
                                    onView:
                                        _selectedModule ==
                                            RegisterModule.fabricStock
                                        ? () => _viewEntry(entry)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildAddForm() {
    switch (_selectedModule) {
      case RegisterModule.cutting:
        return RegisterCuttingFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('cutting', data),
        );
      case RegisterModule.lay:
        return RegisterLayFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('lay', data),
        );
      case RegisterModule.ironing:
        return RegisterIroningFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('ironing', data),
        );
      case RegisterModule.checkingAndFinishing:
        return RegisterCheckingFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('checking', data),
        );
      case RegisterModule.fabricStock:
        return RegisterFabricStockFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('fabricStock', data),
        );
      case RegisterModule.buttoningAndButtonHoling:
        return RegisterButtoningFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('buttoning', data),
        );
      case RegisterModule.stitching:
        return RegisterStitchingFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('stitching', data),
        );
      case RegisterModule.washing:
        return RegisterWashingFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('washing', data),
        );
      case RegisterModule.dailyProduction:
        return RegisterDailyProductionFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('dailyProduction', data),
        );
      case RegisterModule.sizewiseProduction:
        return RegisterSizewiseProductionFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('sizewiseProduction', data),
        );
      case RegisterModule.productionPlanner:
        return RegisterProductionPlannerFormWidget(
          initialData: _editingEntry,
          onSave: (data) => _saveEntry('productionPlanner', data),
        );
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_selectedModule.icon, size: 48, color: AppTheme.mutedText),
                const SizedBox(height: 16),
                Text(
                  '${_selectedModule.label} module coming soon',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
}
