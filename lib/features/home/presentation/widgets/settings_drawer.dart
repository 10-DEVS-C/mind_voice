import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../audio_recorder/presentation/providers/audio_recorder_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../pages/plans_page.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  void _openPlansPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlansPage()),
    );
  }

  Future<void> _showEditProfileSheet(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final user = authProvider.user;

    final nameController = TextEditingController(text: user?.name ?? '');
    final usernameController = TextEditingController(
      text: user?.username ?? '',
    );
    final emailController = TextEditingController(text: user?.email ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        final bottomInset = media.viewInsets.bottom;
        final safeBottom = media.viewPadding.bottom;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            (bottomInset > 0 ? bottomInset : safeBottom) + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.translate('editProfile'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('nameLabel'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.translate('username'),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.translate('email'),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await authProvider.updateProfile(
                      username: usernameController.text.trim(),
                      email: emailController.text.trim(),
                      name: nameController.text.trim(),
                    );
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? l10n.translate('saveProfile')
                              : (authProvider.error ?? 'Error'),
                        ),
                      ),
                    );
                  },
                  child: Text(l10n.translate('saveProfile')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.95)
                  : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.18),
                      child: Text(
                        (user?.name.isNotEmpty == true
                                ? user!.name
                                : (user?.username.isNotEmpty == true
                                    ? user!.username
                                    : 'M'))
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.username.isNotEmpty == true
                                ? user!.username
                                : l10n.translate('profile'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openPlansPage(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user?.plan == 'premium'
                                        ? l10n.translate('premiumPlan')
                                        : l10n.translate('basicPlan'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_right_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditProfileSheet(context),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.translate('editProfile'),
                    ),
                  ],
                ),
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
                const SizedBox(height: 24),
                _buildSectionTitle(context, l10n.translate('profile')),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.translate('nameLabel')}: ${user?.name ?? ''}'),
                      const SizedBox(height: 4),
                      Text('${l10n.translate('username')}: ${user?.username ?? ''}'),
                      const SizedBox(height: 4),
                      Text('${l10n.translate('email')}: ${user?.email ?? ''}'),
                      const SizedBox(height: 8),
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.workspace_premium_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        title: Text(l10n.translate('planDetails')),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _openPlansPage(context),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showEditProfileSheet(context),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(l10n.translate('editProfile')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    // Clear user data
                    Provider.of<AudioRecorderProvider>(
                      context,
                      listen: false,
                    ).clear();
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
                const SizedBox(height: 6),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
        ),
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
