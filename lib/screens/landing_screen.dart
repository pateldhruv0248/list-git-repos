import 'package:flutter/material.dart';
import 'package:list_github_repos/screens/home_screen.dart';
import 'package:local_auth/local_auth.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  //Intialised by false, and wait untill authorisation.
  //After authorisation is successful, make it true.
  bool authenticated = false;

  //Check if device contains biometric authorisation.
  void checkingForBioMetrics() async {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    if (canCheckBiometrics) {
      await _authenticateMe();
    }
  }

  //Wait for users authorisation.
  Future<void> _authenticateMe() async {
    try {
      authenticated = await _localAuthentication.authenticate(
        biometricOnly: true,
        localizedReason: "Fingerprint authentication",
        useErrorDialogs: true,
        stickyAuth: true,
      );
      setState(() {
        authenticated = authenticated;
      });
      debugPrint(authenticated.toString());
      if (authenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    checkingForBioMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jake\'s Git'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            if (!authenticated) {
              _authenticateMe();
            }
          },
          child: Container(
            alignment: Alignment.center,
            height: 50.0,
            width: 150.0,
            color: Colors.grey,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Go to repos'),
            ),
          ),
        ),
      ),
    );
  }
}
