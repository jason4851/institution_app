import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsedTicketsPage extends StatefulWidget {
  const UsedTicketsPage({super.key});

  @override
  _UsedTicketsPageState createState() => _UsedTicketsPageState();
}

class _UsedTicketsPageState extends State<UsedTicketsPage> {
  List<Map<String, dynamic>> usedTickets = [];
  bool isLoading = true;

  final String backendUrl = "http://127.0.0.1:5001"; // your backend IP

  @override
  void initState() {
    super.initState();
    fetchUsedTickets();
  }

  Future<void> fetchUsedTickets() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$backendUrl/get_used_tickets'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ticketsRaw = data['used_tickets'];

        setState(() {
          usedTickets = ticketsRaw.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        print('Failed to load used tickets. Code: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching tickets: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Used Tickets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchUsedTickets, // Call API again on tap
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : usedTickets.isEmpty
              ? Center(
                  child: Text(
                    'No used tickets found.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: usedTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = usedTickets[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: ListTile(
                        leading: Icon(Icons.confirmation_num, color: Colors.grey),
                        title: Text(ticket['name'] ?? 'Unknown Ticket'),
                        subtitle: Text('Ticket ID: ${ticket['ticket_id'] ?? 'N/A'}'),
                        trailing: Text(
                          'Used',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}


