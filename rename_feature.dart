import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length < 2) {
    print(
        '❗  Usage: dart run rename_feature.dart <old_feature_name> <new_feature_name>');
    exit(0);
  }

  final oldName = arguments[0];
  final newName = arguments[1];

  // Konversi nama ke snake_case & PascalCase
  final oldSnake = _toSnakeCase(oldName);
  final newSnake = _toSnakeCase(newName);
  final oldPascal = _toPascalCase(oldName);
  final newPascal = _toPascalCase(newName);

  print('Renaming feature "$oldName" -> "$newName"');
  print('oldSnake  = $oldSnake, oldPascal  = $oldPascal');
  print('newSnake  = $newSnake, newPascal  = $newPascal\n');

  // 1. RENAME FILE yang ada di presentation/pages dan presentation/controllers
  //    karena path lamanya masih valid sebelum folder di-rename.
  _renameIfExists(
    'lib/presentation/pages/$oldSnake/${oldSnake}_page.dart',
    'lib/presentation/pages/$oldSnake/${newSnake}_page.dart',
  );
  _renameIfExists(
    'lib/presentation/controllers/$oldSnake/${oldSnake}_controller.dart',
    'lib/presentation/controllers/$oldSnake/${newSnake}_controller.dart',
  );

  // 2. RENAME FOLDER "pages/oldSnake" -> "pages/newSnake"
  _renameIfExists(
    'lib/presentation/pages/$oldSnake',
    'lib/presentation/pages/$newSnake',
  );
  //    RENAME FOLDER "controllers/oldSnake" -> "controllers/newSnake"
  _renameIfExists(
    'lib/presentation/controllers/$oldSnake',
    'lib/presentation/controllers/$newSnake',
  );

  // 3. RENAME FILE di folder data (model, service, repository)
  _renameIfExists(
    'lib/data/models/${oldSnake}_model.dart',
    'lib/data/models/${newSnake}_model.dart',
  );
  _renameIfExists(
    'lib/data/services/${oldSnake}_service.dart',
    'lib/data/services/${newSnake}_service.dart',
  );
  _renameIfExists(
    'lib/data/repositories/${oldSnake}_repository.dart',
    'lib/data/repositories/${newSnake}_repository.dart',
  );

  // 4. UBAH ISI FILE (replaceAll oldSnake->newSnake dan oldPascal->newPascal)
  final updatedPaths = [
    'lib/data/models/${newSnake}_model.dart',
    'lib/data/services/${newSnake}_service.dart',
    'lib/data/repositories/${newSnake}_repository.dart',
    'lib/presentation/pages/$newSnake/${newSnake}_page.dart',
    'lib/presentation/controllers/$newSnake/${newSnake}_controller.dart',
  ];

  for (final path in updatedPaths) {
    final file = File(path);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      // Naïve approach: cukup replace string
      content = content.replaceAll(oldPascal, newPascal);
      content = content.replaceAll(oldSnake, newSnake);
      file.writeAsStringSync(content);
      print('Updated references in: $path');
    }
  }

  print('\n✅ Feature "$oldName" renamed to "$newName" successfully!');
}

/// Helper rename file/folder jika ada
void _renameIfExists(String oldPath, String newPath) {
  final type = FileSystemEntity.typeSync(oldPath);
  if (type == FileSystemEntityType.notFound) {
    print('Skip rename (not found): $oldPath');
    return;
  }
  final entity = (type == FileSystemEntityType.directory)
      ? Directory(oldPath)
      : File(oldPath);

  entity.renameSync(newPath);
  print('Renamed $oldPath -> $newPath');
}

/// Contoh: "TodoList" -> "todo_list"
String _toSnakeCase(String input) {
  final regex = RegExp(r'(?<=[a-z])[A-Z]');
  final snake = input
      .replaceAllMapped(regex, (match) => '_${match.group(0)}')
      .toLowerCase();
  return snake.replaceAll(' ', '_');
}

/// Contoh: "todo_list" -> "TodoList"
String _toPascalCase(String input) {
  final words = input.split(RegExp(r'[_\W]+'));
  return words
      .map((word) => word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join();
}
