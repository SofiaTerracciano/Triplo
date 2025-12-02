import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/controller/diary.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import '../controller/diary.dart';

class DiaryPage extends StatefulWidget {
  DiaryController diaryController;
  final String diaryId;
  final void Function(Locale) onLocaleChanged;

  DiaryPage({
    super.key, 
    required this.diaryId,
    required this.diaryController,
    required this.onLocaleChanged
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

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text('da prender'), centerTitle: true),

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
                        const Text(
                          'arco33Mega',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${local.date_trecking_label}', // da prendere dal db
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    // How much time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${local.duration_trekking_label}: ',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    // Friends
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${local.friends_trekking_label}: ', 
                          style: TextStyle(fontSize: 14)
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
                      backgroundImage: AssetImage(
                        'images/profile_placeholder.png',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
          // Other information about the trekking
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [ 
              Text(
                '${local.photos_trekking_label}: ', 
                style: TextStyle(fontSize: 14)
              )
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // orizontal scroll
            child: Row(
              children: [
                // sarà da prendere in modo dinamico
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
                SizedBox(width: 3),
                Image.asset('images/prova.jpeg', width: 150, height: 100),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${local.challenges_trekking_label}: ', 
                style: TextStyle(fontSize: 14)
              ),
              // fai json in cui metti path dell'immagine della sfida e descrzione della sfida
            ],
          ),

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${local.refuge_trekking_label}: ', 
                style: TextStyle(fontSize: 14)
              ),
              //modo dinamico per mettere le stelline al rifugio
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${local.mood_trekking_label}: ', 
                style: TextStyle(fontSize: 14)
              ),
              // fai come le challenges
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                '${local.notes_trekking_label}: ', 
                style: TextStyle(fontSize: 14)
              ),
              // prendi da database
            ],
          ),
        ],
      ),
    );
  }
}
