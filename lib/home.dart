import 'package:flutter/material.dart';
import 'camera.dart';
import 'used_tickets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> activeTickets = [];
  final String backendUrl = "http://192.168.0.163:5001";

  @override
  void initState() {
    super.initState();
    institutionName = widget.institutionName;
    fetchActiveTickets();
  }

  Future<void> fetchActiveTickets() async {
    final uri = Uri.parse('$backendUrl/get_active_tickets');
    final payload = jsonEncode({'institution_id': widget.institutionId});

    try {
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'}, body: payload);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List<dynamic> ticketsRaw = data['tickets'] ?? [];
        setState(() {
          activeTickets = ticketsRaw.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching active tickets: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> t) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t['name'] ?? 'Unnamed Ticket',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if ((t['description'] as String?)?.isNotEmpty == true)
              Text(
                t['description']!,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(t['event_time'] ?? t['created_at']),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $institutionName!'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Active Tickets',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: activeTickets.length,
                    itemBuilder: (context, i) {
                      return _buildTicketCard(activeTickets[i]);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsedTicketsPage(
                      institutionId: widget.institutionId,
                    ),
                  ),
                );
              },
              child: const Text('Used Tickets'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Camera(
                      institution_id: widget.institutionId,
                    ),
                  ),
                );
              },
              child: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}

