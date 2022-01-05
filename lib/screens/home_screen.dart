import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:list_github_repos/Hive/hive_db.dart';
import 'package:local_auth/local_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static int page = 1;
  bool isLoading = false;
  List users = [];

  //For Api calls
  final dio = Dio();

  //Initialised by true, and if internet connection is broken
  //or API call is failed,
  //it will become false.
  bool internetIsAvailable = true;

  //Intialised by false, and wait untill authorisation.
  //After authorisation is successful, make it true.
  bool authenticated = false;

  HiveDB hiveDB = HiveDB();
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  //Check if device contains biometric authorisation.
  void checkingForBioMetrics() async {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    if (canCheckBiometrics) {
      await _authenticateMe();
    }
  }

  //Wait for users authorisation.
  Future<bool> _authenticateMe() async {
    try {
      authenticated = await _localAuthentication.authenticate(
        biometricOnly: true,
        localizedReason: "Fingerprint authentication",
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
    if (!mounted) {
      return authenticated;
    } else {
      return !authenticated;
    }
  }

  //Check internet connection.
  void _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('connected');
        internetIsAvailable = true;
        _getMoreData();
      }
    } on SocketException catch (_) {
      debugPrint('not connected');
      // Get data from Hive
      setState(() {
        internetIsAvailable = false;
        users = hiveDB.getLocalData().values.toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkingForBioMetrics();
    _checkConnectivity();
  }

  @override
  void dispose() {
    hiveDB.closeBox();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //If user do not has access, Show blank page 
    //with message of unauthorisation.
    if (!authenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Jake\'s Git'),
        ),
        body: const Center(
          child: Text('You are unauthorized!'),
        ),
      );
    }
    //If user is authorised, Show the working module of app.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jake\'s Git'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LazyLoadScrollView(
                //In offline mode, we can not call extra data.
                onEndOfPage: () => internetIsAvailable ? _getMoreData() : '',
                scrollOffset: 300,
                child: ListView.builder(
                  itemCount: users.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == users.length) {
                      return _buildProgressIndicator();
                    } else {
                      return ListTile(
                        leading: const Icon(Icons.book),
                        title: Text((users[index]['name'] ?? '')),
                        subtitle: Text((users[index]['description'] ?? '')),
                      );
                    }
                  },
                ),
              ),
            ),
            if (!internetIsAvailable)
              Container(
                color: Colors.black54,
                width: MediaQuery.of(context).size.width * 100,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'You are offline or something went wrong. Showing local data',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  void _getMoreData() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });
      try {
        String url =
            "https://api.github.com/users/JakeWharton/repos?&per_page=15&page=" +
                page.toString();
        debugPrint(url);
        final response = await dio.get(url);
        List newList = [];
        for (int i = 0; i < response.data.length; i++) {
          newList.add(response.data[i]);
        }

        //Store/Update on HiveDB
        hiveDB.storeResponseLocally(response);
        setState(() {
          isLoading = false;
          users.addAll(newList);
        });
        page++;
      } catch (e) {
        setState(() {
          internetIsAvailable = false;
          isLoading = false;
        });
      }
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Opacity(
          opacity: isLoading ? 1.0 : 00,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
