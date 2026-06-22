import 'package:flutter/material.dart';

import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import 'new_order_screen.dart';

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});

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
                title: 'Restaurant Orders',
                subtitle: 'Manage today’s table orders',
              ),
              const SizedBox(height: 28),
              const Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: EmptyStateCard(
                    icon: Icons.receipt_long_outlined,
                    message: 'No orders yet',
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
              builder: (context) => const NewOrderScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }
}
