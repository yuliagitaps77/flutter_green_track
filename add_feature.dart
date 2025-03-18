import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('❗  Usage: dart run generate_feature.dart <feature_name>');
    exit(0);
  }

  final featureName = arguments.first;
  final pascalCaseName = _toPascalCase(featureName);
  final snakeCaseName = _toSnakeCase(featureName);

  // 1. Buat folder untuk Page & Controller di dalam presentation
  // misalnya: lib/presentation/pages/todo/todo_page.dart
  //           lib/presentation/controllers/todo/todo_controller.dart
  final featurePageDir = Directory('lib/presentation/pages/$snakeCaseName');
  final featureControllerDir =
      Directory('lib/presentation/controllers/$snakeCaseName');
  if (!featurePageDir.existsSync()) {
    featurePageDir.createSync(recursive: true);
    print('Created directory: ${featurePageDir.path}');
  }
  if (!featureControllerDir.existsSync()) {
    featureControllerDir.createSync(recursive: true);
    print('Created directory: ${featureControllerDir.path}');
  }

  // 2. Buat folder opsional untuk data model, service, dan repository
  // misalnya: lib/data/models/todo_model.dart
  //           lib/data/services/todo_service.dart
  //           lib/data/repositories/todo_repository.dart
  final modelFile = File('lib/data/models/${snakeCaseName}_model.dart');
  final serviceFile = File('lib/data/services/${snakeCaseName}_service.dart');
  final repositoryFile =
      File('lib/data/repositories/${snakeCaseName}_repository.dart');

  _createFileIfNotExists(
    modelFile,
    _modelTemplate(pascalCaseName, snakeCaseName),
  );
  _createFileIfNotExists(
    serviceFile,
    _serviceTemplate(pascalCaseName, snakeCaseName),
  );
  _createFileIfNotExists(
    repositoryFile,
    _repositoryTemplate(pascalCaseName, snakeCaseName),
  );

  // 3. Buat file Page & Controller
  final pageFile = File('${featurePageDir.path}/${snakeCaseName}_page.dart');
  final controllerFile =
      File('${featureControllerDir.path}/${snakeCaseName}_controller.dart');

  _createFileIfNotExists(
    pageFile,
    _pageTemplate(pascalCaseName, snakeCaseName),
  );
  _createFileIfNotExists(
    controllerFile,
    _controllerTemplate(pascalCaseName, snakeCaseName),
  );

  // 4. Tampilkan pesan sukses
  print('\n✅ Berhasil generate fitur "$featureName"!');
}

/// Membuat file dengan konten [content] hanya jika file belum ada.
void _createFileIfNotExists(File file, String content) {
  if (file.existsSync()) {
    print('File already exists: ${file.path}');
  } else {
    file.writeAsStringSync(content);
    print('Created file: ${file.path}');
  }
}

/// Template konten untuk Model
String _modelTemplate(String pascalCaseName, String snakeCaseName) {
  return '''
class ${pascalCaseName}Model {
  final int id;
  final String name;

  ${pascalCaseName}Model({
    required this.id,
    required this.name,
  });

  // Contoh parse JSON
  factory ${pascalCaseName}Model.fromJson(Map<String, dynamic> json) {
    return ${pascalCaseName}Model(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  // Contoh to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
''';
}

/// Template konten untuk Service
String _serviceTemplate(String pascalCaseName, String snakeCaseName) {
  return '''
class ${pascalCaseName}Service {
  // Misal: method untuk fetch data dari API atau database
  // Contoh:
  Future<List<Map<String, dynamic>>> fetch${pascalCaseName}Data() async {
    // TODO: Implement service logic
    await Future.delayed(const Duration(seconds: 1));
    return [
      {"id": 1, "name": "${pascalCaseName} One"},
      {"id": 2, "name": "${pascalCaseName} Two"},
    ];
  }
}
''';
}

/// Template konten untuk Repository
String _repositoryTemplate(String pascalCaseName, String snakeCaseName) {
  return '''
import '../models/${snakeCaseName}_model.dart';
import '../services/${snakeCaseName}_service.dart';

class ${pascalCaseName}Repository {
  final ${pascalCaseName}Service service = ${pascalCaseName}Service();

  Future<List<${pascalCaseName}Model>> getAll${pascalCaseName}() async {
    final data = await service.fetch${pascalCaseName}Data();
    return data.map((json) => ${pascalCaseName}Model.fromJson(json)).toList();
  }
}
''';
}

/// Template konten untuk Page
String _pageTemplate(String pascalCaseName, String snakeCaseName) {
  return '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/$snakeCaseName/${snakeCaseName}_controller.dart';

class ${pascalCaseName}Page extends GetView<${pascalCaseName}Controller> {
  const ${pascalCaseName}Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Daftarkan controller di sini, kalau mau lazyPut, dsb.
    Get.put(${pascalCaseName}Controller());
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$pascalCaseName Page'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return const Center(child: Text('No data.'));
        }
        return ListView.builder(
          itemCount: controller.items.length,
          itemBuilder: (context, index) {
            final item = controller.items[index];
            return ListTile(
              title: Text(item.name),
            );
          },
        );
      }),
    );
  }
}
''';
}

/// Template konten untuk Controller
String _controllerTemplate(String pascalCaseName, String snakeCaseName) {
  return '''
import 'package:get/get.dart';
import '../../../data/repositories/${snakeCaseName}_repository.dart';
import '../../../data/models/${snakeCaseName}_model.dart';

class ${pascalCaseName}Controller extends GetxController {
  final ${pascalCaseName}Repository repository = ${pascalCaseName}Repository();

  RxBool isLoading = false.obs;
  RxList<${pascalCaseName}Model> items = <${pascalCaseName}Model>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchItems();
  }

  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final result = await repository.getAll${pascalCaseName}();
      items.assignAll(result);
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}
''';
}

/// Helper untuk mengubah string jadi PascalCase (contoh: "todo_list" -> "TodoList")
String _toPascalCase(String input) {
  // Hilangkan karakter non-alphanumeric & underscore, lalu pisah
  final words = input.split(RegExp(r'[_\W]+'));
  return words
      .map((word) => word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join();
}

/// Helper untuk mengubah string jadi snake_case (contoh: "TodoList" -> "todo_list")
String _toSnakeCase(String input) {
  // Bagi berdasarkan pergantian huruf kapital -> huruf kecil
  final regex = RegExp(r'(?<=[a-z])[A-Z]');
  final snake = input
      .replaceAllMapped(regex, (match) => '_${match.group(0)}')
      .toLowerCase();
  return snake.replaceAll(' ', '_');
}
