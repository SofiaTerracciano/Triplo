import 'package:app_triplo_wearos/model/diary.dart';
import 'package:app_triplo_wearos/pages/UserProfilePage/user.dart';
import 'package:flutter/material.dart';
import 'package:app_triplo_wearos/controller/user.dart';
import 'package:app_triplo_wearos/l10n/app_localizations.dart';
import 'package:app_triplo_wearos/model/user.dart';
import 'package:provider/provider.dart';

class DiaryPage extends StatefulWidget {
  final Diary diary;

  const DiaryPage({super.key, required this.diary});

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool _isLoading = true;
  Future<Users?>? _ownerFuture;
  final Map<String, Future<Users?>> _friendFutures = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userController = context.read<UserController>();
      final diary = widget.diary;

      _ownerFuture = userController.getUserById(diary.userId);
      for (final id in diary.friends) {
        _friendFutures[id] = userController.getUserById(id);
      }
    } catch (e) {
      debugPrint('Errore in _loadData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final diary = widget.diary;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    String formattedTime = diary.duration < 60
        ? "${diary.duration} m"
        : "${diary.duration ~/ 60} h ${diary.duration % 60} m";

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 32, bottom: 20),
          children: [
            // Trekking name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                diary.trekkigName,
                textAlign: TextAlign.center,
                maxLines: 3, 
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    FutureBuilder<Users?>(
                      future: _ownerFuture,
                      builder: (_, snap) {
                        if (!snap.hasData) return const SizedBox(height: 20);
                        final user = snap.data!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: (user.photoProfile?.isNotEmpty ?? false)
                                  ? NetworkImage(user.photoProfile!)
                                  : null,
                              child: (user.photoProfile?.isEmpty ?? true)
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                user.username,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 12),
                    _infoRow(Icons.calendar_today, diary.date),
                    const SizedBox(height: 4),
                    _infoRow(Icons.timer, formattedTime),
                  ],
                ),
              ),
            ),

            // Friends section only if there are friends
            if (diary.friends.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SectionTitle(text: local.friends_trekking_label, icon: Icons.group),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: diary.friends.map((id) {
                      return FutureBuilder<Users?>(
                        future: _friendFutures[id],
                        builder: (_, snap) {
                          if (!snap.hasData) return const SizedBox(height: 24);
                          final friend = snap.data!;
                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UserPage(uidOverride: friend.uid)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline, size: 12, color: primaryColor),
                                  const SizedBox(width: 4),
                                  Text(friend.username, style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            // Challenge section only if there are challenges
            if (diary.challenges.isNotEmpty) ...[
              const SizedBox(height: 8),
              _SectionTitle(text: local.challenges_trekking_label, icon: Icons.emoji_events),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: diary.challenges.map((challengePath) {
                      // Challenge icons
                      return Image.asset(
                        challengePath,
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.flag, size: 20, color: primaryColor),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 30),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(local.back_label, style: TextStyle(fontSize: 11)),
              ),
            ),

            const SizedBox(height: 14),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
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

