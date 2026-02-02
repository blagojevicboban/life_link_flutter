import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';

import '../providers/sensor_provider.dart';
import '../core/app_theme.dart';
import 'settings_screen.dart'; // Import SettingsScreen

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark background matching the watch face style
    return Scaffold(
      backgroundColor: const Color(0xFF020E15), // Deep navy/black
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(provider),

                                const SizedBox(height: 32),
                                // Main Status Card with rounded/circular aesthetic
                                // Removed Expanded to prevent overflow/collapse in IntrinsicHeight
                                _buildStatusCard(context, provider),

                                const SizedBox(height: 24),
                                // Metrics Grid
                                _buildMetricsGrid(provider),

                                const Spacer(),
                                // Logo Section
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        "Info",
                                        style: GoogleFonts.rajdhani(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Life",
                                            style: GoogleFonts.rajdhani(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Image.asset(
                                            'assets/logo128.png',
                                            height: 80,
                                            width: 80,
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            "Link",
                                            style: GoogleFonts.rajdhani(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),
                                if (provider.alertState != AlertState.safe)
                                  ElevatedButton(
                                    onPressed: () => provider.resetAlarm(),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: AppTheme.danger
                                          .withOpacity(0.9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.danger,
                                        width: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text("RESET ALARM"),
                                  ),

                                // Map Section (Visible on Alarm with valid location)
                                if (provider.alertState == AlertState.alarm &&
                                    provider.fallLocation != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.danger,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: FlutterMap(
                                          options: MapOptions(
                                            initialCenter:
                                                provider.fallLocation!,
                                            initialZoom: 15.0,
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName:
                                                  'com.lifelink.app',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: provider.fallLocation!,
                                                  width: 80,
                                                  height: 80,
                                                  child: const Icon(
                                                    Icons.location_on,
                                                    color: Colors.red,
                                                    size: 40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: provider.isConnected
                                      ? ElevatedButton(
                                          onPressed: () =>
                                              provider.disconnect(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.danger
                                                .withOpacity(0.2),
                                            foregroundColor: AppTheme.danger,
                                            side: BorderSide(
                                              color: AppTheme.danger,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: const Text("DISCONNECT"),
                                        )
                                      : ElevatedButton(
                                          onPressed: () =>
                                              provider.retryConnection(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyan
                                                .withOpacity(0.2),
                                            foregroundColor: Colors.cyan,
                                            side: const BorderSide(
                                              color: Colors.cyan,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: const Text("RECONNECT"),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Countdown Overlay
              if (provider.isCountingDown)
                Container(
                  color: Colors.black.withOpacity(
                    0.9,
                  ), // Darken background primarily
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "FALL DETECTED!",
                        style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Requesting help in",
                        style: GoogleFonts.rajdhani(
                          color: Colors.white70,
                          fontSize: 18,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${provider.currentCountdown}",
                          style: GoogleFonts.rajdhani(
                            color: Colors.red,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 200,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => provider.cancelFall(),
                          child: Text(
                            "I'M OK",
                            style: GoogleFonts.rajdhani(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          // Trigger immediately
                          // provider.forceExecuteAction(); // Optional method if we want instant trigger
                          // For now user can just wait.
                        },
                        child: Text(
                          "Sending to: ${provider.emergencyContactName.isNotEmpty ? provider.emergencyContactName : 'Emergency'}",
                          style: GoogleFonts.rajdhani(
                            color: Colors.white30,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(SensorProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Using visible placeholder for Impact similar to design
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "IMPACT (G)",
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              provider.gForce.toStringAsFixed(2),
              style: GoogleFonts.rajdhani(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: provider.isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20), // More rounded
            border: Border.all(
              color: provider.isConnected ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            children: [
              Icon(
                provider.isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                size: 16,
                color: provider.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                provider.isConnected && provider.batteryLevel > 0
                    ? "BAT ${provider.batteryLevel}%"
                    : "BLT",
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, SensorProvider provider) {
    Color statusColor;
    String statusText;
    String subText;
    IconData statusIcon;

    switch (provider.alertState) {
      case AlertState.safe:
        statusColor = const Color(0xFF00E5FF); // Cyan
        statusText = "SYSTEM NOMINAL";
        subText = "Monitoring Active";
        statusIcon = Icons.shield_outlined;
        break;
      case AlertState.warning:
        statusColor = AppTheme.warning;
        statusText = "MOVEMENT DETECTED";
        subText = "Analyzing Impact Pattern...";
        statusIcon = Icons.warning_amber_rounded;
        break;
      case AlertState.alarm:
        statusColor = AppTheme.danger;
        statusText = "FALL DETECTED";
        subText = "CRITICAL ALERT";
        statusIcon = Icons.health_and_safety_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF051923), // Slightly lighter dark for card
        shape: BoxShape.circle, // Circular shape key for design
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, size: 48, color: statusColor),
          const SizedBox(height: 12),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
              shadows: [
                Shadow(color: statusColor.withOpacity(0.8), blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(SensorProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMetricTile(
          "PULSE",
          "${provider.pulse} BPM",
          Icons.favorite,
          Colors.redAccent,
        ),
        _buildMetricTile(
          "SpO2",
          "${provider.spo2}%",
          Icons.water_drop,
          Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
