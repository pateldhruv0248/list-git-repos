import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveDB {
  
  final box = Hive.box('git-repos');

  void storeResponseLocally(Response response) {
    for (int i = 0; i < response.data.length; i++) {
        box.put(response.data[i]["id"] , response.data[i]);
      } 
  }

   Map getLocalData(){
     Map map = box.toMap();
     return map;
  }
  
  closeBox(){
    box.clear();
  }
}