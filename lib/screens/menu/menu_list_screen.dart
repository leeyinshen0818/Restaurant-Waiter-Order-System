import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/restaurant_menu_item.dart';
import '../../services/menu_seed_service.dart';
import '../../services/menu_service.dart';
import '../../widgets/menu_item_card.dart';
import '../../widgets/screen_header.dart';
import 'menu_form_screen.dart';

class MenuListScreen extends StatefulWidget {
  const MenuListScreen({this.menuService, super.key});

  final MenuService? menuService;

  @override
  State<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends State<MenuListScreen> {
  late final MenuService _menuService;
  late Stream<List<RestaurantMenuItem>> _menuItemsStream;
  MenuSeedService? _menuSeedService;
  final Set<String> _updatingAvailabilityIds = {};

  @override
  void initState() {
    super.initState();
    _menuService = widget.menuService ?? MenuService();
    _menuItemsStream = _menuService.watchMenuItems();
  }

  void _retryLoading() {
    setState(() {
      _menuItemsStream = _menuService.watchMenuItems();
    });
  }

  Future<void> _openMenuForm([RestaurantMenuItem? item]) async {
    final result = await Navigator.push<MenuFormResult>(
      context,
      MaterialPageRoute<MenuFormResult>(
        builder: (context) =>
            MenuFormScreen(item: item, menuService: _menuService),
      ),
    );

    if (!mounted || result != MenuFormResult.saved) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item == null
              ? 'Menu item added successfully.'
              : 'Menu item updated successfully.',
        ),
      ),
    );
  }

  Future<void> _updateAvailability(
    RestaurantMenuItem item,
    bool available,
  ) async {
    if (_updatingAvailabilityIds.contains(item.id)) {
      return;
    }

    setState(() {
      _updatingAvailabilityIds.add(item.id);
    });

    try {
      await _menuService.updateAvailability(item.id, available);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} is now ${available ? 'available' : 'unavailable'}.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update availability.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingAvailabilityIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _confirmDelete(RestaurantMenuItem item) async {
    final result = await showDialog<_DeleteResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _DeleteMenuItemDialog(item: item, menuService: _menuService),
    );

    if (!mounted || result == null || result == _DeleteResult.cancelled) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == _DeleteResult.deleted
              ? 'Menu item deleted successfully.'
              : 'Unable to delete the menu item. Please try again.',
        ),
      ),
    );
  }

  Future<void> _confirmSeedMenu() async {
    final result = await showDialog<_SeedResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SeedMenuDialog(
        menuSeedService: _menuSeedService ??= MenuSeedService(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final message = switch (result) {
      _SeedResult.seeded =>
        '${MenuSeedService.sampleMenuItems.length} sample menu items '
            'added successfully.',
      _SeedResult.skipped =>
        'Sample menu was not added because menu items already exist.',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<RestaurantMenuItem>>(
                  stream: _menuItemsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _MenuErrorState(onRetry: _retryLoading);
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _MenuLoadingState();
                    }

                    final items = snapshot.data ?? const <RestaurantMenuItem>[];
                    if (items.isEmpty) {
                      return _MenuEmptyState(
                        onAddItem: () => _openMenuForm(),
                        onLoadSampleMenu: kDebugMode ? _confirmSeedMenu : null,
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return MenuItemCard(
                          item: item,
                          availabilityLoading: _updatingAvailabilityIds
                              .contains(item.id),
                          onAvailabilityChanged: (value) =>
                              _updateAvailability(item, value),
                          onEdit: () => _openMenuForm(item),
                          onDelete: () => _confirmDelete(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMenuForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Menu Item'),
      ),
    );
  }
}

class _MenuLoadingState extends StatelessWidget {
  const _MenuLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading menu items...'),
        ],
      ),
    );
  }
}

class _MenuEmptyState extends StatelessWidget {
  const _MenuEmptyState({required this.onAddItem, this.onLoadSampleMenu});

  final VoidCallback onAddItem;
  final VoidCallback? onLoadSampleMenu;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No menu items yet',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first food or drink item to begin.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Menu Item'),
              ),
              if (onLoadSampleMenu != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onLoadSampleMenu,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Load Sample Menu'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuErrorState extends StatelessWidget {
  const _MenuErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load menu items.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SeedResult { seeded, skipped }

class _SeedMenuDialog extends StatefulWidget {
  const _SeedMenuDialog({required this.menuSeedService});

  final MenuSeedService menuSeedService;

  @override
  State<_SeedMenuDialog> createState() => _SeedMenuDialogState();
}

class _SeedMenuDialogState extends State<_SeedMenuDialog> {
  bool _isSeedingMenu = false;

  Future<void> _seedMenu() async {
    if (_isSeedingMenu) {
      return;
    }

    setState(() {
      _isSeedingMenu = true;
    });

    try {
      await widget.menuSeedService.seedMenuIfEmpty();
      if (!mounted) {
        return;
      }
      Navigator.pop(context, _SeedResult.seeded);
    } on MenuSeedSkippedException {
      if (!mounted) {
        return;
      }
      Navigator.pop(context, _SeedResult.skipped);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSeedingMenu = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load the sample menu. '
            'Please check your connection and try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load Sample Menu?'),
      content: const Text(
        'This will add 15 sample food and drink items to the empty menu '
        'for development and testing.',
      ),
      actions: [
        TextButton(
          onPressed: _isSeedingMenu ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSeedingMenu ? null : _seedMenu,
          child: _isSeedingMenu
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Load Menu'),
        ),
      ],
    );
  }
}

enum _DeleteResult { cancelled, deleted, failed }

class _DeleteMenuItemDialog extends StatefulWidget {
  const _DeleteMenuItemDialog({required this.item, required this.menuService});

  final RestaurantMenuItem item;
  final MenuService menuService;

  @override
  State<_DeleteMenuItemDialog> createState() => _DeleteMenuItemDialogState();
}

class _DeleteMenuItemDialogState extends State<_DeleteMenuItemDialog> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) {
      return;
    }

    setState(() {
      _deleting = true;
    });

    try {
      await widget.menuService.deleteMenuItem(widget.item.id);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, _DeleteResult.deleted);
    } catch (_) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context, _DeleteResult.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('Delete Menu Item?'),
      content: Text(
        'Are you sure you want to delete ${widget.item.name}?\n\n'
        'Historical orders will not be affected because they store item name '
        'and price snapshots.',
      ),
      actions: [
        TextButton(
          onPressed: _deleting
              ? null
              : () => Navigator.pop(context, _DeleteResult.cancelled),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: errorColor,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _deleting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
