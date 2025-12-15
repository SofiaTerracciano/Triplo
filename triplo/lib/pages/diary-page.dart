import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      formattedTime = "${diary.duration} ${local.minutes_trekking_label}";
    } else {
      if (diary.duration % 60 == 0) {
        if (diary.duration / 60 == 1) {
          formattedTime = "${diary.duration / 60} ${local.hour_trekking_label}";
        } else {
          formattedTime =
              "${diary.duration / 60} ${local.hours_trekking_label}";
        }
      } else {
        if (diary.duration / 60 == 1) {
          formattedTime =
              "${diary.duration / 60} ${local.hour_trekking_label} ${diary.duration % 60} ${local.minutes_trekking_label}";
        } else {
          formattedTime =
              "${diary.duration / 60} ${local.hours_trekking_label} ${diary.duration % 60} ${local.minutes_trekking_label}";
        }
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

          body: ListView(
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
                                    user.photoProfile,
                                  ) !=
                                  null)
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (diary.challenges != [])
                    Text(
                      '${local.challenges_trekking_label}: ',
                      style: TextStyle(fontSize: 14),
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

              const SizedBox(height: 15),
              // Reshment point
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (diary.refreshmentPoint != '')
                    Text(
                      '${local.refreshment_point_trekking_label}: ${diary.refreshmentPoint}',
                      style: TextStyle(fontSize: 14),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${local.notes_trekking_label}: ${diary.notes}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
