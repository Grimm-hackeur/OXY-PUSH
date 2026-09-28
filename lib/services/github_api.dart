import 'dart:convert';
import 'package:http/http.dart' as http;

class GitHubApi {
  final String token;
  GitHubApi(this.token);

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      };

  Future<Map<String, dynamic>> getUser() async {
    final res = await http.get(
      Uri.parse('https://api.github.com/user'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Token invalide (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listRepos() async {
    final res = await http.get(
      Uri.parse('https://api.github.com/user/repos?sort=updated&per_page=100'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur chargement depots (${res.statusCode})');
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<List<dynamic>> listContents(
      String owner, String repo, String path) async {
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur chargement dossier (${res.statusCode})');
    }
    final data = jsonDecode(res.body);
    return data is List ? data : [data];
  }

  Future<Map<String, dynamic>> getFile(
      String owner, String repo, String path) async {
    final res = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Erreur chargement fichier (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> commitFile({
    required String owner,
    required String repo,
    required String path,
    required String content,
    required String message,
    String? sha,
    String branch = 'main',
  }) async {
    final res = await http.put(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: _headers,
      body: jsonEncode({
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        if (sha != null) 'sha': sha,
        'branch': branch,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erreur push (${res.statusCode})');
    }
  }
}
