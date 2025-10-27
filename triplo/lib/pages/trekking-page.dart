import 'package:flutter/material.dart';
import 'package:flutter/src/material/icons.dart';

class TrekkingPage extends StatefulWidget {
  final String routeName;

  TrekkingPage({super.key, required this.routeName});

  @override
  _TrekkingPageState createState() => _TrekkingPageState();
}

class _TrekkingPageState extends State<TrekkingPage> {
  int currentIconIndex = 0;
  bool isFamFriendly = true;
  bool isPicnicable = true;

  final List<Icon> icons = [
    Icon(Icons.bookmark_border),
    Icon(Icons.bookmark)
  ];

  @override
  Widget build(BuildContext context) {
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
                children: [
                  Text("Starting Point: XYZ")
                ],
              ),
              Row(
                children: [
                  Text("Level: Medium"),
                ],
              ),
              Row(
                children: [
                  Text("Distance: 10 km"),
                ],
              ),
              Row(
              children: [
                Text("Estimated Time: 3 hours"),
                ],
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Elevation Gain: 500 m  ',
                          style: TextStyle(color: Colors.black),
                        ),
                        //da capire dai dati 
                        WidgetSpan(
                          child: Icon(Icons.arrow_upward, size: 16),
                        ),
                        WidgetSpan(
                          child: Icon(Icons.arrow_downward, size: 16),
                        ),
                      ],
                    ),
                    ),
                ],
              ),
              Row(
                children: [
                  Text("Ending Point: ABC"),
                ],
              ),
              //immagine ending point
              Row(),
              Row(
                children: [
                  Text("Info: Beautiful trek with scenic views."),
                ]
              ),
              Row(
                children: [
                  Text("Description"), // da prendere da DB
                ],
              ),
              Row(
                children: [
                  Text("Ristors Points"), // non sarà un text, ma sarà interattivo
                ],
              ),
              Row(
                children: [
                  Text("Picnic"), // sarà un true o false
                ],
              ),
              Row(
                children: [
                  Text("Adapt to famiglis"), // sarà un true o false
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
