import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/language_provider.dart';
import 'services/tflite_service.dart';

void main() {
  runApp(const PlantDiseaseApp());
}

class PlantDiseaseApp extends StatelessWidget {
  const PlantDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        title: 'Plant Disease Detector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2E7D32),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: HomeScreen(tfliteService: TFLiteService()),
      ),
    );
  }
}
