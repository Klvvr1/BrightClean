import 'package:flutter/material.dart';
//import '../../../../core/theme/app_colors.dart';

class AgentOrderManagementScreen extends StatefulWidget {
  final String orderId;

  const AgentOrderManagementScreen({super.key, required this.orderId});

  @override
  State<AgentOrderManagementScreen> createState() =>
      _AgentOrderManagementScreenState();
}

class _AgentOrderManagementScreenState
    extends State<AgentOrderManagementScreen> {
  String _currentStatus = 'received'; // received, washing, ready

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة الطلب #${widget.orderId}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تفاصيل الطلب:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('العميل: أحمد محمد'),
                    Text('الخدمة: غسيل ملابس (كي فقط)'),
                    Text('الكمية: 10 قطع'),
                    Divider(),
                    Text(
                      'الإجمالي: 100 درهم',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'تحديث حالة الطلب:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile(
              title: const Text('تم الاستلام'),
              value: 'received',
              groupValue: _currentStatus,
              onChanged: (v) => setState(() => _currentStatus = v.toString()),
            ),
            RadioListTile(
              title: const Text('قيد الغسيل / المعالجة'),
              value: 'washing',
              groupValue: _currentStatus,
              onChanged: (v) => setState(() => _currentStatus = v.toString()),
            ),
            RadioListTile(
              title: const Text('جاهز للتسليم'),
              value: 'ready',
              groupValue: _currentStatus,
              onChanged: (v) => setState(() => _currentStatus = v.toString()),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث حالة الطلب بنجاح')),
                );
              },
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }
}
