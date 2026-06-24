import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../services/verification_service.dart';

enum _DocumentSlot { dniFront, dniBack, selfie, certificate }

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key, this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _picker = ImagePicker();
  final _service = VerificationService();

  String? _dniFrontPath;
  String? _dniBackPath;
  String? _selfiePath;
  String? _certificatePath;
  bool _isSubmitting = false;

  List<SubmittedDoc> _existingDocs = const [];
  Map<String, String> _imgHeaders = const {};
  bool _loadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  /// Carga los documentos ya enviados (para que el técnico los vea al volver).
  Future<void> _loadExisting() async {
    final headers = await _service.authImageHeaders();
    final docs = await _service.getMyDocuments();
    if (!mounted) return;
    setState(() {
      _imgHeaders = headers;
      _existingDocs = docs;
      _loadingExisting = false;
    });
  }

  String get _status {
    final technician = widget.profileData?['technician'];
    if (technician is Map && technician['verification_status'] != null) {
      return technician['verification_status'].toString();
    }
    return 'pending';
  }

  String? get _rejectionReason {
    final technician = widget.profileData?['technician'];
    if (technician is Map && technician['rejection_reason'] != null) {
      final reason = technician['rejection_reason'].toString().trim();
      return reason.isEmpty ? null : reason;
    }
    return null;
  }

  bool get _canSubmit =>
      _dniFrontPath != null &&
      _dniBackPath != null &&
      _selfiePath != null &&
      !_isSubmitting;

  Future<void> _chooseSource(_DocumentSlot slot) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'Tomar foto',
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Elegir de galería',
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    await _pickImage(slot, source);
  }

  Future<void> _pickImage(_DocumentSlot slot, ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 86,
    );

    if (image == null || !mounted) return;

    setState(() {
      switch (slot) {
        case _DocumentSlot.dniFront:
          _dniFrontPath = image.path;
        case _DocumentSlot.dniBack:
          _dniBackPath = image.path;
        case _DocumentSlot.selfie:
          _selfiePath = image.path;
        case _DocumentSlot.certificate:
          _certificatePath = image.path;
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      showAppToast(
        context,
        message: 'Sube las 3 fotos requeridas para continuar.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _service.submitIdentityDocuments(
      dniFrontPath: _dniFrontPath!,
      dniBackPath: _dniBackPath!,
      selfiePath: _selfiePath!,
      certificatePath: _certificatePath,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showAppToast(
      context,
      message: result.message,
      type: result.success ? ToastType.success : ToastType.error,
      duration: const Duration(seconds: 4),
    );

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Verificar identidad',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: _loadingExisting
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusNotice(
                      status: _status,
                      rejectionReason: _rejectionReason,
                    ),
                    const SizedBox(height: 18),
                    if (_existingDocs.isNotEmpty) ...[
                      _SubmittedDocsSection(
                        docs: _existingDocs,
                        headers: _imgHeaders,
                        urlForKey: _service.storageUrlForKey,
                      ),
                      const SizedBox(height: 22),
                    ],
                    Text(
                      _existingDocs.isEmpty
                          ? 'Documentos requeridos'
                          : 'Reenviar documentos',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usaremos estas imágenes solo para validar tu cuenta. El bucket es privado y visible para el equipo de revisión.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DocumentTile(
                      title: 'DNI frontal',
                      description:
                          'Foto clara del lado donde aparecen tus datos.',
                      imagePath: _dniFrontPath,
                      onTap: () => _chooseSource(_DocumentSlot.dniFront),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: 'DNI reverso',
                      description: 'Foto clara del reverso del documento.',
                      imagePath: _dniBackPath,
                      onTap: () => _chooseSource(_DocumentSlot.dniBack),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: 'Selfie',
                      description:
                          'Tu rostro debe verse completo y con buena luz.',
                      imagePath: _selfiePath,
                      onTap: () => _chooseSource(_DocumentSlot.selfie),
                    ),
                    const SizedBox(height: 12),
                    _DocumentTile(
                      title: 'Certificado de estudios',
                      description:
                          'Opcional — título, certificado de cursos o constancia de tu oficio.',
                      imagePath: _certificatePath,
                      onTap: () => _chooseSource(_DocumentSlot.certificate),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.neutral300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Enviar a revisión',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.status, this.rejectionReason});

  final String status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      'verified' => (
        color: AppColors.success,
        bg: AppColors.successLight,
        icon: Icons.verified_rounded,
        title: 'Tu identidad ya está verificada',
        body:
            'Si necesitas corregir documentos, puedes reenviarlos para una nueva revisión.',
      ),
      'rejected' => (
        color: AppColors.error,
        bg: AppColors.errorLight,
        icon: Icons.error_outline_rounded,
        title: 'Verificación rechazada',
        body:
            rejectionReason ??
            'Reenvía fotos claras y legibles para volver a revisión.',
      ),
      _ => (
        color: AppColors.warning,
        bg: AppColors.warningLight,
        icon: Icons.schedule_rounded,
        title: 'Pendiente de revisión',
        body:
            'El equipo revisará tus documentos antes de habilitar postulaciones.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.icon, color: config.color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.body,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String description;
  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasImage ? AppColors.primaryLight : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: hasImage
                      ? AppColors.neutral100
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.file(File(imagePath!), fit: BoxFit.cover)
                    : const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasImage ? 'Cambiar foto' : 'Agregar foto',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                hasImage
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: hasImage ? AppColors.success : AppColors.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      ),
      onTap: onTap,
    );
  }
}

/// Sección "Documentos enviados": lo que el técnico ya mandó a revisión, con
/// miniatura (cargada del bucket privado con header de autorización) y estado.
class _SubmittedDocsSection extends StatelessWidget {
  const _SubmittedDocsSection({
    required this.docs,
    required this.headers,
    required this.urlForKey,
  });

  final List<SubmittedDoc> docs;
  final Map<String, String> headers;
  final String Function(String key) urlForKey;

  static const _labels = {
    'dni_front': 'DNI frontal',
    'dni_back': 'DNI reverso',
    'selfie': 'Selfie',
    'certificate': 'Certificado de estudios',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos enviados',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estos son los documentos que ya enviaste a revisión.',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        ...docs.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubmittedDocRow(
              status: d.status,
              label: _labels[d.docType] ?? d.docType,
              imageUrl: urlForKey(d.filePath),
              headers: headers,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmittedDocRow extends StatelessWidget {
  const _SubmittedDocRow({
    required this.status,
    required this.label,
    required this.imageUrl,
    required this.headers,
  });

  final String status;
  final String label;
  final String imageUrl;
  final Map<String, String> headers;

  ({Color color, Color bg, String text}) get _statusStyle => switch (status) {
    'verified' => (
      color: AppColors.success,
      bg: AppColors.successLight,
      text: 'Verificado',
    ),
    'rejected' => (
      color: AppColors.error,
      bg: AppColors.errorLight,
      text: 'Rechazado',
    ),
    _ => (
      color: AppColors.warning,
      bg: AppColors.warningLight,
      text: 'En revisión',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: AppColors.neutral100,
              child: Image.network(
                imageUrl,
                headers: headers,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.description_outlined,
                  color: AppColors.neutral400,
                ),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              s.text,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: s.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
