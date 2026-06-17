import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/error/user_error_message.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/widgets/map_picker_screen.dart';
import '../data/models/customer_address_model.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<CustomerAddressModel> _addresses = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final BaseApiClient _apiClient = BaseApiClient();

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/api/addresses');
      if (!mounted) return;
      setState(() {
        _addresses = response is List
            ? response
                .whereType<Map>()
                .map((item) => CustomerAddressModel.fromJson(
                      item.map((key, value) => MapEntry(key.toString(), value)),
                    ))
                .where((address) => address.isValid)
                .toList()
            : [];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAddress(int index) async {
    final address = _addresses[index];
    try {
      await _apiClient.delete('/api/addresses/${address.addressID}');
      await _loadSavedAddresses();
    } catch (e) {
      if (!mounted) return;
      final message = userMessageFromError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف العنوان: $message'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _navigateAndAddNewAddress() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    final coordinates = result['coordinates'];
    final addressLabel = result['address']?.toString() ?? '';

    // Handle both payload shapes: coordinates object with lat/lng properties, or direct lat/lng in result
    final double lat = (coordinates != null && coordinates.latitude != null)
        ? coordinates.latitude
        : (result['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (coordinates != null && coordinates.longitude != null)
        ? coordinates.longitude
        : (result['longitude'] as num?)?.toDouble() ?? 0.0;

    if (lat == 0.0 && lng == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'يرجى تحديد موقع صالح على الخريطة'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Extract area (everything before first comma or full label) and street (everything after or full label)
    String area = addressLabel;
    String street = addressLabel;
    final commaSplit = addressLabel.split(',');
    if (commaSplit.length >= 2) {
      area = commaSplit[0].trim();
      street = commaSplit.sublist(1).join(',').trim();
    }

    // Post to API
    setState(() => _isSaving = true);
    try {
      await _apiClient.post('/api/addresses', body: {
        'area': area,
        'street': street,
        'latitude': lat,
        'longitude': lng,
      });

      await _loadSavedAddresses();

      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إضافة العنوان بنجاح'),
          backgroundColor: theme.colorScheme.primary,
        ),
      );
    } on ServerException catch (e) {
      if (mounted) {
        final message = userMessageFromError(e,
            fallback: 'فشل حفظ العنوان. يرجى المحاولة مرة أخرى.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ العنوان: $message'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = userMessageFromError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $message'),
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
            title:
                Text(_addresses[index].label, style: theme.textTheme.bodyLarge),
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
