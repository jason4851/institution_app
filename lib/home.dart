import 'package:flutter/material.dart';
import 'camera.dart';
import 'used_tickets.dart';

class HomePage extends StatefulWidget {
  final String institutionId;
  final String institutionName;

  const HomePage({
    Key? key,
    required this.institutionId,
    required this.institutionName,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String institutionName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // simply use the name you passed in
    institutionName = widget.institutionName;
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // show hello in the app bar
        title: Text('Hello, $institutionName!'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // big greeting up front
                  Text(
                    'Hello, $institutionName!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 40),

                  // you can still show other UI below
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UsedTicketsPage(),
                        ),
                      );
                    },
                    child: Text('View Used Tickets'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Camera(),
                        ),
                      );
                    },
                    child: Text('Open Camera'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

