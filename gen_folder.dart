import 'dart:io';

void main() {
  // Daftar folder yang ingin dibuat
  final directories = [
    'lib/core/constants',
    'lib/core/utils',
    'lib/core/themes',
    'lib/data/models',
    'lib/data/services',
    'lib/data/repositories',
    'lib/presentation/pages',
    'lib/presentation/widgets',
    'lib/presentation/controllers',
    'lib/routes',
  ];

  // Membuat folder2 di atas secara rekursif
  for (var dirPath in directories) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('Created directory: $dirPath');
    } else {
      print('Directory already exists: $dirPath');
    }
  }

  // Membuat file main.dart jika belum ada
  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) {
    mainFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}
''');
    print('Created file: lib/main.dart');
  } else {
    print('File already exists: lib/main.dart');
  }

  // Membuat file app.dart jika belum ada
  final appFile = File('lib/app.dart');
  if (!appFile.existsSync()) {
    appFile.writeAsStringSync('''
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetX Structure',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Hello, GetX Structure!'),
        ),
      ),
    );
  }
}
''');
    print('Created file: lib/app.dart');
  } else {
    print('File already exists: lib/app.dart');
  }

  print('\n✅ Struktur folder dan file dasar berhasil dibuat!');
}
