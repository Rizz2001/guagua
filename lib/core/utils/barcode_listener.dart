import 'package:flutter/services.dart';

/// Listener global de hardware para lectores de código de barras USB en PC (Windows/Mac/Linux)
class BarcodeScannerListener {
  final StringBuffer _buffer = StringBuffer();
  DateTime? _lastKeyTime;
  final Function(String code) onBarcodeScanned;

  BarcodeScannerListener({required this.onBarcodeScanned}) {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      
      // Si la diferencia entre teclas es menor a 50ms, es una ráfaga del lector láser USB
      if (_lastKeyTime == null || now.difference(_lastKeyTime!).inMilliseconds < 50) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_buffer.isNotEmpty) {
            onBarcodeScanned(_buffer.toString().trim());
            _buffer.clear();
          }
        } else if (event.character != null && event.character!.isNotEmpty) {
          _buffer.write(event.character);
        }
      } else {
        // Escritura manual por teclado (humano), reiniciar buffer
        _buffer.clear();
        if (event.character != null && event.character!.isNotEmpty) {
          _buffer.write(event.character);
        }
      }
      _lastKeyTime = now;
    }
    return false;
  }

  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }
}
