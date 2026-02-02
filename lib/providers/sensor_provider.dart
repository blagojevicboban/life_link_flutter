import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

import 'package:android_intent_plus/android_intent.dart';
import '../services/ble_service.dart';

enum AlertState { safe, warning, alarm }

enum FallAction { call, sms, sos }

class SensorProvider with ChangeNotifier {
  final BleService _bleService = BleService();

  AlertState _alertState = AlertState.safe;
  String _rawMessage = "Waiting for data...";
  double _gForce = 0.0;
  int _pulse = 0;
  int _spo2 = 0;
  int _batteryLevel = 0;
  bool _isConnected = false;

  String _debugStatus = "";

  // Settings
  String? _defaultDeviceAddress;
  String _emergencyContactName = "";
  String _emergencyContactNumber = "";
  FallAction _selectedFallAction = FallAction.call;
  int _countdownDuration = 15;

  // Countdown State
  bool _isCountingDown = false;
  int _currentCountdown = 0;
  Timer? _countdownTimer;

  // Scanning State
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  AlertState get alertState => _alertState;
  String get rawMessage => _rawMessage;
  double get gForce => _gForce;
  int get pulse => _pulse;
  int get spo2 => _spo2;
  int get batteryLevel => _batteryLevel;
  bool get isConnected => _isConnected;
  LatLng? get fallLocation => _fallLocation;

  // Getters for Settings & UI
  String get emergencyContactName => _emergencyContactName;
  String get emergencyContactNumber => _emergencyContactNumber;
  FallAction get selectedFallAction => _selectedFallAction;
  int get countdownDuration => _countdownDuration;
  bool get isCountingDown => _isCountingDown;
  int get currentCountdown => _currentCountdown;
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  String? get defaultDeviceAddress => _defaultDeviceAddress;
  String? get connectedDeviceAddress =>
      _bleService.connectedDevice?.remoteId.toString();
  String get connectedDeviceName =>
      _bleService.connectedDevice?.platformName ?? "Unknown Device";

  LatLng? _fallLocation;

  SensorProvider() {
    _init();
  }

  void _init() async {
    await _loadSettings();
    await _bleService.init(); // Wait for permissions

    // Listen to connection state
    // Listen to connection state
    _bleService.connectionStateStream.listen((state) {
      _isConnected = (state == BluetoothConnectionState.connected);

      if (_isConnected) {
        stopScan();
      }

      notifyListeners();
      if (!_isConnected) {
        _rawMessage = "Disconnected";
      }
    });

    // Listen to data stream
    _bleService.dataStream.listen((data) {
      _parseData(data);
    });

    // Listen to scan results
    _bleService.scanResultsStream.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    // Attempt Auto-Connect
    if (_defaultDeviceAddress != null && _defaultDeviceAddress!.isNotEmpty) {
      _debugStatus = "Init: Waiting 1s...";
      notifyListeners();
      // Small delay to ensure BLE stack is ready
      await Future.delayed(const Duration(seconds: 1));
      startScan(isAutoConnect: true);
    } else {
      _debugStatus = "Init: No default.";
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultDeviceAddress = prefs.getString('default_device_address');
    print("SETTINGS LOADED: Default Device = $_defaultDeviceAddress");
    _emergencyContactName = prefs.getString('contact_name') ?? "";
    _emergencyContactNumber = prefs.getString('contact_number') ?? "";
    _countdownDuration = prefs.getInt('countdown_duration') ?? 15;

    int actionIdx = prefs.getInt('fall_action') ?? 0;
    _selectedFallAction = FallAction.values[actionIdx];

    notifyListeners();
  }

  Future<void> saveSettings({
    String? contactName,
    String? contactNumber,
    FallAction? action,
    int? duration,
    String? deviceAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (contactName != null) {
      _emergencyContactName = contactName;
      prefs.setString('contact_name', contactName);
    }
    if (contactNumber != null) {
      _emergencyContactNumber = contactNumber;
      prefs.setString('contact_number', contactNumber);
    }
    if (action != null) {
      _selectedFallAction = action;
      prefs.setInt('fall_action', action.index);
    }
    if (duration != null) {
      _countdownDuration = duration;
      prefs.setInt('countdown_duration', duration);
    }
    if (deviceAddress != null) {
      _defaultDeviceAddress = deviceAddress;
      prefs.setString('default_device_address', deviceAddress);
    }
    notifyListeners();
  }

  void startScan({bool isAutoConnect = false}) {
    _isScanning = true;
    _scanResults = [];
    notifyListeners();
    _bleService.startScan();

    if (isAutoConnect && _defaultDeviceAddress != null) {
      _debugStatus = "Auto: Start $_defaultDeviceAddress";
      notifyListeners();

      try {
        for (var d in FlutterBluePlus.connectedDevices) {
          if (d.remoteId.toString() == _defaultDeviceAddress) {
            _debugStatus = "Auto: System Connected!";
            notifyListeners();
            connect(d);
            return;
          }
        }
      } catch (e) {
        _debugStatus = "Auto: Sys Check Error";
      }

      StreamSubscription? sub;
      sub = _bleService.scanResultsStream.listen((results) {
        for (var r in results) {
          // Case-insensitive check
          if (r.device.remoteId.toString().toLowerCase() ==
              _defaultDeviceAddress?.toLowerCase()) {
            _bleService.log("Auto: Found! Connecting...");
            notifyListeners();
            connect(r.device);
            sub?.cancel();
            break;
          }
        }
      });

      Future.delayed(const Duration(seconds: 10), () {
        sub?.cancel();
        if (!_isConnected && isAutoConnect) {
          _bleService.log("Auto: Timeout. Not found.");
          notifyListeners();
        }
      });
    }
  }

  void stopScan() {
    _isScanning = false;
    _bleService.stopScan();
    notifyListeners();
  }

  void connect(BluetoothDevice device) async {
    await _bleService.connectToDevice(device);
  }

  void disconnect() {
    _bleService.disconnect();
  }

  void _parseData(List<int> data) {
    try {
      String msg = utf8.decode(data).trim();
      _rawMessage = msg;

      AlertState previousState = _alertState;

      if (msg.startsWith("POTENTIAL_FALL")) {
        _alertState = AlertState.warning;
        _extractMetrics(msg);
      } else if (msg.startsWith("FALL_ACCEPTED")) {
        if (_alertState != AlertState.alarm && !_isCountingDown) {
          _alertState = AlertState.alarm;
          _startCountdown();
        }
        _extractMetrics(msg);
      } else if (msg.startsWith("FALL_DETECTED")) {
        if (_alertState != AlertState.alarm && !_isCountingDown) {
          _alertState = AlertState.alarm;
          _startCountdown();
        }
        _extractMetrics(msg);
      } else if (msg.startsWith("STATUS")) {
        _extractMetrics(msg);
      }

      if (_alertState != previousState) {
        _handleHaptics(_alertState);
      }

      notifyListeners();
    } catch (e) {
      print("Parse Error: $e");
    }
  }

  void _startCountdown() {
    _isCountingDown = true;
    _currentCountdown = _countdownDuration;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentCountdown--;
      if (_currentCountdown <= 0) {
        _countdownTimer?.cancel();
        _isCountingDown = false;
        _executeFallAction();
      }
      notifyListeners();
    });
  }

  void cancelFall() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    resetAlarm();
  }

  Future<void> _executeFallAction() async {
    print("EXECUTING FALL ACTION: $_selectedFallAction");

    switch (_selectedFallAction) {
      case FallAction.call:
        if (_emergencyContactNumber.isNotEmpty) {
          if (Platform.isAndroid || Platform.isIOS) {
            await FlutterPhoneDirectCaller.callNumber(_emergencyContactNumber);
          } else {
            print("Direct call not supported on this platform.");
          }
        }
        break;
      case FallAction.sms:
        if (_emergencyContactNumber.isNotEmpty) {
          String message =
              "SOS! I have detected a fall. Location: https://maps.google.com/?q=${_fallLocation?.latitude},${_fallLocation?.longitude}";

          final Uri smsLaunchUri = Uri(
            scheme: 'sms',
            path: _emergencyContactNumber,
            queryParameters: <String, String>{'body': message},
          );

          try {
            if (await canLaunchUrl(smsLaunchUri)) {
              await launchUrl(smsLaunchUri);
            } else {
              print("Could not launch SMS uri");
            }
          } catch (e) {
            print("SMS Error: $e");
          }
        }
        break;
      case FallAction.sos:
        if (_emergencyContactNumber.isNotEmpty) {
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: _emergencyContactNumber,
          );
          await launchUrl(launchUri);
        }
        break;
    }
  }

  void _handleHaptics(AlertState state) async {
    // Vibration is only supported on mobile
    if (!Platform.isAndroid && !Platform.isIOS) return;

    bool hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;

    if (state == AlertState.alarm) {
      Vibration.vibrate(
        pattern: [500, 1000, 500, 1000, 500, 1000],
        intensities: [128, 255, 128, 255, 128, 255],
      );
    } else if (state == AlertState.warning) {
      Vibration.vibrate(duration: 500);
    } else {
      Vibration.cancel();
    }
  }

  void _extractMetrics(String msg) {
    RegExp latReg = RegExp(r"Lat:\s*([0-9.-]+)");
    RegExp lonReg = RegExp(r"Lon:\s*([0-9.-]+)");
    RegExp gReg = RegExp(r"G:\s*([0-9.]+)");
    RegExp pReg = RegExp(r"P:\s*([0-9]+)");
    RegExp sReg = RegExp(r"S:\s*([0-9]+)");
    RegExp bReg = RegExp(r"B:\s*([0-9]+)");

    var latMatch = latReg.firstMatch(msg);
    var lonMatch = lonReg.firstMatch(msg);
    var gMatch = gReg.firstMatch(msg);
    var pMatch = pReg.firstMatch(msg);
    var sMatch = sReg.firstMatch(msg);
    var bMatch = bReg.firstMatch(msg);

    if (latMatch != null && lonMatch != null) {
      double lat = double.tryParse(latMatch.group(1)!) ?? 0.0;
      double lon = double.tryParse(lonMatch.group(1)!) ?? 0.0;
      if (lat != 0.0 || lon != 0.0) {
        _fallLocation = LatLng(lat, lon);
      } else if (_alertState == AlertState.alarm) {
        _fetchPhoneLocation();
      }
    } else if (_alertState == AlertState.alarm && _fallLocation == null) {
      _fetchPhoneLocation();
    }

    if (gMatch != null) _gForce = double.tryParse(gMatch.group(1)!) ?? _gForce;
    if (pMatch != null) _pulse = int.tryParse(pMatch.group(1)!) ?? _pulse;
    if (sMatch != null) _spo2 = int.tryParse(sMatch.group(1)!) ?? _spo2;
    if (bMatch != null) {
      _batteryLevel = int.tryParse(bMatch.group(1)!) ?? _batteryLevel;
    }
  }

  void resetAlarm() {
    _alertState = AlertState.safe;
    _isCountingDown = false;
    _countdownTimer?.cancel();
    _gForce = 0.0;
    notifyListeners();
  }

  Future<void> _fetchPhoneLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      _fallLocation = LatLng(position.latitude, position.longitude);
      notifyListeners();
      print("Used Phone GPS for Fall Location: $_fallLocation");
    } catch (e) {
      print("Error fetching phone location: $e");
    }
  }

  void retryConnection() {
    startScan(isAutoConnect: true);
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openBluetoothSettings() async {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.BLUETOOTH_SETTINGS',
      );
      await intent.launch();
    } else if (Platform.isWindows) {
      // Open Windows Bluetooth settings
      await Process.run('start', ['ms-settings:bluetooth'], runInShell: true);
    }
  }
}
