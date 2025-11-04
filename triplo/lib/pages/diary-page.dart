import 'package:flutter/material.dart';
import 'package:flutter/src/material/icons.dart';

class DiaryPage extends StatefulWidget {
  final String routeName;

  DiaryPage({super.key, required this.routeName});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        centerTitle: true, 
      ),
      
      body: ListView(
        padding: const EdgeInsets.all(25.0),
        children: [
          // Profile info + avatar
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
                          'Username: ',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),

                    // Date
                    const Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 8.0),
                      child: Text(
                        'Date: ', // da prendere dal database
                      ),
                    ),

                    // How much time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration: ',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    
                    // Friends
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'Friends: ',
                          style: TextStyle(fontSize: 14),
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

          const SizedBox(height: 20),

          // Other information about the trekking
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Images: ', 
                style: TextStyle(fontSize: 14)
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // orizontal scroll
            child: Row(
              children: [ // sarà da prendere in modo dinamico
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg',
                  width: 150, 
                  height: 100),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
                SizedBox(width: 8),
                Image.asset(
                  'images/prova.jpeg', 
                  width: 150, 
                  height: 100
                ),
              ],
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Challenges: ', 
                style: TextStyle(fontSize: 14)
                ),
              // fai json in cui metti path dell'immagine della sfida e descrzione della sfida
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Refuge: ', 
                style: TextStyle(fontSize: 14)
              ),
             //modo dinamico per mettere le stelline al rifugio
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Mood: ', 
                style: TextStyle(fontSize: 14)
              ),
              // fai come le challenges
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Notes: ', 
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
