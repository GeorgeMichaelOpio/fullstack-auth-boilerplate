import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '/profile_page.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  _LoginCardState createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _passwordVisible = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your email';
              }
              if (!isValidEmail(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: !_passwordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Checkbox(value: false, onChanged: (value) {}),
                  const Text('Remember Me'),
                ],
              ),
              GestureDetector(
                onTap: () {
                  print('Forgot Password');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(
              fixedSize: const Size(150, 15),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            onPressed: () {
              try {
                if (_formKey.currentState!.validate()) {
                  _login(emailController.text, passwordController.text);
                }
              } catch (error) {
                print('Login error: $error');
              }
            },
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login(String email, String password) async {
    try {
      final response = await Dio().post(
        'http://127.0.0.1:3000/login',
        data: {'email': email, 'password': password},
      );

      if (response.data != null && response.data['token'] != null) {
        print('Login successful');
        _showUserProfile(response.data['user']);
      } else {
        print('Unexpected response format during login');
      }
    } on DioException catch (error) {
      _handleLoginError(error);
    } catch (error) {
      print('Login error: $error');
    }
  }

  void _showUserProfile(Map<String, dynamic> userData) {
    print('User ID: ${userData['_id']}');
    print('Email: ${userData['email']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDashboard(userData: userData),
      ),
    );
  }

  void _handleLoginError(DioException error) {
    if (error.response?.statusCode == 401) {
      print('Invalid username or password');
      _showErrorDialog('Error', 'Invalid username or password');
    } else {
      print('Check your internet connection');
      _showErrorDialog('Error', 'Check your internet connection');
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            content,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }
}
