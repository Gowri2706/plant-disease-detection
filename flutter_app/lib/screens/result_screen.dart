import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/disease_model.dart';
import '../services/language_provider.dart';
import '../services/tflite_service.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final TFLiteService tfliteService;

  const ResultScreen({
    super.key,
    required this.imageFile,
    required this.tfliteService,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const primaryGreen = Color(0xFF2E7D32);

  bool _loading = true;
  DiseaseInfo? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runPrediction();
  }

  Future<void> _runPrediction() async {
    try {
      final result = await widget.tfliteService.predict(widget.imageFile);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(lang.t('Result', 'முடிவு')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(widget.imageFile, height: 260, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            if (_loading) _buildLoading(lang),
            if (!_loading && _error != null) _buildErrorCard(lang),
            if (!_loading && _error == null && _result == null)
              _buildNotAPlantCard(lang),
            if (!_loading && _result != null) _buildResultCard(lang, _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(LanguageProvider lang) {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(lang.t('Analyzing leaf...', 'இலையை பகுப்பாய்வு செய்கிறது...')),
      ],
    );
  }

  Widget _buildErrorCard(LanguageProvider lang) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(lang.t('Something went wrong.', 'ஏதோ தவறு நடந்தது.')),
            const SizedBox(height: 6),
            Text(_error ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAPlantCard(LanguageProvider lang) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.help_outline, color: Colors.orange, size: 56),
            const SizedBox(height: 12),
            Text(
              lang.t('This is not a plant.', 'இது ஒரு தாவரம் இல்லை.'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              lang.t(
                'The AI is not confident this photo shows a plant leaf clearly. Try a closer, well-lit photo of a single leaf.',
                'இந்த புகைப்படம் ஒரு இலையை தெளிவாக காட்டுகிறதா என்பதில் AI-க்கு நம்பிக்கை இல்லை. நல்ல வெளிச்சத்தில் ஒரு இலையை நெருக்கமாக எடுத்து முயற்சிக்கவும்.',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(LanguageProvider lang, DiseaseInfo info) {
    final confidencePct = (info.confidence * 100).toStringAsFixed(1);
    final statusColor = info.isHealthy ? Colors.green : Colors.deepOrange;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  info.isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang.isTamil ? info.nameTa : info.nameEn,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${lang.t('Confidence', 'நம்பகத்தன்மை')}: $confidencePct%',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const Divider(height: 28),
            Text(
              lang.t('Description', 'விளக்கம்'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(lang.isTamil ? info.descriptionTa : info.descriptionEn),
            const SizedBox(height: 20),
            Text(
              lang.t('Solution', 'தீர்வு'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(lang.isTamil ? info.solutionTa : info.solutionEn),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                lang.t(
                  'AI predictions can occasionally be wrong. For valuable crops, please confirm with a local agriculture expert before taking action.',
                  'AI கணிப்புகள் சில நேரங்களில் தவறாக இருக்கலாம். மதிப்புமிக்க பயிர்களுக்கு, நடவடிக்கை எடுக்கும் முன் உள்ளூர் வேளாண் நிபுணரிடம் உறுதி செய்யவும்.',
                ),
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
