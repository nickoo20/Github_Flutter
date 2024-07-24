// 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
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> repos = [];
  bool isLoading = true;
  bool isError = false;

  final String githubToken = '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';

  @override
  void initState() {
    super.initState();
    fetchRepos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GitHub Repositories'),
        backgroundColor: Colors.blueGrey,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text('Failed to load repositories. Please try again.', style: TextStyle(color: Colors.red, fontSize: 16)))
              : ListView.builder(
                  padding: EdgeInsets.all(8.0),
                  itemCount: repos.length,
                  itemBuilder: (context, index) {
                    final repo = repos[index];
                    final name = repo['name'] ?? 'No name';
                    final description = repo['description'] ?? 'No description';
                    final stargazersCount = repo['stargazers_count'] ?? 0;
                    final lastCommitMessage = repo['lastCommitMessage'] ?? 'Loading...';
                    final avatarUrl = repo['owner']['avatar_url'] ?? '';

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                          radius: 30,
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description, style: TextStyle(color: Colors.grey[600])),
                            SizedBox(height: 8),
                            Text('Last commit: $lastCommitMessage', style: TextStyle(color: Colors.blueGrey[800])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.yellow),
                            SizedBox(width: 4),
                            Text(stargazersCount.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        onTap: () {
                          // Optionally handle tap to view repository details
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchRepos,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  Future<void> fetchRepos() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    const url = 'https://api.github.com/users/freeCodeCamp/repos';
    final uri = Uri.parse(url);
    final headers = {
      'Authorization': 'token $githubToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = response.body;
        final List<dynamic> json = jsonDecode(body);

        // Fetch last commit for each repo
        for (var repo in json) {
          final repoName = repo['name'];
          final commitUrl = 'https://api.github.com/repos/freeCodeCamp/$repoName/commits';
          final commitUri = Uri.parse(commitUrl);
          final commitResponse = await http.get(commitUri, headers: headers);

          if (commitResponse.statusCode == 200) {
            final commitBody = commitResponse.body;
            final List<dynamic> commitJson = jsonDecode(commitBody);
            if (commitJson.isNotEmpty) {
              repo['lastCommitMessage'] = commitJson[0]['commit']['message'];
            } else {
              repo['lastCommitMessage'] = 'No commits found';
            }
          } else {
            repo['lastCommitMessage'] = 'Failed to load commit';
            print('Failed to load commit for $repoName: ${commitResponse.statusCode}');
          }
        }

        setState(() {
          repos = json.cast<Map<String, dynamic>>(); // Ensure type is List<Map<String, dynamic>>
          isLoading = false;
        });
        print('Repos fetched successfully');
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
        print('Failed to load repos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
      print('An error occurred: $e');
    }
  }
}

