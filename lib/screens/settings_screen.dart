import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/sensor_provider.dart';
import '../core/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SensorProvider>(context, listen: false);
    _nameController.text = provider.emergencyContactName;
    _numberController.text = provider.emergencyContactNumber;

    // Start scanning when entering settings to show available devices
    provider.startScan();
  }

  @override
  void dispose() {
    // Stop scanning when leaving settings
    final provider = Provider.of<SensorProvider>(context, listen: false);
    provider.stopScan();
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020E15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "SETTINGS",
          style: GoogleFonts.rajdhani(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("DEVICE CONNECTION"),
                const SizedBox(height: 16),
                _buildDeviceSection(context, provider),

                const SizedBox(height: 32),
                _buildSectionHeader("SYSTEM PERMISSIONS"),
                const SizedBox(height: 16),
                _buildPermissionsSection(provider),

                const SizedBox(height: 32),
                _buildSectionHeader("SAFETY CONFIGURATION"),
                const SizedBox(height: 16),
                _buildSafetySection(context, provider),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    "Version 1.0.0",
                    style: GoogleFonts.rajdhani(color: Colors.white30),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.rajdhani(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.accent,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDeviceSection(BuildContext context, SensorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                provider.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth,
                color: provider.isConnected ? Colors.green : Colors.white70,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.isConnected ? "Connected" : "Disconnected",
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (provider.defaultDeviceAddress != null)
                      Text(
                        "Default: ${provider.defaultDeviceAddress}",
                        style: GoogleFonts.rajdhani(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (provider.isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => provider.startScan(),
                ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),

          if (provider.isConnected)
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    provider.connectedDeviceName,
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    provider.connectedDeviceAddress ?? "",
                    style: GoogleFonts.rajdhani(color: Colors.white54),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => provider.disconnect(),
                    child: const Text("DISCONNECT"),
                  ),
                ),
                if (!provider.isScanning)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        label: Text(
                          "Scan for other devices",
                          style: GoogleFonts.rajdhani(color: Colors.white70),
                        ),
                        onPressed: () => provider.startScan(),
                      ),
                    ),
                  ),
              ],
            )
          else ...[
            if (provider.scanResults.isEmpty && !provider.isScanning)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "No devices found. Tap refresh to scan.",
                  style: GoogleFonts.rajdhani(color: Colors.white54),
                ),
              ),

            ...provider.scanResults.map((result) {
              bool isDefault =
                  result.device.remoteId.toString() ==
                  provider.defaultDeviceAddress;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : "Unknown Device",
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  result.device.remoteId.toString(),
                  style: GoogleFonts.rajdhani(color: Colors.white54),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDefault
                        ? AppTheme.accent
                        : Colors.white10,
                    foregroundColor: isDefault ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () {
                    provider.connect(result.device);
                    provider.saveSettings(
                      deviceAddress: result.device.remoteId.toString(),
                    );
                  },
                  child: Text(isDefault ? "DEFAULT" : "CONNECT"),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(SensorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPermissionTile(
            "Location Services",
            "Required for BLE Scanning",
            Icons.location_on,
            () => provider.openLocationSettings(),
          ),
          const Divider(color: Colors.white10),
          _buildPermissionTile(
            "Bluetooth Settings",
            "Manage paired devices",
            Icons.settings_bluetooth,
            () => provider.openBluetoothSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: GoogleFonts.rajdhani(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.rajdhani(color: Colors.white54),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white30,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSafetySection(BuildContext context, SensorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "EMERGENCY CONTACT",
            style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.rajdhani(color: Colors.white),
            decoration: _inputDecoration("Contact Name"),
            onChanged: (val) => provider.saveSettings(contactName: val),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numberController,
            style: GoogleFonts.rajdhani(color: Colors.white),
            decoration: _inputDecoration("Phone Number"),
            keyboardType: TextInputType.phone,
            onChanged: (val) => provider.saveSettings(contactNumber: val),
          ),

          const SizedBox(height: 24),
          Text(
            "FALL ACTION",
            style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white10, // Match input fill
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FallAction>(
                value: provider.selectedFallAction,
                dropdownColor: const Color(0xFF051923),
                isExpanded: true,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16),
                items: FallAction.values.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(
                      action.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) provider.saveSettings(action: val);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "COUNTDOWN TIMER",
                style: GoogleFonts.rajdhani(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                "${provider.countdownDuration} sec",
                style: GoogleFonts.rajdhani(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: provider.countdownDuration.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            activeColor: AppTheme.accent,
            inactiveColor: Colors.white10,
            onChanged: (val) => provider.saveSettings(duration: val.toInt()),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
