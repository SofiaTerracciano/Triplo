import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/l10n/app_localizations_de.dart';
import 'package:triplo/l10n/app_localizations_it.dart';
import 'package:triplo/l10n/app_localizations_en.dart';
import 'package:triplo/l10n/app_localizations_fr.dart';
import 'package:triplo/l10n/app_localizations_es.dart';
import 'package:flutter/src/material/icons.dart';

class TrekkingPage extends StatefulWidget {
  final String routeName;
  final void Function(Locale) onLocaleChanged;

  TrekkingPage({
    super.key,
    required this.routeName,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        centerTitle: true, // Forced center the title
        actions: [
          IconButton(
            icon: Icon(Icons.start),
            onPressed: () {
              // Implement start trekking functionality hereR
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
                children: [Text("${local.starting_point_trekking_label}: XYZ")],
              ),
              Row(children: [Text("${local.level_label}: Medium")]),
              Row(children: [Text("${local.distance_trekking_label}: 10 km")]),
              Row(
                children: [
                  Text("${local.estimated_time_trekking_label}: 3 hours"),
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${local.elevaition_gain_trekking_label}: 500 m  ',
                          style: TextStyle(color: Colors.black),
                        ),
                        //da capire dai dati
                        WidgetSpan(child: Icon(Icons.arrow_upward, size: 16)),
                        WidgetSpan(child: Icon(Icons.arrow_downward, size: 16)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [Text("${local.ending_point_trekking_label}: ABC")],
              ),
              //immagine ending point
              Row(),
              Row(
                children: [
                  Text(
                    "${local.info_trekking_label}: Beautiful trek with scenic views.",
                  ),
                ],
              ),
              Row(
                children: [
                  //mettere una legenda da qualche parte?
                  Icon(
                    Icons.family_restroom,
                    size: 16,
                  ), // da prendere da db --> family friendly
                  Icon(
                    Icons.table_restaurant,
                    size: 16,
                  ), // da prendere da db --> picknick area
                  Icon(
                    Icons.local_parking,
                    size: 16,
                  ), // da prendere da db --> parking
                ],
              ),
              Row(
                children: [
                  Text("${local.description_trekking_label}"), // da prendere da DB
                ],
              ),
              Row(
                children: [
                  Text(
                    "${local.refreshment_point_trekking_label}",
                  ), // non sarà un text, ma sarà interattivo
                ],
              ),
              Row(
                children: [
                  Text("${local.pic_nic_area_trekking_label}"), // sarà un true o false
                ],
              ),
              Row(
                children: [
                  Text("${local.family_friendly_trekking_label}"), // sarà un true o false
                ],
              ),
              // Add more details and widgets as needed
            ],
          ),
        ),
      ),
    );
  }
}

/*// Function to get icon based on trekking attributes
Icon trekkingIcon(Trekking t) {
  if (t.pic_nic_area) {
    return const Icon(Icons.park, color: Colors.green, size: 40);
  }
  if (t.family_firendly) {
    return const Icon(Icons.family_restroom, size: 40);
  }
}*/
