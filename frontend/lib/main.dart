import 'package:flutter/material.dart';
import 'cards/login_card.dart';
import 'cards/signup_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _showLogin = true;
  final TextStyle _selectedTextStyle = const TextStyle(
    color: Colors.blue,
    fontWeight: FontWeight.bold,
  );
  final TextStyle _defaultTextStyle = const TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: Colors.white.withOpacity(0.75),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showLogin = true;
                                  });
                                },
                                child: Text(
                                  'LOGIN',
                                  style: _showLogin
                                      ? _selectedTextStyle
                                      : _defaultTextStyle,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showLogin = false;
                                  });
                                },
                                child: Text(
                                  'SIGNUP',
                                  style: _showLogin
                                      ? _defaultTextStyle
                                      : _selectedTextStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _showLogin ? const LoginCard() : const SignupCard(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Or Continue With:',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      IconButton(
                        color: Colors.white,
                        iconSize: 50,
                        icon: const Icon(Icons.facebook),
                        onPressed: () {
                          // ...
                        },
                      ),
                      IconButton(
                        color: Colors.white,
                        iconSize: 50,
                        icon: const Icon(Icons.mail),
                        onPressed: () {
                          // ...
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
