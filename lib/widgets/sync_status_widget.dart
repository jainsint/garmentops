import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget>
    with SingleTickerProviderStateMixin {
  final SyncService _syncService = SyncService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _syncService.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
    if (_syncService.status == SyncStatus.syncing) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _syncService.status;
    final pending = _syncService.pendingCount;
    final lastSync = _syncService.lastSyncTime;

    // Don't show banner when idle and nothing pending
    if (status == SyncStatus.idle && pending == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor(status),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor(status), width: 1),
      ),
      child: Row(
        children: [
          _buildIcon(status),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title(status, pending),
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textColor(status),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (lastSync != null && status != SyncStatus.syncing)
                  Text(
                    'Last sync: ${_formatTime(lastSync)}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: _textColor(status).withAlpha(179),
                    ),
                  ),
              ],
            ),
          ),
          if (status != SyncStatus.syncing)
            GestureDetector(
              onTap: () => _syncService.syncNow(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _textColor(status).withAlpha(26),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sync Now',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textColor(status),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(SyncStatus status) {
    if (status == SyncStatus.syncing) {
      return FadeTransition(
        opacity: _pulseController,
        child: Icon(Icons.sync_rounded, size: 18, color: _textColor(status)),
      );
    }
    return Icon(_iconData(status), size: 18, color: _textColor(status));
  }

  String _title(SyncStatus status, int pending) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing to Google Sheets…';
      case SyncStatus.success:
        return _syncService.statusMessage.isNotEmpty
            ? _syncService.statusMessage
            : 'Synced successfully';
      case SyncStatus.failed:
        return _syncService.statusMessage.isNotEmpty
            ? _syncService.statusMessage
            : 'Sync failed — tap to retry';
      case SyncStatus.noNetwork:
        return 'Offline — $pending ${pending == 1 ? 'entry' : 'entries'} queued';
      case SyncStatus.idle:
        return pending > 0
            ? '$pending ${pending == 1 ? 'entry' : 'entries'} pending sync'
            : 'Ready to sync';
    }
  }

  IconData _iconData(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Icons.cloud_done_rounded;
      case SyncStatus.failed:
        return Icons.cloud_off_rounded;
      case SyncStatus.noNetwork:
        return Icons.wifi_off_rounded;
      default:
        return Icons.cloud_upload_outlined;
    }
  }

  Color _bgColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppTheme.primaryContainer;
      case SyncStatus.success:
        return AppTheme.successContainer;
      case SyncStatus.failed:
        return AppTheme.errorContainer;
      case SyncStatus.noNetwork:
        return AppTheme.warningContainer;
      case SyncStatus.idle:
        return AppTheme.surfaceVariantLight;
    }
  }

  Color _borderColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppTheme.primary.withAlpha(77);
      case SyncStatus.success:
        return AppTheme.success.withAlpha(77);
      case SyncStatus.failed:
        return AppTheme.error.withAlpha(77);
      case SyncStatus.noNetwork:
        return AppTheme.warning.withAlpha(77);
      case SyncStatus.idle:
        return AppTheme.outlineVariantLight;
    }
  }

  Color _textColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppTheme.primary;
      case SyncStatus.success:
        return AppTheme.success;
      case SyncStatus.failed:
        return AppTheme.error;
      case SyncStatus.noNetwork:
        return AppTheme.warning;
      case SyncStatus.idle:
        return AppTheme.mutedText;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
