import 'package:flutter/material.dart';
import '../main.dart';
import '../services/github_api.dart';
import 'editor_screen.dart';

class FileBrowserScreen extends StatefulWidget {
  final String token;
  final String owner;
  final String repo;
  final String path;
  final String branch;
  const FileBrowserScreen({
    super.key,
    required this.token,
    required this.owner,
    required this.repo,
    required this.path,
    required this.branch,
  });

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  late final GitHubApi _api = GitHubApi(widget.token);
  List<dynamic>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items =
          await _api.listContents(widget.owner, widget.repo, widget.path);
      items.sort((a, b) {
        final ad = a['type'] == 'dir';
        final bd = b['type'] == 'dir';
        if (ad != bd) return ad ? -1 : 1;
        return (a['name'] as String).compareTo(b['name'] as String);
      });
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur de chargement');
    }
  }

  IconData _iconFor(String name, bool isDir) {
    if (isDir) return Icons.folder_rounded;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        return Icons.code_rounded;
      case 'json':
      case 'yaml':
      case 'yml':
        return Icons.settings_suggest_rounded;
      case 'md':
        return Icons.article_rounded;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'svg':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color _colorFor(String name, bool isDir) {
    if (isDir) return violet;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return const Color(0xFF3FB6F5);
      case 'js':
      case 'jsx':
        return const Color(0xFFF2D94E);
      case 'json':
      case 'yaml':
      case 'yml':
        return muted;
      case 'md':
        return soft;
      default:
        return muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.path.isEmpty ? widget.repo : widget.path.split('/').last;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: errorColor)))
          : _items == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = _items![i] as Map<String, dynamic>;
                    final isDir = item['type'] == 'dir';
                    final name = item['name'] as String;
                    final path = item['path'] as String;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (isDir) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FileBrowserScreen(
                              token: widget.token,
                              owner: widget.owner,
                              repo: widget.repo,
                              path: path,
                              branch: widget.branch,
                            ),
                          ));
                        } else {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => EditorScreen(
                              token: widget.token,
                              owner: widget.owner,
                              repo: widget.repo,
                              path: path,
                              branch: widget.branch,
                            ),
                          ));
                        }
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line, width: .5),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconFor(name, isDir),
                                size: 18, color: _colorFor(name, isDir)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 13, color: textPrimary)),
                            ),
                            if (isDir)
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: muted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
