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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        institutionName = 'No user logged in';
        isLoading = false;
      });
      return;
    }

    final userId = user.uid;

    try {
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
        title: Text('Welcome'),
        centerTitle: false,
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
                  MaterialPageRoute(builder: (context) => Camera()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('Used Tickets'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Camera'),
              ),
            ],
          ),
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

