import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';  // add intl: ^0.17.0 to pubspec.yaml

class UsedTicketsPage extends StatefulWidget {
  final String institutionId;
  const UsedTicketsPage({Key? key, required this.institutionId})
      : super(key: key);

  @override
  State<UsedTicketsPage> createState() => _UsedTicketsPageState();
}

class _UsedTicketsPageState extends State<UsedTicketsPage> {
  List<Map<String, dynamic>> usedTickets = [];
  bool isLoading = true;

  // point this at your real backend/server IP & port
  final String backendUrl = "http://192.168.0.163:5001";

  @override
  void initState() {
    super.initState();
    fetchUsedTickets();
  }

  Future<void> fetchUsedTickets() async {
    setState(() => isLoading = true);

    final uri = Uri.parse('$backendUrl/get_used_tickets');
    final payload = jsonEncode({
      'institution_id': widget.institutionId,
    });

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic> ticketsRaw = data['tickets'] ?? [];

        setState(() {
          usedTickets =
              ticketsRaw.cast<Map<String, dynamic>>().toList(growable: false);
        });
      } else {
        debugPrint('Failed to load used tickets: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    } finally {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Used Tickets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUsedTickets,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : usedTickets.isEmpty
              ? const Center(
                  child: Text(
                    'No used tickets found.',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    itemCount: usedTickets.length,
                    itemBuilder: (context, i) {
                      final t = usedTickets[i];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ticket name
                              Text(
                                t['name'] ?? 'Unnamed Ticket',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Description
                              if ((t['description'] as String?)?.isNotEmpty ==
                                  true)
                                Text(
                                  t['description']!,
                                  style: const TextStyle(fontSize: 16),
                                ),

                              const SizedBox(height: 12),

                              // Usage info row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event_available,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(t['last_accessed'] ??
                                            t['created_at']),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'USED',
                                      style: TextStyle(
                                        color: Colors.red,
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
                    },
                  ),
                ),
    );
  }
}
