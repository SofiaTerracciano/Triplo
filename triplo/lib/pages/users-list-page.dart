import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/model/user.dart';
import '../pages/user-page-public.dart';

class UsersList extends StatelessWidget {
  final String listName; // "Followers" or "Following"

  const UsersList({
    super.key,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {

    final controller = context.read<UserController>();
    final myUid = controller.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(listName),
        centerTitle: true,
      ),

      body: FutureBuilder<List<Users>>(
        future: listName == 'Followers'
            ? controller.getFollowers(myUid)
            : controller.getFollowing(myUid),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text("No users"),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {

              final user = users[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoProfile != null &&
                      user.photoProfile!.isNotEmpty
                      ? NetworkImage(user.photoProfile!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: user.photoProfile == null ||
                      user.photoProfile!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),

                title: Text(user.username),

                subtitle: Text(user.email),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserPagePublic(
                        userId: user.uid,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
