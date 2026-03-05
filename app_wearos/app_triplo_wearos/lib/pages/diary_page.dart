import 'package:app_triplo_wearos/model/diary.dart';
import 'package:flutter/material.dart';
import 'package:app_triplo_wearos/controller/diary.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/user.dart';
import 'package:provider/provider.dart';

/// WearOS-optimized DiaryPage — same visual identity as the mobile app.
/// Read-only: trekkingName, username, date, duration, friends, challenges.
class DiaryPage extends StatefulWidget {
  final Diary diary;

  const DiaryPage({super.key, required this.diary});

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool _isLoading = true;

  // Cache futures so they are NOT recreated on every rebuild
  Future<Users?>? _ownerFuture;
  final Map<String, Future<Users?>> _friendFutures = {};

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
  try {
    final diaryController = context.read<DiaryController>();
    final userController = context.read<UserController>();

    final currentUser = diaryController.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final currentUserId = currentUser.uid;

    await diaryController.loadPublicDiary(currentUserId);
    await diaryController.loadPrivateDiary(currentUserId);

    final diary = widget.diary;
    if (diary != null) {
      _ownerFuture = userController.getUserById(diary.userId);
      for (final id in diary.friends) {
        _friendFutures[id] = userController.getUserById(id);
      }
    }
  } catch (e) {
    debugPrint('Errore in _loadDiaries: $e');
  } finally {
    // ✅ Garantisce che il loading venga sempre rimosso
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final diary = widget.diary;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Format duration
    String formattedTime;
    if (diary.duration < 60) {
      formattedTime = "${diary.duration} m";
    } else if (diary.duration % 60 == 0) {
      formattedTime = "${diary.duration ~/ 60} h";
    } else {
      formattedTime = "${diary.duration ~/ 60} h ${diary.duration % 60} m";
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          children: [

            // TITLE
            Text(
              diary.trekkigName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // INFO CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [

                    /// USER
                    FutureBuilder<Users?>(
                      future: _ownerFuture,
                      builder: (_, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(height: 20);
                        }

                        final user = snap.data!;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: user.photoProfile != null &&
                                      user.photoProfile!.isNotEmpty
                                  ? NetworkImage(user.photoProfile!)
                                  : null,
                              child: user.photoProfile == null ||
                                      user.photoProfile!.isEmpty
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                user.username,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 6),

                    _infoRow(Icons.calendar_today, diary.date),

                    const SizedBox(height: 4),

                    _infoRow(Icons.timer, formattedTime),
                  ],
                ),
              ),
            ),

            /// FRIENDS
            if (diary.friends.isNotEmpty) ...[
              const SizedBox(height: 6),

              _SectionTitle(
                text: local.friends_trekking_label,
                icon: Icons.group,
              ),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: diary.friends.map((id) {
                      return FutureBuilder<Users?>(
                        future: _friendFutures[id],
                        builder: (_, snap) {
                          if (!snap.hasData) {
                            return const SizedBox(height: 14);
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: _infoRow(
                              Icons.person_outline,
                              snap.data!.username,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            /// CHALLENGES
            if (diary.challenges.isNotEmpty) ...[
              const SizedBox(height: 6),

              _SectionTitle(
                text: local.challenges_trekking_label,
                icon: Icons.flag,
              ),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _infoRow(
                    Icons.emoji_events,
                    "${diary.challenges.length}",
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SectionTitle({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _infoRow(IconData icon, String text) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 12, color: Colors.grey),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    ],
  );
}
