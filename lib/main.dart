import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sensor_provider.dart';
import 'core/app_theme.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const LifeLinkApp());
}

class LifeLinkApp extends StatelessWidget {
  const LifeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: MaterialApp(
        title: 'LifeLink Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const DashboardScreen(),
      ),
    );
  }
}


