import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class FabricStockViewScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const FabricStockViewScreen({required this.entry, super.key});

  @override
  Widget build(BuildContext context) {
    final rolls = entry['rolls'];
    final rollList = rolls is List
        ? List<Map<String, dynamic>>.from(
            rolls.map((r) => r as Map<String, dynamic>),
          )
        : <Map<String, dynamic>>[];
    final photoUrl =
        entry['swatchPhotoPath'] as String? ?? entry['photoUrl'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.onSurfaceLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fabric Stock Entry',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00695C).withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF00695C),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['styleNo'] as String? ??
                              entry['style'] as String? ??
                              '—',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurfaceLight,
                          ),
                        ),
                        Text(
                          entry['date'] as String? ?? '—',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            color: AppTheme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Photo
            if (photoUrl != null && photoUrl.isNotEmpty) ...[
              _SectionHeader(title: 'Swatch Photo'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Fabric swatch photo for ${entry['styleNo'] ?? ''}',
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: AppTheme.surfaceVariantLight,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppTheme.mutedText,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Details
            _SectionHeader(title: 'Details'),
            const SizedBox(height: 8),
            _DetailCard(
              children: [
                _DetailRow(
                  label: 'Style',
                  value:
                      entry['styleNo'] as String? ??
                      entry['style'] as String? ??
                      '—',
                ),
                _DetailRow(
                  label: 'Design',
                  value: entry['design'] as String? ?? '—',
                ),
                _DetailRow(
                  label: 'Colour',
                  value: entry['colour'] as String? ?? '—',
                ),
                _DetailRow(
                  label: 'Date',
                  value: entry['date'] as String? ?? '—',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary
            _SectionHeader(title: 'Summary'),
            const SizedBox(height: 8),
            _DetailCard(
              children: [
                _DetailRow(
                  label: 'Total Rolls',
                  value: '${entry['totalRolls'] ?? 0}',
                ),
                _DetailRow(
                  label: 'Total Metres',
                  value: '${entry['totalMtrs'] ?? 0} m',
                ),
                _DetailRow(
                  label: 'Total Used',
                  value: '${entry['totalUsed'] ?? 0} m',
                ),
                _DetailRow(
                  label: 'Balance',
                  value: '${entry['balance'] ?? 0} m',
                  valueColor: ((entry['balance'] as num?) ?? 0) < 0
                      ? AppTheme.error
                      : const Color(0xFF00695C),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Roll breakdown
            if (rollList.isNotEmpty) ...[
              _SectionHeader(title: 'Roll Breakdown'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariantLight),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantLight,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Roll No.',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurfaceLight,
                              ),
                            ),
                          ),
                          Text(
                            'Metres',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...rollList.asMap().entries.map((e) {
                      final isLast = e.key == rollList.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Roll ${e.value['rollNo'] ?? e.key + 1}',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 13,
                                      color: AppTheme.onSurfaceLight,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${e.value['mtrs'] ?? 0} m',
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: AppTheme.outlineVariantLight,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Remarks
            if ((entry['remarks'] as String? ?? '').isNotEmpty) ...[
              _SectionHeader(title: 'Remarks'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariantLight),
                ),
                child: Text(
                  entry['remarks'] as String? ?? '',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    color: AppTheme.onSurfaceLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.ibmPlexSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.mutedText,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariantLight),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppTheme.outlineVariantLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                color: AppTheme.mutedText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppTheme.onSurfaceLight,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
