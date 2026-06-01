import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/booking_repository.dart';
import '../repositories/booking_repository_impl.dart';
import '../../domain/models/order.dart';
import '../models/booking_model.dart';

class OrderProvider extends ChangeNotifier {
  final BookingRepository bookingRepository;
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isCheckoutLoading = false;
  String? _errorMessage;
  int? _currentBookingId;

  int? get currentBookingId => _currentBookingId;

  set currentBookingId(int? value) {
    _currentBookingId = value;
    notifyListeners();
  }

  Future<void> clearOrders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('orders');
      _orders = [];
      _currentBookingId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing orders: $e');
    }
  }

  bool get isActionLoading => _isActionLoading;
  bool get isCheckoutLoading => _isCheckoutLoading;

  OrderProvider({BookingRepository? bookingRepository})
      : bookingRepository = bookingRepository ??
            BookingRepositoryImpl(apiClient: BaseApiClient()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadOrders();
    // Seed demo orders only in debug mode if DB is empty
    if (kDebugMode && _orders.isEmpty) {
      seedDemoOrders();
    }
  }

  Future<void> loadLocalOrders() => _loadOrders();


  Future<void> _loadOrders() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('orders', orderBy: 'date DESC');

      if (maps.isNotEmpty) {
        _orders = maps.map((map) => Order(
          orderId: map['orderId'] as String,
          date: map['date'] as String,
          details: map['details'] as String,
          status: map['status'] as String,
          activeStepIndex: map['activeStepIndex'] as int,
          locationDescription: map['locationDescription'] as String?,
          paymentMethod: map['paymentMethod'] as String?,
          isRated: (map['isRated'] as int) == 1,
          pickupDate: map['pickupDate'] != null ? DateTime.parse(map['pickupDate'] as String) : null,
          pickupTimeSlot: map['pickupTimeSlot'] as String?,
          category: map['category'] as String?,
        )).toList();
      } else {
        _orders = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  /// Seeds demo orders for testing/debug purposes.
  /// Should only be called explicitly in debug mode or test scenarios.
  void seedDemoOrders() {
    _orders = [
      Order(
        orderId: '1025',
        date: '16 أبريل 2026',
        details: 'تنظيف سجاد - 2 قطعة',
        status: 'قيد الانتظار',
        activeStepIndex: 0,
        category: 'carpets',
      ),
      Order(
        orderId: '1024',
        date: '15 أبريل 2026',
        details: 'غسيل ملابس - 5 قطع',
        status: 'في الطريق',
        activeStepIndex: 1,
        category: 'clothes',
      ),
      Order(
        orderId: '1023',
        date: '14 أبريل 2026',
        details: 'غسيل سيارة - كبيرة',
        status: 'تم التوصيل',
        activeStepIndex: 4,
        category: 'carsBikes',
      ),
    ];
    for (var order in _orders) {
      _saveOrderToDb(order);
    }
  }

  Future<void> _saveOrderToDb(Order order) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('orders', {
        'orderId': order.orderId,
        'date': order.date,
        'details': order.details,
        'status': order.status,
        'activeStepIndex': order.activeStepIndex,
        'locationDescription': order.locationDescription,
        'paymentMethod': order.paymentMethod,
        'isRated': order.isRated ? 1 : 0,
        'pickupDate': order.pickupDate?.toIso8601String(),
        'pickupTimeSlot': order.pickupTimeSlot,
        'category': order.category,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error saving order: $e');
    }
  }

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void addOrder(Order order) {
    _orders.insert(0, order);
    _saveOrderToDb(order);
    notifyListeners();
  }

  void markOrderAsRated(String orderId) {
    final index = _orders.indexWhere((o) => o.orderId == orderId);
    if (index != -1) {
      final oldOrder = _orders[index];
      _orders[index] = Order(
        orderId: oldOrder.orderId,
        date: oldOrder.date,
        details: oldOrder.details,
        status: oldOrder.status,
        activeStepIndex: oldOrder.activeStepIndex,
        locationDescription: oldOrder.locationDescription,
        paymentMethod: oldOrder.paymentMethod,
        isRated: true,
        pickupDate: oldOrder.pickupDate,
        pickupTimeSlot: oldOrder.pickupTimeSlot,
        category: oldOrder.category,
      );
      _saveOrderToDb(_orders[index]);
      notifyListeners();
    }
  }

  Future<void> fetchPendingBookings(int agentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookingModels = await bookingRepository.getPendingBookings(agentId);
      
      _orders = bookingModels.map((booking) {
        return Order(
          orderId: booking.bookingID.toString(),
          date: '${booking.createdAt.day} ${_getMonthName(booking.createdAt.month)} ${booking.createdAt.year}',
          details: _mapBookingItemsToDetails(booking),
          status: _mapStatusToString(booking.status),
          activeStepIndex: _mapStatusToStepIndex(booking.status),
          category: _mapCategory(booking),
          pickupDate: booking.scheduledAt,
        );
      }).toList();
      
      _isLoading = false;
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ في الخادم';
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  String _mapBookingItemsToDetails(BookingModel booking) {
    if (booking.bookingItems.isEmpty) return 'طلب فارغ';
    return booking.bookingItems.map((item) {
      final name = item.serviceCatalogItem?.serviceName ?? 'خدمة';
      return '$name - ${item.quantity} قطعة';
    }).join(', ');
  }

  String _mapStatusToString(int statusInt) {
    switch (statusInt) {
      case 0:
        return 'مسودة';
      case 1:
        return 'قيد الانتظار';
      case 2:
        return 'في الطريق';
      case 3:
        return 'قيد المعالجة';
      case 4:
        return 'جاهز';
      case 5:
        return 'تم التوصيل';
      case 6:
        return 'ملغي';
      default:
        return 'قيد الانتظار';
    }
  }

  int _mapStatusToStepIndex(int statusInt) {
    switch (statusInt) {
      case 1:
        return 0;
      case 2:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      case 5:
        return 4;
      default:
        return 0;
    }
  }

  String? _mapCategory(BookingModel booking) {
    if (booking.bookingItems.isEmpty) return null;
    final catId = booking.bookingItems.first.serviceCatalogItem?.category;
    switch (catId) {
      case 0:
        return 'clothes';
      case 1:
        return 'carpets';
      case 2:
        return 'carsBikes';
      case 3:
        return 'furniture';
      default:
        return null;
    }
  }

  Future<void> acceptOrder(int bookingId, int agentId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await bookingRepository.acceptBooking(bookingId);
      await fetchPendingBookings(agentId);
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ في الخادم';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> markOrderReady(int bookingId, int agentId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await bookingRepository.markBookingReady(bookingId);
      await fetchPendingBookings(agentId);
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ في الخادم';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<double?> submitOrder(int bookingId, {Order? localOrder}) async {
    _isCheckoutLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final serverFinalTotal = await bookingRepository.submitBooking(bookingId);
      if (localOrder != null) {
        _orders.insert(0, localOrder);
        await _saveOrderToDb(localOrder);
      }

      // On success, clear local cart DB table
      final db = await DatabaseHelper.instance.database;
      await db.delete('cart_items');

      return serverFinalTotal;
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ في الخادم';
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isCheckoutLoading = false;
      notifyListeners();
    }
  }

  Future<int> createBooking(int laundryAgentID, List<Map<String, int>> items, {int? addressID}) async {
    _isCheckoutLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bookingId = await bookingRepository.createBooking(laundryAgentID, items, addressID: addressID);
      _currentBookingId = bookingId;
      _isCheckoutLoading = false;
      notifyListeners();
      return bookingId;
    } on ServerException catch (e) {
      _errorMessage = e.message ?? 'حدث خطأ أثناء إنشاء الحجز';
      _isCheckoutLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isCheckoutLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
