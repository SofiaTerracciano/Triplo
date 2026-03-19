import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/pages/diary_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/user.dart';
import '../controller/diary.dart';
import 'user_list_page.dart';

class UserPage extends StatelessWidget {
  final String? uidOverride;
  const UserPage({super.key, this.uidOverride});

  Widget _statButton({
    required BuildContext context,
    required String label,
    required int value,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    Widget card = InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toString(),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: card) : Expanded(child: card);
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = context.watch<UserController>();
    final diaryCtrl = context.watch<DiaryController>();
    final local = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isOwnProfile = uidOverride == null;
    final uid = uidOverride ?? userCtrl.effectiveUid;

    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator()
        )
      );
    }

    return FutureBuilder(
      future: userCtrl.getUserById(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator()
            )
          );
        }

        final user = snapshot.data!;
        final photoUrl = user.photoProfile ?? "";

        // Determins level name and color based on user.level
        String levelName = "-";
        Color levelColor = Colors.grey;

        if (user.level == 'Beginner') {
          levelName = local.beginner_level;
          levelColor = Colors.lightBlue;
        } else if (user.level == 'Intermediate') {
          levelName = local.intermediate_level;
          levelColor = Colors.red;
        } else if (user.level == 'Advanced') {
          levelName = local.advanced_level;
          levelColor = const Color.fromARGB(255, 135, 1, 162);
        }

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              children: [
                // User info section
                Column(
                  children: [
                    // Image profile row
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
                    ),
                    const SizedBox(height: 4),
                    // Username row
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    // Level row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${local.level_label}: ",
                          style: const TextStyle(
                            fontSize: 10, 
                            color: Colors.grey
                          ),
                        ),
                        Text(
                          levelName,
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold, 
                            color: levelColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Follower and following section
                FutureBuilder<List<String>>(
                  future: userCtrl.getFollowerUids(uid),
                  builder: (context, snapFol) {
                    final followers = snapFol.data ?? [];
                    return FutureBuilder<List<String>>(
                      future: userCtrl.getFollowingUids(uid),
                      builder: (context, snapFollw) {
                        final following = snapFollw.data ?? [];
                        return Row(
                          children: [
                            _statButton(
                              context: context, 
                              label: local.follower_label, 
                              value: followers.length,
                              onTap: () => Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => UserListPage(
                                    title: local.follower_label, 
                                    uids: followers
                                  )
                                )
                              ),
                            ),
                            const SizedBox(width: 4),
                            _statButton(
                              context: context, 
                              label: local.following_label, 
                              value: following.length,
                              onTap: () => Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => UserListPage(
                                    title: local.following_label, 
                                    uids: following
                                  )
                                )
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                // Diaries secction
                FutureBuilder<List<Diary>?>(
                  future: diaryCtrl.fetchDiaryById(uid),
                  builder: (context, snapDiaries) {
                    final diaries = snapDiaries.data ?? [];
                    final publicDiaries = diaries.where((d) => d.isPublic).toList();
                    final privateDiaries = diaries.where((d) => !d.isPublic).toList();

                    if (isOwnProfile) {
                      // If the profile belongs to the current user: I see both Public and Private, in two separate buttons
                      return Row(
                        children: [
                          _statButton(
                            context: context,
                            label: local.public_botton_label,
                            value: publicDiaries.length,
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => DiaryListPage(
                                  title: local.public_diaries_label, 
                                  diaries: publicDiaries
                                )
                              )
                            ),
                          ),
                          const SizedBox(width: 4),
                          _statButton(
                            context: context,
                            label: local.private_botton_label,
                            value: privateDiaries.length,
                            onTap: () => Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => DiaryListPage(
                                  title: local.private_diaries_label, 
                                  diaries: privateDiaries
                                )
                              )
                            ),
                          ),
                        ],
                      );
                    } else {
                      // If it's NOT my profile: I only see Public
                      return _statButton(
                        context: context,
                        label: local.public_botton_label,
                        value: publicDiaries.length,
                        fullWidth: true,
                        onTap: () => Navigator.push(
                          context, MaterialPageRoute(
                            builder: (_) => DiaryListPage(
                              title: local.public_diaries_label, 
                              diaries: publicDiaries
                            )
                          )
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 10),

                // Logout only if the profile belongs to the current user
                if (isOwnProfile)...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => userCtrl.logoutWatch(),
                      child: Text(
                        local.logout_label, 
                        style: TextStyle(fontSize: 11)
                      ),
                    ),
                  ),
                ] else 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        local.back_label, 
                        style: TextStyle(fontSize: 11)
                      ),
                    ),
                  ),
                 
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}