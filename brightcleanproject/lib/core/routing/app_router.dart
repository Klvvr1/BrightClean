import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:brightcleanprojet/core/enums/order_status.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/customer_registration_screen.dart';
import '../../features/auth/presentation/agent_registration_screen.dart';
import '../../features/auth/presentation/driver_registration_screen.dart';
import '../../features/customer/presentation/customer_main_layout.dart';
import '../../features/customer/presentation/service_details_screen.dart';
import '../../features/customer/presentation/checkout_screen.dart';
import '../../features/agent/presentation/agent_dashboard_screen.dart';
import '../../features/agent/presentation/agent_order_management_screen.dart';
import '../../features/driver/presentation/driver_dashboard_screen.dart';
import '../../features/driver/presentation/driver_tracking_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';

// Import AgentOrderModel for type checking in routes
// (AgentOrderModel is defined in agent_dashboard_screen.dart)

// Import TrackingWorkflow enum for driver tracking routes
// (TrackingWorkflow is defined in driver_tracking_screen.dart)

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role_selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/register/customer',
        builder: (context, state) => const CustomerRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/agent',
        builder: (context, state) => const AgentRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/driver',
        builder: (context, state) => const DriverRegistrationScreen(),
      ),
      GoRoute(
        path: '/customer_home',
        builder: (context, state) => const CustomerMainLayout(),
      ),
      GoRoute(
        path: '/service_details/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'unknown';
          return ServiceDetailsScreen(serviceType: type);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/agent_dashboard',
        builder: (context, state) => const AgentDashboardScreen(),
      ),
      GoRoute(
        path: '/agent_order_management/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          final extra = state.extra as Map<String, dynamic>?;

          // Validate the payload before casting
          if (extra == null || !extra.containsKey('order') || extra['order'] is! AgentOrderModel) {
            // Fallback: redirect to agent dashboard if order data is missing or invalid
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/agent_dashboard');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final initialStatus = extra['status'] as OrderStatus? ?? OrderStatus.received;
          final isReadOnly = extra['isReadOnly'] as bool? ?? false;
          final order = extra['order'] as AgentOrderModel;
          return AgentOrderManagementScreen(
            orderId: id,
            initialStatus: initialStatus,
            isReadOnly: isReadOnly,
            order: order,
          );
        },
      ),
      GoRoute(
        path: '/driver_dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      GoRoute(
        path: '/driver_tracking/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'unknown';
          final extra = state.extra as Map<String, dynamic>?;

          // Extract workflow from extra data (default to pickup if not provided)
          final workflowValue = extra?['workflow'] as int? ?? 1;
          final workflow = workflowValue == 2 ? TrackingWorkflow.delivery : TrackingWorkflow.pickup;

          return DriverTrackingScreen(
            taskId: id,
            workflow: workflow,
          );
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
