import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import 'map_picker_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Use SharedPreferences to persist local address display strings
  List<String> _addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final BaseApiClient _apiClient = BaseApiClient();

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  // 1. Load addresses from local cache on initialization
  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';
    if (!mounted) return;
    setState(() {
      _addresses = prefs.getStringList('user_saved_addresses_$userId') ?? [];
      _isLoading = false;
    });
  }

  // 2. Persist address label locally (for display)
  Future<void> _saveAddressLocally(String address) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';
    _addresses.add(address);
    await prefs.setStringList('user_saved_addresses_$userId', _addresses);
    if (!mounted) return;
    setState(() {});
  }

  // 3. Remove an address from local cache
  Future<void> _removeAddress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';
    _addresses.removeAt(index);
    await prefs.setStringList('user_saved_addresses_$userId', _addresses);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _navigateAndAddNewAddress() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    // MapPickerScreen returns a plain String like 'موقع محدد (lat, lng)'
    if (result == null || result.isEmpty) return;

    final addressLabel = result;

    // Parse coordinates from the label string if available (format: 'label (lat, lng)')
    double lat = 0.0;
    double lng = 0.0;
    final coordMatch = RegExp(r'\(([-\d.]+),\s*([-\d.]+)\)').firstMatch(result);
    if (coordMatch != null) {
      lat = double.tryParse(coordMatch.group(1) ?? '0') ?? 0.0;
      lng = double.tryParse(coordMatch.group(2) ?? '0') ?? 0.0;
    }

    // Post to API
    setState(() => _isSaving = true);
    try {
      await _apiClient.post('/api/addresses', body: {
        'area': addressLabel,
        'street': addressLabel,
        'latitude': lat,
        'longitude': lng,
      });

      await _saveAddressLocally(addressLabel);

      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تمت إضافة العنوان بنجاح'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
      }
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ العنوان: ${e.message ?? "خطأ في الخادم"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        onPressed: _isSaving ? null : _navigateAndAddNewAddress,
        backgroundColor: theme.colorScheme.primary,
        icon: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.add, color: theme.colorScheme.onPrimary),
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
              onPressed: () => _removeAddress(index),
            ),
          ),
        );
      },
    );
  }
}
