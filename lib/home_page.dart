import 'package:cityscope/library_tab.dart';
import 'package:cityscope/google_map.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _body = const [
    MapPage(),
    LibraryTab(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:  const Color.fromARGB(255, 145, 233, 214),
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color.fromARGB(255, 3, 81, 65),
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            label: 'Map',
            icon: Icon(Icons.map)
          ),
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(Icons.menu_rounded)
          ),
        ],
      ),
    );
  }
}