// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

Future<void> main() async {
  print('=== PDF Converter Engine Builder ===');
  final isWindows = Platform.isWindows;
  final isLinux = Platform.isLinux;

  if (!isWindows && !isLinux) {
    print('Unsupported platform for this script.');
    exit(1);
  }

  final rustDir = p.join(Directory.current.path, 'rust');
  if (!Directory(rustDir).existsSync()) {
    print('Error: rust directory not found.');
    exit(1);
  }

  // 1. Build Rust Engine
  print('\n[1/3] Building Rust engine (--release)...');
  final cargoResult = await Process.start(
    'cargo',
    ['build', '--release'],
    workingDirectory: rustDir,
    runInShell: true,
  );
  
  cargoResult.stdout.transform(utf8.decoder).listen((data) => stdout.write(data));
  cargoResult.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));
  
  if (await cargoResult.exitCode != 0) {
    print('Rust build failed.');
    exit(1);
  }
  print('Rust build completed.');

  // 2. Download PDFium
  print('\n[2/3] Downloading PDFium...');
  final pdfiumUrl = isWindows
      ? 'https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/7920/pdfium-win-x64.tgz'
      : 'https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/7920/pdfium-linux-x64.tgz';

  final archivePath = p.join(Directory.current.path, 'pdfium.tgz');
  final request = await HttpClient().getUrl(Uri.parse(pdfiumUrl));
  final response = await request.close();
  await response.pipe(File(archivePath).openWrite());
  print('Downloaded PDFium archive.');

  // Extract PDFium
  final pdfiumDir = p.join(Directory.current.path, 'pdfium_extracted');
  Directory(pdfiumDir).createSync(recursive: true);
  
  print('Extracting PDFium...');
  // We use tar because both Windows 10/11 and Linux have tar built-in now.
  final tarResult = await Process.run('tar', ['-xzf', archivePath, '-C', pdfiumDir], runInShell: true);
  if (tarResult.exitCode != 0) {
    print('Extraction failed: \${tarResult.stderr}');
    exit(1);
  }
  
  // 3. Copy files
  print('\n[3/3] Copying binaries...');
  final targetPlatformDir = isWindows ? 'windows' : 'linux';
  final engineBinDir = p.join(Directory.current.path, 'engine_bin', targetPlatformDir);
  Directory(engineBinDir).createSync(recursive: true);

  final execName = isWindows ? 'pdf_converter_engine.exe' : 'pdf_converter_engine';
  final libName = isWindows ? 'pdfium.dll' : 'libpdfium.so';

  final srcExec = p.join(rustDir, 'target', 'release', execName);
  final srcLib = p.join(pdfiumDir, 'lib', libName);
  final srcLibAlt = p.join(pdfiumDir, 'bin', libName); // Windows pdfium.dll is usually in bin/

  final actualSrcLib = File(srcLibAlt).existsSync() ? srcLibAlt : srcLib;

  // Copy to engine_bin for production CMake bundling
  File(srcExec).copySync(p.join(engineBinDir, execName));
  File(actualSrcLib).copySync(p.join(engineBinDir, libName));
  
  // Give execution permission on Linux
  if (isLinux) {
    await Process.run('chmod', ['+x', p.join(engineBinDir, execName)], runInShell: true);
  }

  // Copy to rust/target/release and debug so it works during development
  File(actualSrcLib).copySync(p.join(rustDir, 'target', 'release', libName));
  final debugDir = p.join(rustDir, 'target', 'debug');
  if (Directory(debugDir).existsSync()) {
    File(actualSrcLib).copySync(p.join(debugDir, libName));
  }

  // Cleanup
  File(archivePath).deleteSync();
  Directory(pdfiumDir).deleteSync(recursive: true);

  print('\nDone! The engine and PDFium are now ready.');
  print('During `flutter build`, CMake will automatically bundle them.');
}
