import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:brightcleanproject/core/enums/order_status.dart';
import '../../features/auth/data/providers/auth_provider.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/customer_registration_screen.dart';
import '../../features/auth/presentation/agent_registration_screen.dart';
import '../../features/auth/presentation/driver_registration_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/customer/presentation/customer_main_layout.dart';
import '../../features/customer/presentation/service_details_screen.dart';
import '../../features/customer/domain/models/cart_item.dart';
import '../../features/customer/presentation/checkout_screen.dart';
import '../../features/customer/presentation/order_success_screen.dart';
import '../../features/agent/presentation/agent_dashboard_screen.dart';
import '../../features/agent/presentation/agent_order_management_screen.dart';
import '../../features/driver/data/models/delivery_task_model.dart';
import '../../features/driver/presentation/driver_dashboard_screen.dart';
import '../../features/driver/presentation/driver_tracking_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/customer/presentation/notifications_screen.dart';
import '../../features/customer/presentation/cart_screen.dart';

class AppRouter {
  static String _getHomeRouteForRole(String? role) {
    if (role == null) {
      return '/login';
    }
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'admin') {
      return '/admin';
    } else if (normalizedRole == 'manager' || normalizedRole == 'agent' || normalizedRole == 'laundryagent') {
      return '/agent_dashboard';
    } else if (normalizedRole == 'driver' || normalizedRole == 'deliverystaff') {
      return '/driver_dashboard';
    } else if (normalizedRole == 'client' || normalizedRole == 'customer') {
      return '/customer_home';
    } else {
      return '/login';
    }
  }

  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final isLoggedIn = authProvider.isAuthenticated;
      final location = state.matchedLocation;

      // Define public routes
      final publicRoutes = [
        '/',
        '/login',
        '/role_selection',
        '/register/customer',
        '/register/agent',
        '/register/driver',
        '/forgot_password',
      ];

      // If not logged in and trying to access a private route, redirect to /login
      if (!isLoggedIn && !publicRoutes.contains(location)) {
        return '/login';
      }

      // If logged in and trying to go to login or registration pages, redirect to their home
      if (isLoggedIn && (location == '/login' || location == '/role_selection' || location.startsWith('/register') || location == '/forgot_password')) {
        return _getHomeRouteForRole(authProvider.role);
      }

      // Role authorization guards
      if (isLoggedIn) {
        final role = authProvider.role;

        // 1. Admin Guard
        if (location.startsWith('/admin') && (role == null || role.toLowerCase() != 'admin')) {
          return _getHomeRouteForRole(role);
        }

        // 2. Agent Guard
        if ((location.startsWith('/agent_dashboard') || location.startsWith('/agent_order_management')) &&
            (role == null || !(role.toLowerCase() == 'manager' || role.toLowerCase() == 'agent' || role.toLowerCase() == 'laundryagent'))) {
          return _getHomeRouteForRole(role);
        }

        // 3. Driver Guard
        if ((location.startsWith('/driver_dashboard') || location.startsWith('/driver_tracking')) &&
            (role == null || !(role.toLowerCase() == 'driver' || role.toLowerCase() == 'deliverystaff'))) {
          return _getHomeRouteForRole(role);
        }

        // 4. Customer/Client Guard
        final customerPaths = ['/customer_home', '/service_details', '/checkout', '/notifications', '/cart'];
        final isCustomerPath = customerPaths.any((path) => location.startsWith(path));
        if (isCustomerPath &&
            (role == null ||
             role.toLowerCase() == 'admin' ||
             role.toLowerCase() == 'manager' || role.toLowerCase() == 'agent' || role.toLowerCase() == 'laundryagent' ||
             role.toLowerCase() == 'driver' || role.toLowerCase() == 'deliverystaff')) {
          return _getHomeRouteForRole(role);
        }
      }

      return null;
    },
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
        path: '/forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
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
        builder: (context, state) {
          if (state.extra is List<CartItem>) {
            return CheckoutScreen(directItems: state.extra as List<CartItem>);
          } else if (state.extra is CartItem) {
            return CheckoutScreen(directItems: [state.extra as CartItem]);
          }
          return const CheckoutScreen();
        },
      ),
      GoRoute(
        path: '/order_success',
        builder: (context, state) => const OrderSuccessScreen(),
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

          // Safely extract and normalize workflow from extra data
          TrackingWorkflow workflow = TrackingWorkflow.pickup; // default fallback
          DeliveryTaskModel? task;

          if (state.extra != null && state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            final workflowValue = extra['workflow'];
            final taskValue = extra['task'];

            if (workflowValue is TrackingWorkflow) {
              // Direct enum instance
              workflow = workflowValue;
            } else if (workflowValue is int) {
              // Integer: compare against enum indices
              if (workflowValue == TrackingWorkflow.delivery.index) {
                workflow = TrackingWorkflow.delivery;
              } else {
                workflow = TrackingWorkflow.pickup;
              }
            } else if (workflowValue is String) {
              // String: parse enum name
              if (workflowValue.toLowerCase() == 'delivery') {
                workflow = TrackingWorkflow.delivery;
              } else {
                workflow = TrackingWorkflow.pickup;
              }
            }
            if (taskValue is DeliveryTaskModel) {
              task = taskValue;
            } else if (taskValue is Map<String, dynamic>) {
              task = DeliveryTaskModel.fromJson(taskValue);
            } else if (taskValue is Map) {
              task = DeliveryTaskModel.fromJson(Map<String, dynamic>.from(taskValue));
            }
            // For any other type or null, use default (pickup)
          }

          return DriverTrackingScreen(
            taskId: id,
            workflow: workflow,
            task: task,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
