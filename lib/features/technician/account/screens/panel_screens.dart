import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/feedback/app_toast.dart';

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

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({super.key, this.profileData});

  @override
  Widget build(BuildContext context) {
    final String firstName = profileData?['first_name'] as String? ?? 'Usuario';
    final String lastName = profileData?['last_name'] as String? ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String avatarUrl = profileData?['avatar_url'] as String? ?? '';
    final Map<String, dynamic> technician =
        profileData?['technician'] as Map<String, dynamic>? ?? {};
    final String district =
        technician['district'] as String? ??
        profileData?['district'] as String? ??
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
                onPressed: () {
                  showAppToast(
                    context,
                    message: 'Disponible pronto',
                    type: ToastType.info,
                  );
                },
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
                            onTap: () {
                              showAppToast(
                                context,
                                message: 'Disponible pronto',
                                type: ToastType.info,
                              );
                            },
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
                      onEdit: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _EditableField(
                      label: 'Nombre completo',
                      value: fullName,
                      onEdit: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _EditableField(
                      label: 'Ciudad donde vives',
                      value: district,
                      onEdit: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _EditableField(
                      label: 'Presentación / Biografía',
                      value: bio,
                      onEdit: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _EditableField(
                      label: 'Tengo factura legal',
                      value: 'No',
                      onEdit: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _GradientDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    // Navigation links
                    _NavigationLink(
                      icon: Icons.description_outlined,
                      label: 'Mi ficha profesional',
                      onTap: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _NavigationLink(
                      icon: Icons.design_services_outlined,
                      label: 'Mis servicios y habilidades',
                      onTap: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _NavigationLink(
                      icon: Icons.location_on_outlined,
                      label: 'Mis zonas de cobertura',
                      onTap: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _NavigationLink(
                      icon: Icons.help_outline_rounded,
                      label: 'Preguntas y respuestas',
                      onTap: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
                        );
                      },
                    ),
                    _NavigationLink(
                      icon: Icons.photo_library_outlined,
                      label: 'Fotos de mis trabajos',
                      onTap: () {
                        showAppToast(
                          context,
                          message: 'Disponible pronto',
                          type: ToastType.info,
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

class ServicesScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const ServicesScreen({super.key, this.profileData});

  static const Map<String, String> _serviceEmojis = {
    'Albañil': '🧱',
    'Albañilería': '🧱',
    'Electricista': '⚡',
    'Electricidad': '⚡',
    'Pintura': '🎨',
    'Pintor': '🎨',
    'Plomero': '🔧',
    'Plomería': '🔧',
    'Aire Acondicionado': '❄️',
    'Climatización': '❄️',
    'Piscinas': '🏊',
    'Jardinería': '🌿',
    'Jardinero': '🌿',
    'Contratista': '🏗️',
    'Construcción': '🏗️',
    'Carpintería': '🪚',
    'Carpintero': '🪚',
    'Cerrajería': '🔑',
    'Cerrajero': '🔑',
    'Limpieza': '🧹',
    'Mudanzas': '📦',
    'Techista': '🏠',
    'Gasista': '🔥',
    'Herrero': '⚒️',
    'Herrería': '⚒️',
  };

  String _getEmoji(String categoryName) {
    for (final entry in _serviceEmojis.entries) {
      if (categoryName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return '🛠️';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> technician =
        profileData?['technician'] as Map<String, dynamic>? ?? {};
    final List<dynamic> categories =
        technician['categories'] as List<dynamic>? ?? [];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Mis servicios'),
            const _GradientDivider(),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPaddingH,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.handyman_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Aún no tenés servicios agregados',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Agregá tus servicios para que los clientes puedan encontrarte.',
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPaddingH,
                        vertical: AppSpacing.xl,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category =
                            categories[index] as Map<String, dynamic>? ?? {};
                        final String name =
                            category['name'] as String? ?? 'Servicio';
                        final String description =
                            category['description'] as String? ??
                            'Sin descripción';
                        final String emoji = _getEmoji(name);

                        return _ServiceCard(
                          name: name,
                          description: description,
                          emoji: emoji,
                          onEdit: () {
                            showAppToast(
                              context,
                              message: 'Disponible pronto',
                              type: ToastType.info,
                            );
                          },
                          onDelete: () {
                            showAppToast(
                              context,
                              message: 'Disponible pronto',
                              type: ToastType.info,
                            );
                          },
                        );
                      },
                    ),
            ),
            _StickyBottomButton(
              label: 'Agregar servicio',
              onTap: () {
                showAppToast(
                  context,
                  message: 'Disponible pronto',
                  type: ToastType.info,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final String description;
  final String emoji;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.name,
    required this.description,
    required this.emoji,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 38)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.secondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Editar servicios',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. CoverageZoneScreen
// ============================================================================

class CoverageZoneScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const CoverageZoneScreen({super.key, this.profileData});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> technician =
        profileData?['technician'] as Map<String, dynamic>? ?? {};
    final String district =
        technician['district'] as String? ??
        profileData?['district'] as String? ??
        'Provincia de Trujillo';
    final List<String> districts = [
      'Trujillo',
      'La Esperanza',
      'El Porvenir',
      'Víctor Larco',
      'Huanchaco',
      'Laredo',
    ];

    final List<String> availableZones = [
      'La Libertad',
      'Lima',
      'Arequipa',
      'Cusco',
      'Piura',
      'Lambayeque',
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            const _PanelAppBar(title: 'Mi zona de cobertura'),
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
                      'Este es el listado de las zonas donde podrás brindar tus servicios. Recordá que solo recibirás pedidos en las zonas mencionadas.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Current zone card
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
                            district,
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            districts.join(', '),
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  showAppToast(
                                    context,
                                    message: 'Disponible pronto',
                                    type: ToastType.info,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Editar ciudades',
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  showAppToast(
                                    context,
                                    message: 'Disponible pronto',
                                    type: ToastType.info,
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    // Select zones section
                    Text(
                      'Seleccionar zonas',
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
                      itemCount: availableZones.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showAppToast(
                              context,
                              message: 'Disponible pronto',
                              type: ToastType.info,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.neutral200),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              availableZones[index],
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
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

class WorkPhotosScreen extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const WorkPhotosScreen({super.key, this.profileData});

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
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPaddingH,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        AppImages.mascot,
                        width: 140,
                        height: 140,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Aún no tenés publicaciones',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Da a conocer tu trabajo y experiencia a través de fotos.',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _StickyBottomButton(
              label: 'Publicar fotos',
              onTap: () {
                showAppToast(
                  context,
                  message: 'Disponible pronto',
                  type: ToastType.info,
                );
              },
            ),
          ],
        ),
      ),
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
              label: 'Guardar cambios',
              onTap: () {
                showAppToast(
                  context,
                  message: 'Disponible pronto',
                  type: ToastType.info,
                );
              },
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
