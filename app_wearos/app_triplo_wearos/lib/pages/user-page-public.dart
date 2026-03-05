import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/pages/diary_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';
import '../controller/diary.dart';
import 'user_list_page.dart';

class UserPagePublic extends StatelessWidget {
  final String? uidOverride;
  const UserPagePublic({super.key, this.uidOverride});

  String _fmtBirthdate(dynamic birthdateRaw) {
    if (birthdateRaw == null) return "-";
    if (birthdateRaw is String) {
      final dt = DateTime.tryParse(birthdateRaw);
      if (dt == null) return birthdateRaw;
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return "$d/$m/$y";
    }
    return birthdateRaw.toString();
  }

  Widget _infoRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statButton({
    required BuildContext context,
    required String label,
    required int value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? photoUrl) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        image: (photoUrl != null && photoUrl.trim().isNotEmpty)
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: (photoUrl == null || photoUrl.trim().isEmpty)
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final diaryController = context.watch<DiaryController>();

    final local = AppLocalizations.of(context)!;

    // se uidOverride è null => profilo "paired" (watch)
    final uid = uidOverride ?? userCtrl.effectiveUid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return FutureBuilder(
      future: userCtrl.getUserById(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        final user = snapshot.data!;
        final username = user.username;
        final email = (user.email ?? "").toString();
        final level = (user.level ?? "-").toString();
        final birthdate = _fmtBirthdate(user.birthdate);


        final photoUrl = (user.photoProfile ?? "").toString();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.10)),
                              ),
                              child: Row(
                                children: [
                                  _avatar(photoUrl),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        if (user.level == 'Beginner')
                                          Text(
                                            '${local.level_label}: ${local.beginner_level}',
                                            style:
                                                const TextStyle(fontSize: 10, color: Colors.lightBlue),
                                          )
                                        else if (user.level == 'Intermediate')
                                          Text(
                                            '${local.level_label}: ${local.intermediate_level}',
                                          style:
                                              const TextStyle(fontSize: 10, color: Colors.red),
                                        )
                                        else if (user.level == 'Advanced')
                                          Text(
                                            '${local.level_label}: ${local.advanced_level}',
                                            style:
                                                const TextStyle(fontSize: 10, color: const Color.fromARGB(255, 135, 1, 162)),
                                          )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Followers / Following clickable
                            FutureBuilder<List<String>>(
                              future: userCtrl.getFollowerUids(uid),
                              builder: (context, snapFollowers) {
                                final followerUids = snapFollowers.data ?? const <String>[];

                                return FutureBuilder<List<String>>(
                                  future: userCtrl.getFollowingUids(uid),
                                  builder: (context, snapFollowing) {
                                    final followingUids = snapFollowing.data ?? const <String>[];

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _statButton(
                                          context: context,
                                          label: "Followers",
                                          value: followerUids.length,
                                          onTap: followerUids.isEmpty
                                              ? () {}
                                              : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => UserListPage(
                                                  title: "Followers",
                                                  uids: followerUids,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 10),
                                        _statButton(
                                          context: context,
                                          label: "Following",
                                          value: followingUids.length,
                                          onTap: followingUids.isEmpty
                                              ? () {}
                                              : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => UserListPage(
                                                  title: "Following",
                                                  uids: followingUids,
                                                ),
   
                                           ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // Diary button 
                            FutureBuilder<List<Diary>?>(
                              future: diaryController.fetchDiaryById(uid),
                              builder: (context, snapshot) {

                                if (!snapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final diaries = snapshot.data ?? [];

                                final publicDiaries =
                                    diaries.where((d) => d.isPublic == true).toList();

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    // da capire come fare qui
                                    _statButton(
                                      context: context,
                                      label: local.public_botton_label,
                                      value: publicDiaries.length,
                                      onTap: publicDiaries.isEmpty
                                          ? () {}
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DiaryListPage(
                                                    title: "Public diaries",
                                                    diaries: publicDiaries,
                                                  ),
                                                ),
                                              );
                                            },
                                    
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}