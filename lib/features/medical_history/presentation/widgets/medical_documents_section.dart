import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_url.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/medical_document_api_service.dart';
import '../../domain/models/patient_medical_document.dart';
import '../pages/medical_document_viewer_page.dart';

class MedicalDocumentsSection extends StatefulWidget {
  final bool readOnly;
  final String? patientId;

  const MedicalDocumentsSection({
    super.key,
    this.readOnly = false,
    this.patientId,
  });

  @override
  State<MedicalDocumentsSection> createState() =>
      _MedicalDocumentsSectionState();
}

class _MedicalDocumentsSectionState extends State<MedicalDocumentsSection> {
  final _service = MedicalDocumentApiService();
  List<PatientMedicalDocument> _docs = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = widget.readOnly && widget.patientId != null
          ? await _service.listPatientDocuments(widget.patientId!)
          : await _service.listMyDocuments();
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los documentos';
        _loading = false;
      });
    }
  }

  String _fullUrl(String path) {
    return ApiUrl.resolve(path);
  }

  Future<void> _upload() async {
    final meta = await showDialog<_UploadMeta>(
      context: context,
      builder: (ctx) => const _UploadDocumentDialog(),
    );
    if (meta == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _snack('No se pudo leer el archivo', isError: true);
      return;
    }

    setState(() => _uploading = true);
    try {
      await _service.upload(
        category: meta.category,
        title: meta.title,
        notes: meta.notes,
        fileName: file.name,
        mimeType: _mimeFor(file.name, file.extension),
        bytes: bytes,
      );
      await _load();
      if (!mounted) return;
      _snack('Documento subido. Tu médico podrá verlo en tu historial.');
    } on ApiException catch (e) {
      _snack(e.message, isError: true);
    } catch (_) {
      _snack('Error al subir el archivo', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _mimeFor(String name, String? ext) {
    final e = (ext ?? name.split('.').last).toLowerCase();
    switch (e) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _delete(PatientMedicalDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteMyDocument(doc.id);
      await _load();
    } on ApiException catch (e) {
      _snack(e.message, isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Exámenes y documentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!widget.readOnly)
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file_rounded, size: 18),
                label: Text(_uploading ? 'Subiendo…' : 'Subir'),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.readOnly
              ? 'Archivos que el paciente compartió (laboratorio, radiografías, etc.).'
              : 'Sube PDF o imágenes para que tu médico los revise antes o durante la consulta.',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red))
        else if (_docs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.readOnly
                  ? 'El paciente aún no ha subido documentos.'
                  : 'Aún no has subido documentos.\nUsa el botón Subir para compartir resultados.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ..._docs.map((d) => _DocumentTile(
                doc: d,
                fullUrl: _fullUrl(d.fileUrl),
                readOnly: widget.readOnly,
                onDelete: () => _delete(d),
                onOpen: () => _openDocument(context, d),
              )),
      ],
    );
  }

  void _openDocument(BuildContext context, PatientMedicalDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalDocumentViewerPage(
          document: doc,
          fileUrl: _fullUrl(doc.fileUrl),
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final PatientMedicalDocument doc;
  final String fullUrl;
  final bool readOnly;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _DocumentTile({
    required this.doc,
    required this.fullUrl,
    required this.readOnly,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.primaryLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(
            doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          doc.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${doc.category.label} · ${doc.fileName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: readOnly
            ? const Icon(Icons.chevron_right_rounded)
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                onPressed: onDelete,
              ),
      ),
    );
  }
}

class _UploadMeta {
  final MedicalDocumentCategory category;
  final String title;
  final String? notes;

  const _UploadMeta({
    required this.category,
    required this.title,
    this.notes,
  });
}

class _UploadDocumentDialog extends StatefulWidget {
  const _UploadDocumentDialog();

  @override
  State<_UploadDocumentDialog> createState() => _UploadDocumentDialogState();
}

class _UploadDocumentDialogState extends State<_UploadDocumentDialog> {
  MedicalDocumentCategory _category = MedicalDocumentCategory.lab;
  final _title = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Subir documento médico'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<MedicalDocumentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: MedicalDocumentCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ej: Hemograma marzo 2026',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_title.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              _UploadMeta(
                category: _category,
                title: _title.text.trim(),
                notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            );
          },
          child: const Text('Elegir archivo'),
        ),
      ],
    );
  }
}
