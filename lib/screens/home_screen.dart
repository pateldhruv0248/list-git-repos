import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:list_github_repos/Hive/hive_db.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static int page = 0;
  bool isLoading = false;
  List users = [];
  final dio = Dio();
  bool flag = false;

  HiveDB hiveDB = HiveDB();

  void checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        debugPrint('connected');
        _getMoreData(page);
      }
    } on SocketException catch (_) {
      debugPrint('not connected');
      //Get data from Hive
      
    }
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LazyLoadScrollView(
          onEndOfPage: () => _getMoreData(page),
          scrollOffset: 100,
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
    );
  }

  void _getMoreData(int index) async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });
      String url = "https://api.github.com/users/JakeWharton/repos?page=" +
          index.toString() +
          "per_page=15";
      debugPrint(url);
      final response = await dio.get(url);
      List newList = [];
      for (int i = 0; i < response.data.length; i++) {
        newList.add(response.data[i]);
      }
      
      //Store on HiveDB
      hiveDB.storeResponseLocally(response);
      

      setState(() {
        isLoading = false;
        users.addAll(newList);
        page++;
      });
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
