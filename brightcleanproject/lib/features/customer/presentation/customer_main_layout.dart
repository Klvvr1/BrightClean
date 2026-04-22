import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'customer_home_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class CustomerMainLayout extends StatefulWidget {
  const CustomerMainLayout({super.key});

  @override
  State<CustomerMainLayout> createState() => _CustomerMainLayoutState();
}

class _CustomerMainLayoutState extends State<CustomerMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CustomerHomeScreen(),
    MyOrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(_pages.length, (index) {
          final isSelected = _currentIndex == index;
          return IgnorePointer(
            ignoring: !isSelected,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _pages[index],
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex != index) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade500,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'طلباتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}
