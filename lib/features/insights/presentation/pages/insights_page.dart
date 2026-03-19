import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('aiResults'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Respuestas y estructura accionable a partir de tus audios',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('lastSummary'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.translate('insightSummaryBody'),
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  context,
                  Icons.biotech,
                  l10n.translate('mindMap'),
                  l10n.translate('nodesCount'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _infoCard(
                  context,
                  Icons.share,
                  l10n.translate('share'),
                  l10n.translate('shareFormats'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.translate('nextSteps'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _stepItem(l10n.translate('nextStepOne')),
          _stepItem(l10n.translate('nextStepTwo')),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkSurface.withOpacity(0.92)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.16 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF6D28D9)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
