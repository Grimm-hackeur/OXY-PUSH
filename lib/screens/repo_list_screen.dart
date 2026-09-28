import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../main.dart';
import '../services/github_api.dart';
import '../services/secure_store.dart';
import 'file_browser_screen.dart';
import 'login_screen.dart';

class RepoListScreen extends StatefulWidget {
  final String token;
  const RepoListScreen({super.key, required this.token});
  @override
  State<RepoListScreen> createState() => _RepoListScreenState();
}

class _RepoListScreenState extends State<RepoListScreen> {
  late final GitHubApi _api = GitHubApi(widget.token);
  List<dynamic>? _repos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final repos = await _api.listRepos();
      if (mounted) setState(() => _repos = repos);
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossible de charger les depots');
    }
  }

  Future<void> _logout() async {
    await SecureStore.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes depots'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: _load),
          IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              onPressed: _logout),
          const SizedBox(width: 6),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: errorColor)))
          : _repos == null
              ? _buildShimmer()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: violet,
                  backgroundColor: card,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _repos!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final repo = _repos![i] as Map<String, dynamic>;
                      final owner = repo['owner']['login'] as String;
                      final name = repo['name'] as String;
                      final priv = repo['private'] == true;
                      final branch = (repo['default_branch'] as String?) ?? 'main';
                      return _RepoTile(
                        name: name,
                        owner: owner,
                        private: priv,
                        branch: branch,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => FileBrowserScreen(
                            token: widget.token,
                            owner: owner,
                            repo: name,
                            path: '',
                            branch: branch,
                          ),
                        )),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: card,
        highlightColor: line,
        child: Container(
          height: 64,
          decoration:
              BoxDecoration(color: card, borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _RepoTile extends StatelessWidget {
  final String name;
  final String owner;
  final bool private;
  final String branch;
  final VoidCallback onTap;
  const _RepoTile({
    required this.name,
    required this.owner,
    required this.private,
    required this.branch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: line, width: .6),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: violet.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: violet, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('$owner . $branch',
                      style: const TextStyle(fontSize: 11, color: muted)),
                ],
              ),
            ),
            if (private) const Icon(Icons.lock_rounded, size: 14, color: muted),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}
