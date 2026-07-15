import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/pharmacy_prescription_api_service.dart';
import '../../domain/models/prescription_explanation.dart';

class PrescriptionAnalyzerPage extends StatefulWidget {
  const PrescriptionAnalyzerPage({super.key});

  @override
  State<PrescriptionAnalyzerPage> createState() => _PrescriptionAnalyzerPageState();
}

class _PrescriptionAnalyzerPageState extends State<PrescriptionAnalyzerPage> {
  final PharmacyPrescriptionApiService _api = PharmacyPrescriptionApiService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = false;
  String _loadingStep = '';
  Timer? _stepTimer;
  int _currentStepIdx = 0;
  String? _error;
  PrescriptionExplanation? _explanation;
  XFile? _selectedImage;

  final List<String> _loadingSteps = [
    'Subiendo receta...',
    'Leyendo el texto manuscrito...',
    'Gemini está analizando la composición química...',
    'Generando explicaciones en lenguaje sencillo...',
    'Preparando tus recomendaciones...'
  ];

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  void _startLoadingSteps() {
    _currentStepIdx = 0;
    setState(() {
      _loadingStep = _loadingSteps[_currentStepIdx];
    });
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentStepIdx < _loadingSteps.length - 1) {
        _currentStepIdx++;
        if (mounted) {
          setState(() {
            _loadingStep = _loadingSteps[_currentStepIdx];
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _analyzeImage(ImageSource source) async {
    setState(() {
      _error = null;
      _explanation = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = image;
        _loading = true;
      });
      _startLoadingSteps();

      final result = await _api.explainByXFile(image);

      if (!mounted) return;

      _stepTimer?.cancel();

      if (!result.isPrescription || (result.issue != null && result.issue != 'none')) {
        setState(() {
          _error = result.issueMessage ?? 'No pudimos reconocer una receta médica en esta imagen. Por favor, asegúrate de que sea clara y tenga buena luz.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _explanation = result;
        _loading = false;
      });
    } catch (e) {
      _stepTimer?.cancel();
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _goToPharmacySearch() {
    if (_explanation == null) return;
    final meds = _explanation!.medications
        .map((m) => m.name)
        .where((name) => name.isNotEmpty)
        .toList();

    if (meds.isEmpty) return;

    Navigator.pushNamed(
      context,
      AppRoutes.pharmacy,
      arguments: {'prefilledMedications': meds},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideAppBar: false,
      title: const Text('Explicador de Recetas IA'),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Premium
              _buildAIHeader(),
              const SizedBox(height: 24),

              if (_loading)
                _buildLoadingState()
              else if (_error != null)
                _buildErrorState()
              else if (_explanation != null)
                _buildExplanationResult()
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analizador Médico Inteligente',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gemini descifra la letra y te explica dosis, usos y efectos secundarios de forma simple.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeSlideIn(
      child: Column(
        children: [
          AppPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sube la foto de tu receta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Puedes escanear una receta física con tu cámara o subir un archivo de imagen desde tu galería.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _analyzeImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Galería'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _analyzeImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Cámara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return FadeSlideIn(
      child: AppPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 28),
                Text(
                  _loadingStep,
                  key: ValueKey(_loadingStep),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Este proceso tarda unos segundos mientras la IA procesa la imagen...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return FadeSlideIn(
      child: Column(
        children: [
          AppPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudo analizar la receta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectedImage != null
                            ? () => _analyzeImage(ImageSource.gallery)
                            : null,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Intentar de nuevo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _selectedImage = null;
                          });
                        },
                        child: const Text('Subir otra foto'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationResult() {
    final exp = _explanation!;

    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Explicación General / Recomendaciones
          if (exp.patientExplanation != null && exp.patientExplanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF059669)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Indicaciones Generales',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exp.patientExplanation!,
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'Medicamentos Detectados',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // ── Lista de Fármacos desglosados
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exp.medications.length,
            itemBuilder: (ctx, index) {
              final med = exp.medications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMedicationCard(med),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Botón CTA para buscar en farmacias
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton.icon(
              onPressed: _goToPharmacySearch,
              icon: const Icon(Icons.local_pharmacy_rounded),
              label: const Text('Buscar medicamentos en farmacias aliadas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
              ),
            ),
          ),

          // Botón para volver a subir
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _explanation = null;
                  _selectedImage = null;
                });
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Escanear otra receta'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(ExplainedMedication med) {
    return AppPanel(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fármaco Título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ¿Para qué sirve?
            const Text(
              '¿Para qué sirve?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              med.purpose,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),

            // Dosis e instrucciones
            const Text(
              'Dosis y Frecuencia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              med.dosage,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 14),

            const Divider(),
            const SizedBox(height: 8),

            // Precauciones
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    med.precautions,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Efectos secundarios
            if (med.sideEffects.isNotEmpty) ...[
              const Text(
                'Efectos secundarios comunes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: med.sideEffects.map((effect) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      effect,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black87.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
