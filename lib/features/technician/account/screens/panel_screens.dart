import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/services/auth_store.dart';
import '../../../auth/services/district_service.dart';
import '../services/account_stats_service.dart';
import '../services/services_catalog_service.dart';
import '../services/work_posts_service.dart';
import '../../../profile/screens/update_profile_photo_screen.dart';
import 'technician_profile_preview_screen.dart';

// ============================================================================
// SHARED WIDGETS
// ============================================================================

class _GradientDivider extends StatelessWidget {
  const _GradientDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
    );
  }
}

class _PanelAppBar extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _PanelAppBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
          vertical: 12,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.secondaryDark,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _StickyBottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StickyBottomButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. EditProfileScreen
// ============================================================================

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({super.key, this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _auth = AuthService();
  late Map<String, dynamic>? _profileData = widget.profileData;

  Future<void> _refreshProfile() async {
    final fresh = await _auth.getMyTechnicianProfile();
    if (!mounted) return;
    AuthStore.instance.setAuthenticated(fresh);
    setState(() => _profileData = fresh);
  }

  Future<void> _openEditSheet({
    required String title,
    required List<_EditSheetField> fields,
    required Future<({bool success, String? message})> Function(
      Map<String, String> values,
    )
    onSave,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => _EditSheet(title: title, fields: fields, onSave: onSave),
    );
    if (saved == true) await _refreshProfile();
  }

  /// Guarda la casilla "Tengo factura legal" (toggle directo).
  Future<void> _setInvoice(bool value) async {
    final res = await _auth.updateTechnicianProfile(hasInvoice: value);
    if (!mounted) return;
    showAppToast(
      context,
      message: res.success
          ? (value ? 'Factura legal activada.' : 'Factura legal desactivada.')
          : (res.message ?? 'No se pudo guardar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success) await _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final String firstName =
        _profileData?['first_name'] as String? ?? 'Usuario';
    final String lastName = _profileData?['last_name'] as String? ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String avatarUrl = _profileData?['avatar_url'] as String? ?? '';
    final Map<String, dynamic> technician =
        _profileData?['technician'] as Map<String, dynamic>? ?? {};
    final String district =
        technician['district'] as String? ??
        _profileData?['district'] as String? ??
        'Sin especificar';
    final String bio = technician['bio'] as String? ?? 'Sin presentación aún';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            _PanelAppBar(
              title: 'Mi perfil',
              trailing: IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TechnicianPublicPreviewScreen(
                      profileData: _profileData,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: AppColors.secondaryDark,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const _GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    // Avatar section
                    Center(
                      child: Column(
                        children: [
                          ClipOval(
                            child: avatarUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 100,
                                      height: 100,
                                      color: AppColors.neutral200,
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          width: 100,
                                          height: 100,
                                          color: AppColors.neutral200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: AppColors.neutral200,
                                    child: const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => UpdateProfilePhotoScreen(
                                  profile: _profileData,
                                ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.neutral200,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: AppColors.secondaryDark,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Editar',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Editable fields
                    _EditableField(
                      label: 'Nombre público',
                      value: fullName,
                      onEdit: () => _openEditSheet(
                        title: 'Editar nombre',
                        fields: [
                          _EditSheetField(
                            key: 'first',
                            label: 'Nombre',
                            initial:
                                _profileData?['first_name'] as String? ?? '',
                          ),
                          _EditSheetField(
                            key: 'last',
                            label: 'Apellido',
                            initial:
                                _profileData?['last_name'] as String? ?? '',
                          ),
                        ],
                        onSave: (v) => _auth.updateTechnicianProfile(
                          firstName: v['first'],
                          lastName: v['last'],
                        ),
                      ),
                    ),
                    _EditableField(
                      label: 'Nombre completo',
                      value: fullName,
                      onEdit: () => _openEditSheet(
                        title: 'Editar nombre',
                        fields: [
                          _EditSheetField(
                            key: 'first',
                            label: 'Nombre',
                            initial:
                                _profileData?['first_name'] as String? ?? '',
                          ),
                          _EditSheetField(
                            key: 'last',
                            label: 'Apellido',
                            initial:
                                _profileData?['last_name'] as String? ?? '',
                          ),
                        ],
                        onSave: (v) => _auth.updateTechnicianProfile(
                          firstName: v['first'],
                          lastName: v['last'],
                        ),
                      ),
                    ),
                    _EditableField(
                      label: 'Ciudad donde vives',
                      value: district,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CoverageZoneScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    _EditableField(
                      label: 'Presentación / Biografía',
                      value: bio,
                      onEdit: () => _openEditSheet(
                        title: 'Editar presentación',
                        fields: [
                          _EditSheetField(
                            key: 'bio',
                            label: 'Contanos sobre vos y tu experiencia',
                            initial: technician['bio'] as String? ?? '',
                            multiline: true,
                          ),
                        ],
                        onSave: (v) =>
                            _auth.updateTechnicianProfile(bio: v['bio']),
                      ),
                    ),
                    _InvoiceToggleTile(
                      value: technician['has_invoice'] == true,
                      onChanged: _setInvoice,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _GradientDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    // Navigation links
                    _NavigationLink(
                      icon: Icons.description_outlined,
                      label: 'Mi ficha',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TechnicianFichaScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    _NavigationLink(
                      icon: Icons.design_services_outlined,
                      label: 'Mis servicios y habilidades',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ServicesScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    _NavigationLink(
                      icon: Icons.location_on_outlined,
                      label: 'Mis zonas de cobertura',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CoverageZoneScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    _NavigationLink(
                      icon: Icons.help_outline_rounded,
                      label: 'Preguntas y respuestas',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              QuestionsScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    _NavigationLink(
                      icon: Icons.photo_library_outlined,
                      label: 'Fotos de mis trabajos',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              WorkPhotosScreen(profileData: _profileData),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TechnicianFichaScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const TechnicianFichaScreen({super.key, this.profileData});

  @override
  State<TechnicianFichaScreen> createState() => _TechnicianFichaScreenState();
}

class _TechnicianFichaScreenState extends State<TechnicianFichaScreen> {
  final TechnicianAccountStatsService _statsService =
      TechnicianAccountStatsService();
  TechnicianAccountStats _stats = const TechnicianAccountStats();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getStats(profileData: widget.profileData);
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 20, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.secondaryDark,
                        size: 26,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Mi ficha',
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryDark,
                          height: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TechnicianPublicPreviewScreen(
                            profileData: widget.profileData,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.secondaryDark,
                        size: 27,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFDCE2EC)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 38),
                children: [
                  _FichaSection(
                    title: 'Información financiera',
                    items: [
                      _FichaMetric(
                        label: 'Créditos disponibles a utilizar',
                        value: '${_stats.availableCredits}',
                      ),
                      _FichaMetric(
                        label: 'Saldo de créditos comprados',
                        value: '${_stats.paidCreditsBalance}',
                      ),
                      _FichaMetric(
                        label: 'Créditos comprados facturados',
                        value: '${_stats.invoicedCredits}',
                      ),
                      _FichaMetric(
                        label: 'Total pagado',
                        value: _stats.totalPaid.toStringAsFixed(2),
                      ),
                    ],
                  ),
                  _FichaSection(
                    title: 'Actividad en Pedidos',
                    items: [
                      _FichaMetric(
                        label: 'Participaciones',
                        value: '${_stats.participations}',
                      ),
                      _FichaMetric(
                        label: 'Actualmente participando',
                        value: '${_stats.activeParticipations}',
                      ),
                      _FichaMetric(
                        label: 'Pedidos finalizados que gané',
                        value: '${_stats.wonJobs}',
                      ),
                      _FichaMetric(
                        label: 'Pedidos finalizados donde No gané',
                        value: '${_stats.lostJobs}',
                      ),
                      _FichaMetric(
                        label: 'Costo crédito por desbloqueo',
                        value: '${_stats.unlockCreditCost}',
                      ),
                    ],
                  ),
                  _FichaSection(
                    title: 'Créditos Gratuitos',
                    items: [
                      _FichaMetric(
                        label: 'Total de créditos gratuitos',
                        value: '${_stats.freeCredits}',
                      ),
                      _FichaMetric(
                        label: 'Vencimiento de créditos gratuitos',
                        value: _formatDate(_stats.freeCreditsExpiresAt),
                      ),
                    ],
                  ),
                  const _FichaSubscriptionSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FichaMetric {
  const _FichaMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _FichaSection extends StatelessWidget {
  final String title;
  final List<_FichaMetric> items;

  const _FichaSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF697386),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 2, color: const Color(0xFFDCE2EC)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.secondaryDark,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.value,
                                style: GoogleFonts.nunito(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _FichaSubscriptionSection extends StatelessWidget {
  const _FichaSubscriptionSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suscripción PimerPro',
            style: GoogleFonts.nunito(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF697386),
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 2, color: const Color(0xFFDCE2EC)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No tenés suscripción',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryDark,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Actualmente no tenés ninguna suscripción',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF667085),
                          height: 1.1,
                        ),
                      ),
                    ],
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

class _EditSheetField {
  final String key;
  final String label;
  final String initial;
  final bool multiline;

  const _EditSheetField({
    required this.key,
    required this.label,
    this.initial = '',
    this.multiline = false,
  });
}

/// Bottom sheet reutilizable para editar uno o varios campos de texto del
/// perfil. Devuelve `true` por Navigator.pop cuando el guardado fue exitoso.
class _EditSheet extends StatefulWidget {
  final String title;
  final List<_EditSheetField> fields;
  final Future<({bool success, String? message})> Function(
    Map<String, String> values,
  )
  onSave;

  const _EditSheet({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: f.initial),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final values = <String, String>{
      for (final e in _controllers.entries) e.key: e.value.text.trim(),
    };
    final res = await widget.onSave(values);
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      message: res.success
          ? 'Cambios guardados.'
          : (res.message ?? 'No se pudo guardar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPaddingH,
        right: AppSpacing.screenPaddingH,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final f in widget.fields) ...[
            Text(
              f.label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _controllers[f.key],
              maxLines: f.multiline ? 5 : 1,
              minLines: f.multiline ? 3 : 1,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(color: AppColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.neutral200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Guardar',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;

  const _EditableField({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Casilla "Tengo factura legal": un toggle simple (sin pantalla de edición).
class _InvoiceToggleTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InvoiceToggleTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tengo factura legal',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value
                      ? 'Puedo emitir factura a mis clientes'
                      : 'No emito factura',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _NavigationLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.secondaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ServicesScreen
// ============================================================================

class ServicesScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final int? initialCategoryId;

  const ServicesScreen({super.key, this.profileData, this.initialCategoryId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final ServicesCatalogService _catalogService = ServicesCatalogService();

  List<ServiceCatalogCategory> _catalog = const [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await _catalogService.getCatalog();
    final allowed = _allowedCategoryIds();
    final filtered = allowed.isEmpty
        ? <ServiceCatalogCategory>[]
        : cats.where((c) => allowed.contains(c.id)).toList();
    if (!mounted) return;
    setState(() {
      _catalog = filtered;
      _selected
        ..clear()
        ..addAll(
          cats
              .expand((c) => c.services)
              .where((s) => s.selected)
              .map((s) => s.id),
        );
      _loading = false;
    });
  }

  int _selectedCountIn(ServiceCatalogCategory c) =>
      c.services.where((s) => _selected.contains(s.id)).length;

  Set<int> _allowedCategoryIds() {
    final technician = widget.profileData?['technician'];
    final raw = technician is Map ? technician['categories'] : null;
    if (raw is! List) return const {};
    return raw
        .map((item) {
          if (item is Map) return (item['id'] as num?)?.toInt();
          if (item is num) return item.toInt();
          return int.tryParse(item.toString());
        })
        .whereType<int>()
        .toSet();
  }

  void _toggle(int id, bool value) {
    setState(() {
      if (value) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final res = await _catalogService.setServices(_selected.toList());
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      message: res.success
          ? 'Servicios guardados (${_selected.length}).'
          : (res.message ?? 'No se pudo guardar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Mis servicios y habilidades'),
            const _GradientDivider(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _catalog.isEmpty
                  ? const _EmptyServicesState()
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH,
                        vertical: AppSpacing.lg,
                      ),
                      children: [
                        Text(
                          'Marcá los servicios que ofrecés en cada categoría. Los clientes te encontrarán por ellos.',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ..._catalog.map(
                          (c) => _CategoryServicesTile(
                            category: c,
                            selectedCount: _selectedCountIn(c),
                            initiallyExpanded:
                                widget.initialCategoryId == c.id ||
                                _selectedCountIn(c) > 0,
                            isSelected: _selected.contains,
                            onToggle: _toggle,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
            ),
            _StickyBottomButton(
              label: _saving ? 'Guardando...' : 'Guardar (${_selected.length})',
              onTap: _saving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyServicesState extends StatelessWidget {
  const _EmptyServicesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.design_services_outlined,
              size: 56,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Primero elegí tus categorías',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Los servicios se muestran solo dentro de las categorías que ofrecés como técnico.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Categoría expandible con sus servicios como checkboxes. El técnico marca
/// los que ofrece (agregar = marcar, eliminar = desmarcar).
class _CategoryServicesTile extends StatelessWidget {
  final ServiceCatalogCategory category;
  final int selectedCount;
  final bool initiallyExpanded;
  final bool Function(int id) isSelected;
  final void Function(int id, bool value) onToggle;

  const _CategoryServicesTile({
    required this.category,
    required this.selectedCount,
    required this.initiallyExpanded,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
          leading: Text(category.emoji, style: const TextStyle(fontSize: 26)),
          title: Text(
            category.name,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryDark,
            ),
          ),
          subtitle: Text(
            selectedCount == 0
                ? '${category.services.length} servicios'
                : '$selectedCount seleccionado${selectedCount == 1 ? "" : "s"}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selectedCount > 0
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
          ),
          children: category.services.map((s) {
            return CheckboxListTile(
              value: isSelected(s.id),
              onChanged: (v) => onToggle(s.id, v ?? false),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              title: Text(
                s.name,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. CoverageZoneScreen
// ============================================================================

class CoverageZoneScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const CoverageZoneScreen({super.key, this.profileData});

  @override
  State<CoverageZoneScreen> createState() => _CoverageZoneScreenState();
}

class _CoverageZoneScreenState extends State<CoverageZoneScreen> {
  final DistrictService _districtService = DistrictService();
  final AuthService _auth = AuthService();

  List<District> _districts = const [];
  int? _selectedId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final technician = widget.profileData?['technician'];
    _selectedId = technician is Map ? technician['district_id'] as int? : null;
    _load();
  }

  Future<void> _load() async {
    final list = await _districtService.getActiveDistricts();
    if (!mounted) return;
    setState(() {
      _districts = list;
      _loading = false;
    });
  }

  Future<void> _select(District d) async {
    if (_saving) return;
    setState(() {
      _selectedId = d.id;
      _saving = true;
    });
    final res = await _auth.updateTechnicianProfile(districtId: d.id);
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      message: res.success
          ? 'Zona de cobertura: ${d.name}.'
          : (res.message ?? 'No se pudo guardar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success) {
      final fresh = await _auth.getMyTechnicianProfile();
      AuthStore.instance.setAuthenticated(fresh);
    }
  }

  String get _currentName {
    for (final d in _districts) {
      if (d.id == _selectedId) return d.name;
    }
    final t = widget.profileData?['technician'];
    if (t is Map && t['district'] != null) return t['district'].toString();
    return 'Sin asignar';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Mi zona de cobertura'),
            const _GradientDivider(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Elegí tu distrito dentro de la Provincia de Trujillo. '
                            'Solo recibirás pedidos cercanos a esa zona.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zona actual',
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentName,
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Provincia de Trujillo - Perú',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            'Seleccioná tu distrito',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: 2.8,
                                ),
                            itemCount: _districts.length,
                            itemBuilder: (context, index) {
                              final d = _districts[index];
                              final selected = d.id == _selectedId;
                              return GestureDetector(
                                onTap: () => _select(d),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.neutral200,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    d.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.secondaryDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. WorkPhotosScreen
// ============================================================================

class WorkPhotosScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const WorkPhotosScreen({super.key, this.profileData});

  @override
  State<WorkPhotosScreen> createState() => _WorkPhotosScreenState();
}

class _WorkPhotosScreenState extends State<WorkPhotosScreen> {
  final WorkPostsService _service = WorkPostsService();

  List<TechnicianWorkPost> _posts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final posts = await _service.getMyPosts();
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  Future<void> _openPublish() async {
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const PublishWorkPostScreen()),
    );
    if (published == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Trabajos realizados'),
            const _GradientDivider(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _posts.isEmpty
                  ? const _EmptyWorkPosts()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH,
                        vertical: AppSpacing.lg,
                      ),
                      itemBuilder: (context, index) =>
                          _WorkPostCard(post: _posts[index]),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemCount: _posts.length,
                    ),
            ),
            _StickyBottomButton(label: 'Publicar fotos', onTap: _openPublish),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkPosts extends StatelessWidget {
  const _EmptyWorkPosts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPaddingH,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(AppImages.mascot, width: 120, height: 120),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aún no tenés publicaciones',
              style: GoogleFonts.nunito(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Publicá trabajos realizados para que los clientes vean la calidad de tus servicios.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkPostCard extends StatelessWidget {
  final TechnicianWorkPost post;

  const _WorkPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 78,
              height: 78,
              child: imageUrl == null
                  ? Container(
                      color: AppColors.neutral100,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${post.imageUrls.length} foto${post.imageUrls.length == 1 ? '' : 's'} publicada${post.imageUrls.length == 1 ? '' : 's'}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
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

class PublishWorkPostScreen extends StatefulWidget {
  const PublishWorkPostScreen({super.key});

  @override
  State<PublishWorkPostScreen> createState() => _PublishWorkPostScreenState();
}

class _PublishWorkPostScreenState extends State<PublishWorkPostScreen> {
  final ImagePicker _picker = ImagePicker();
  final WorkPostsService _service = WorkPostsService();
  final TextEditingController _descriptionController = TextEditingController();
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (image != null && mounted) {
        setState(() {
          if (_photos.length < 6) _photos.add(image);
        });
      }
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'No se pudo acceder a la cámara o galería.',
        type: ToastType.error,
      );
    }
  }

  Future<void> _submit() async {
    if (_saving) return;
    final description = _descriptionController.text.trim();
    if (_photos.isEmpty || description.isEmpty) {
      showAppToast(
        context,
        message: 'Agrega fotos y describe el trabajo realizado.',
        type: ToastType.info,
      );
      return;
    }

    setState(() => _saving = true);
    final res = await _service.createPost(
      description: description,
      photoPaths: _photos.map((p) => p.path).toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      message: res.success
          ? 'Trabajo publicado en tu perfil.'
          : (res.message ?? 'No se pudo publicar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Publicar trabajo realizado'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publicar un trabajo realizado',
                      style: GoogleFonts.nunito(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryDark,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Es una forma de demostrar la calidad de tus servicios.',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF687386),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _PublishLabel(text: 'Fotos', onHelp: () {}),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < _photos.length; i++)
                          _SelectedPhotoTile(
                            file: _photos[i],
                            onRemove: () => setState(() => _photos.removeAt(i)),
                          ),
                        _PhotoActionTile(
                          icon: Icons.photo_library_outlined,
                          onTap: () => _pick(ImageSource.gallery),
                        ),
                        _PhotoActionTile(
                          icon: Icons.photo_camera_outlined,
                          onTap: () => _pick(ImageSource.camera),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    _PublishLabel(text: 'Detallar el trabajo', onHelp: () {}),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      minLines: 5,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.nunito(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe qué trabajo realizaste...',
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.all(18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD7DFEC),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _StickyBottomButton(
              label: _saving ? 'Publicando...' : 'Publicar trabajo',
              onTap: _saving ? () {} : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishLabel extends StatelessWidget {
  final String text;
  final VoidCallback onHelp;

  const _PublishLabel({required this.text, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4D5A70),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onHelp,
          child: const Icon(Icons.help_outline, color: Color(0xFF6C7482)),
        ),
      ],
    );
  }
}

class _PhotoActionTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PhotoActionTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neutral300, width: 1.4),
        ),
        child: Icon(icon, size: 28, color: AppColors.secondaryDark),
      ),
    );
  }
}

class _SelectedPhotoTile extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _SelectedPhotoTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            File(file.path),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.secondaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. QuestionsScreen
// ============================================================================

class QuestionsScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const QuestionsScreen({super.key, this.profileData});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController _answer1Controller = TextEditingController();
  final TextEditingController _answer2Controller = TextEditingController();
  final TextEditingController _answer3Controller = TextEditingController();
  final AuthService _auth = AuthService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final technician = widget.profileData?['technician'];
    final qa = technician is Map ? technician['qa'] : null;
    if (qa is Map) {
      _answer1Controller.text = qa['q1']?.toString() ?? '';
      _answer2Controller.text = qa['q2']?.toString() ?? '';
      _answer3Controller.text = qa['q3']?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final res = await _auth.updateTechnicianProfile(
      qa: {
        'q1': _answer1Controller.text.trim(),
        'q2': _answer2Controller.text.trim(),
        'q3': _answer3Controller.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      message: res.success
          ? 'Respuestas guardadas.'
          : (res.message ?? 'No se pudo guardar.'),
      type: res.success ? ToastType.success : ToastType.error,
    );
    if (res.success) {
      final fresh = await _auth.getMyTechnicianProfile();
      AuthStore.instance.setAuthenticated(fresh);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _answer3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Preguntas y respuestas'),
            const _GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preguntas y respuestas',
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Los clientes tienen en cuenta estas respuestas como factor de valoración, por lo que contestarlas puede ayudarte a aumentar la confianza en tu trabajo.',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _QuestionField(
                      question:
                          '¿Qué formación y/o experiencia tienes que estén relacionadas con tu trabajo?',
                      controller: _answer1Controller,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _QuestionField(
                      question:
                          '¿Cómo empezaste a trabajar en este sector laboral?',
                      controller: _answer2Controller,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _QuestionField(
                      question:
                          '¿De qué forma sueles presupuestar tus servicios? Por hora, por proyecto, por comisión...',
                      controller: _answer3Controller,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            _StickyBottomButton(
              label: _saving ? 'Guardando...' : 'Guardar cambios',
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  final String question;
  final TextEditingController controller;

  const _QuestionField({required this.question, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: question,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryDark,
                ),
              ),
              TextSpan(
                text: ' (opcional)',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryDark,
          ),
          decoration: InputDecoration(
            hintText: 'Escriba su respuesta aquí...',
            hintStyle: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
