import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/database/database_service.dart';
import '../../../core/models/district.dart';
import '../../../core/models/service_category.dart';
import '../../auth/providers/auth_provider.dart';

// Riverpod providers for loading DB lists
final districtsProvider = FutureProvider<List<District>>((ref) async {
  return DatabaseService().fetchActiveDistricts();
});

final categoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  return DatabaseService().fetchActiveCategories();
});

class TechRegistrationScreen extends ConsumerStatefulWidget {
  const TechRegistrationScreen({super.key});

  @override
  ConsumerState<TechRegistrationScreen> createState() => _TechRegistrationScreenState();
}

class _TechRegistrationScreenState extends ConsumerState<TechRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _bioController = TextEditingController();
  
  int? _selectedDistrictId;
  final List<int> _selectedCategoryIds = [];
  bool _isSubmitting = false;
  String _categorySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _bioController.addListener(_onBioChanged);
  }

  void _onBioChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _bioController.removeListener(_onBioChanged);
    _dniController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDistrictId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un distrito'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una especialidad'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(authProvider.notifier).registerAsTechnician(
      dni: _dniController.text.trim(),
      districtId: _selectedDistrictId!,
      bio: _bioController.text.trim(),
      categoryIds: _selectedCategoryIds,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el perfil. Verifica tus datos.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.warningLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pending_actions_rounded,
                      color: AppColors.warning,
                      size: 40,
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  'Registro Enviado',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutral900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu solicitud para unirte como técnico ha sido enviada con éxito.\n\nActualmente está en revisión por nuestro equipo de soporte. Te notificaremos una vez sea verificada para que puedas comenzar a recibir trabajos.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.clientHome);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Entendido',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCategoriesBottomSheet(List<ServiceCategory> allCategories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filtered = allCategories.where((cat) {
              return cat.name.toLowerCase().contains(_categorySearchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Handle indicator bar
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seleccionar Especialidades',
                          style: GoogleFonts.nunito(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.neutral900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.neutral600),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Search Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar especialidad (ej. Pintor, Plomero)...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 22),
                        filled: true,
                        fillColor: AppColors.neutral50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          _categorySearchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textTertiary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No se encontraron especialidades',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                              itemBuilder: (context, index) {
                                final cat = filtered[index];
                                final isChecked = _selectedCategoryIds.contains(cat.id);
                                return CheckboxListTile(
                                  value: isChecked,
                                  activeColor: AppColors.primary,
                                  checkColor: Colors.white,
                                  title: Text(
                                    '${cat.emoji ?? '🛠️'} ${cat.name}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                      color: isChecked ? AppColors.primaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (checked) {
                                    setModalState(() {
                                      if (checked == true) {
                                        _selectedCategoryIds.add(cat.id);
                                      } else {
                                        _selectedCategoryIds.remove(cat.id);
                                      }
                                    });
                                    // Rebuild parent screen in parallel
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  
                  // Sticky bottom button
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Confirmar (${_selectedCategoryIds.length} seleccionadas)',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clear query when closing the bottom sheet
      _categorySearchQuery = '';
    });
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final districtsAsync = ref.watch(districtsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Registro de Técnico',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral800),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium intro header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryLight, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.engineering_outlined, color: AppColors.primary, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ofrece tus servicios profesionales',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Completa los datos para crear tu perfil técnico. El soporte verificará tu solicitud.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: Basic Info
                _buildSectionHeader('1. Información básica y cobertura', Icons.badge_outlined),
                
                // DNI Input
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  enabled: !_isSubmitting,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Número de DNI',
                    hintText: 'Ingresa tus 8 dígitos de DNI',
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu número de DNI';
                    }
                    if (value.length != 8) {
                      return 'El DNI debe tener 8 dígitos numéricos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // District Dropdown
                districtsAsync.when(
                  data: (districts) => DropdownButtonFormField<int>(
                    initialValue: _selectedDistrictId,
                    decoration: InputDecoration(
                      labelText: 'Distrito de Cobertura',
                      hintText: 'Selecciona tu zona de trabajo',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: districts.map((district) {
                      return DropdownMenuItem<int>(
                        value: district.id,
                        child: Text(district.name),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _selectedDistrictId = val),
                    validator: (value) => value == null ? 'Selecciona tu distrito' : null,
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, stackTrace) => const Text('Error al cargar distritos'),
                ),
                
                const SizedBox(height: 12),
                const Divider(height: 24, color: AppColors.borderLight),

                // Section 2: Specialties
                _buildSectionHeader('2. Especialidades de trabajo', Icons.construction_outlined),
                
                categoriesAsync.when(
                  data: (allCategories) {
                    final selectedCats = allCategories.where((c) => _selectedCategoryIds.contains(c.id)).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedCats.isEmpty)
                          InkWell(
                            onTap: () => _openCategoriesBottomSheet(allCategories),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neutral50,
                                border: Border.all(color: AppColors.border, width: 1.2),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.build_circle_outlined, color: AppColors.textSecondary, size: 22),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Seleccionar especialidades...',
                                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
                                ],
                              ),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              ...selectedCats.map((cat) {
                                return InputChip(
                                  label: Text('${cat.emoji ?? '🛠️'} ${cat.name}'),
                                  labelStyle: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  backgroundColor: AppColors.primarySurface,
                                  deleteIconColor: AppColors.primary,
                                  onDeleted: () {
                                    setState(() {
                                      _selectedCategoryIds.remove(cat.id);
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: AppColors.primaryLight, width: 1),
                                  ),
                                );
                              }),
                              
                              // "Add more" chip button
                              ActionChip(
                                label: const Text('+ Añadir'),
                                labelStyle: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide.none,
                                ),
                                onPressed: () => _openCategoriesBottomSheet(allCategories),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (error, stackTrace) => const Text('Error al cargar categorías'),
                ),

                const SizedBox(height: 12),
                const Divider(height: 24, color: AppColors.borderLight),

                // Section 3: Professional Bio
                _buildSectionHeader('3. Perfil profesional', Icons.psychology_outlined),
                
                // Biography
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Biografía Profesional',
                    hintText: 'Cuéntanos sobre tu experiencia, certificaciones o servicios que ofreces...',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cuéntanos un poco sobre ti y tu trabajo';
                    }
                    if (value.length < 20) {
                      return 'La biografía debe tener al menos 20 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mínimo 20 caracteres',
                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                    ),
                    Text(
                      '${_bioController.text.length} / 500',
                      style: AppTypography.caption.copyWith(
                        color: _bioController.text.length < 20
                            ? AppColors.error
                            : AppColors.textTertiary,
                        fontWeight: _bioController.text.length < 20 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Enviar Registro Técnico',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ),
    );
  }
}
