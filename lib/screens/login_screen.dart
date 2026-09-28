import 'package:flutter/material.dart';
import '../main.dart';
import '../services/github_api.dart';
import '../services/secure_store.dart';
import 'repo_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _hide = true;

  Future<void> _connect() async {
    final token = _controller.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = GitHubApi(token);
      await api.getUser();
      await SecureStore.saveToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => RepoListScreen(token: token),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));
    } catch (e) {
      setState(() => _error = 'Token invalide ou expire');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: violet,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.terminal_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'Connecte ton compte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Colle un Personal Access Token GitHub (scope "repo").',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                obscureText: _hide,
                style: const TextStyle(
                    fontSize: 13, fontFamily: 'monospace', color: textPrimary),
                decoration: InputDecoration(
                  hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                  hintStyle: const TextStyle(color: muted, fontSize: 12),
                  prefixIcon:
                      const Icon(Icons.vpn_key_rounded, size: 18, color: muted),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _hide
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18,
                        color: muted),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                  filled: true,
                  fillColor: card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: line, width: .6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: violet, width: 1.2),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: errorColor, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: violet,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Se connecter',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
