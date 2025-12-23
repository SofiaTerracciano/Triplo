import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/model/trekking.dart';
import 'package:triplo/controller/trekking.dart';
import 'package:triplo/controller/user.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/pages/user-page.dart';
import 'package:triplo/pages/loading-page.dart';

class AddingDiaryPage extends StatefulWidget {
  final String trekkingId;
  
  const AddingDiaryPage({
    super.key, 
    required this.trekkingId
  });

  @override
  State<AddingDiaryPage> createState() => _AddingDiaryPageState();
}

class _AddingDiaryPageState extends State<AddingDiaryPage> {
  final _notesController = TextEditingController();
  final _refreshmentController = TextEditingController();
  final _picker = ImagePicker();

  // Date variables
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  int selectedHours = 0;
  int selectedMinutes = 0;

  final List<File> _images = [];
  final List<String> friends = [];
  final List<String> challenges = [];
  final List<int> selectedChallengeIndexes = [];
  final List<String> moods = [];

  bool usedRefreshment = false;
  bool isPublic = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDay = now.day;
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _refreshmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trekkingController = context.watch<TrekkingController>();
    final userController = context.watch<UserController>();
    final diaryController = context.watch<DiaryController>();
    final local = AppLocalizations.of(context)!;

    final Trekking trekking = trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;

    final days = List.generate(31, (i) => i + 1);
    final months = List.generate(12, (i) => i + 1);
    final years = List.generate(100, (i) => DateTime.now().year - i);
    final hoursList = List.generate(24, (i) => i);
    final minutesList = List.generate(60, (i) => i);

    final availableMoods = ["😍", "😁", "🥰", "😅", "😎", "😞", "🤩"];
    final moodLabels = [
      local.mood_love_label,
      local.mood_happy_label,
      local.mood_relaxed_label,
      local.mood_tired_label,
      local.mood_proud_label,
      local.mood_sad_label,
      local.mood_excited_label,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name), 
        centerTitle: true
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Date picker
            _section(
              context,
              local.date_trekking_label,
              Icons.calendar_today,
              Column(
                children: [
                  _rowDropdown([
                    _dropdown(
                      selectedDay,
                      days,
                      (v) => setState(() => selectedDay = v),
                    ),
                    _dropdown(
                      selectedMonth,
                      months,
                      (v) => setState(() => selectedMonth = v),
                    ),
                    _dropdown(
                      selectedYear,
                      years,
                      (v) => setState(() => selectedYear = v),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Duration picker
            _section(
              context,
              local.duration_trekking_label,
              Icons.timer, 
              Column(
                children: [
                  _rowDropdown([
                    _dropdown(
                      selectedHours,
                      hoursList,
                      (v) => setState(() => selectedHours = v),
                      pad: true,
                    ),
                    _dropdown(
                      selectedMinutes,
                      minutesList,
                      (v) => setState(() => selectedMinutes = v),
                      pad: true,
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Friends selector
            _section(
              context,
              local.friends_trekking_label,
              Icons.group,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview friends selected
                  friends.isEmpty
                      ? Text(
                          local.friends_selected_label, // "No friends selected"
                          style: const TextStyle(fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: userController.currentUser!.following
                              .where((u) => friends.contains(u.uid))
                              .map(
                                (u) => Chip(
                                  avatar: CircleAvatar(
                                    backgroundImage:
                                        (u.photoProfile?.isNotEmpty ?? false)
                                            ? NetworkImage(u.photoProfile!)
                                            : null,
                                    child: (u.photoProfile?.isEmpty ?? true)
                                        ? const Icon(Icons.person, size: 14)
                                        : null,
                                  ),
                                  label: Text(u.username),
                                  onDeleted: () {
                                    setState(() => friends.remove(u.uid));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                  const SizedBox(height: 8),
                  // Selection of friends
                  ExpansionTile(
                    title: Text(
                      local.choose_friend_label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    children: userController.currentUser!.following.map((u) {
                      final selected = friends.contains(u.uid);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: (u.photoProfile?.isNotEmpty ?? false)
                              ? NetworkImage(u.photoProfile!)
                              : null,
                          child: (u.photoProfile?.isEmpty ?? true)
                              ? const Icon(Icons.person, size: 18)
                              : null,
                        ),
                        title: Text(u.username, style: const TextStyle(fontSize: 14)),
                        trailing: Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                        ),
                        onTap: () => setState(() {
                          selected ? friends.remove(u.uid) : friends.add(u.uid);
                        }),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Notes input
            _section(
              context,
              local.notes_trekking_label,
              Icons.notes,
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: _input(local.notes_placeholder_trekking_label),
              ),
            ),

            const SizedBox(height: 8),
            // Refreshment input
            _section(
              context,
              local.refuge_trekking_label,
              Icons.restaurant,
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text(local.yes_botton_label),
                        selected: usedRefreshment,
                        onSelected: (_) =>
                            setState(() => usedRefreshment = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(local.no_botton_label),
                        selected: !usedRefreshment,
                        onSelected: (_) =>
                            setState(() => usedRefreshment = false),
                      ),
                    ],
                  ),
                  if (usedRefreshment) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _refreshmentController,
                      style: const TextStyle(fontSize: 14),
                      decoration: _input(
                        local.refreshment_point_trekking_label,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Challenges selector
            _section(
              context,
              local.challenges_trekking_label,
              Icons.flag,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview challenge selected
                  challenges.isEmpty
                      ? Text(
                          local.challenge_selected_label,
                          style: const TextStyle(fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: challenges.map((c) {
                            return FutureBuilder<String>(
                              future: trekkingController.getDownloadUrl(c),
                              builder: (_, snap) {
                                if (!snap.hasData) {
                                  return const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        snap.data!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    Positioned.fill(
                                      child: Center(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              final index = trekking.challenges.indexOf(c);
                                              challenges.remove(c);
                                              selectedChallengeIndexes.remove(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 8),
                  // Selection of challenges
                  ExpansionTile(
                    title: Text(
                      local.choose_challenge_label,
                      style: const TextStyle(fontSize: 14),
                    ),
                    children: [
                      SizedBox(
                        height: 260,
                        child: FutureBuilder<List<String>>(
                          future: Future.wait(
                            trekking.challenges
                                .map((c) => trekkingController.getDownloadUrl(c)),
                          ),
                          builder: (_, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final urls = snapshot.data!;

                            return GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: urls.length,
                              itemBuilder: (_, index) {
                                final challengeName = trekking.challenges[index];
                                final isSelected =
                                    selectedChallengeIndexes.contains(index);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        selectedChallengeIndexes.remove(index);
                                        challenges.remove(challengeName);
                                      } else {
                                        selectedChallengeIndexes.add(index);
                                        challenges.add(challengeName);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isSelected ? Colors.green : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        urls[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Mood selector
            _section(
              context,
              local.mood_trekking_label,
              Icons.mood,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview mood slected
                  moods.isEmpty
                      ? Text(
                          local.mood_selected_label, // "No mood selected"
                          style: const TextStyle(fontSize: 14),
                        )
                      : Wrap(
                          spacing: 8,
                          children: moods
                              .map(
                                (m) => Chip(
                                  label: Text(m, style: const TextStyle(fontSize: 20)),
                                  onDeleted: () {
                                    setState(() => moods.remove(m));
                                  },
                                ),
                              )
                              .toList(),
                        ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    title: Text(local.choose_mood_label),
                    children: List.generate(availableMoods.length, (i) {
                      final emoji = availableMoods[i];
                      final selected = moods.contains(emoji);
                      return ListTile(
                        dense: true,
                        leading: Text(emoji, style: const TextStyle(fontSize: 20)),
                        title: Text(moodLabels[i], style: const TextStyle(fontSize: 14)),
                        trailing:
                            Icon(selected ? Icons.check_circle : Icons.circle_outlined),
                        onTap: () => setState(() {
                          selected ? moods.remove(emoji) : moods.add(emoji);
                        }),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Photos picker
            _section(
              context,
              local.photos_trekking_label,
              Icons.photo,
              Column(
                children: [
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _images[i],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),

                            // Delete button
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _images.removeAt(i));
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Add photo button
                  Center(
                    child:
                      ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                      label: Text(local.add_botton_label),
                      onPressed: _pickImages,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 8),
            // Public/Private toggle
            _section(
              context,
              local.public_private_label,
              Icons.lock,
              Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _toggle(
                        local.public_botton_label,
                        isPublic,
                        () => setState(() => isPublic = true),
                      ),
                      const SizedBox(width: 8),
                      _toggle(
                        local.private_botton_label,
                        !isPublic,
                        () => setState(() => isPublic = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Save/Cancel buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(local.cancel_button_label),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    child: Text(local.save_botton_label),
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoadingPage()),
                      );

                      final date =
                          "${selectedDay.toString().padLeft(2, '0')}/${selectedMonth.toString().padLeft(2, '0')}/$selectedYear";
                      final duration = selectedHours * 60 + selectedMinutes;
                      final photos = await diaryController.uploadDiaryImages(
                        _images,
                      );

                      await diaryController.addDiary(
                        trekking.name,
                        isPublic,
                        date,
                        duration.toDouble(),
                        friends,
                        photos,
                        challenges,
                        _refreshmentController.text,
                        moods,
                        _notesController.text,
                        false,
                        '',
                      );

                      await userController.updateUserLevel(trekking.difficulty_level);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const UserPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Section card widget
  Widget _section(BuildContext context, String title, IconData icon, Widget c) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            c,
          ],
        ),
      ),
    );
  }

  // Row of dropdowns
  Widget _rowDropdown(List<Widget> children) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: e,
            ),
          )
          .toList(),
    );
  }

  // Dropdown widget
  Widget _dropdown(
    int value,
    List<int> items,
    ValueChanged<int> onChanged, {
    bool pad = false,
  }) {
    return DropdownButton<int>(
      value: value,
      onChanged: (v) => onChanged(v!),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(pad ? e.toString().padLeft(2, '0') : e.toString()),
            ),
          )
          .toList(),
    );
  }

  // Input decoration
  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );

  // Toggle button widget
  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: active ? const Color(0xFF303030) : Colors.grey[300],
        foregroundColor: active ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: active ? 3 : 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(maxWidth: 800, maxHeight: 800);
    if (picked.isNotEmpty) {
      setState(() {
        _images
          ..clear()
          ..addAll(picked.map((x) => File(x.path)));
      });
    }
  }
}