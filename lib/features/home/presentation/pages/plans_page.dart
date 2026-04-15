import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/main_background.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final plan = Provider.of<AuthProvider>(context).user?.plan.toLowerCase();

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                title: Text(
                  l10n.translate('availablePlansTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                sliver: SliverList.list(
                  children: [
                    Text(
                      l10n.translate('availablePlansSubtitle'),
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PlanCard(
                      name: l10n.translate('planFreeName'),
                      description: l10n.translate('planFreeDesc'),
                      price: '\$0',
                      ctaText: l10n.translate('planCurrentBtn'),
                      isCurrent: plan != 'premium',
                      isFeatured: false,
                      features: [
                        l10n.translate('planFeatFree1'),
                        l10n.translate('planFeatFree2'),
                        l10n.translate('planFeatFree3'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PlanCard(
                      name: l10n.translate('planProName'),
                      description: l10n.translate('planProDesc'),
                      price: '\$12',
                      ctaText: plan == 'premium'
                          ? l10n.translate('planCurrentBtn')
                          : l10n.translate('planUpgradeBtn'),
                      isCurrent: plan == 'premium',
                      isFeatured: true,
                      features: [
                        l10n.translate('planFeatPro1'),
                        l10n.translate('planFeatPro2'),
                        l10n.translate('planFeatPro3'),
                        l10n.translate('planFeatPro4'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PlanCard(
                      name: l10n.translate('planBusinessName'),
                      description: l10n.translate('planBusinessDesc'),
                      price: '\$39',
                      ctaText: l10n.translate('planContactBtn'),
                      isCurrent: false,
                      isFeatured: false,
                      features: [
                        l10n.translate('planFeatBiz1'),
                        l10n.translate('planFeatBiz2'),
                        l10n.translate('planFeatBiz3'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String description;
  final String price;
  final String ctaText;
  final bool isCurrent;
  final bool isFeatured;
  final List<String> features;

  const _PlanCard({
    required this.name,
    required this.description,
    required this.price,
    required this.ctaText,
    required this.isCurrent,
    required this.isFeatured,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.darkSurface.withOpacity(0.92)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isFeatured
              ? AppColors.primary.withOpacity(0.5)
              : (isDarkMode ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured
                ? AppColors.primary.withOpacity(0.18)
                : Colors.black.withOpacity(isDarkMode ? 0.22 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFeatured)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.translate('planPopularBadge'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.translate('planPerMonth'),
                style: TextStyle(
                  color: isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrent ? Colors.grey.shade500 : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isCurrent
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.translate('planSoonMessage'))),
                      );
                    },
              child: Text(ctaText),
            ),
          ),
        ],
      ),
    );
  }
}
