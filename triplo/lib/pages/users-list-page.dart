import 'package:flutter/material.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/model/user.dart';
import '../pages/user-page-public.dart';
import 'package:provider/provider.dart';


class UsersList extends StatefulWidget {
  final String listName;

  const UsersList({
    super.key,
    required this.listName,
  });

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late List<Users> users;

  @override
  void initState() {
    super.initState();
    final userController = context.read<UserController>();
    if(widget.listName == 'Followers') {
      users = userController.currentUser!.followers;
    } else {
      users = userController.currentUser!.following;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
     body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:user.photoProfile != null && user.photoProfile!.isNotEmpty
                  ? NetworkImage(user.photoProfile!)
                  : null,
              backgroundColor: Colors.grey[300],
              child:
                  user.photoProfile == null ||
                      user.photoProfile!.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            title: Text(user.username),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => UserPagePublic(
                    userId: user.uid,
                  ),
                ),
              );
            },
          );
        },
      )
    );
  }
}