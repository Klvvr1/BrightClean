import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _systemSuspended = false;

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRegistration(String name, String type) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name),
      subtitle: Text('طلب تسجيل: $type'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.check_circle, color: AppColors.success), onPressed: () {}),
          IconButton(icon: const Icon(Icons.cancel, color: AppColors.error), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildActiveOrder(String id, String status) {
    return ListTile(
      title: Text('طلب #$id'),
      subtitle: Text('الحالة: $status'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {},
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'complete', child: Text('إنهاء إجباري')),
          const PopupMenuItem(value: 'cancel', child: Text('إلغاء إجباري', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم المشرف (Admin)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics
            const Text('الإحصائيات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildAnalyticsCard('الطلبات', '150', Icons.shopping_bag, AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildAnalyticsCard('الإيرادات', '4500 درهم', Icons.attach_money, AppColors.success)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildAnalyticsCard('العملاء', '80', Icons.people, AppColors.secondary)),
                const SizedBox(width: 8),
                Expanded(child: _buildAnalyticsCard('السائقين', '12', Icons.drive_eta, AppColors.tertiary)),
              ],
            ),
            const SizedBox(height: 24),
            // System Control
            ExpansionTile(
              title: const Text('التحكم بالنظام', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.settings_system_daydream),
              children: [
                SwitchListTile(
                  title: const Text('إيقاف النظام (وضع الصيانة)'),
                  value: _systemSuspended,
                  onChanged: (v) => setState(() => _systemSuspended = v),
                  activeThumbColor: AppColors.error,
                ),
                if (_systemSuspended) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CustomTextField(hintText: 'رسالة الصيانة...'),
                  ),
                  ElevatedButton(onPressed: () {}, child: const Text('حفظ الإعدادات')),
                  const SizedBox(height: 16),
                ]
              ],
            ),
            // Management
            ExpansionTile(
              title: const Text('إدارة التسجيلات', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.app_registration),
              children: [
                _buildPendingRegistration('مغسلة النور', 'مغسلة'),
                const Divider(),
                _buildPendingRegistration('سعيد عبدالله', 'سائق'),
              ],
            ),
            // Live Orders
            ExpansionTile(
              title: const Text('الطلبات النشطة', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.track_changes),
              children: [
                _buildActiveOrder('1024', 'في الطريق'),
                const Divider(),
                _buildActiveOrder('1025', 'قيد الغسيل'),
              ],
            ),
            // Marketing
            ExpansionTile(
              title: const Text('التسويق والإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
              leading: const Icon(Icons.campaign),
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CustomTextField(hintText: 'نص الإشعار الترويجي (Push Notification)'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('إرسال للجميع'),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
