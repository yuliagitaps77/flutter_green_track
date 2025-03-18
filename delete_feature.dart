import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('❗  Usage: dart run delete_feature.dart <feature_name>');
    exit(0);
  }

  final featureName = arguments.first;
  final snakeName = _toSnakeCase(featureName);

  // Folder yang ingin dihapus
  final directories = [
    'lib/presentation/pages/$snakeName',
    'lib/presentation/controllers/$snakeName',
  ];

  // File yang ingin dihapus
  final files = [
    'lib/data/models/${snakeName}_model.dart',
    'lib/data/services/${snakeName}_service.dart',
    'lib/data/repositories/${snakeName}_repository.dart',
  ];

  // Hapus folder
  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      print('Deleted directory: $dirPath');
    } else {
      print('Directory not found: $dirPath');
    }
  }

  // Hapus file
  for (final filePath in files) {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
      print('Deleted file: $filePath');
    } else {
      print('File not found: $filePath');
    }
  }

  print('\n✅ Feature "$featureName" successfully deleted!');
}

/// Ubah "NamaFitur" menjadi "nama_fitur"
String _toSnakeCase(String input) {
  final regex = RegExp(r'(?<=[a-z])[A-Z]');
  final snake = input
      .replaceAllMapped(regex, (match) => '_${match.group(0)}')
      .toLowerCase();
  return snake.replaceAll(' ', '_');
}
