import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/model/diary.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/DiaryPage/change-diary-page.dart';
import 'package:triplo/pages/UserProfilePage/user-page-public.dart';
import 'package:provider/provider.dart';
import 'package:triplo/pages/UserProfilePage/user-page.dart';

// DiaryPage widget to display details of a specific diary that you have created
class DiaryPage extends StatefulWidget {
  final String diaryId;

  DiaryPage({super.key, required this.diaryId});

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final diaryController = context.read<DiaryController>();
    final userController = context.watch<UserController>();
    final trekkingController = context.watch<TrekkingController>();

    //final diary = diaryController.getDiaryById(widget.diaryId);

    return FutureBuilder<Diary?>(
      // Usiamo il nuovo metodo asincrono
      future: diaryController.getDiaryByIdAsync(widget.diaryId),
      builder: (context, diarySnapshot) {
        if (diarySnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final diary = diarySnapshot.data;
        if (diary == null) {
          return Scaffold(body: Center(child: Text(local.diary_not_found)));
        }

        // Format duration into hours and minutes
        String formattedTime;
        if (diary.duration < 60) {
          formattedTime = "${diary.duration} m";
        } else {
          if (diary.duration % 60 == 0) {
            formattedTime = "${diary.duration ~/ 60} h";
          } else {
            formattedTime =
                "${diary.duration ~/ 60} h ${diary.duration % 60} m";
          }
        }

        return FutureBuilder<Users?>(
          future: userController.getUserById(diary.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Scaffold(body: Center(child: Text(local.user_not_found)));
            }

            final user = snapshot.data!;

            return Scaffold(
              appBar: AppBar(
                title: Text(diary.trekkigName),
                centerTitle: true, // Forced center the title
                actions: [
                  // Edit button only if the current user is the diary owner so you can watch and edit your
                  // own diaries but not other users' diaries
                  if (userController.currentUser!.uid == diary.userId)
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ModifyDiaryPage(
                              trekkingId:
                                  trekkingController.getTrekkingId(
                                    diary.trekkigName,
                                  ) ??
                                  '',
                              diaryId: widget.diaryId,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),

              body: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: ListView(
                  padding: const EdgeInsets.all(25.0),
                  children: [
                    // Info card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile photo
                            CircleAvatar(
                              radius: 36,
                              backgroundImage:
                                  user.photoProfile != null &&
                                      user.photoProfile!.isNotEmpty
                                  ? NetworkImage(user.photoProfile!)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child:
                                  user.photoProfile == null ||
                                      user.photoProfile!.isEmpty
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Username
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextButton(
                                    child: Text(
                                      user.username,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              userController.currentUser!.uid ==
                                                  diary.userId
                                              ? UserPage()
                                              : UserPagePublic(
                                                  userId: diary.userId,
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 3),
                                  // Date
                                  infoRow(
                                    Icons.calendar_today,
                                    '${local.date_trekking_label}: ${diary.date}',
                                  ),
                                  // Duration
                                  infoRow(
                                    Icons.timer,
                                    '${local.duration_trekking_label}: $formattedTime',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Freinds
                    if (diary.friends.isNotEmpty) ...[
                      SectionTitle(
                        text: local.friends_trekking_label,
                        icon: Icons.group,
                      ),
                      Wrap(
                        spacing: 8,
                        children: diary.friends.map((id) {
                          return FutureBuilder<Users?>(
                            future: userController.getUserById(id),
                            builder: (_, snap) {
                              if (!snap.hasData) return const SizedBox.shrink();
                              final friend = snap.data!;
                              return ActionChip(
                                label: Text(friend.username),
                                avatar: const Icon(Icons.person, size: 18),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserPagePublic(userId: friend.uid),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    // Photos only if you have upload them
                    if (diary.photos.isNotEmpty) ...[
                      SectionTitle(
                        text: local.photos_trekking_label,
                        icon: Icons.photo,
                      ),
                      imageScroller(
                        diary.photos,
                        diaryController.getDownloadUrlChild,
                      ),
                    ],

                    // Challenges only if you have done them
                    if (diary.challenges.isNotEmpty) ...[
                      SectionTitle(
                        text: local.challenges_trekking_label,
                        icon: Icons.flag,
                      ),
                      imageScroller(
                        diary.challenges,
                        diaryController.getDownloadUrl,
                        isBadge: true,
                      ),
                    ],

                    // Mood only if you have selected
                    if (diary.mood.isNotEmpty) ...[
                      SectionTitle(
                        text: local.mood_trekking_label,
                        icon: Icons.mood,
                      ),
                      Wrap(
                        spacing: 8,
                        children: diary.mood.map((m) {
                          return Chip(
                            label: Text(
                              m,
                              style: const TextStyle(fontSize: 22),
                            ),
                            backgroundColor: Theme.of(context).cardColor,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Refreshment point only if you have you eaten there
                    if (diary.refreshmentPoint.isNotEmpty) ...[
                      SectionTitle(
                        text: local.refreshment_point_trekking_label,
                        icon: Icons.restaurant,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(diary.refreshmentPoint),
                        ),
                      ),
                    ],

                    // Notes only if you have written
                    if (diary.notes.isNotEmpty) ...[
                      SectionTitle(
                        text: local.notes_trekking_label,
                        icon: Icons.notes,
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(diary.notes),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const SectionTitle({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

Widget infoRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
    ],
  );
}

Widget imageScroller(
  List<String> images,
  Future<String?> Function(String) loader, {
  bool isBadge = false, 
}) {
  double height = isBadge ? 60 : 120;
  double width = isBadge ? 60 : 160;

  return SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        return FutureBuilder<String?>(
          future: loader(images[i]),
          builder: (_, snap) {
            if (!snap.hasData) {
              return Container(
                width: width,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                snap.data!,
                width: width,
                height: height,
                // Le sfide devono stare intere (contain), le foto riempiono (cover)
                fit: isBadge ? BoxFit.contain : BoxFit.cover,
              ),
            );
          },
        );
      },
    ),
  );
}
