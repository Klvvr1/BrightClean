import 'package:brightcleanproject/features/admin/data/models/pending_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads requested services for pending laundry registration', () {
    final user = PendingUserModel.fromJson({
      'userID': 10,
      'firstName': 'أحمد',
      'lastName': 'علي',
      'email': 'agent@example.com',
      'role': 'LaundryAgent',
      'requestedServices': [
        {'serviceID': 1, 'serviceName': 'غسيل ملابس'},
        {'ServiceID': 2, 'ServiceName': 'كي ملابس'},
      ],
    });

    expect(
      user.requestedServices.map((service) => service.serviceName),
      ['غسيل ملابس', 'كي ملابس'],
    );
  });
}
