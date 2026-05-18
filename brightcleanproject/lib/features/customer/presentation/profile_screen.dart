import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_profile_screen.dart';
import '../../admin/presentation/admin_profile_screen.dart';
import '../../driver/presentation/driver_profile_screen.dart';
import '../../agent/presentation/agent_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role')?.toLowerCase() ?? 'customer';
    if (mounted) {
      setState(() {
        _role = role;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_role) {
      case 'admin':
        return const AdminProfileScreen();
      case 'manager':
      case 'agent':
        return const AgentProfileScreen();
      case 'driver':
        return const DriverProfileScreen();
      default:
        return const CustomerProfileScreen();
    }
  }
}
