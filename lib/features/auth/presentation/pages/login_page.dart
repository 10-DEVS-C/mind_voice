import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart'; // We will create this
import '../../../../shared/widgets/custom_text_field.dart'; // We will create this
import '../providers/auth_provider.dart';
import 'signup_page.dart';
import '../../../home/presentation/pages/home_page.dart'; // For HomePage navigation

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _requiredValidator(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.translate('requiredField');
    }
    return null;
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = await authProvider.checkAuthStatus();

    if (isAuthenticated && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  isDarkMode ? AppAssets.logo1 : AppAssets.logo2,
                  height: 140,
                  width: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    AppIcons.login,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'MindVoice',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.translate('loginTitle'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _usernameController,
                  label: l10n.translate('usernameLabel'),
                  icon: AppIcons.username,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) => _requiredValidator(value, l10n),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: l10n.translate('passwordLabel'),
                  icon: AppIcons.password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) => _requiredValidator(value, l10n),
                ),
                const SizedBox(height: 24),
                if (authProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      authProvider.error!,
                      style: TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                CustomButton(
                  text: l10n.translate('loginButton'),
                  isLoading: authProvider.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final success = await authProvider.login(
                      _usernameController.text.trim(),
                      _passwordController.text,
                    );
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: Text(l10n.translate('noAccount')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
