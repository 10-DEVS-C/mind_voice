import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                l10n.translate('settings'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSectionTitle(context, l10n.translate('theme')),
                const SizedBox(height: 8),
                _buildThemeSelector(context, l10n, settingsProvider),
                const SizedBox(height: 24),
                _buildSectionTitle(context, l10n.translate('language')),
                const SizedBox(height: 8),
                _buildLanguageSelector(context, l10n, settingsProvider),
              ],
            ),
          ),
          const Divider(color: AppColors.textSecondaryDark),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              l10n.translate('logout'),
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // Close drawer
              Navigator.pop(context);
              // Logout
              Provider.of<AuthProvider>(context, listen: false).logout();
              // Navigate to Login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    AppLocalizations l10n,
    SettingsProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRadioTile<ThemeMode>(
            title: l10n.translate('system'),
            value: ThemeMode.system,
            groupValue: provider.themeMode,
            onChanged: provider.updateThemeMode,
          ),
          _buildRadioTile<ThemeMode>(
            title: l10n.translate('light'),
            value: ThemeMode.light,
            groupValue: provider.themeMode,
            onChanged: provider.updateThemeMode,
          ),
          _buildRadioTile<ThemeMode>(
            title: l10n.translate('dark'),
            value: ThemeMode.dark,
            groupValue: provider.themeMode,
            onChanged: provider.updateThemeMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    AppLocalizations l10n,
    SettingsProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRadioTile<Locale>(
            title: 'English',
            value: const Locale('en'),
            groupValue: provider.locale,
            onChanged: provider.updateLocale,
          ),
          _buildRadioTile<Locale>(
            title: 'Español',
            value: const Locale('es'),
            groupValue: provider.locale,
            onChanged: provider.updateLocale,
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
