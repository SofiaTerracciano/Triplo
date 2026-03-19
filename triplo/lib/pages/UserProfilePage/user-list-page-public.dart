import 'package:flutter/material.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/user.dart';
import 'user-page-public.dart';
import 'package:provider/provider.dart';

class UsersListPublic extends StatefulWidget {
  final String listName; 
  final String userId;

  const UsersListPublic({
    super.key,
    required this.listName,
    required this.userId,
  });

  @override
  _UsersListPublicState createState() => _UsersListPublicState();
}

class _UsersListPublicState extends State<UsersListPublic> {
  List<Users> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final userController = context.read<UserController>();
    List<Users> result;

    if (widget.listName == 'Follower') {
      result = await userController.getFollowers(widget.userId);
    } else {
      result = await userController.getFollowing(widget.userId);
    }

    if (!mounted) return;

    setState(() {
      users = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      // Avvolgiamo il contenuto del body con ScrollConfiguration
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: users.isEmpty
            ? Center(child: Text(local.no_users_found_label))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          user.photoProfile != null &&
                              user.photoProfile!.isNotEmpty
                          ? NetworkImage(user.photoProfile!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child:
                          user.photoProfile == null || user.photoProfile!.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    title: Text(user.username),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPagePublic(userId: user.uid),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}