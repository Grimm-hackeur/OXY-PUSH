import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/languages/dart.dart' as lang_dart;
import 'package:highlight/languages/javascript.dart' as lang_js;
import 'package:highlight/languages/json.dart' as lang_json;
import 'package:highlight/languages/yaml.dart' as lang_yaml;
import 'package:highlight/languages/markdown.dart' as lang_md;
import 'package:highlight/languages/xml.dart' as lang_xml;
import '../main.dart';
import '../services/github_api.dart';

class EditorScreen extends StatefulWidget {
  final String token;
  final String owner;
  final String repo;
  final String path;
  final String branch;
  const EditorScreen({
    super.key,
    required this.token,
    required this.owner,
    required this.repo,
    required this.path,
    required this.branch,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final GitHubApi _api = GitHubApi(widget.token);
  CodeController? _controller;
  String? _sha;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  dynamic _languageFor(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return lang_dart.dart;
      case 'js':
      case 'jsx':
      case 'ts':
      case 'tsx':
        return lang_js.javascript;
      case 'json':
        return lang_json.json;
      case 'yaml':
      case 'yml':
        return lang_yaml.yaml;
      case 'md':
        return lang_md.markdown;
      case 'html':
      case 'xml':
        return lang_xml.xml;
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.getFile(widget.owner, widget.repo, widget.path);
      final raw = (data['content'] as String).replaceAll('\n', '');
      final content = utf8.decode(base64Decode(raw));
      setState(() {
        _sha = data['sha'] as String?;
        _controller = CodeController(
          text: content,
          language: _languageFor(widget.path),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Impossible d'ouvrir ce fichier";
        _loading = false;
      });
    }
  }

  Future<void> _commit() async {
    if (_controller == null || _saving) return;
    final messageController = TextEditingController(
        text: 'Mise a jour de ${widget.path.split('/').last}');
    final message = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Message de commit',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              autofocus: true,
              style: const TextStyle(fontSize: 13, color: textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: bg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, messageController.text.trim()),
                icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                label: const Text('Confirmer',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violet,
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (message == null || message.isEmpty) return;

    setState(() => _saving = true);
    try {
      await _api.commitFile(
        owner: widget.owner,
        repo: widget.repo,
        path: widget.path,
        content: _controller!.text,
        message: message,
        sha: _sha,
        branch: widget.branch,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pousse sur GitHub'), backgroundColor: successColor),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec du push'), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.path.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 14)),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: violet))
                  : const Icon(Icons.cloud_upload_rounded, size: 20, color: violet),
              onPressed: _saving ? null : _commit,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!, style: const TextStyle(color: errorColor)))
              : Container(
                  color: const Color(0xFF15112A),
                  padding: const EdgeInsets.only(top: 8),
                  child: CodeTheme(
                    data: const CodeThemeData(styles: atomOneDarkTheme),
                    child: CodeField(
                      controller: _controller!,
                      textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                      lineNumberStyle: const LineNumberStyle(
                        width: 44,
                        textStyle: TextStyle(color: muted, fontSize: 11),
                      ),
                    ),
                  ),
                ),
    );
  }
}
