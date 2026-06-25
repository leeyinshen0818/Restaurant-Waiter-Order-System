import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/restaurant_menu_item.dart';
import '../../services/menu_service.dart';

enum MenuFormResult { saved }

class MenuFormScreen extends StatefulWidget {
  const MenuFormScreen({
    this.item,
    this.initialCategory,
    this.menuService,
    super.key,
  });

  final RestaurantMenuItem? item;
  final String? initialCategory;
  final MenuService? menuService;

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  static const List<String> _categories = [
    'Main Dish',
    'Drink',
    'Dessert',
    'Side Dish',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final MenuService _menuService;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  String? _selectedCategory;
  late bool _available;
  bool _saving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _menuService = widget.menuService ?? MenuService();
    _nameController = TextEditingController(text: item?.name ?? '');
    _priceController = TextEditingController(
      text: item == null ? '' : item.price.toStringAsFixed(2),
    );
    final initialCategory = widget.initialCategory;
    _selectedCategory = item != null && _categories.contains(item.category)
        ? item.category
        : initialCategory != null && _categories.contains(initialCategory)
        ? initialCategory
        : null;
    _available = item?.available ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Please enter the item name.';
    }
    if (name.length > 80) {
      return 'Item name is too long.';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Please enter the price.';
    }

    final price = double.tryParse(input);
    if (price == null || !price.isFinite) {
      return 'Please enter a valid price.';
    }
    if (price <= 0) {
      return 'Price must be greater than RM 0.00.';
    }
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final existingItem = widget.item;
    final item = RestaurantMenuItem(
      id: existingItem?.id ?? '',
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _selectedCategory!,
      available: _available,
      createdAt: existingItem?.createdAt,
      updatedAt: existingItem?.updatedAt,
    );

    try {
      if (_isEditing) {
        await _menuService.updateMenuItem(item);
      } else {
        await _menuService.addMenuItem(item);
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context, MenuFormResult.saved);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Unable to update the menu item. Please try again.'
                : 'Unable to add the menu item. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Text(
                _isEditing
                    ? 'Update this menu item’s details and availability.'
                    : 'Add a food or drink item to the restaurant menu.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Chicken Burger',
                  prefixIcon: Icon(Icons.restaurant_outlined),
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: '0.00',
                  prefixText: 'RM ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                validator: _validateCategory,
              ),
              const SizedBox(height: 18),
              Card(
                child: SwitchListTile(
                  value: _available,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _available = value;
                          });
                        },
                  title: const Text('Available'),
                  subtitle: Text(
                    _available
                        ? 'Waiters can add this item to new orders.'
                        : 'This item remains in the menu but cannot be ordered.',
                  ),
                  secondary: Icon(
                    _available
                        ? Icons.check_circle_outline
                        : Icons.pause_circle_outline,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _saving
                      ? const SizedBox.square(
                          key: ValueKey('saving'),
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Menu Item' : 'Save Menu Item',
                          key: const ValueKey('label'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
