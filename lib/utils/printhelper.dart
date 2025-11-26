import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterHelper {
  static const MethodChannel _channel = MethodChannel('printer_channel');
  static const String _prefKey = 'default_printer';

  static Future<bool> printBytes(Uint8List bytes) async {
    final defaultPrinter = await getDefaultPrinter();
    if (defaultPrinter == null) return false;

    try {
      final bool connected = await _channel.invokeMethod('connectPrinter', {
        'address': defaultPrinter,
      });
      if (connected) {
        final result = await _channel.invokeMethod('printBytes', {
          'bytes': bytes,
        });
        return result == true;
      }
      return false;
    } catch (e) {
      debugPrint("Print bytes error: $e");
      return false;
    }
  }
  /// Save default printer address
  static Future<void> setDefaultPrinter(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, address);
  }

  /// Get saved default printer address
  static Future<String?> getDefaultPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  /// Connect and print text
  static Future<bool> printText(String text) async {
    final defaultPrinter = await getDefaultPrinter();
    if (defaultPrinter == null) return false;

    try {
      final bool connected = await _channel.invokeMethod(
        'connectPrinter',
        {'address': defaultPrinter},
      );
      if (connected) {
        await _channel.invokeMethod('printText', {'text': text});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Printing error: $e');
      return false;
    }
  }
}
