import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../config/service_locator.dart';
import '../../../../core/services/shared_prefs_service.dart';
import '../../../../core/theme/app_colors.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  static const String _baseUrl = 'http://18.223.30.63:5000';

  final TextEditingController _tagController = TextEditingController();
  final List<_TagItem> _tags = <_TagItem>[];

  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;

  SharedPrefsService get _prefs => sl<SharedPrefsService>();
  http.Client get _http => sl<http.Client>();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
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
        Uri.parse('$_baseUrl/tags/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron cargar los tags (${response.statusCode}).';
        });
        return;
      }

      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      final parsed = data
          .whereType<Map<String, dynamic>>()
          .map(_TagItem.fromJson)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _tags
          ..clear()
          ..addAll(parsed);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Error de red al cargar los tags.';
      });
    }
  }

  Future<void> _createTag() async {
    final name = _tagController.text.trim();
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
        Uri.parse('$_baseUrl/tags/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        _showSnack('No se pudo crear el tag (${response.statusCode}).');
        setState(() {
          _isCreating = false;
        });
        return;
      }

      final Map<String, dynamic> created =
          jsonDecode(response.body) as Map<String, dynamic>;
      final newTag = _TagItem.fromJson(created);

      setState(() {
        _tags.removeWhere((t) => t.id == newTag.id);
        _tags.add(newTag);
        _tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _isCreating = false;
      });
      _tagController.clear();
      _showSnack('Tag creado correctamente.');
    } catch (_) {
      setState(() {
        _isCreating = false;
      });
      _showSnack('Error de red al crear el tag.');
    }
  }

  Future<void> _deleteTag(_TagItem tag) async {
    final token = _prefs.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('Sesion expirada. Inicia sesion de nuevo.');
      return;
    }

    try {
      final response = await _http.delete(
        Uri.parse('$_baseUrl/tags/${tag.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        _showSnack('No se pudo eliminar el tag (${response.statusCode}).');
        return;
      }

      setState(() {
        _tags.removeWhere((t) => t.id == tag.id);
      });
      _showSnack('Tag eliminado.');
    } catch (_) {
      _showSnack('Error de red al eliminar el tag.');
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
        title: const Text('Tags'),
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
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo tag',
                      hintText: 'Ej: productividad',
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isCreating ? null : _createTag(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createTag,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
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
                  : _tags.isEmpty
                      ? const Center(
                          child: Text('Aun no tienes tags. Crea el primero.'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTags,
                          child: ListView.separated(
                            itemCount: _tags.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final tag = _tags[index];
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
                                  leading: const Icon(Icons.local_offer_outlined),
                                  title: Text(tag.name),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _deleteTag(tag),
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

class _TagItem {
  final String id;
  final String name;

  const _TagItem({required this.id, required this.name});

  factory _TagItem.fromJson(Map<String, dynamic> json) {
    return _TagItem(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
