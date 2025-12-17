import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/change-diary-page.dart';
import 'package:triplo/pages/user-page-public.dart';

class DiaryPage extends StatefulWidget {
  final DiaryController diaryController;
  final UserController userController;
  final TrekkingController trekkingController;
  final String diaryId;
  final void Function(Locale) onLocaleChanged;
  DiaryPage({
    super.key,
    required this.diaryId,
    required this.diaryController,
    required this.userController,
    required this.trekkingController,
    required this.onLocaleChanged,
  });

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final currentUserId = widget.diaryController.currentUser!.uid;

    // aspettiamo i due caricamenti
    await widget.diaryController.loadPublicDiary(currentUserId);
    await widget.diaryController.loadPrivateDiary(currentUserId);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final diary = widget.diaryController.getDiaryById(widget.diaryId);
    if (diary == null) {
      return const Scaffold(
        body: Center(child: Text('Diary not found')),
      );
    }


    String formattedTime;
    if (diary.duration < 60) {
      formattedTime = "${diary.duration} m";
    } else {
      if (diary.duration % 60 == 0) {
        formattedTime = "${diary.duration ~/ 60} h";
      } else {
        formattedTime = "${diary.duration ~/ 60} h ${diary.duration % 60} m";
      }
    }

    return FutureBuilder<Users?>(
      future: widget.userController.getUserById(diary.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text("This user doesn't exist")),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(diary.trekkigName),
            centerTitle: true, // Forced center the title
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModifyDiaryPage(
                        trekkingId: widget.trekkingController.getTrekkingId(diary.trekkigName)!,
                        diaryId: widget.diaryId,
                        trekkingController: widget.trekkingController,
                        diaryController: widget.diaryController,
                        userController: widget.userController,
                        onLocaleChanged: widget.onLocaleChanged,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          /*body: ListView(
            padding: const EdgeInsets.all(25.0),
            children: [
              // Profile info + profile pictures
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: general information
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Navigate to user profile page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserPagePublic(
                                      trekkingController:
                                          widget.trekkingController,
                                      diaryController: widget.diaryController,
                                      userController: widget.userController,
                                      onLocaleChanged: widget.onLocaleChanged,
                                      userId: user.uid,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                user.username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),
                        // Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '${local.date_trekking_label}: ${diary.date}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),
                        // Duration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '${local.duration_trekking_label}: $formattedTime',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),
                        // Friends
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${local.friends_trekking_label}: ',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: List.generate(diary.friends.length, (
                                  index,
                                ) {
                                  final friendId = diary.friends[index];
                                  return FutureBuilder<Users?>(
                                    future: widget.userController.getUserById(
                                      friendId,
                                    ),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData ||
                                          snapshot.data == null) {
                                        return const SizedBox.shrink();
                                      }
                                      final friend = snapshot.data!;

                                      // Aggiunge la virgola dopo ogni amico tranne l'ultimo
                                      String displayName = friend.username;
                                      if (index < diary.friends.length - 1)
                                        displayName += ', ';

                                      return GestureDetector(
                                        onTap: () {
                                          // Naviga alla pagina user dell'amico
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserPagePublic(
                                                userController:
                                                    widget.userController,
                                                diaryController:
                                                    widget.diaryController,
                                                trekkingController: widget
                                                    .trekkingController, // se serve
                                                onLocaleChanged:
                                                    widget.onLocaleChanged,
                                                userId: friend
                                                    .uid, // passiamo l'uid dell'amico
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right column: avatar
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              (widget.userController.getDownloadUrl(
                                    user.photoProfile,) != null)
                              ? NetworkImage(user.photoProfile!)
                                    as ImageProvider
                              : null,
                          backgroundColor: Colors.grey[400],
                          child:
                              (user.photoProfile == null ||
                                  user.photoProfile!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              // Photos
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${local.photos_trekking_label}: ',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: diary.photos.map((path) {
                    return FutureBuilder<String?>(
                      future: widget.diaryController.getDownloadUrlChild(path),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 150,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data == null) {
                          return Container(
                            width: 150,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          );
                        }

                        final url = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Image.network(
                            url,
                            width: 150,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Challenges
              if (diary.challenges.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '${local.challenges_trekking_label}: ',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: diary.challenges.map((path) {
                      return FutureBuilder<String?>(
                        future: widget.diaryController.getDownloadUrl(path),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              width: 150,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data == null) {
                            return Container(
                              width: 150,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          }

                          final url = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Image.network(
                              url,
                              width: 150,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 15),
              // Reshment point
              if (diary.refreshmentPoint != '')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${local.refreshment_point_trekking_label}: ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        diary.refreshmentPoint,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 15),
              // Mood
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${local.mood_trekking_label}: ${diary.mood.join(', ')}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Notes
              if (diary.notes != '')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${local.notes_trekking_label}: ',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        diary.notes,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
            ],
          ),*/
          body: ListView(
            padding: const EdgeInsets.all(25.0),
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundImage: user.photoProfile != null && user.photoProfile!.isNotEmpty
                            ? NetworkImage(user.photoProfile!)
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: user.photoProfile == null || user.photoProfile!.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                user.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 6),
                            infoRow(Icons.calendar_today, '${local.date_trekking_label}: ${diary.date}'),
                            infoRow(Icons.timer, '${local.duration_trekking_label}: $formattedTime'),
                          ]
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Freinds 
              if (diary.friends.isNotEmpty) ...[
                SectionTitle(text: local.friends_trekking_label, icon: Icons.group),
                Wrap(
                  spacing: 8,
                  children: diary.friends.map((id) {
                    return FutureBuilder<Users?>(
                      future: widget.userController.getUserById(id),
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
                                builder: (_) => UserPagePublic(
                                  userId: friend.uid,
                                  diaryController: widget.diaryController,
                                  userController: widget.userController,
                                  trekkingController: widget.trekkingController,
                                  onLocaleChanged: widget.onLocaleChanged,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ],

              // Photos and challenges
              SectionTitle(text: local.photos_trekking_label, icon: Icons.photo),
              imageScroller(
                diary.photos,
                widget.diaryController.getDownloadUrlChild,
              ),

              if (diary.challenges.isNotEmpty) ...[
                SectionTitle(text: local.challenges_trekking_label, icon: Icons.flag),
                imageScroller(
                  diary.challenges,
                  widget.diaryController.getDownloadUrl,
                ),
              ],

              // Mood
              SectionTitle(text: local.mood_trekking_label, icon: Icons.mood),
              Wrap(
                spacing: 8,
                children: diary.mood.map((m) {
                  return Chip(
                    label: Text(
                      m,
                      style: const TextStyle(
                        fontSize: 22, 
                      ),
                    ),
                    backgroundColor: Theme.of(context).cardColor, 
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),

              // Notes and refreshment point
              if (diary.refreshmentPoint.isNotEmpty) ...[
                SectionTitle(text: local.refreshment_point_trekking_label, icon: Icons.local_cafe),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(diary.refreshmentPoint),
                  ),
                ),
              ],

              if (diary.notes.isNotEmpty) ...[
                SectionTitle(text: local.notes_trekking_label, icon: Icons.notes),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(diary.notes),
                  ),
                ),
              ],
            ]
          )
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
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
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ],
  );
}

Widget imageScroller(
  List<String> images,
  Future<String?> Function(String) loader,
) {
  return SizedBox(
    height: 120,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        return FutureBuilder<String?>(
          future: loader(images[i]),
          builder: (_, snap) {
            if (!snap.hasData) {
              return Container(
                width: 160,
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
                width: 160,
                fit: BoxFit.cover,
              ),
            );
          },
        );
      },
    ),
  );
}


