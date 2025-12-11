import 'dart:io';
import 'package:flutter/material.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/user.dart';
import '../controller/trekking.dart';
import '../controller/diary.dart';
import '../model/user.dart';
import '../model/diary.dart';
import '../model/trekking.dart';



//DA CAPIRE LA COSA DEL POP

class UserPagePublic extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;
  final String userId;
  final TrekkingController trekkingController;
  final DiaryController diaryController;
  final UserController userController;

  const UserPagePublic({
    super.key,
    required this.onLocaleChanged,
    required this.userId,
    required this.trekkingController,
    required this.diaryController,
    required this.userController,
  });

  @override
  State<UserPagePublic> createState() => _UserPagePublicState();
}

class _UserPagePublicState extends State<UserPagePublic> {
  Users? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await widget.userController.getUserById(widget.userId);
    if (!mounted) return;

    setState(() {
      user = u;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(local.profile_page_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(local.profile_page_title)),
        body: const Center(child: Text("User not found")),
      );
    }

    // Shortcut
    final u = user!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${u.username}"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                // LOGICA DEL FOLLOW QUI
              },
            )
          ],
        ),

        body: Column(
          children: [

            Row(
              children: [
                // FOTO PROFILO
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircleAvatar(
                    radius: 40,

                    backgroundImage: (u.photoProfile != null && u.photoProfile!.isNotEmpty)
                        ? NetworkImage(u.photoProfile!)
                        : null,

                    child: (u.photoProfile == null || u.photoProfile!.isEmpty)
                        ? const Icon(Icons.person, size: 42)
                        : null,
                  ),

                ),

                // INFO UTENTE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Followers: ${u.followers.length}"),
                    Text("Following: ${u.following.length}"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.public)),
                Tab(icon: Icon(Icons.lock)),
                Tab(icon: Icon(Icons.bookmark)),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // ----------- TAB 1: DIARI PUBBLICI -----------
                  _buildPublicDiaryTab(u),

                  // ----------- TAB 2: DIARI PRIVATI -----------
                  const Center(
                    child: Text("Private diaries are not visible"),
                  ),

                  // ----------- TAB 3: TREKKING SALVATI -----------
                  _buildSavedTrekkingTab(u),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PUBLIC DIARY LIST ---
  Widget _buildPublicDiaryTab(Users u) {
    final List<Diary> list = u.publicDiaryPages;

    if (list.isEmpty) {
      return const Center(child: Text("No public diaries"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final d = list[i];
        return ListTile(
          title: Text(d.trekkigName),
          subtitle: Text(d.date),
          onTap: () {
            // APRI DIARIO (se vuoi)
          },
        );
      },
    );
  }

  // --- SAVED TREKKINGS ---
  Widget _buildSavedTrekkingTab(Users u) {
    final List<Trekking> list = u.savedTrekkings;

    if (list.isEmpty) {
      return const Center(child: Text("No saved trekking"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final t = list[i];
        return ListTile(
          title: Text(t.name),
          subtitle: Text("Distance: ${t.distance} km"),
          onTap: () {
            // APRI DETTAGLI TREKKING
          },
        );
      },
    );
  }
}
