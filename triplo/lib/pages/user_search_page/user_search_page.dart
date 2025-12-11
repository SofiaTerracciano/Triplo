import 'package:flutter/material.dart';
import '../../controller/user.dart';
import '../../model/user.dart';

class UserSearchPage extends StatefulWidget {
  final UserController userController;

  const UserSearchPage({super.key, required this.userController});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  List<Users> results = [];
  bool loading = false;

  Future<void> runSearch(String query) async {
    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);

    results = await widget.userController.searchUsers(query);

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Users")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _ctrl,
              onChanged: runSearch,
              decoration: InputDecoration(
                hintText: "Search username...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : results.isEmpty
                ? Center(child: Text("No results"))
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final u = results[i];
                return ListTile(
                  title: Text(u.username),
                  subtitle: Text(u.email),
                  onTap: () {
                    Navigator.pushNamed(context, "/userProfileRemote",
                      arguments: u.uid,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}