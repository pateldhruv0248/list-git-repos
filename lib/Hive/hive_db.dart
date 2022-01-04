import 'package:hive/hive.dart';

class HiveDB {
  final Box _box = Hive.box('');

  void putInToBox(Map map) {
    _box.putAll(map);
  }

  Map getBoxData(args) {
    Map map = {};
    map[args] = _box.get(args, defaultValue: '-');
    return map;
  }
}