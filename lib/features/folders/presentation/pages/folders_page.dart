import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../config/service_locator.dart';
import '../../../../core/errors/request_error_mapper.dart';
import '../../../../core/services/shared_prefs_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  static const String _baseUrl = 'http://18.223.30.63:5000';

  final TextEditingController _folderController = TextEditingController();
  final List<_FolderItem> _folders = <_FolderItem>[];

  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;

  SharedPrefsService get _prefs => sl<SharedPrefsService>();
  http.Client get _http => sl<http.Client>();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  Future<void> _redirectToLogin() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<bool> _handleHttpStatus(
    int statusCode,
    String operationMessage,
  ) async {
    if (RequestErrorMapper.isSessionInvalidStatus(statusCode)) {
      await _redirectToLogin();
      return true;
    }

    if (!mounted) {
      return true;
    }

    setState(() {
      _error = RequestErrorMapper.fromHttpStatus(statusCode, operationMessage);
    });
    return false;
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = _prefs.getToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Sesion expirada. Inicia sesion de nuevo.';
      });
      return;
    }

    try {
      final response = await _http.get(
        Uri.parse('$_baseUrl/folders/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        final keepOnPage = await _handleHttpStatus(
          response.statusCode,
          'No se pudieron cargar las carpetas.',
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        if (!keepOnPage) {
          _showSnack(_error!);
        }
        return;
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(_FolderItem.fromJson)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _folders
          ..clear()
          ..addAll(parsed);
        _isLoading = false;
      });
    } on SocketException {
      setState(() {
        _isLoading = false;
        _error = RequestErrorMapper.networkRetryMessage;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'No se pudieron cargar las carpetas. Intenta de nuevo.';
      });
    }
  }

  Future<void> _createFolder() async {
    final name = _folderController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final token = _prefs.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('Sesion expirada. Inicia sesion de nuevo.');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/folders/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'parentFolderId': null,
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final keepOnPage = await _handleHttpStatus(
          response.statusCode,
          'No se pudo crear la carpeta.',
        );
        if (!keepOnPage) {
          _showSnack(_error!);
        }
        setState(() {
          _isCreating = false;
        });
        return;
      }

      final Map<String, dynamic> created =
          jsonDecode(response.body) as Map<String, dynamic>;
      final newFolder = _FolderItem.fromJson(created);

      setState(() {
        _folders.removeWhere((f) => f.id == newFolder.id);
        _folders.add(newFolder);
        _folders.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isCreating = false;
      });
      _folderController.clear();
      _showSnack('Carpeta creada correctamente.');
    } on SocketException {
      setState(() {
        _isCreating = false;
      });
      _showSnack(RequestErrorMapper.networkRetryMessage);
    } catch (_) {
      setState(() {
        _isCreating = false;
      });
      _showSnack('No se pudo crear la carpeta. Intenta de nuevo.');
    }
  }

  Future<void> _deleteFolder(_FolderItem folder) async {
    final token = _prefs.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('Sesion expirada. Inicia sesion de nuevo.');
      return;
    }

    try {
      final response = await _http.delete(
        Uri.parse('$_baseUrl/folders/${folder.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final keepOnPage = await _handleHttpStatus(
          response.statusCode,
          'No se pudo eliminar la carpeta.',
        );
        if (!keepOnPage) {
          _showSnack(_error!);
        }
        return;
      }

      setState(() {
        _folders.removeWhere((f) => f.id == folder.id);
      });
      _showSnack('Carpeta eliminada.');
    } on SocketException {
      _showSnack(RequestErrorMapper.networkRetryMessage);
    } catch (_) {
      _showSnack('No se pudo eliminar la carpeta. Intenta de nuevo.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis carpetas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _folderController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva carpeta',
                      hintText: 'Ej: Trabajo',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isCreating ? null : _createFolder(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createFolder,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.create_new_folder_outlined),
                  label: const Text('Crear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(isDarkMode ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Text(_error!),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _folders.isEmpty
                      ? const Center(
                          child: Text('Aun no tienes carpetas. Crea la primera.'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFolders,
                          child: ListView.separated(
                            itemCount: _folders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final folder = _folders[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkSurface.withOpacity(0.92)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.folder_outlined),
                                  title: Text(folder.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteFolder(folder),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderItem {
  final String id;
  final String name;

  const _FolderItem({required this.id, required this.name});

  factory _FolderItem.fromJson(Map<String, dynamic> json) {
    return _FolderItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
