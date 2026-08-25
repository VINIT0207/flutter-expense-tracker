import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ModelSetupService {
  static const String assetPath = 'lib/assets/myapp-ai-Q4_K_M.gguf';
  static const String fileName = 'myapp-ai-Q4_K_M.gguf';

  /// Prepares the model file. If it doesn't exist or is outdated, streams it to disk.
  static Future<String?> prepareModelFile({Function(double)? onProgress}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final modelPath = '${directory.path}/$fileName';
      final file = File(modelPath);

      // FAST PATH: If file already exists and is valid on disk, reuse immediately with ZERO memory footprint
      if (await file.exists()) {
        final existingLength = await file.length();
        if (existingLength > 10 * 1024 * 1024) { // > 10 MB indicates extracted model
          debugPrint("✅ Model file ready in sandbox: $modelPath (${(existingLength / (1024 * 1024)).toStringAsFixed(1)} MB)");
          return modelPath;
        }
        // If file exists but is corrupted (0 bytes or partial), remove it
        await file.delete();
      }

      debugPrint("Reading model asset into memory for first-time extraction...");
      if (onProgress != null) onProgress(0.1);
      final byteData = await rootBundle.load(assetPath);

      // Read asset bytes
      final rawBytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

      // Offload file writing to a background isolate to prevent UI stutters
      debugPrint("Spawning file write isolate...");
      if (onProgress != null) onProgress(0.3);
      
      final receivePort = ReceivePort();
      await Isolate.spawn(_writeTask, [
        receivePort.sendPort,
        rawBytes,
        modelPath,
      ]);

      // Wait for isolate to finish
      await for (final msg in receivePort) {
        if (msg is double) {
          if (onProgress != null) onProgress(0.3 + (msg * 0.7));
        } else if (msg == "DONE") {
          receivePort.close();
          break;
        } else if (msg is Exception || msg is Error) {
          throw msg;
        }
      }

      return modelPath;
    } catch (e) {
      debugPrint("Failed to prepare model: $e");
      return null;
    }
  }

  /// The heavy lifting executed on a background Isolate
  static void _writeTask(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final Uint8List bytes = args[1];
    final String targetPath = args[2];

    try {
      final file = File(targetPath);
      final sink = file.openWrite();

      final totalBytes = bytes.length;
      const chunkSize = 1024 * 512; // 512 KB chunks
      int writtenBytes = 0;

      for (int i = 0; i < totalBytes; i += chunkSize) {
        final end = (i + chunkSize < totalBytes) ? i + chunkSize : totalBytes;
        sink.add(bytes.sublist(i, end));
        writtenBytes += (end - i);

        // Emit progress periodically
        sendPort.send(writtenBytes / totalBytes);
      }

      sink.close().then((_) {
        sendPort.send("DONE");
      });
    } catch (e) {
      sendPort.send(e);
    }
  }
}
