import 'package:flutter/foundation.dart';

Future<bool> sendRawEscPos(String ip, int port, List<int> bytes) async {
  debugPrint('🌐 Entorno Web: Simulación de comando ESC/POS LAN $ip:$port');
  return true;
}
