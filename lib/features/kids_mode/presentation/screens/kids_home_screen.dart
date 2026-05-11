import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme/app_colors.dart';

class KidsHomeScreen extends StatelessWidget {
  const KidsHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yaza Kids'),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => context.go('/profile')),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _KidCard(icon: Icons.auto_stories, label: 'Read', color: Colors.blue),
          _KidCard(icon: Icons.quiz_outlined, label: 'Quiz', color: Colors.green),
          _KidCard(icon: Icons.mic, label: 'Spell', color: Colors.orange),
          _KidCard(icon: Icons.star, label: 'Games', color: Colors.purple),
        ].map((c) => GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon!'))),
          child: Container(
            decoration: BoxDecoration(
              color: c.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(c.icon, size: 48, color: c.color),
                const SizedBox(height: 12),
                Text(c.label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.color)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _KidCard {
  final IconData icon;
  final String label;
  final Color color;
  _KidCard({required this.icon, required this.label, required this.color});
}
