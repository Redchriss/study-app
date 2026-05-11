import 'package:flutter/material.dart';

class ScannerResultsScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  const ScannerResultsScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final solutions = (sessionData['solutions'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Solutions')),
      body: solutions.isEmpty
          ? const Center(child: Text('No solutions available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: solutions.length,
              itemBuilder: (_, i) {
                final sol = solutions[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${sol['questionNumber']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(sol['questionText'] ?? ''),
                        const Divider(height: 24),
                        ...(sol['steps'] as List? ?? []).asMap().entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 12, child: Text('${e.key + 1}', style: const TextStyle(fontSize: 11))),
                                const SizedBox(width: 8),
                                Expanded(child: Text(e.value)),
                              ],
                            ),
                          ),
                        ),
                        if (sol['answer'] != null && sol['answer'] != 'N/A') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Answer: ${sol['answer']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
