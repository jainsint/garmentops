import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/offline_queue_service.dart';

/// Banner shown at top of screens when offline or when there are pending syncs.
class OfflineBannerWidget extends StatefulWidget {
  const OfflineBannerWidget({super.key});

  @override
  State<OfflineBannerWidget> createState() => _OfflineBannerWidgetState();
}

class _OfflineBannerWidgetState extends State<OfflineBannerWidget> {
  @override
  void initState() {
    super.initState();
    OfflineQueueService.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    OfflineQueueService.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc = OfflineQueueService.instance;
    final isOnline = svc.isOnline;
    final pending = svc.pendingCount;
    final isSyncing = svc.isSyncing;

    if (isOnline && pending == 0) return const SizedBox.shrink();

    final Color bg;
    final Color fg;
    final IconData icon;
    final String message;

    if (!isOnline) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
      icon = Icons.wifi_off_rounded;
      message = pending > 0
          ? "You're offline — $pending ${pending == 1 ? 'entry' : 'entries'} pending sync"
          : "You're offline — reconnect to log entries";
    } else if (isSyncing) {
      bg = AppTheme.primaryContainer;
      fg = AppTheme.primary;
      icon = Icons.sync_rounded;
      message =
          'Syncing $pending pending ${pending == 1 ? 'entry' : 'entries'}…';
    } else {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
      icon = Icons.pending_outlined;
      message = '$pending ${pending == 1 ? 'entry' : 'entries'} pending sync';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bg,
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
          if (isOnline && pending > 0 && !isSyncing)
            GestureDetector(
              onTap: () => OfflineQueueService.instance.syncQueue(),
              child: Text(
                'Sync now',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
