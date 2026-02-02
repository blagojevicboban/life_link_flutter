import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final String _serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String _characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  // Stream for received data
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  // Stream for connection state
  final StreamController<BluetoothConnectionState> _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  // Stream for scan results
  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get scanResultsStream =>
      _scanResultsController.stream;

  Future<void> init() async {
    // Request permissions
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }
  }

  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) return;

    print("Starting BLE Scan...");

    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResultsController.add(results);
    });

    // Start scanning
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print("Error starting BLE scan: $e");
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    print("Connecting to ${device.platformName}...");

    // Stop scanning before connecting
    await stopScan();

    connectedDevice = device;

    // Listen to connection state
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        print("Disconnected.");
        targetCharacteristic = null;
      }
    });

    try {
      // autoConnect: false forces immediate connection attempt
      await device.connect(autoConnect: false);
      await _discoverServices();
    } catch (e) {
      print("Connection Error: $e");
      // Add disconnected state if error
      _connectionStateController.add(BluetoothConnectionState.disconnected);
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    print("Discovering Services...");
    // Note: discoverServices can be flaky, sometimes a delay helps
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      List<BluetoothService> services = await connectedDevice!
          .discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == _serviceUuid) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString() == _characteristicUuid) {
              targetCharacteristic = characteristic;
              await _subscribeToCharacteristic();
              return; // Found it
            }
          }
        }
      }
    } catch (e) {
      print("Error discovering services: $e");
    }
  }

  Future<void> _subscribeToCharacteristic() async {
    if (targetCharacteristic == null) return;

    print("Subscribing to Characteristic...");
    await targetCharacteristic!.setNotifyValue(true);
    targetCharacteristic!.onValueReceived.listen((value) {
      _dataController.add(value);
    });
  }

  void log(String message) {
    print(message);
  }

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataController.close();
    _connectionStateController.close();
    _scanResultsController.close();
  }
}
