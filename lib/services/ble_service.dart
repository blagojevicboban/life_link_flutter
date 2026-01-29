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
  final String _deviceName = "ESP32_SPP_SERVER";

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  final StreamController<List<int>> _dataController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get dataStream => _dataController.stream;

  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  Future<void> init() async {
    // Request permissions
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    }

    // Determine if we are already connected to a device
    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      connectedDevice = FlutterBluePlus.connectedDevices.first;
      _connectionStateController.add(BluetoothConnectionState.connected);
      await _discoverServices();
    }
  }

  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) return;

    print("Starting BLE Scan...");
    
    // Listen to scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        print("Found device: ${result.device.platformName} (${result.device.remoteId})");
        print("  Services: ${result.advertisementData.serviceUuids}");
        
        if (result.device.platformName == _deviceName || 
            result.advertisementData.serviceUuids.contains(Guid(_serviceUuid))) {
          print("  >>> MATCH FOUND! Connecting...");
          _connectToDevice(result.device);
          stopScan(); // Stop scanning once found
          break;
        }
      }
    });

    // Start scanning without filter first to test visibility
    await FlutterBluePlus.startScan(
      // withServices: [Guid(_serviceUuid)], 
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    print("Connecting to ${device.platformName}...");
    connectedDevice = device;

    // Listen to connection state
    _connectionSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);
      if (state == BluetoothConnectionState.disconnected) {
        print("Disconnected. Attempting reconnect...");
        targetCharacteristic = null;
        // Simple auto-reconnect logic could go here, or trigger a re-scan.
      }
    });

    try {
      await device.connect(autoConnect: false);
      await _discoverServices();
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  Future<void> _discoverServices() async {
    if (connectedDevice == null) return;

    print("Discovering Services...");
    List<BluetoothService> services = await connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString() == _serviceUuid) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == _characteristicUuid) {
            targetCharacteristic = characteristic;
            await _subscribeToCharacteristic();
            return; // Found it
          }
        }
      }
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

  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataController.close();
    _connectionStateController.close();
  }
}
