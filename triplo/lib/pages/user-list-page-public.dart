import 'package:flutter/material.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/model/user.dart';
import '../pages/user-page-public.dart';
import 'package:provider/provider.dart';

class UsersListPublic extends StatefulWidget {
  final String listName; // 'Followers' o 'Following'
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

    // Prendi l'utente target
    final targetUser = await userController.getUserById(widget.userId);
    if (!mounted) return;

    setState(() {
      if (widget.listName == 'Followers') {
        users = targetUser?.followers ?? [];
      } else {
        users = targetUser?.following ?? [];
      }
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      body: users.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                // Fallback sicuro per avatar
                ImageProvider? avatar;
                if (user.photoProfile != null &&
                    user.photoProfile!.startsWith('http')) {
                  avatar = NetworkImage(user.photoProfile!);
                } else {
                  avatar = const AssetImage('assets/images/default_avatar.png');
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: avatar,
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
    );
  }
}

