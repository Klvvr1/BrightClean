import 'package:brightcleanproject/features/driver/data/models/delivery_task_model.dart';
import 'package:brightcleanproject/features/driver/data/providers/driver_provider.dart';
import 'package:brightcleanproject/features/driver/domain/repositories/delivery_task_repository.dart';
import 'package:brightcleanproject/features/driver/presentation/driver_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeDeliveryTaskRepository implements DeliveryTaskRepository {
  final DeliveryTaskModel task;
  int completeCalls = 0;

  _FakeDeliveryTaskRepository(this.task);

  @override
  Future<void> claimTask(int taskId, int driverId) async {}

  @override
  Future<void> completeTask(int taskId) async {
    completeCalls += 1;
  }

  @override
  Future<bool> getAvailability() async => true;

  @override
  Future<List<DeliveryTaskModel>> getMyTasks() async => [task];

  @override
  Future<List<DeliveryTaskModel>> getTaskPool() async => [task];

  @override
  Future<DeliveryTaskModel> getTaskDetails(int taskId) async => task;

  @override
  Future<bool> setAvailability(bool isAvailable) async => isAvailable;

  @override
  Future<void> startTask(int taskId) async {}

  @override
  Future<void> updateTaskProgress(int taskId, int currentStep) async {}
}

DeliveryTaskModel _task({int status = 1, int currentStep = 0}) {
  return DeliveryTaskModel(
    taskID: 7,
    bookingID: 42,
    deliveryStaffID: 5,
    pickupAddressID: 1,
    dropoffAddressID: 2,
    stageNumber: 1,
    type: 0,
    status: status,
    deliveryFee: 1.5,
    currentStep: currentStep,
    pickupAddress: const {
      'area': 'حي العميل',
      'street': 'شارع 1',
      'latitude': 24.7136,
      'longitude': 46.6753,
    },
    dropoffAddress: const {
      'area': 'حي المغسلة',
      'street': 'شارع 2',
      'latitude': 24.7137,
      'longitude': 46.6754,
    },
    booking: const {
      'client': {'firstName': 'عميل', 'lastName': 'اختبار', 'phoneNo': ''},
      'laundryAgent': {'businessName': 'مغسلة اختبار'},
      'bookingItems': [],
    },
  );
}

void main() {
  testWidgets(
      'driver tracking moves one step at a time without a status dropdown',
      (tester) async {
    final task = _task();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DriverProvider(
          deliveryTaskRepository: _FakeDeliveryTaskRepository(task),
        ),
        child: MaterialApp(
          home: DriverTrackingScreen(
            taskId: task.taskID.toString(),
            workflow: TrackingWorkflow.pickup,
            task: task,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DropdownButton<int>), findsNothing);
    expect(find.text('تحديث للخطوة التالية'), findsOneWidget);
  });

  testWidgets('driver completion requires the fixed 1234 code', (tester) async {
    final task = _task(status: 2, currentStep: 3);
    final repository = _FakeDeliveryTaskRepository(task);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => DriverProvider(deliveryTaskRepository: repository),
        child: MaterialApp(
          home: DriverTrackingScreen(
            taskId: task.taskID.toString(),
            workflow: TrackingWorkflow.pickup,
            task: task,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('إنهاء المهمة بنجاح'));
    await tester.pump();
    await tester.tap(find.text('إنهاء المهمة بنجاح'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('تأكيد'));
    await tester.pump();

    expect(find.text('رمز التحقق غير صحيح'), findsOneWidget);
    expect(repository.completeCalls, 0);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(repository.completeCalls, 1);
  });
}
