import 'package:flutter/material.dart';
import 'package:triplo/controller/user.dart';
import '../../model/user.dart';
import 'package:provider/provider.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

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

    final userController = context.read<UserController>();
    results = await userController.searchUsers(query);


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
                          Navigator.pushNamed(
                            context,
                            "/userProfileRemote",
                            arguments: u.uid,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
