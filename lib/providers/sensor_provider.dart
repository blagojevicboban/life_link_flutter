import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';

enum AlertState { safe, warning, alarm }

class SensorProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  
  AlertState _alertState = AlertState.safe;
  String _rawMessage = "Waiting for data...";
  double _gForce = 0.0;
  int _pulse = 0;
  int _spo2 = 0;
  bool _isConnected = false;

  AlertState get alertState => _alertState;
  String get rawMessage => _rawMessage;
  double get gForce => _gForce;
  int get pulse => _pulse;
  int get spo2 => _spo2;
  bool get isConnected => _isConnected;

  SensorProvider() {
    _init();
  }

  void _init() {
    _bleService.init();
    
    // Listen to connection state
    _bleService.connectionStateStream.listen((state) {
      _isConnected = (state == BluetoothConnectionState.connected);
      notifyListeners();
      if (!_isConnected) {
        // If disconnected, maybe reset data but keep alert state? 
        // Or reset everything. Let's reset for now.
        _rawMessage = "Disconnected";
      }
    });

    // Listen to data stream
    _bleService.dataStream.listen((data) {
      _parseData(data);
    });

    // Start scanning immediately
    _bleService.startScan();
  }

  void _parseData(List<int> data) {
    try {
      String msg = utf8.decode(data).trim();
      _rawMessage = msg;
      
      // Parse patterns:
      // POTENTIAL_FALL G:2.50 P:100 S:98
      // FALL_DETECTED G:3.20 P:0 S:0
      
      if (msg.startsWith("POTENTIAL_FALL")) {
        _alertState = AlertState.warning;
        _extractMetrics(msg);
      } else if (msg.startsWith("FALL_DETECTED")) {
        _alertState = AlertState.alarm;
        _extractMetrics(msg);
      } else {
        // Normal data or status
        if (_alertState != AlertState.alarm) {
             // Only reset to safe if we aren't in an alarm state (unless we want auto-reset)
             // For now, let's assume if we get normal data, maybe we are safe? 
             // Actually, usually "FALL_DETECTED" persists. 
             // Let's rely on explicit resets or consistent stream for "safe" if needed.
             // But based on spec, we might just be getting alerts.
             // If we get just "STATUS ...", maybe that's safe.
             // For now, minimal logic.
        }
      }
      notifyListeners();
    } catch (e) {
      print("Parse Error: $e");
    }
  }

  void _extractMetrics(String msg) {
    // Simple regex or split parsing
    // POTENTIAL_FALL G:2.50 P:100 S:98
    // Note: The user spec has specific format.
    try {
      // Logic to pull out G, P, S
      // This is a naive implementation, robust regex is better.
      RegExp gReg = RegExp(r"G:([0-9.]+)");
      RegExp pReg = RegExp(r"P:([0-9]+)");
      RegExp sReg = RegExp(r"S:([0-9]+)");

      var gMatch = gReg.firstMatch(msg);
      var pMatch = pReg.firstMatch(msg);
      var sMatch = sReg.firstMatch(msg);

      if (gMatch != null) _gForce = double.tryParse(gMatch.group(1)!) ?? _gForce;
      if (pMatch != null) _pulse = int.tryParse(pMatch.group(1)!) ?? _pulse;
      if (sMatch != null) _spo2 = int.tryParse(sMatch.group(1)!) ?? _spo2;
    } catch (e) {
      print("Metric Extraction Error: $e");
    }
  }

  void resetAlarm() {
    _alertState = AlertState.safe;
    _gForce = 0.0; // Reset metrics if desired
    notifyListeners();
  }
  
  void retryConnection() {
    _bleService.startScan();
  }
}
