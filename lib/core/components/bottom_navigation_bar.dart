import 'package:flutter/material.dart';

class MyNavBar extends StatefulWidget {
  final int currentIndex;
  final List<Widget> screens;
  final Function(int) onTabSelected;
  final VoidCallback onFabPressed;
  final Icon icon;

  const MyNavBar({
    super.key,
    required this.currentIndex,
    required this.screens,
    required this.onTabSelected,
    required this.onFabPressed,
    required this.icon,
  });

  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
