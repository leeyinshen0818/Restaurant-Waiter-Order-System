import 'package:flutter/material.dart';

import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import 'menu_form_screen.dart';

class MenuListScreen extends StatelessWidget {
  const MenuListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(
                title: 'Restaurant Menu',
                subtitle: 'Manage food and drink items',
              ),
              const SizedBox(height: 28),
              const Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: EmptyStateCard(
                    icon: Icons.restaurant_menu_outlined,
                    message: 'No menu items yet',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const MenuFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Menu Item'),
      ),
    );
  }
}
