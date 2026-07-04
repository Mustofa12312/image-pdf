import 'dart:convert';
import 'dart:io';
void main() async {
  final process = await Process.start('sh', ['-c', 'echo "hello stdout"; echo "hello stderr" >&2; exit 1;']);
  
  await for (final line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
    print('STDOUT: $line');
  }
  
  final exitCode = await process.exitCode;
  print('Exit code: $exitCode');
  
  final errOut = await process.stderr.transform(utf8.decoder).join();
  print('STDERR: $errOut');
}
