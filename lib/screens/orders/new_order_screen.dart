import 'package:flutter/material.dart';

import '../../models/order_line_item.dart';
import '../../models/order_status.dart';
import '../../models/restaurant_menu_item.dart';
import '../../models/restaurant_order.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import '../../widgets/order_cart_item.dart';
import '../../widgets/order_menu_item_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/table_selection_grid.dart';
import 'order_detail_screen.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({
    this.orderId,
    this.orderService,
    this.menuService,
    this.onGoToMenu,
    super.key,
  });

  final String? orderId;
  final OrderService? orderService;
  final MenuService? menuService;
  final VoidCallback? onGoToMenu;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  static const _maxQuantity = 99;
  static const _allCategory = 'All';
  static const _categories = [
    _allCategory,
    'Main Dish',
    'Drink',
    'Dessert',
    'Side Dish',
    'Other',
  ];

  late final OrderService _orderService;
  late final MenuService _menuService;
  late final Stream<List<RestaurantOrder>> _ordersStream;
  late final Stream<List<RestaurantMenuItem>> _availableMenuItemsStream;
  late final TextEditingController _searchController;

  int? _selectedTable;
  String _selectedCategory = _allCategory;
  bool _isSaving = false;
  bool _isLoadingEditOrder = false;
  String? _editLoadMessage;
  final Map<String, RestaurantMenuItem> _selectedItems = {};
  final Map<String, int> _selectedQuantities = {};
  final Map<String, String> _existingLineItemIds = {};
  final Set<String> _unavailableExistingItemIds = {};

  bool get _isEditMode => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _orderService = widget.orderService ?? OrderService();
    _menuService = widget.menuService ?? MenuService();
    _ordersStream = _orderService.watchOrders();
    _availableMenuItemsStream = _menuService.watchAvailableMenuItems();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    if (_isEditMode) {
      _loadOrderForEditing();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _selectTable(int tableNo) {
    setState(() {
      _selectedTable = tableNo;
    });
  }

  void _setCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _addItem(RestaurantMenuItem item) {
    setState(() {
      _selectedItems.putIfAbsent(item.id, () => item);
      _selectedQuantities[item.id] = 1;
    });
  }

  void _incrementItem(RestaurantMenuItem item) {
    if (_unavailableExistingItemIds.contains(item.id)) {
      return;
    }

    setState(() {
      _selectedItems.putIfAbsent(item.id, () => item);
      final currentQuantity = _selectedQuantities[item.id] ?? 0;
      if (currentQuantity < _maxQuantity) {
        _selectedQuantities[item.id] = currentQuantity + 1;
      }
    });
  }

  Future<void> _loadOrderForEditing() async {
    setState(() {
      _isLoadingEditOrder = true;
      _editLoadMessage = null;
    });

    try {
      final orderId = widget.orderId!;
      final order = await _orderService.getOrder(orderId);
      if (!mounted) {
        return;
      }
      if (order == null) {
        setState(() {
          _editLoadMessage = 'Order not found.';
          _isLoadingEditOrder = false;
        });
        return;
      }
      if (order.status != OrderStatus.pending) {
        setState(() {
          _editLoadMessage =
              'This order is no longer Pending and cannot be edited.';
          _isLoadingEditOrder = false;
        });
        return;
      }

      final items = await _orderService.getOrderItems(orderId);
      if (!mounted) {
        return;
      }
      if (items.isEmpty) {
        setState(() {
          _editLoadMessage = 'No order items found.';
          _isLoadingEditOrder = false;
        });
        return;
      }

      setState(() {
        _selectedTable = order.tableNo;
        for (final item in items) {
          _existingLineItemIds[item.menuItemId] = item.id;
          _selectedItems[item.menuItemId] = RestaurantMenuItem(
            id: item.menuItemId,
            name: item.nameSnapshot,
            price: item.priceSnapshot,
            category: 'Existing Item',
            available: true,
          );
          _selectedQuantities[item.menuItemId] = item.quantity;
        }
        _isLoadingEditOrder = false;
      });
    } on OrderServiceException catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _editLoadMessage =
            'This order is no longer Pending and cannot be edited.';
        _isLoadingEditOrder = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _editLoadMessage =
            'Unable to load the order for editing. Please try again.';
        _isLoadingEditOrder = false;
      });
    }
  }

  void _decrementItem(String itemId) {
    setState(() {
      final currentQuantity = _selectedQuantities[itemId] ?? 0;
      final nextQuantity = currentQuantity - 1;
      if (nextQuantity <= 0) {
        _selectedQuantities.remove(itemId);
        _selectedItems.remove(itemId);
      } else {
        _selectedQuantities[itemId] = nextQuantity;
      }
    });
  }

  Future<void> _reviewAndPlaceOrder() async {
    final tableNo = _selectedTable;
    if (tableNo == null) {
      _showMessage('Please select a table.');
      return;
    }
    if (_selectedQuantities.isEmpty) {
      _showMessage('Please add at least one menu item.');
      return;
    }
    if (_isSaving) {
      return;
    }

    final shouldPlaceOrder = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmOrderDialog(
        isEditMode: _isEditMode,
        tableNo: tableNo,
        itemCount: _selectedItemCount,
        total: _orderTotal,
        selectedItems: _cartItems,
        selectedQuantities: _selectedQuantities,
        formatPrice: _formatPrice,
      ),
    );

    if (shouldPlaceOrder == true && mounted) {
      if (_isEditMode) {
        await _updateOrder(tableNo);
      } else {
        await _placeOrder(tableNo);
      }
    }
  }

  Future<void> _updateOrder(int tableNo) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _orderService.updatePendingOrder(
        orderId: widget.orderId!,
        tableNo: tableNo,
        items: _buildOrderItems(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully.')),
      );
      Navigator.pop(context);
    } on OrderServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_friendlyEditServiceMessage(error, tableNo));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to update the order. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _placeOrder(int tableNo) async {
    setState(() {
      _isSaving = true;
    });

    var succeeded = false;
    try {
      final hasActiveOrder = await _orderService.hasActiveOrderForTable(
        tableNo,
      );
      if (hasActiveOrder) {
        _showMessage(
          'Table $tableNo already has an active order. '
          'Please select another table.',
        );
        return;
      }

      final orderId = await _orderService.createOrder(
        tableNo: tableNo,
        items: _buildOrderItems(),
      );
      succeeded = true;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order for Table $tableNo created successfully.'),
        ),
      );

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => OrderDetailScreen(
            orderId: orderId,
            orderService: _orderService,
            menuService: _menuService,
          ),
        ),
      );
    } on OrderServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_friendlyServiceMessage(error, tableNo));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        'Unable to create the order. '
        'Please check your connection and try again.',
      );
    } finally {
      if (mounted && !succeeded) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<OrderLineItem> _buildOrderItems() {
    return _selectedQuantities.entries.map((entry) {
      final item = _selectedItems[entry.key]!;
      return OrderLineItem(
        id: _existingLineItemIds[item.id] ?? '',
        orderId: widget.orderId ?? '',
        menuItemId: item.id,
        nameSnapshot: item.name,
        priceSnapshot: item.price,
        quantity: entry.value,
      );
    }).toList();
  }

  String _friendlyEditServiceMessage(OrderServiceException error, int tableNo) {
    return switch (error.failure) {
      OrderServiceFailure.invalidInput =>
        'Unable to create the order. Please review the table and items.',
      OrderServiceFailure.tableOccupied =>
        'Table $tableNo already has an active order. '
            'Please select another table.',
      OrderServiceFailure.statusChanged =>
        'This order has already changed and can no longer be edited.',
      OrderServiceFailure.itemUnavailable =>
        'One or more selected items are no longer available. '
            'Please review the order.',
      OrderServiceFailure.databaseFailure =>
        'Unable to update the order. Please try again.',
    };
  }

  String _friendlyServiceMessage(OrderServiceException error, int tableNo) {
    return switch (error.failure) {
      OrderServiceFailure.invalidInput =>
        'Unable to update the order. Please review the table and items.',
      OrderServiceFailure.tableOccupied =>
        'Table $tableNo already has an active order. '
            'Please select another table.',
      OrderServiceFailure.itemUnavailable =>
        'One or more selected items are no longer available. '
            'Please review the order.',
      OrderServiceFailure.statusChanged =>
        'Unable to create the order. '
            'Please check your connection and try again.',
      OrderServiceFailure.databaseFailure =>
        'Unable to create the order. '
            'Please check your connection and try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBackToMenuOrPreviousScreen() {
    if (widget.onGoToMenu == null) {
      Navigator.maybePop(context);
      return;
    }

    Navigator.pop(context);
    widget.onGoToMenu!();
  }

  List<RestaurantMenuItem> get _cartItems {
    return _selectedQuantities.keys
        .map((itemId) => _selectedItems[itemId])
        .nonNulls
        .toList();
  }

  int get _selectedItemCount {
    return _selectedQuantities.values.fold(0, (total, quantity) {
      return total + quantity;
    });
  }

  double get _orderTotal {
    return _selectedQuantities.entries.fold(0, (total, entry) {
      final item = _selectedItems[entry.key];
      if (item == null) {
        return total;
      }
      return total + (item.price * entry.value);
    });
  }

  bool get _canPlaceOrder {
    return _selectedTable != null && _selectedQuantities.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEditOrder) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Order')),
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading order for editing...'),
              ],
            ),
          ),
        ),
      );
    }

    final editLoadMessage = _editLoadMessage;
    if (editLoadMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Order')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 46,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editLoadMessage,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<RestaurantOrder>>(
      stream: _ordersStream,
      builder: (context, ordersSnapshot) {
        final occupiedTables = _occupiedTablesFromSnapshot(ordersSnapshot);

        return StreamBuilder<List<RestaurantMenuItem>>(
          stream: _availableMenuItemsStream,
          builder: (context, menuSnapshot) {
            final availableItemIds =
                (menuSnapshot.data ?? const <RestaurantMenuItem>[])
                    .map((item) => item.id)
                    .toSet();
            _unavailableExistingItemIds
              ..clear()
              ..addAll(
                _existingLineItemIds.keys.where(
                  (itemId) => !availableItemIds.contains(itemId),
                ),
              );

            return Scaffold(
              appBar: AppBar(
                title: Text(_isEditMode ? 'Edit Order' : 'New Order'),
              ),
              resizeToAvoidBottomInset: true,
              body: SafeArea(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    ScreenHeader(
                      title: _isEditMode ? 'Edit Order' : 'New Order',
                      subtitle: _isEditMode
                          ? 'Update the table or selected items'
                          : 'Select a table and add menu items',
                    ),
                    const SizedBox(height: 22),
                    _SectionCard(
                      title: 'Select Table',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ordersSnapshot.connectionState ==
                              ConnectionState.waiting) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 12),
                          ],
                          TableSelectionGrid(
                            tables: List.generate(20, (index) => index + 1),
                            occupiedTables: occupiedTables,
                            selectedTable: _selectedTable,
                            onTableSelected: _selectTable,
                          ),
                          if (_selectedTable != null &&
                              occupiedTables.contains(_selectedTable)) ...[
                            const SizedBox(height: 12),
                            Text(
                              'This table already has an active order.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Select Menu Items',
                      child: _MenuItemsSection(
                        snapshot: menuSnapshot,
                        selectedCategory: _selectedCategory,
                        searchController: _searchController,
                        selectedQuantities: _selectedQuantities,
                        onCategorySelected: _setCategory,
                        onAdd: _addItem,
                        onIncrement: _incrementItem,
                        onDecrement: _decrementItem,
                        onGoBack: _goBackToMenuOrPreviousScreen,
                        formatPrice: _formatPrice,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Current Order',
                      child: _CurrentOrderSection(
                        selectedItems: _cartItems,
                        selectedQuantities: _selectedQuantities,
                        onIncrement: _incrementItem,
                        onDecrement: _decrementItem,
                        unavailableExistingItemIds: _unavailableExistingItemIds,
                        formatPrice: _formatPrice,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TotalCard(
                      itemCount: _selectedItemCount,
                      total: _orderTotal,
                      formatPrice: _formatPrice,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _BottomOrderSummary(
                itemCount: _selectedItemCount,
                total: _orderTotal,
                isSaving: _isSaving,
                canPlaceOrder: _canPlaceOrder,
                onPlaceOrder: _reviewAndPlaceOrder,
                formatPrice: _formatPrice,
                buttonLabel: _isEditMode ? 'Review Changes' : null,
                savingLabel: _isEditMode ? 'Updating...' : null,
              ),
            );
          },
        );
      },
    );
  }

  Set<int> _occupiedTablesFromSnapshot(
    AsyncSnapshot<List<RestaurantOrder>> snapshot,
  ) {
    final orders = snapshot.data ?? const <RestaurantOrder>[];
    return orders
        .where(
          (order) => switch (order.status) {
            OrderStatus.pending ||
            OrderStatus.preparing ||
            OrderStatus.served => order.id != widget.orderId,
            OrderStatus.paid => false,
          },
        )
        .map((order) => order.tableNo)
        .toSet();
  }

  static String _formatPrice(double value) => 'RM ${value.toStringAsFixed(2)}';
}

class _MenuItemsSection extends StatelessWidget {
  const _MenuItemsSection({
    required this.snapshot,
    required this.selectedCategory,
    required this.searchController,
    required this.selectedQuantities,
    required this.onCategorySelected,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onGoBack,
    required this.formatPrice,
  });

  final AsyncSnapshot<List<RestaurantMenuItem>> snapshot;
  final String selectedCategory;
  final TextEditingController searchController;
  final Map<String, int> selectedQuantities;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<RestaurantMenuItem> onAdd;
  final ValueChanged<RestaurantMenuItem> onIncrement;
  final ValueChanged<String> onDecrement;
  final VoidCallback onGoBack;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load menu items',
        message: 'Please check your connection and try again.',
      );
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _LoadingState(message: 'Loading available menu items...');
    }

    final items = snapshot.data ?? const <RestaurantMenuItem>[];
    if (items.isEmpty) {
      return _MessageState(
        icon: Icons.restaurant_menu_outlined,
        title: 'No available menu items',
        message: 'Add or enable menu items before creating an order.',
        action: OutlinedButton.icon(
          onPressed: onGoBack,
          icon: const Icon(Icons.restaurant_menu_outlined),
          label: const Text('Go to Menu'),
        ),
      );
    }

    final filteredItems = _filteredItems(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search food or drinks',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.trim().isEmpty
                ? null
                : IconButton(
                    onPressed: searchController.clear,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in _NewOrderScreenState._categories) ...[
                if (category != _NewOrderScreenState._allCategory)
                  const SizedBox(width: 8),
                FilterChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  onSelected: (_) => onCategorySelected(category),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (filteredItems.isEmpty)
          const _MessageState(
            icon: Icons.search_off_outlined,
            title: 'No matching menu items',
            message: 'Try another search or category.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              final quantity = selectedQuantities[item.id] ?? 0;
              return OrderMenuItemCard(
                item: item,
                quantity: quantity,
                onAdd: () => onAdd(item),
                onIncrement: () => onIncrement(item),
                onDecrement: () => onDecrement(item.id),
                formatPrice: formatPrice,
              );
            },
          ),
      ],
    );
  }

  List<RestaurantMenuItem> _filteredItems(List<RestaurantMenuItem> items) {
    final query = searchController.text.trim().toLowerCase();

    return items.where((item) {
      final categoryMatches =
          selectedCategory == _NewOrderScreenState._allCategory ||
          item.category == selectedCategory;
      final searchMatches =
          query.isEmpty || item.name.toLowerCase().contains(query);
      return categoryMatches && searchMatches;
    }).toList();
  }
}

class _CurrentOrderSection extends StatelessWidget {
  const _CurrentOrderSection({
    required this.selectedItems,
    required this.selectedQuantities,
    required this.onIncrement,
    required this.onDecrement,
    required this.unavailableExistingItemIds,
    required this.formatPrice,
  });

  final List<RestaurantMenuItem> selectedItems;
  final Map<String, int> selectedQuantities;
  final ValueChanged<RestaurantMenuItem> onIncrement;
  final ValueChanged<String> onDecrement;
  final Set<String> unavailableExistingItemIds;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    if (selectedItems.isEmpty) {
      return Text(
        'No items selected yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: selectedItems.length,
      separatorBuilder: (context, index) => Divider(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.55),
      ),
      itemBuilder: (context, index) {
        final item = selectedItems[index];
        final isUnavailable = unavailableExistingItemIds.contains(item.id);
        return OrderCartItem(
          item: item,
          quantity: selectedQuantities[item.id] ?? 0,
          onIncrement: () => onIncrement(item),
          onDecrement: () => onDecrement(item.id),
          canIncrement: !isUnavailable,
          warning: isUnavailable ? 'This item is no longer available' : null,
          formatPrice: formatPrice,
        );
      },
    );
  }
}

class _ConfirmOrderDialog extends StatelessWidget {
  const _ConfirmOrderDialog({
    required this.isEditMode,
    required this.tableNo,
    required this.itemCount,
    required this.total,
    required this.selectedItems,
    required this.selectedQuantities,
    required this.formatPrice,
  });

  final bool isEditMode;
  final int tableNo;
  final int itemCount;
  final double total;
  final List<RestaurantMenuItem> selectedItems;
  final Map<String, int> selectedQuantities;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Confirm Changes' : 'Confirm Order'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Table ${tableNo.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('$itemCount selected items'),
            Text(
              isEditMode
                  ? 'Updated total: ${formatPrice(total)}'
                  : 'Total: ${formatPrice(total)}',
            ),
            const SizedBox(height: 16),
            for (final item in selectedItems.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${item.name} × ${selectedQuantities[item.id] ?? 0}',
                ),
              ),
            if (selectedItems.length > 6)
              Text('+${selectedItems.length - 6} more items'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Go Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(isEditMode ? 'Update Order' : 'Place Order'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.itemCount,
    required this.total,
    required this.formatPrice,
  });

  final int itemCount;
  final double total;
  final String Function(double value) formatPrice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$itemCount items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              formatPrice(total),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomOrderSummary extends StatelessWidget {
  const _BottomOrderSummary({
    required this.itemCount,
    required this.total,
    required this.isSaving,
    required this.canPlaceOrder,
    required this.onPlaceOrder,
    required this.formatPrice,
    this.buttonLabel,
    this.savingLabel,
  });

  final int itemCount;
  final double total;
  final bool isSaving;
  final bool canPlaceOrder;
  final VoidCallback onPlaceOrder;
  final String Function(double value) formatPrice;
  final String? buttonLabel;
  final String? savingLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$itemCount items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    formatPrice(total),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('review-place-order-button'),
                onPressed: canPlaceOrder && !isSaving ? onPlaceOrder : null,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isSaving
                      ? savingLabel ?? 'Placing Order...'
                      : buttonLabel ?? 'Review and Place Order',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(message),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
