import 'package:flutter/material.dart';
import './main.dart';

void main() {
  runApp(const MyApp());
}

class ProfileDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileDashboard({
    super.key,
    required this.userData,
  });

  @override
  _ProfileDashboardState createState() => _ProfileDashboardState();
}

class _ProfileDashboardState extends State<ProfileDashboard> {
  @override
  Widget build(BuildContext context) {
    final String username = widget.userData['username'] ?? '';
    const String joinDate = "January 2023";
    final String firstName = widget.userData['first_name'] ?? '';
    final String lastName = widget.userData['last_name'] ?? '';
    final String birthdate = widget.userData['birthdate'] ?? '';
    final String gender = widget.userData['gender'] ?? '';
    final String city = widget.userData['location'] ?? '';
    final String ipAddress = widget.userData['ip_address'] ?? '';
    final String email = widget.userData['email'] ?? '';
    final String profilepic = widget.userData['profile_picture'] ?? '';
    const String phone = "+256 000 00000 00";

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Container(
                            width: (MediaQuery.of(context).size.width) / 2,
                            height: (MediaQuery.of(context).size.width) / 2,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  profilepic,
                                  fit: BoxFit.cover,
                                )),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child:
                              InfoCard(username: username, joinDate: joinDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BioCard(
                      birthdate: birthdate,
                      gender: gender,
                      firstName: firstName,
                      lastName: lastName,
                    ),
                    const SizedBox(height: 10),
                    LocationCard(city: city, ipAddress: ipAddress),
                    const SizedBox(height: 20),
                    ContactCard(email: email, phone: phone),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const MainPage(),
    ));
    print('Logout button pressed');
  }
}

class InfoCard extends StatelessWidget {
  final String username;
  final String joinDate;

  const InfoCard({
    Key? key,
    required this.username,
    required this.joinDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: @$username'),
            Text('Joined: $joinDate'),
          ],
        ),
      ),
    );
  }
}

class BioCard extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String birthdate;
  final String gender;

  const BioCard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.birthdate,
    required this.gender,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('Name: $firstName $lastName'),
            Text('Date Of Birth: $birthdate'),
            Text('Gender: $gender'),
          ],
        ),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  final String city;
  final String ipAddress;

  const LocationCard({
    Key? key,
    required this.city,
    required this.ipAddress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('City: $city'),
            Text('IP Address: $ipAddress'),
          ],
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String email;
  final String phone;

  const ContactCard({
    Key? key,
    required this.email,
    required this.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text('Email: $email'),
            Text('Phone: $phone'),
          ],
        ),
      ),
    );
  }
}
