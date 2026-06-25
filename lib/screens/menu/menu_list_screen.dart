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
  static const _allCategory = 'All';
  static const _categories = [
    _allCategory,
    'Main Dish',
    'Drink',
    'Dessert',
    'Side Dish',
    'Other',
  ];

  late final MenuService _menuService;
  late Stream<List<RestaurantMenuItem>> _menuItemsStream;
  MenuSeedService? _menuSeedService;
  final Set<String> _updatingAvailabilityIds = {};
  String _selectedCategory = _allCategory;

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
    final initialCategory = item == null && _selectedCategory != _allCategory
        ? _selectedCategory
        : null;
    final result = await Navigator.push<MenuFormResult>(
      context,
      MaterialPageRoute<MenuFormResult>(
        builder: (context) => MenuFormScreen(
          item: item,
          initialCategory: initialCategory,
          menuService: _menuService,
        ),
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

                    final filteredItems = _filteredItems(items);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MenuCategoryFilters(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          counts: _MenuCategoryCounts.fromItems(items),
                          onSelected: (category) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: filteredItems.isEmpty
                              ? _MenuFilteredEmptyState(
                                  category: _selectedCategory,
                                  onAddItem: () => _openMenuForm(),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  itemCount: filteredItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];
                                    return MenuItemCard(
                                      item: item,
                                      availabilityLoading:
                                          _updatingAvailabilityIds.contains(
                                            item.id,
                                          ),
                                      onAvailabilityChanged: (value) =>
                                          _updateAvailability(item, value),
                                      onEdit: () => _openMenuForm(item),
                                      onDelete: () => _confirmDelete(item),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  List<RestaurantMenuItem> _filteredItems(List<RestaurantMenuItem> items) {
    if (_selectedCategory == _allCategory) {
      return items;
    }

    return items
        .where((item) => item.category == _selectedCategory)
        .toList(growable: false);
  }
}

class _MenuCategoryCounts {
  const _MenuCategoryCounts(this._counts);

  factory _MenuCategoryCounts.fromItems(List<RestaurantMenuItem> items) {
    final counts = <String, int>{
      _MenuListScreenState._allCategory: items.length,
    };
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return _MenuCategoryCounts(counts);
  }

  final Map<String, int> _counts;

  int forCategory(String category) => _counts[category] ?? 0;
}

class _MenuCategoryFilters extends StatelessWidget {
  const _MenuCategoryFilters({
    required this.categories,
    required this.selectedCategory,
    required this.counts,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final _MenuCategoryCounts counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          for (final category in categories) ...[
            if (category != categories.first) const SizedBox(width: 8),
            FilterChip(
              label: Text('$category ${counts.forCategory(category)}'),
              selected: selectedCategory == category,
              onSelected: (_) => onSelected(category),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              checkmarkColor: colorScheme.onPrimary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelStyle: TextStyle(
                color: selectedCategory == category
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: selectedCategory == category
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
              side: BorderSide(
                color: selectedCategory == category
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
            ),
          ],
        ],
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

class _MenuFilteredEmptyState extends StatelessWidget {
  const _MenuFilteredEmptyState({
    required this.category,
    required this.onAddItem,
  });

  final String category;
  final VoidCallback onAddItem;

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
                Icons.filter_alt_off_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'No $category items',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add a new item to this category when it is ready.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: Text('Add $category Item'),
              ),
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
