import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/buttons/gradient_pill_button.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../auth/screens/district_selector_screen.dart';
import '../../../auth/services/district_service.dart';
import '../../home/services/category_service.dart';
import '../services/request_service.dart';
import 'request_result_screen.dart';
import '../widgets/request_widgets.dart';

/// Modo de fecha elegido en el paso 3.
enum _DateMode { flexible, choose, urgent }

/// Flujo "Pedir un servicio" en 4 pasos (descripción+categoría, ubicación,
/// fecha, resumen). Publica un pedido real (queda en revisión del admin).
class RequestServiceWizardScreen extends StatefulWidget {
  const RequestServiceWizardScreen({super.key, this.initialCategoryName});

  /// Nombre de categoría preseleccionada (p.ej. al entrar desde el carrusel del
  /// home). Se resuelve contra las categorías cargadas de la BD.
  final String? initialCategoryName;

  @override
  State<RequestServiceWizardScreen> createState() =>
      _RequestServiceWizardScreenState();
}

class _RequestServiceWizardScreenState
    extends State<RequestServiceWizardScreen> {
  static const int _totalSteps = 4;
  int _step = 1; // 1..4

  final _descriptionController = TextEditingController();
  final _barrioController = TextEditingController();

  final CategoryService _categoryService = CategoryService();
  final RequestService _requestService = RequestService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();
  final AiService _ai = AiService();

  List<ServiceCategory> _categories = const [];
  ServiceCategory? _selectedCategory;
  District? _selectedDistrict;
  bool _suggesting = false;
  final List<XFile> _photos = [];
  static const int _maxPhotos = 4;

  _DateMode _dateMode = _DateMode.flexible;
  int _selectedDay = 0;
  bool _needsInvoice = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryService.getActiveCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      // Resolver la categoría preseleccionada (por nombre) contra la lista real.
      final name = widget.initialCategoryName;
      if (name != null && _selectedCategory == null) {
        for (final c in cats) {
          if (c.name == name) {
            _selectedCategory = c;
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _barrioController.dispose();
    super.dispose();
  }

  /// Agrega fotos desde galería (múltiple) o cámara, respetando el máximo.
  Future<void> _pickPhotos({required bool fromCamera}) async {
    try {
      if (fromCamera) {
        final shot = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          maxWidth: 1600,
        );
        if (shot != null) _addPhotos([shot]);
      } else {
        final picked = await _imagePicker.pickMultiImage(
          imageQuality: 70,
          maxWidth: 1600,
        );
        if (picked.isNotEmpty) _addPhotos(picked);
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'No se pudo acceder a las fotos.',
        type: ToastType.error,
      );
    }
  }

  void _addPhotos(List<XFile> incoming) {
    if (!mounted) return;
    setState(() {
      final remaining = _maxPhotos - _photos.length;
      if (remaining <= 0) return;
      _photos.addAll(incoming.take(remaining));
    });
    if (incoming.length > _maxPhotos - (_photos.length - incoming.length)) {
      showAppToast(
        context,
        message: 'Puedes adjuntar hasta $_maxPhotos fotos.',
        type: ToastType.info,
      );
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  /// Pide a la IA que sugiera la categoría a partir de la descripción.
  Future<void> _suggestCategory() async {
    final desc = _descriptionController.text.trim();
    if (desc.length < 10) {
      showAppToast(
        context,
        message: 'Escribe primero qué necesitas.',
        type: ToastType.info,
      );
      return;
    }
    if (_categories.isEmpty || _suggesting) return;

    setState(() => _suggesting = true);
    final cats = _categories
        .map((c) => {'id': c.id.toString(), 'name': c.name})
        .toList();
    final suggestion = await _ai.suggestCategory(desc, cats);
    if (!mounted) return;

    // 1) Resultado de la IA (si vino con confianza).
    ServiceCategory? match;
    if (suggestion != null && suggestion.isConfident) {
      for (final c in _categories) {
        if (c.id.toString() == suggestion.categoryId) {
          match = c;
          break;
        }
      }
    }
    // 2) Fallback local por palabras clave (funciona aunque la IA no responda).
    match ??= _localGuessCategory(desc);

    setState(() => _suggesting = false);

    final chosen = match;
    if (chosen != null) {
      setState(() => _selectedCategory = chosen);
      showAppToast(
        context,
        message: 'Categoría sugerida: ${chosen.name}',
        type: ToastType.success,
      );
    } else {
      showAppToast(
        context,
        message: 'No pudimos sugerir una categoría. Elígela manualmente.',
        type: ToastType.info,
      );
    }
  }

  /// Normaliza texto: minúsculas y sin tildes/ñ, para comparar por palabras.
  String _norm(String s) {
    s = s.toLowerCase();
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      sb.write(i >= 0 ? to[i] : ch);
    }
    return sb.toString();
  }

  /// Adivina la categoría localmente a partir de la descripción (palabras del
  /// nombre + sinónimos). Devuelve null si nada coincide.
  ServiceCategory? _localGuessCategory(String desc) {
    final d = _norm(desc);
    final synonyms = <(List<String>, String)>[
      (['pint', 'cuadro', 'pared', 'mural', 'barniz'], 'pintur'),
      (['electr', 'luz', 'enchufe', 'corto', 'cable', 'foco', 'tomacorr'], 'electr'),
      (['plome', 'gasfi', 'cano', 'tuberi', 'fuga', 'desague', 'inodoro', 'grifo', 'caño'], 'gasf'),
      (['limpie', 'limpiar', 'aseo'], 'limpie'),
      (['carpint', 'mueble', 'madera', 'closet', 'ropero'], 'carpint'),
      (['albani', 'cement', 'construc', 'ladrillo', 'tarrajeo'], 'alban'),
      (['cerraj', 'llave', 'cerradura', 'candado', 'chapa'], 'cerraj'),
      (['jardin', 'cesped', 'pasto', 'planta', 'poda'], 'jardin'),
      (['mudanz', 'flete', 'carga', 'transport'], 'mudanz'),
      (['aire', 'climatiz', 'refriger', 'split'], 'aire'),
      (['comput', 'laptop', 'impresora', 'redes', 'software'], 'comput'),
      (['cocin', 'chef', 'comida', 'banquet', 'reposter'], 'cocin'),
      (['costur', 'sastr', 'bastas'], 'costur'),
      (['mecan', 'auto', 'carro', 'motor'], 'mecan'),
    ];

    ServiceCategory? best;
    var bestScore = 0;
    for (final c in _categories) {
      final name = _norm(c.name);
      var score = 0;
      for (final w in name.split(RegExp(r'[^a-z]+'))) {
        if (w.length >= 4 && d.contains(w)) score += 2;
      }
      for (final (keys, hint) in synonyms) {
        if (name.contains(hint) && keys.any(d.contains)) score += 3;
      }
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return bestScore > 0 ? best : null;
  }

  /// Valida el paso actual antes de avanzar/publicar.
  bool _validateStep() {
    switch (_step) {
      case 1:
        if (_selectedCategory == null) {
          showAppToast(
            context,
            message: 'Elige una categoría.',
            type: ToastType.warning,
          );
          return false;
        }
        if (_descriptionController.text.trim().length < 10) {
          showAppToast(
            context,
            message: 'Describe tu pedido (mínimo 10 caracteres).',
            type: ToastType.warning,
          );
          return false;
        }
        return true;
      case 2:
        if (_selectedDistrict == null) {
          showAppToast(
            context,
            message: 'Elige tu distrito.',
            type: ToastType.warning,
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _onBack() {
    if (_step > 1) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _onNext() {
    if (_publishing) return;
    if (!_validateStep()) return;
    if (_step < _totalSteps) {
      setState(() => _step++);
    } else {
      _publish();
    }
  }

  /// Convierte el modo de fecha en una fecha preferida (o null si es flexible).
  DateTime? _preferredDate() {
    switch (_dateMode) {
      case _DateMode.flexible:
        return null;
      case _DateMode.urgent:
        return DateTime.now();
      case _DateMode.choose:
        return DateTime.now().add(Duration(days: _selectedDay));
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);

    // GPS best-effort: si se niega, el pedido se publica igual (sin coords).
    final pos = await _locationService.getCurrentLatLng();

    // Subir fotos (best-effort): las que fallen se omiten.
    final imageUrls = _photos.isEmpty
        ? const <String>[]
        : await _requestService.uploadPhotos(
            _photos.map((x) => x.path).toList(),
          );

    final result = await _requestService.createRequest(
      categoryId: _selectedCategory!.id,
      districtId: _selectedDistrict!.id,
      title: _selectedCategory!.name,
      description: _descriptionController.text.trim(),
      preferredDate: _preferredDate(),
      needsInvoice: _needsInvoice,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      address: _barrioController.text.trim().isEmpty
          ? null
          : _barrioController.text.trim(),
      imageUrls: imageUrls.isEmpty ? null : imageUrls,
    );

    if (!mounted) return;
    setState(() => _publishing = false);

    if (result.success) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestResultScreen(requestId: result.requestId),
        ),
      );
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo publicar el pedido.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header: back + título + progreso ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.screenPaddingH,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: _onBack,
                    ),
                    Text(
                      'Pedir un servicio',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingH,
                  vertical: AppSpacing.sm,
                ),
                child: StepProgressBar(total: _totalSteps, current: _step),
              ),

              // ── Contenido del paso ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPaddingH,
                    AppSpacing.md,
                    AppSpacing.screenPaddingH,
                    AppSpacing.xxl,
                  ),
                  child: _buildStep(),
                ),
              ),

              // ── Botón inferior ──
              RequestBottomBar(
                child: GradientPillButton(
                  label: _publishing
                      ? 'Publicando...'
                      : (_step < _totalSteps ? 'Siguiente' : 'Publicar'),
                  onTap: _onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Elige una categoría',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _categories
                    .map(
                      (c) => ListTile(
                        leading: Text(
                          c.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(c.name, style: AppTypography.bodyLarge),
                        trailing: _selectedCategory?.id == c.id
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedCategory = c);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDistrictPicker() async {
    final result = await Navigator.of(context).push<District>(
      MaterialPageRoute(
        builder: (_) =>
            DistrictSelectorScreen(currentSelection: _selectedDistrict),
      ),
    );
    if (result != null) {
      setState(() => _selectedDistrict = result);
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return _DescriptionStep(
          controller: _descriptionController,
          categories: _categories,
          selectedCategory: _selectedCategory,
          onSelectCategory: (c) => setState(() => _selectedCategory = c),
          onPickCategory: _openCategoryPicker,
          onDescriptionChanged: () => setState(() {}),
          photos: _photos,
          onAddFromGallery: () => _pickPhotos(fromCamera: false),
          onAddFromCamera: () => _pickPhotos(fromCamera: true),
          onRemovePhoto: _removePhoto,
          suggesting: _suggesting,
          onSuggestCategory: _suggestCategory,
        );
      case 2:
        return _LocationStep(
          districtName: _selectedDistrict?.name,
          barrioController: _barrioController,
          onDistrictTap: _openDistrictPicker,
        );
      case 3:
        return _DateStep(
          mode: _dateMode,
          selectedDay: _selectedDay,
          needsInvoice: _needsInvoice,
          onModeChanged: (m) => setState(() => _dateMode = m),
          onDaySelected: (i) => setState(() => _selectedDay = i),
          onInvoiceChanged: (v) => setState(() => _needsInvoice = v),
        );
      default:
        return const _SummaryStep();
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 1 — Descripción
// ═══════════════════════════════════════════════════════════
class _DescriptionStep extends StatelessWidget {
  const _DescriptionStep({
    required this.controller,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.onPickCategory,
    required this.onDescriptionChanged,
    required this.photos,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onRemovePhoto,
    required this.suggesting,
    required this.onSuggestCategory,
  });

  final TextEditingController controller;
  final List<ServiceCategory> categories;
  final ServiceCategory? selectedCategory;
  final ValueChanged<ServiceCategory> onSelectCategory;
  final VoidCallback onPickCategory;
  final VoidCallback onDescriptionChanged;
  final List<XFile> photos;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromCamera;
  final ValueChanged<int> onRemovePhoto;
  final bool suggesting;
  final VoidCallback onSuggestCategory;

  @override
  Widget build(BuildContext context) {
    final descError =
        controller.text.isNotEmpty && controller.text.trim().length < 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pedir un servicio',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Categoría: carrusel de emojis + "Ver todos" ──
        Row(
          children: [
            Expanded(child: _FieldLabel('Categoría')),
            GestureDetector(
              onTap: onPickCategory,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver todos',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _CategoryEmojiCarousel(
          categories: categories,
          selected: selectedCategory,
          onSelect: onSelectCategory,
        ),

        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                '¿Qué estás necesitando?',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const HelpBadge(
              message:
                  'Describe lo mejor posible tu necesidad, así los trabajadores '
                  'podrán enviarte un presupuesto más preciso y detallado.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Área de texto multilínea ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: descError ? AppColors.error : AppColors.border,
              width: descError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            onChanged: (_) => onDescriptionChanged(),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText:
                  'ej: Algún albañil que termine mi casa...\n'
                  'Quiero pintar mi sala, 30 metros cuadrado',
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),

        // ── Validación inline (mínimo 10 caracteres) ──
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: descError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mínimo 10 caracteres',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Sugerir categoría con IA ──
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: suggesting ? null : onSuggestCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (suggesting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    suggesting ? 'Pensando...' : 'Sugerir categoría con IA',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Adjuntar fotos (opcional) ──
        Text(
          'Agrega fotos (opcional)',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Ayuda al técnico a entender mejor el trabajo.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _PhotoButton(
              icon: Icons.photo_library_outlined,
              onTap: onAddFromGallery,
            ),
            const SizedBox(width: AppSpacing.sm),
            _PhotoButton(
              icon: Icons.photo_camera_outlined,
              onTap: onAddFromCamera,
            ),
            const SizedBox(width: AppSpacing.sm),
            // ── Miniaturas ──
            Expanded(
              child: SizedBox(
                height: 64,
                child: photos.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (_, i) => _PhotoThumb(
                          file: photos[i],
                          onRemove: () => onRemovePhoto(i),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carrusel horizontal de categorías (emoji + nombre) para elegir rápido.
/// Se desplaza automáticamente para mostrar la categoría seleccionada.
class _CategoryEmojiCarousel extends StatefulWidget {
  const _CategoryEmojiCarousel({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<ServiceCategory> categories;
  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory> onSelect;

  @override
  State<_CategoryEmojiCarousel> createState() => _CategoryEmojiCarouselState();
}

class _CategoryEmojiCarouselState extends State<_CategoryEmojiCarousel> {
  final ScrollController _controller = ScrollController();

  // Ancho de cada ítem (68) + separador (AppSpacing.sm).
  static const double _itemExtent = 68 + AppSpacing.sm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _CategoryEmojiCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al cambiar la selección (o al resolverse una preseleccionada), centrarla.
    if (widget.selected?.id != oldWidget.selected?.id ||
        widget.categories.length != oldWidget.categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    final sel = widget.selected;
    if (sel == null || !_controller.hasClients) return;
    final i = widget.categories.indexWhere((c) => c.id == sel.id);
    if (i < 0) return;
    final viewport = _controller.position.viewportDimension;
    final target = (i * _itemExtent) - (viewport / 2) + (_itemExtent / 2);
    final clamped = target.clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final c = widget.categories[i];
          final sel = widget.selected?.id == c.id;
          return GestureDetector(
            onTap: () => widget.onSelect(c),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primarySurface : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.border,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall.copyWith(
                      color: sel ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 26),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.file(
            File(file.path),
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 2 — Ubicación
// ═══════════════════════════════════════════════════════════
class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.districtName,
    required this.barrioController,
    required this.onDistrictTap,
  });

  final String? districtName;
  final TextEditingController barrioController;
  final VoidCallback onDistrictTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicación',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '¿Dónde se realizará el trabajo?.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Distrito ──
        Row(
          children: [
            Expanded(child: _FieldLabel('Distrito')),
            const HelpBadge(
              message:
                  'Elegí el distrito donde se realizará el trabajo para '
                  'mostrarte prestadores cercanos.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FakeSelectField(
          value: districtName ?? 'Seleccione su distrito',
          onTap: onDistrictTap,
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Dirección/referencia (opcional) ──
        _FieldLabel('Dirección o referencia', optional: true),
        const SizedBox(height: AppSpacing.xs),
        _PlainInput(controller: barrioController, hint: 'Ej: Av. España 123'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 3 — Fecha
// ═══════════════════════════════════════════════════════════
class _DateStep extends StatelessWidget {
  const _DateStep({
    required this.mode,
    required this.selectedDay,
    required this.needsInvoice,
    required this.onModeChanged,
    required this.onDaySelected,
    required this.onInvoiceChanged,
  });

  final _DateMode mode;
  final int selectedDay;
  final bool needsInvoice;
  final ValueChanged<_DateMode> onModeChanged;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<bool> onInvoiceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha',
          style: AppTypography.displaySmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Indicá cuando necesitas que se realice o se empiece el trabajo.',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Modos (en una sola fila) ──
        Row(
          children: [
            Expanded(
              child: SelectableChip(
                expand: true,
                label: 'Soy flexible',
                selected: mode == _DateMode.flexible,
                onTap: () => onModeChanged(_DateMode.flexible),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SelectableChip(
                expand: true,
                label: 'Elegir fecha',
                selected: mode == _DateMode.choose,
                onTap: () => onModeChanged(_DateMode.choose),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SelectableChip(
                expand: true,
                label: 'Urgente',
                selected: mode == _DateMode.urgent,
                onTap: () => onModeChanged(_DateMode.urgent),
              ),
            ),
          ],
        ),

        // ── Selector de días (solo en "Elegir fecha") ──
        if (mode == _DateMode.choose) ...[
          const SizedBox(height: AppSpacing.lg),
          _DayStrip(selected: selectedDay, onSelected: onDaySelected),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Factura legal ──
        CheckTile(
          value: needsInvoice,
          onChanged: onInvoiceChanged,
          label: 'Necesito factura legal',
          showHelp: true,
          helpMessage:
              'Activá esta opción si necesitás comprobante (boleta o factura) '
              'por el servicio.',
        ),
      ],
    );
  }
}

/// Tira horizontal de días, scrolleable. Empieza mostrando 2 semanas y, al
/// elegir uno de los últimos, agrega más días automáticamente (scroll infinito).
class _DayStrip extends StatefulWidget {
  const _DayStrip({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  State<_DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<_DayStrip> {
  final ScrollController _controller = ScrollController();
  int _count = 5;

  static const double _itemWidth = 60;
  static const double _gap = AppSpacing.sm;

  static const _weekdays = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
  static const _months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    widget.onSelected(i);
    // Al elegir el último día visible, aparece el siguiente (uno a uno) y se
    // desplaza para mostrarlo.
    if (i == _count - 1) {
      setState(() => _count += 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: SizedBox(
        height: 90,
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _count,
          separatorBuilder: (_, _) => const SizedBox(width: _gap),
          itemBuilder: (_, i) {
            final d = now.add(Duration(days: i));
            final isSel = i == widget.selected;
            return GestureDetector(
              onTap: () => _onTap(i),
              child: Container(
                width: _itemWidth,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdays[d.weekday - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${d.day}',
                      style: AppTypography.headingSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _months[d.month - 1],
                      style: AppTypography.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Paso 4 — Resumen
// ═══════════════════════════════════════════════════════════
class _SummaryStep extends StatelessWidget {
  const _SummaryStep();

  static const _items = [
    'Verificamos cada publicación antes de mostrarla.',
    'Recibirás hasta 5 prestadores interesados; algunos enviarán presupuesto, '
        'otros te contactarán directo, o si deseas, contáctalos vos mismo.',
    'Si no te convencen, pedís más opciones.',
    'Confirmá al prestador ideal con el botón "Confirmar".',
    'Pagá siempre directo al prestador, nunca por adelantado.',
    'Al finalizar, cerrá el pedido, calificá y compartí fotos del trabajo.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Te contamos que pasará:',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                _NumberedItem(number: i + 1, text: _items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberedItem extends StatelessWidget {
  const _NumberedItem({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$number.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Helpers compartidos de campos
// ═══════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTypography.titleLarge.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (optional)
            TextSpan(
              text: ' (opcional)',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlainInput extends StatelessWidget {
  const _PlainInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
