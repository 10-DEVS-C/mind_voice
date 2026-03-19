import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../home/presentation/pages/home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _requiredValidator(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.translate('requiredField');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('signupTitle'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _usernameController,
                  label: l10n.translate('usernameLabel'),
                  icon: AppIcons.signup,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) => _requiredValidator(value, l10n),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: l10n.translate('nameLabel'),
                  icon: AppIcons.signup,
                  keyboardType: TextInputType.name,
                  validator: (value) => _requiredValidator(value, l10n),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: l10n.translate('emailLabel'),
                  icon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: l10n.translate('confirmPasswordLabel'),
                  icon: AppIcons.password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) {
                    final requiredMessage = _requiredValidator(value, l10n);
                    if (requiredMessage != null) {
                      return requiredMessage;
                    }
                    if (value != _passwordController.text) {
                      return l10n.translate('passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: l10n.translate('signupButton'),
                  isLoading: authProvider.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }
                    final success = await authProvider.register(
                      _usernameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text,
                      _nameController.text.trim(),
                    );
                    if (success && context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(l10n.translate('hasAccount')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
