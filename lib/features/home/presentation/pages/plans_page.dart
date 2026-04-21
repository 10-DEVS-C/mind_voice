import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/main_background.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  String? _changingPlanKey;

  Future<void> _handleChangePlan(String planKey) async {
    setState(() => _changingPlanKey = planKey);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePlan(planKey);

    if (!mounted) return;
    setState(() => _changingPlanKey = null);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan actualizado correctamente')),
      );
    } else if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error!)),
      );
    }
  }

  Future<void> _initiatePayment(
    String planKey,
    String planName,
    String price,
  ) async {
    // Plan gratis: no requiere pago
    if (planKey == 'basic') {
      await _handleChangePlan(planKey);
      return;
    }
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(planName: planName, price: price),
    );
    if (paid == true && mounted) {
      await _handleChangePlan(planKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final plan = context.watch<AuthProvider>().user?.plan.toLowerCase() ?? 'basic';

    final isBasic = plan == 'basic';
    final isProfessional = plan == 'professional' || plan == 'premium' || plan == 'pro';
    final isBusiness = plan == 'business';

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
                      price: r'$0',
                      ctaText: isBasic
                          ? l10n.translate('planCurrentBtn')
                          : l10n.translate('planUpgradeBtn'),
                      isCurrent: isBasic,
                      isFeatured: false,
                      isLoading: _changingPlanKey == 'basic',
                      onTap: isBasic
                          ? null
                          : () => _initiatePayment(
                                'basic',
                                l10n.translate('planFreeName'),
                                r'$0',
                              ),
                      features: [
                        l10n.translate('planFeatFree1'),
                        l10n.translate('planFeatFree2'),
                        l10n.translate('planFeatFree3'),
                        l10n.translate('planFeatFree4'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PlanCard(
                      name: l10n.translate('planProName'),
                      description: l10n.translate('planProDesc'),
                      price: r'$12',
                      ctaText: isProfessional
                          ? l10n.translate('planCurrentBtn')
                          : l10n.translate('planUpgradeBtn'),
                      isCurrent: isProfessional,
                      isFeatured: true,
                      isLoading: _changingPlanKey == 'professional',
                      onTap: isProfessional
                          ? null
                          : () => _initiatePayment(
                                'professional',
                                l10n.translate('planProName'),
                                r'$12',
                              ),
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
                      price: r'$39',
                      ctaText: isBusiness
                          ? l10n.translate('planCurrentBtn')
                          : l10n.translate('planContactBtn'),
                      isCurrent: isBusiness,
                      isFeatured: false,
                      isLoading: _changingPlanKey == 'business',
                      onTap: isBusiness
                          ? null
                          : () => _initiatePayment(
                                'business',
                                l10n.translate('planBusinessName'),
                                r'$39',
                              ),
                      features: [
                        l10n.translate('planFeatBiz1'),
                        l10n.translate('planFeatBiz2'),
                        l10n.translate('planFeatBiz3'),
                        l10n.translate('planFeatBiz4'),
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
  final bool isLoading;
  final List<String> features;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.name,
    required this.description,
    required this.price,
    required this.ctaText,
    required this.isCurrent,
    required this.isFeatured,
    required this.isLoading,
    required this.features,
    this.onTap,
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
              onPressed: (isCurrent || isLoading) ? null : onTap,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(ctaText),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Sheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final String planName;
  final String price;

  const _PaymentSheet({required this.planName, required this.price});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _processing = false;
  bool _success = false;

  @override
  void dispose() {
    _cardCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _applyCardFormat(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String _applyExpiryFormat(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 3) {
      return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    }
    return digits;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);
    // Simulate payment gateway delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _success = true;
    });
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: _success ? _buildSuccess(l10n) : _buildForm(l10n, isDark),
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.check_circle_rounded,
            color: AppColors.primary, size: 72),
        const SizedBox(height: 16),
        Text(
          l10n.translate('paySuccess'),
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.translate('paySuccessMsg'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Text(
            l10n.translate('payTitle'),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate('paySubtitle'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Plan summary
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.translate('payPlanLabel')}: ${widget.planName}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${l10n.translate('payTotalLabel')}: ${widget.price}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Card number
          _buildField(
            controller: _cardCtrl,
            label: l10n.translate('payCardNumber'),
            hint: '1234 5678 9012 3456',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            maxLength: 19,
            onChanged: (v) {
              final formatted = _applyCardFormat(v);
              if (formatted != v) {
                _cardCtrl.value = TextEditingValue(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
              }
            },
            validator: (v) {
              final digits =
                  (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length != 16) {
                return l10n.translate('payErrCard');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Cardholder name
          _buildField(
            controller: _holderCtrl,
            label: l10n.translate('payCardHolder'),
            hint: 'John Doe',
            icon: Icons.person_rounded,
            keyboardType: TextInputType.name,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) {
                return l10n.translate('payErrHolder');
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Expiry + CVV row
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _expiryCtrl,
                  label: l10n.translate('payExpiry'),
                  hint: '12/26',
                  icon: Icons.date_range_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onChanged: (v) {
                    final formatted = _applyExpiryFormat(v);
                    if (formatted != v) {
                      _expiryCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                            offset: formatted.length),
                      );
                    }
                  },
                  validator: (v) {
                    final parts = (v ?? '').split('/');
                    if (parts.length != 2 ||
                        parts[0].length != 2 ||
                        parts[1].length != 2) {
                      return l10n.translate('payErrExpiry');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _cvvCtrl,
                  label: l10n.translate('payCvv'),
                  hint: '123',
                  icon: Icons.lock_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  validator: (v) {
                    if ((v ?? '').length != 3) {
                      return l10n.translate('payErrCvv');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _processing ? null : _submit,
              child: _processing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.translate('payProcessing')),
                      ],
                    )
                  : Text(l10n.translate('payBtn'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
