import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:triplo/model/user.dart';
import 'package:triplo/pages/adding-diary-page.dart';
import '../controller/trekking.dart';
import '../controller/user.dart';
import '../controller/diary.dart';

class TrekkingPage extends StatefulWidget {
  final TrekkingController trekkingController;
  final UserController userController;
  final DiaryController diaryController;
  final String trekkingId;
  final void Function(Locale) onLocaleChanged;

  TrekkingPage({
    super.key,
    required this.trekkingController,
    required this.userController,
    required this.diaryController,
    required this.trekkingId,
    required this.onLocaleChanged,
  });

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  // Icons for the bookmark button (unsaved and saved) --> 0:not saved, 1:saved
  final List<Icon> icons = [Icon(Icons.bookmark_border), Icon(Icons.bookmark)];

  final titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  final labelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600, // semibold
    color: Colors.black87,
  );

  final valueStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: const Color.fromARGB(255, 0, 0, 0),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final trekking = widget.trekkingController.getTrekkingById(
      widget.trekkingId,
    )!;

    // To calculate the trekking durantion time
    String formattedTime;
    if (trekking.estimated_time < 60) {
      formattedTime =
          "${trekking.estimated_time} ${local.minutes_trekking_label}";
    } else {
      if (trekking.estimated_time % 60 == 0) {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time / 60} ${local.hour_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time / 60} ${local.hours_trekking_label}";
        }
      } else {
        if (trekking.estimated_time / 60 == 1) {
          formattedTime =
              "${trekking.estimated_time / 60} ${local.hour_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}";
        } else {
          formattedTime =
              "${trekking.estimated_time / 60} ${local.hours_trekking_label} ${trekking.estimated_time % 60} ${local.minutes_trekking_label}";
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name),
        centerTitle: true, // Forced center the title
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AddingDiaryPage(
                    trekkingId: trekking.documentId,
                    trekkingController: widget.trekkingController,
                    diaryController: widget.diaryController,
                    userController: widget.userController,
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),

          FutureBuilder<Users?>(
            future: widget.userController.getUserById(
              'Aqcz7x94WnPJNYpb48CtuzMbsMj1',
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.shrink();
              }

              final user = snapshot.data!;

              final isSaved = user.savedTrekkings.any(
                (t) => t.documentId == trekking.documentId,
              );

              return isSaved
                  ? IconButton(
                      icon: icons[1],
                      onPressed: () {
                        setState(() {
                          widget.userController.removeTrekkingFromSaved(
                            trekking.documentId,
                          );
                        });
                      },
                    )
                  : IconButton(
                      icon: icons[0],
                      onPressed: () {
                        setState(() {
                          widget.userController.addTrekkingToSaved(
                            trekking.documentId,
                          );
                        });
                      },
                    );
            },
          ),

          /*if (user.savedTrekkings.any((t) => t.documentId == trekking.documentId,)) ...[
            IconButton(
              icon: icons[1],
              onPressed: () {
                setState(() {
                  widget.userController.removeTrekkingFromSaved(
                    trekking.documentId,
                  );
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: icons[0],
              onPressed: () {
                setState(() {
                  widget.userController.addTrekkingToSaved(trekking.documentId);
                });
              },
            ),
          ],*/
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //placeholder dell'immagine del percorso (facciamo lo screen)
              Row(),
              Row(
                children: [
                  Text(
                    trekking.name, 
                    style: titleStyle
                  )
                ]
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.starting_point_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Text(
                      trekking.starting_point_name,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.level_label}: ", 
                    style: labelStyle
                  ),
                  Expanded(
                    child: Text(
                      trekking.difficulty_level,
                      style: valueStyle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.distance_trekking_label}: ", 
                    style: labelStyle
                  ),
                  Expanded(
                    child: Text(
                      "${trekking.distance} km", 
                      style: valueStyle
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.estimated_time_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Text(
                      formattedTime, 
                      style: valueStyle
                    )
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.elevaition_gain_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${trekking.elevation_gain} m",
                          style: valueStyle,
                        ),
                        if (trekking.upGain)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_upward, size: 16, color: Colors.black),
                          ),
                        if (trekking.downGain)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.arrow_downward, size: 16, color: Colors.black),
                          ),
                      ]
                    )
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.ending_point_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.ending_point_name,
                      style: valueStyle,
                    )
                  ]
                )
              ),
              /*Row(
                children: [
                  Text(
                    "${local.ending_point_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Text(
                      trekking.ending_point_name,
                      style: valueStyle,
                    )
                  )
                ],
              ),*/
              //immagine ending point
              Row(),
              SizedBox(height: 3,),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.info_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.info[getLanguageSelected(locale.languageCode)],
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3,),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "${local.description_trekking_label}: ",
                      style: labelStyle,
                    ),
                    TextSpan(
                      text: trekking.description[getLanguageSelected(locale.languageCode)],
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.refreshment_point_trekking_label}: ",
                    style: labelStyle,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trekking.refreshment_point != '') ...[
                          Text(
                            trekking.refreshment_point,
                            style: valueStyle,
                          ),
                        ] else ...[
                          Text(
                            local.refreshment_point_available_trekking_label,
                            style: valueStyle,
                          ),
                        ],
                      ]
                    )
                  ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.pic_nic_area_trekking_label}: ", 
                    style: labelStyle,
                  ),
                  if (trekking.pic_nic_area)
                    Icon(Icons.table_restaurant, color: Colors.black, size: 16)
                  else
                    Text(
                      local.pic_nic_area_available_trekking_label, 
                      style: labelStyle,
                    ),
                ],
              ),
              SizedBox(height: 3,),
              Row(
                children: [
                  Text(
                    "${local.family_friendly_trekking_label}: ", 
                    style: labelStyle,
                  ),
                  if (trekking.family_firendly)
                    Icon(Icons.family_restroom, color: Colors.black, size: 16)
                  else
                    Text(
                      local.family_friendly_available_trekking_label, 
                      style: labelStyle,
                    ),
                ],
              ),
              SizedBox(height: 3,),
              if (trekking.challenges.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${local.challenges_trekking_label}:", 
                      style: labelStyle
                    ),
                    SizedBox(
                      height: 50, // altezza della riga immagini
                      child: FutureBuilder<List<String>>(
                        future: widget.trekkingController.getDownloadUrls(
                          trekking.challenges,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text('Errore: ${snapshot.error}');
                          } else {
                            List<String> urls = snapshot.data!;
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: urls.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Image.network(
                                    urls[index],
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Text(
                      "${local.challenges_trekking_label}: ",
                      style: labelStyle,
                    ),
                    Expanded(
                      child: Text(
                        local.challenges_available_trekking_label,
                        style: valueStyle
                      ) 
                    )
                  ]
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int getLanguageSelected(String code) {
  switch (code) {
    case 'de': 
      return 0;
    case 'en': 
      return 1;
    case 'es': 
      return 2;
    case 'fr':
      return 3;
    case 'it': 
      return 4;

    default: return 1; 
  }
}

/* TO DO: capire se serve Text.rich oppure una semplice Row -> TextRich va a capo
incolonnato sotto il label mentre Row + Expanded va a capo ma non incolanna sotto 
il label ma sotto il value -> va capito su tutte le righe (anche sulle icone per i non available*/

