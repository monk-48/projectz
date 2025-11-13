import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projectz/core/constants/app_colors.dart';
import 'package:projectz/core/constants/app_strings.dart';
import 'package:projectz/core/error/exception_handler.dart';
import 'package:projectz/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:projectz/mainScreens/addInventoryScreen.dart';
import 'package:projectz/models/inventory_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.inventory, style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                context.read<InventoryProvider>().setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name, brand, or SKU...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Consumer<InventoryProvider>(
                  builder: (context, provider, _) {
                    if (provider.searchQuery.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => provider.setSearchQuery(''),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),
          
          // Filter and Sort Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      Consumer<InventoryProvider>(
                        builder: (context, provider, _) => FilterChip(
                          label: const Text(AppStrings.filter),
                          onSelected: (_) => _showFilterOptions(context, provider),
                          avatar: provider.filterByStatus != 'all'
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                          backgroundColor: provider.filterByStatus != 'all'
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          labelStyle: TextStyle(
                            color: provider.filterByStatus != 'all' ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Consumer<InventoryProvider>(
                        builder: (context, provider, _) => FilterChip(
                          label: const Text(AppStrings.sort),
                          onSelected: (_) => _showSortOptions(context, provider),
                          avatar: const Icon(Icons.unfold_more, color: Colors.white, size: 18),
                          backgroundColor: AppColors.primary,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // Inventory List
          Expanded(
            child: StreamBuilder<List<InventoryItem>>(
              stream: context.read<InventoryProvider>().getInventoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final failure = ExceptionHandler.handleException(snapshot.error);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: ${failure.message}'),
                      ],
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];
                
                return Consumer<InventoryProvider>(
                  builder: (context, provider, _) {
                    // Update provider with new items from stream
                    provider.updateItems(allItems);
                    final items = provider.items;

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.searchQuery.isNotEmpty
                                  ? 'No items match your search'
                                  : 'No inventory items yet',
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildInventoryCard(item, context, provider);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInventoryScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInventoryCard(
    InventoryItem item,
    BuildContext context,
    InventoryProvider provider,
  ) {
    final stockColor = item.isOutOfStock
        ? AppColors.outOfStock
        : item.isLowStock
            ? AppColors.lowStock
            : AppColors.inStock;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.brand,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: stockColor),
                  ),
                  child: Text(
                    item.isOutOfStock
                        ? AppStrings.outOfStock
                        : item.isLowStock
                            ? AppStrings.lowStock
                            : AppStrings.inStock,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // SKU and Capacity info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SKU: ${item.sku}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: ${item.capacity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stock progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.stockLevel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${item.quantity}/${item.capacity} (${item.stockPercentage.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: item.stockPercentage / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit ${item.name} - coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(AppStrings.edit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.info,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(item, context, provider),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text(AppStrings.delete),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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

  void _showSortOptions(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildSortOption(context, provider, 'Name', 'name'),
            _buildSortOption(context, provider, 'Brand', 'brand'),
            _buildSortOption(context, provider, 'Quantity', 'quantity'),
            _buildSortOption(context, provider, 'SKU', 'sku'),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                provider.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: AppColors.primary,
              ),
              title: Text(provider.isAscending ? 'Ascending' : 'Descending'),
              onTap: () {
                provider.toggleSortOrder();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    InventoryProvider provider,
    String label,
    String value,
  ) {
    return ListTile(
      leading: provider.sortBy == value
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      title: Text(label),
      onTap: () {
        provider.setSortBy(value);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterOptions(BuildContext context, InventoryProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter By Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFilterOption(context, provider, 'All Items', 'all'),
            _buildFilterOption(context, provider, 'Low Stock', 'low'),
            _buildFilterOption(context, provider, 'Out of Stock', 'out_of_stock'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    InventoryProvider provider,
    String label,
    String value,
  ) {
    return ListTile(
      leading: provider.filterByStatus == value
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined),
      title: Text(label),
      onTap: () {
        provider.setFilterByStatus(value);
        Navigator.pop(context);
      },
    );
  }

  void _showDeleteConfirmation(
    InventoryItem item,
    BuildContext context,
    InventoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteInventoryItem(item.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.itemDeletedSuccess),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else if (mounted && provider.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
