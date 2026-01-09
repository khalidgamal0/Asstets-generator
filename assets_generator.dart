import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../utils/generate_constants.dart';

/// Run:
/// dart run generate/assets/main.dart
///
/// Supports:
///   assets/png/
///   assets/svg/
///   assets/lottie/*subfolders*/
///
/// Generates:
///   lib/src/config/res/assets_manger.dart

Future<void> main() async {
  const String pngDirPath = 'assets/png';
  const String svgDirPath = 'assets/svg';
  const String lottieRootPath = 'assets/lottie';
  const String outputFilePath = 'lib/src/config/res/assets_manger.dart';

  print('${GenerateConstants.blueColorCode}▶ Assets generator started...${GenerateConstants.resetColorCode}');

  // First run
  await _generateAssetsManager(
    pngDirPath: pngDirPath,
    svgDirPath: svgDirPath,
    lottieDirPath: lottieRootPath,
    outputFilePath: outputFilePath,
  );

  // Watch PNG + SVG normally
  final List<DirectoryWatcher> watchers = [
    DirectoryWatcher(pngDirPath),
    DirectoryWatcher(svgDirPath),
  ];

  // Add watchers for each Lottie subfolder
  watchers.addAll(_createLottieFolderWatchers(lottieRootPath));

  for (final watcher in watchers) {
    watcher.events.listen((event) async {
      final String type = event.type.toString().replaceAll('ChangeType.', '');

      print(
        '${GenerateConstants.orangeColorCode}🔄 [WATCHER] EVENT: ${type.toUpperCase()} | ${event.path}${GenerateConstants.resetColorCode}',
      );

      await _generateAssetsManager(
        pngDirPath: pngDirPath,
        svgDirPath: svgDirPath,
        lottieDirPath: lottieRootPath,
        outputFilePath: outputFilePath,
      );
    });
  }

  print('${GenerateConstants.blueColorCode}👀 Watching folders:${GenerateConstants.resetColorCode}');
  print(' - $pngDirPath');
  print(' - $svgDirPath');
  print(' - $lottieRootPath + ALL subfolders');
}

/// ---------------------------------------------------------------------------
/// LOTTIE: CREATE WATCHERS FOR EACH SUBFOLDER
/// ---------------------------------------------------------------------------
List<DirectoryWatcher> _createLottieFolderWatchers(String root) {
  final Directory dir = Directory(root);

  if (!dir.existsSync()) {
    print('${GenerateConstants.redColorCode}❌ Lottie root not found: $root${GenerateConstants.resetColorCode}');
    return [];
  }

  final List<DirectoryWatcher> watchers = [];

  for (final entity in dir.listSync()) {
    if (entity is Directory) {
      watchers.add(DirectoryWatcher(entity.path));
      print('${GenerateConstants.blueColorCode}📁 Watching Lottie folder: ${entity.path}${GenerateConstants.resetColorCode}');
    }
  }

  return watchers;
}

/// ---------------------------------------------------------------------------
/// GENERATION LOGIC
/// ---------------------------------------------------------------------------

Future<void> _generateAssetsManager({
  required String pngDirPath,
  required String svgDirPath,
  required String lottieDirPath,
  required String outputFilePath,
}) async {
  print('${GenerateConstants.blueColorCode}🚀 Generating AssetsManger...${GenerateConstants.resetColorCode}');

  final pngFiles = _safeListDirectory(pngDirPath).whereType<File>().toList();
  final svgFiles = _safeListDirectory(svgDirPath).whereType<File>().toList();
  final lottieFiles = _listFilesRecursively(lottieDirPath);

  pngFiles.sort((a, b) => a.path.compareTo(b.path));
  svgFiles.sort((a, b) => a.path.compareTo(b.path));
  lottieFiles.sort((a, b) => a.path.compareTo(b.path));

  final buffer = StringBuffer();

  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ignore_for_file: constant_identifier_names\n');
  buffer.writeln('abstract class AssetsManger {');
  buffer.writeln("  static const String pngPath = 'assets/png/';");
  buffer.writeln("  static const String svgPath = 'assets/svg/';");
  buffer.writeln("  static const String lottiePath = 'assets/lottie/';\n");

  // SVG
  buffer.writeln('  /// svgPath');
  for (final entity in svgFiles) {
    final fileName = p.basename(entity.path);
    final baseName = p.basenameWithoutExtension(fileName);
    final constName = _fileNameToCamelCase(baseName);

    buffer.writeln("  static const String $constName = '\${svgPath}$fileName';");
  }

  // PNG
  buffer.writeln('\n  /// pngPath');
  for (final entity in pngFiles) {
    final fileName = p.basename(entity.path);
    final baseName = p.basenameWithoutExtension(fileName);
    final constName = _fileNameToCamelCase(baseName);

    buffer.writeln("  static const String $constName = '\${pngPath}$fileName';");
  }

  // LOTTIE nested
  buffer.writeln('\n  /// lottiePath');
  for (final entity in lottieFiles) {
    final fileName = p.basename(entity.path);
    final folderName = p.basename(p.dirname(entity.path));
    final String name = _fileNameToCamelCase(fileName.replaceAll('.json', '').replaceAll('.png', '').replaceAll('.jpg', ''));

    final relativePath = entity.path.replaceFirst('assets/lottie/', '');

    buffer.writeln(
      "  static const String $name = '\${lottiePath}$relativePath';",
    );
  }

  buffer.writeln('}');

  final outputFile = File(outputFilePath);
  await outputFile.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('${GenerateConstants.greenColorCode}✅ AssetsManger generated successfully at $outputFilePath${GenerateConstants.resetColorCode}');
}

/// ---------------------------------------------------------------------------
/// HELPERS
/// ---------------------------------------------------------------------------

Iterable<FileSystemEntity> _safeListDirectory(String path) {
  final dir = Directory(path);

  if (!dir.existsSync()) {
    print('${GenerateConstants.orangeColorCode}⚠️ Directory missing: $path${GenerateConstants.resetColorCode}');
    return [];
  }

  return dir.listSync().where((e) => !e.path.endsWith('.DS_Store'));
}

List<File> _listFilesRecursively(String rootPath) {
  final root = Directory(rootPath);

  if (!root.existsSync()) return [];

  final List<File> files = [];

  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && !entity.path.endsWith('.DS_Store')) {
      files.add(entity);
    }
  }

  return files;
}

/// ---------------------------------------------------------------------------
/// FILE NAME TO CAMEL CASE (SAFE FOR DART IDENTIFIERS)
/// ---------------------------------------------------------------------------
String _fileNameToCamelCase(String name) {
  if (name.isEmpty) return name;

  // replace invalid characters (-, space) with underscore
  name = name.replaceAll(RegExp(r'[-\s]'), '_');

  // split by underscore
  final parts = name.split('_');

  // convert to camelCase
  final camelCase = parts.mapIndexed((index, part) {
    if (part.isEmpty) return '';
    return index == 0
        ? part[0].toLowerCase() + part.substring(1)
        : part[0].toUpperCase() + part.substring(1);
  }).join();

  return camelCase;
}

/// Extension for mapIndexed (helper)
extension IterableExtensions<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E item) f) {
    var i = 0;
    return map((e) => f(i++, e));
  }
}
