import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum StatusType { complete, inProgress, pending, warning, error }

class StatusBadgeWidget extends StatelessWidget {
  final StatusType status;
  final String? customLabel;

  const StatusBadgeWidget({required this.status, this.customLabel, super.key});

  String get _label {
    if (customLabel != null) return customLabel!;
    switch (status) {
      case StatusType.complete:
        return 'Complete';
      case StatusType.inProgress:
        return 'In Progress';
      case StatusType.pending:
        return 'Pending';
      case StatusType.warning:
        return 'Warning';
      case StatusType.error:
        return 'Error';
    }
  }

  Color get _bg {
    switch (status) {
      case StatusType.complete:
        return AppTheme.successContainer;
      case StatusType.inProgress:
        return AppTheme.secondaryContainer;
      case StatusType.pending:
        return const Color(0xFFEEEEEE);
      case StatusType.warning:
        return AppTheme.warningContainer;
      case StatusType.error:
        return AppTheme.errorContainer;
    }
  }

  Color get _fg {
    switch (status) {
      case StatusType.complete:
        return AppTheme.success;
      case StatusType.inProgress:
        return AppTheme.warning;
      case StatusType.pending:
        return AppTheme.mutedText;
      case StatusType.warning:
        return AppTheme.warning;
      case StatusType.error:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
