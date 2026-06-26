import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/work_models.dart';

class StorageService {
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/work_data.json');
  }

  Future<WorkData> readData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return WorkData.initial();
      }
      final contents = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(contents) as Map<String, dynamic>;
      return WorkData.fromJson(jsonMap);
    } catch (e) {
      return WorkData.initial();
    }
  }

  Future<File> writeData(WorkData data) async {
    final file = await _localFile;
    final jsonString = jsonEncode(data.toJson());
    return file.writeAsString(jsonString);
  }

  Future<void> deleteData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore
    }
  }
}