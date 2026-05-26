import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import 'map_picker_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Use SharedPreferences to persist addresses
  List<String> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  // 1. Load addresses from memory on initialization
  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    // Use a placeholder user ID - in production, get from auth service
    final userId = prefs.getString('user_id') ?? 'default_user';
    if (!mounted) return;
    setState(() {
      _addresses = prefs.getStringList('user_saved_addresses_$userId') ?? [];
      _isLoading = false; // Data loaded, update UI dynamically
    });
  }

  // 2. Save a new address to persistent memory
  Future<void> _saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';
    _addresses.add(address);
    await prefs.setStringList('user_saved_addresses_$userId', _addresses);
    if (!mounted) return;
    setState(() {}); // Rebuild UI
  }

  // 3. Remove an address from persistent memory
  Future<void> _removeAddress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';
    _addresses.removeAt(index);
    await prefs.setStringList('user_saved_addresses_$userId', _addresses);
    if (!mounted) return;
    setState(() {}); // Rebuild UI
  }

  Future<void> _navigateAndAddNewAddress() async {
    final selectedAddress = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    // If the user selected a location and didn't just go back
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      await _saveAddress(selectedAddress); // Persist!

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت إضافة العنوان بنجاح'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('العناوين المحفوظة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_addresses.isEmpty ? _buildEmptyState() : _buildAddressesList()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddNewAddress,
        backgroundColor: theme.colorScheme.primary,
        icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
        label: Text('إضافة عنوان جديد',
            style: TextStyle(color: theme.colorScheme.onPrimary)),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'لا توجد عناوين محفوظة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'قم بإضافة عنوان جديد لتسهيل وصول المندوب إليك',
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _addresses.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return Container(
          decoration: AppStyles.surface(context),
          child: ListTile(
            leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
            title: Text(_addresses[index], style: theme.textTheme.bodyLarge),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () =>
                  _removeAddress(index), // Remove completely from memory
            ),
          ),
        );
      },
    );
  }
}
