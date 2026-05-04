import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة العنوان بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العناوين المحفوظة'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : (_addresses.isEmpty ? _buildEmptyState() : _buildAddressesList()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndAddNewAddress,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('إضافة عنوان جديد', style: TextStyle(color: AppColors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: AppColors.textLight.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'لا توجد عناوين محفوظة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'قم بإضافة عنوان جديد لتسهيل وصول المندوب إليك',
            style: TextStyle(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _addresses.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.primary),
            title: Text(_addresses[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _removeAddress(index), // Remove completely from memory
            ),
          ),
        );
      },
    );
  }
}
