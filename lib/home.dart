import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:institution_app/camera.dart';
import 'package:institution_app/used_tickets';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String institutionName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInstitutionDetails();
  }

  Future<void> fetchInstitutionDetails() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Directly look inside "institutions" collection for current logged-in institution
      final institutionSnapshot = await FirebaseFirestore.instance
          .collection('institutions')
          .doc(userId)
          .get();

      if (institutionSnapshot.exists) {
        setState(() {
          institutionName = institutionSnapshot['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          institutionName = 'Institution not found';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching institution: $e');
      setState(() {
        institutionName = 'Error loading institution';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: Text('Institution Home'),
  centerTitle: true,
  actions: [
    PopupMenuButton<int>(
      onSelected: (value) {
        if (value == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UsedTicketsPage()),
          );
        } else if (value == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Camera()),// will get replaced with blink detection
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Text('Go to Page One'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Go to Page Two'),
        ),
      ],
    )
  ],
),

      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    institutionName,
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
      ),
    );
  }
}
