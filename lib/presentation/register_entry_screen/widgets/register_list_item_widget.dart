import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../register_entry_screen.dart';

class RegisterListItemWidget extends StatelessWidget {
  final Map<String, dynamic> entry;
  final RegisterModule module;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onView;

  const RegisterListItemWidget({
    required this.entry,
    required this.module,
    this.onDelete,
    this.onEdit,
    this.onView,
    super.key,
  });

  StatusType _statusFromString(String s) {
    switch (s) {
      case 'complete':
        return StatusType.complete;
      case 'inProgress':
        return StatusType.inProgress;
      case 'pending':
        return StatusType.pending;
      default:
        return StatusType.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppTheme.primary.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon left
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(module.icon, size: 22, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(child: _buildContent()),
              // Trailing
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadgeWidget(
                    status: _statusFromString(
                      entry['status'] as String? ?? 'pending',
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ActionMenu(
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onView: onView,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (module) {
      case RegisterModule.cutting:
        return _CuttingContent(entry: entry);
      case RegisterModule.ironing:
        return _IroningContent(entry: entry);
      case RegisterModule.checkingAndFinishing:
        return _CheckingContent(entry: entry);
      case RegisterModule.fabricStock:
        return _FabricStockContent(entry: entry);
      case RegisterModule.lay:
        return _LayContent(entry: entry);
      default:
        return _GenericContent(entry: entry);
    }
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const _ActionMenu({this.onEdit, this.onDelete, this.onView});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      iconSize: 18,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: AppTheme.mutedText,
        size: 18,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => [
        if (onView != null)
          PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                const Icon(
                  Icons.visibility_rounded,
                  size: 16,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                Text('View', style: GoogleFonts.ibmPlexSans(fontSize: 13)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text('Edit', style: GoogleFonts.ibmPlexSans(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_rounded, size: 16, color: AppTheme.error),
              const SizedBox(width: 8),
              Text(
                'Delete',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'view') onView?.call();
        if (val == 'edit') onEdit?.call();
        if (val == 'delete') onDelete?.call();
      },
    );
  }
}

class _CuttingContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _CuttingContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              entry['styleNo'] as String? ?? '—',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '• ${entry['designNo'] ?? '—'}',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          entry['color'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: 'Total: ${entry['total']} pcs',
              color: AppTheme.primary,
            ),
            _MetaChip(
              label: entry['avgConsumption'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
            _MetaChip(
              label: entry['date'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ],
    );
  }
}

class _LayContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _LayContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry['styleNo'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry['fabricType'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: '${entry['noOfPlies']} plies',
              color: AppTheme.primary,
            ),
            _MetaChip(
              label: '${entry['totalMeters']}m',
              color: AppTheme.mutedText,
            ),
            _MetaChip(
              label: entry['date'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ],
    );
  }
}

class _FabricStockContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _FabricStockContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry['styleNo'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry['colour'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: '${entry['totalRolls']} rolls',
              color: AppTheme.primary,
            ),
            _MetaChip(
              label: '${entry['totalMtrs']}m',
              color: AppTheme.mutedText,
            ),
            _MetaChip(
              label: 'Bal: ${entry['balance']}m',
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ],
    );
  }
}

class _IroningContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _IroningContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry['styleNo'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry['type'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: '${entry['quantity']} pcs',
              color: AppTheme.primary,
            ),
            _MetaChip(
              label: entry['representative'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
            _MetaChip(
              label: entry['date'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckingContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _CheckingContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry['styleNo'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry['type'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _MetaChip(
              label: '${entry['quantity']} pcs',
              color: AppTheme.primary,
            ),
            _MetaChip(
              label: entry['representative'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
            _MetaChip(
              label: entry['date'] as String? ?? '—',
              color: AppTheme.mutedText,
            ),
          ],
        ),
      ],
    );
  }
}

class _GenericContent extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _GenericContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry['styleNo'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry['color'] as String? ?? '—',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12,
            color: AppTheme.onSurfaceLight,
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color == AppTheme.mutedText ? AppTheme.mutedText : color,
        ),
      ),
    );
  }
}
