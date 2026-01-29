import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/sensor_provider.dart';
import '../core/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(provider),
                  const Spacer(),
                  _buildStatusCard(context, provider),
                  const Spacer(),
                  _buildMetricsGrid(provider),
                  const SizedBox(height: 32),
                  if (provider.alertState != AlertState.safe)
                    ElevatedButton(
                      onPressed: () => provider.resetAlarm(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppTheme.textMain,
                        backgroundColor: AppTheme.danger.withOpacity(0.8),
                        side: BorderSide(color: AppTheme.danger, width: 2),
                      ),
                      child: const Text("RESET ALARM"),
                    ),
                  if (!provider.isConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () => provider.retryConnection(),
                        child: const Text("RECONNECT"),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SensorProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "LIFELINK",
          style: GoogleFonts.rajdhani(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.textDim,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: provider.isConnected ? AppTheme.safe.withOpacity(0.2) : AppTheme.danger.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: provider.isConnected ? AppTheme.safe : AppTheme.danger,
            ),
          ),
          child: Row(
            children: [
              Icon(
                provider.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                size: 16,
                color: provider.isConnected ? AppTheme.safe : AppTheme.danger,
              ),
              const SizedBox(width: 8),
              Text(
                provider.isConnected ? "CONNECTED" : "DISCONNECTED",
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: provider.isConnected ? AppTheme.safe : AppTheme.danger,
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
        statusColor = AppTheme.safe;
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        border: Border.all(color: statusColor, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 64, color: statusColor),
          const SizedBox(height: 16),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: statusColor,
              shadows: [
                Shadow(
                  color: statusColor,
                  blurRadius: 10,
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subText,
            style: TextStyle(
              color: AppTheme.textDim,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(SensorProvider provider) {
    return Row(
      children: [
        Expanded(child: _buildMetricTile("G-FORCE", "${provider.gForce.toStringAsFixed(2)}G", Icons.speed)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricTile("PULSE", "${provider.pulse} BPM", Icons.favorite)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricTile("SpO2", "${provider.spo2}%", Icons.water_drop)),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textDim.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppTheme.textDim),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
