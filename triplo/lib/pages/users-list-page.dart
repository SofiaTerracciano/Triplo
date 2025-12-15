import 'package:flutter/material.dart';
import 'package:triplo/controller/user.dart';
import '../controller/trekking.dart';
import '../controller/diary.dart';
import 'package:triplo/model/user.dart';
import '../pages/user-page-public.dart';
import 'package:triplo/l10n/app_localizations.dart';


class UsersList extends StatefulWidget {
  final String listName;

  final void Function(Locale) onLocaleChanged;
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;

  const UsersList({
    super.key,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
    required this.listName,
    required this.onLocaleChanged,
  });

  @override
  _UsersListState createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late List<Users> users;

  @override
  void initState() {
    super.initState();
    if(widget.listName == 'Followers') {
      users = widget.userController.currentUser!.followers;
    } else {
      users = widget.userController.currentUser!.following;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
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
              backgroundImage: user.photoProfile != null
                  ? NetworkImage( user.photoProfile!) // URL dell'immagine
                  : AssetImage('assets/images/default_avatar.png')
                      as ImageProvider, // immagine di default se nulla
            ),
            title: Text(user.username), // nome utente
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (_) => UserPagePublic(
                    onLocaleChanged: widget.onLocaleChanged,
                    trekkingController: widget.trekkingController,
                    userController: widget.userController,
                    diaryController: widget.diaryController,
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