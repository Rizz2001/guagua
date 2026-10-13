import 'dart:io';
import 'package:flutter/foundation.dart';

Future<bool> sendRawEscPos(String ip, int port, List<int> bytes) async {
  try {
    final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
    socket.add(bytes);
    await socket.flush();
    await socket.close();
    debugPrint('✅ Comando ESC/POS enviado exitosamente a $ip:$port');
    return true;
  } catch (e) {
    debugPrint('⚠️ Error enviando comando ESC/POS a $ip:$port: $e');
    return false;
  }
}
