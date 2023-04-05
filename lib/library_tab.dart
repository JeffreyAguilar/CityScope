import 'package:cityscope/favorites_tab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cityscope/firebase/auth.dart';
import 'login_screen.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({super.key});

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
    print('successfully logged out');
  }

  Widget _userName() {
    return Text(
      user?.email ?? 'User Email',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: () {
        signOut();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color.fromRGBO(171, 245, 229, 1.0),
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(143, 217, 201, 1.0),
      ),
      body: Container(
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 75,
              backgroundColor: Colors.black,
              child: CircleAvatar(
                radius: 72,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(65, 40, 0, 0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(width: 2, color: Colors.black)),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 25,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
             Center(
              child: _userName()
            ),
            const SizedBox(
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 246, 244, 244),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.black,
                      width: 0.2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Edit Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {},
                      hoverColor: const Color.fromRGBO(0, 168, 143, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 246, 244, 244),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: Colors.black,
                    width: 0.2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Past Reviews',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 246, 244, 244),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: Colors.black,
                    width: 0.2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Favorites',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
            ElevatedButton(
              onPressed: () {
                signOut();
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: const Color.fromRGBO(171, 245, 229, 1.0),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}
