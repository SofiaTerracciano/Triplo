import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:flutter/src/material/icons.dart';
import '../controller/trekking.dart';
import '../model/trekking.dart';
import 'adding-diary-page.dart';

class TrekkingPage extends StatefulWidget {
  final Trekking trekking;
  final void Function(Locale) onLocaleChanged;

  TrekkingPage({
    super.key,
    required this.trekking,
    required this.onLocaleChanged,
  });

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  int currentIconIndex = 0;
  bool isFamFriendly = true;
  bool isPicnicable = true;
  

  final List<Icon> icons = [Icon(Icons.bookmark_border), Icon(Icons.bookmark)];

  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context); 
    final trekking = widget.trekking;

    return Scaffold(
      appBar: AppBar(
        title: Text(trekking.name),
        centerTitle: true, // Forced center the title
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => AddingDiaryPage(trekking: widget.trekking, onLocaleChanged: widget.onLocaleChanged,),
              ));
            },
          ),
          IconButton(
            icon: icons[currentIconIndex],
            onPressed: () {
              setState(() {
                if (currentIconIndex == 0) {
                  currentIconIndex = 1;
                  //add to saved trekkings
                } else {
                  currentIconIndex = 0;
                  //remove from saved trekkings
                }
              });
            },
          ),
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
                    "${local.starting_point_trekking_label}: ${trekking.starting_point_name}"),
                ],
              ),
              Row(children: [Text("${local.level_label}: ${trekking.difficulty_level}")]),
              Row(children: [Text("${local.distance_trekking_label}: ${trekking.distance} km")]),
              Row(
                children: [
                  Text("${local.estimated_time_trekking_label}: ${trekking.estimated_time/60} hours ${trekking.estimated_time%60} minutes"),
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${local.elevaition_gain_trekking_label}: ${trekking.elevation_gain} m  ',
                          style: TextStyle(color: Colors.black),
                        ),
                        if (trekking.upGain)
                          WidgetSpan(child: Icon(Icons.arrow_upward, size: 16)),
                        if (trekking.downGain)
                          WidgetSpan(child: Icon(Icons.arrow_downward, size: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [Text("${local.ending_point_trekking_label}: ${trekking.ending_point_name}")],
              ),
              //immagine ending point
              Row(),
              Row(
                children: [
                  if (locale.languageCode == 'de')
                    Text(
                      "${local.info_trekking_label}: ${trekking.info[0]}",
                    ),
                  if (locale.languageCode == 'en')
                    Text(
                      "${local.info_trekking_label}: ${trekking.info[1]}",
                    ),
                  if (locale.languageCode == 'es')
                    Text(
                      "${local.info_trekking_label}: ${trekking.info[2]}",
                    ),
                  if (locale.languageCode == 'fr')
                    Text(
                      "${local.info_trekking_label}: ${trekking.info[3]}",
                    ),
                  if (locale.languageCode == 'it')
                    Text(
                      "${local.info_trekking_label}: ${trekking.info[4]}",
                    ),
                ],
              ),
              Row(
                children: [
                  if (locale.languageCode == 'de')
                    Text(
                      "${local.description_trekking_label}: ${trekking.description[0]}",
                    ),
                  if (locale.languageCode == 'en')  
                    Text(
                      "${local.description_trekking_label}: ${trekking.description[1]}",
                    ),
                  if (locale.languageCode == 'es')  
                    Text(
                      "${local.description_trekking_label}: ${trekking.description[2]}",
                    ),
                  if (locale.languageCode == 'fr')    
                    Text(
                      "${local.description_trekking_label}: ${trekking.description[3]}",
                    ),
                  if (locale.languageCode == 'it')      
                    Text(
                      "${local.description_trekking_label}: ${trekking.description[4]}",
                    ),
                ],
              ),
              Row(
                children: [
                  if (trekking.refreshment_point != "null")
                  Text(
                    "${local.refreshment_point_trekking_label}: ${trekking.refreshment_point}",
                  ), 
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.pic_nic_area_trekking_label}:",
                  ), 
                  if (trekking.pic_nic_area)
                    Icon(
                      Icons.table_restaurant,
                      color: Colors.grey,
                      size: 16,
                    )
                  else
                    Icon(
                      Icons.close,
                      size: 16,
                    ),
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.family_friendly_trekking_label}:",
                  ),
                  if (trekking.family_firendly)
                    Icon(
                      Icons.family_restroom,
                      color: Colors.grey,
                      size: 16,
                    )
                  else
                    Icon(
                      Icons.close,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
