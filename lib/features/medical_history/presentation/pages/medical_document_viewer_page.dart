import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../../../../core/utils/open_external_url.dart';
import '../../domain/models/patient_medical_document.dart';

/// Visor a pantalla completa de exámenes (imagen o PDF).
class MedicalDocumentViewerPage extends StatefulWidget {
  final PatientMedicalDocument document;
  final String fileUrl;

  const MedicalDocumentViewerPage({
    super.key,
    required this.document,
    required this.fileUrl,
  });

  @override
  State<MedicalDocumentViewerPage> createState() =>
      _MedicalDocumentViewerPageState();
}

class _MedicalDocumentViewerPageState extends State<MedicalDocumentViewerPage> {
  Uint8List? _bytes;
  String? _error;
  bool _loading = true;

  PatientMedicalDocument get doc => widget.document;

  @override
  void initState() {
    super.initState();
    if (doc.isImage) {
      _loading = false;
    } else {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode != 200) {
        throw Exception('No se pudo cargar el archivo (${response.statusCode})');
      }
      if (!mounted) return;
      setState(() {
        _bytes = response.bodyBytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el documento. Verifica tu conexión.';
        _loading = false;
      });
    }
  }

  Future<void> _openExternally() async {
    final ok = await openExternalUrl(widget.fileUrl);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'En este dispositivo usa el visor integrado o prueba desde la app web.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: doc.isImage ? Colors.black : const Color(0xFF525659),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.title,
              style: const TextStyle(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${doc.category.label} · ${doc.fileName}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir en otra pestaña',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openExternally,
          ),
        ],
      ),
      body: doc.isImage ? _buildImageBody() : _buildDocumentBody(),
    );
  }

  Widget _buildImageBody() {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Image.network(
          widget.fileUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const CircularProgressIndicator(color: Colors.white);
          },
          errorBuilder: (context, error, stackTrace) => _buildError(
            onRetry: null,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return _buildError(onRetry: _loadFile);
    }
    final bytes = _bytes;
    if (bytes == null || bytes.isEmpty) {
      return _buildError(onRetry: _loadFile);
    }

    if (doc.isPdf) {
      return PdfPreview(
        build: (_) async => bytes,
        allowPrinting: true,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: doc.fileName,
        scrollViewDecoration: const BoxDecoration(color: Color(0xFF525659)),
      );
    }

    // Otro tipo: intentar como imagen por si el mime no coincide.
    return Center(
      child: InteractiveViewer(
        child: Image.memory(bytes, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildError({VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'No se pudo mostrar el archivo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openExternally,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir en pestaña nueva'),
            ),
          ],
        ),
      ),
    );
  }
}
