import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/language_provider.dart';
import '../services/tflite_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  final TFLiteService tfliteService;
  const HomeScreen({super.key, required this.tfliteService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoadingModel = true;
  String? _loadError;

  static const primaryGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      await widget.tfliteService.loadModel();
      setState(() => _isLoadingModel = false);
    } catch (e) {
      setState(() {
        _isLoadingModel = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageFile: File(picked.path),
          tfliteService: widget.tfliteService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(lang.t('Plant Disease Detector', 'தாவர நோய் கண்டறிதல்')),
        actions: [
          TextButton(
            onPressed: () => lang.toggleLanguage(),
            child: Text(
              lang.isTamil ? 'EN' : 'தமிழ்',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingModel
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError(lang)
              : _buildHome(lang),
    );
  }

  Widget _buildError(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              lang.t(
                'Could not load the AI model. Make sure plant_disease_model.tflite, labels.txt and disease_info.json are in assets/.',
                'AI மாடலை ஏற்ற முடியவில்லை. assets/ கோப்புறையில் தேவையான கோப்புகள் இருக்கிறதா என பாருங்கள்.',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(_loadError ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHome(LanguageProvider lang) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.local_florist,
                  size: 90, color: primaryGreen),
            ),
            const SizedBox(height: 24),
            Text(
              lang.t(
                'Take or upload a leaf photo to detect disease',
                'நோயை கண்டறிய இலை புகைப்படத்தை எடுக்கவும் அல்லது பதிவேற்றவும்',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 36),
            _ActionButton(
              icon: Icons.camera_alt,
              label: lang.t('Take Photo', 'புகைப்படம் எடுக்க'),
              color: primaryGreen,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.photo_library,
              label: lang.t('Choose from Gallery', 'கேலரியில் இருந்து தேர்வு'),
              color: const Color(0xFF558B2F),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 32),
            Text(
              lang.t(
                'Tip: use good lighting and fill the frame with the leaf for best results.',
                'குறிப்பு: நல்ல வெளிச்சத்தில், இலையை பெரிதாக எடுத்தால் சிறந்த முடிவு கிடைக்கும்.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
