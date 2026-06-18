import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../../../core/widgets/navigation/app_menu_sheet.dart';
import '../../account/services/credit_service.dart';
import '../services/technician_feed_service.dart';

/// Pantalla de Pedidos del prestador de servicio.
///
/// Muestra los pedidos disponibles de su zona/categoría (con opción de ver
/// todos), su saldo de créditos, y permite postular pagando 1 crédito.
class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({super.key});

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen> {
  final TechnicianFeedService _feedService = TechnicianFeedService();
  final CreditService _creditService = CreditService();

  List<AvailableRequest> _requests = const [];
  int _balance = 0;
  bool _loading = true;
  bool _allCategories = false; // false = mi categoría, true = todas
  final Set<String> _applying = {};

  final List<VoidCallback> _rtUnsub = [];
  String? _walletChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  Future<void> _setupRealtime() async {
    final rt = RealtimeService.instance;
    await rt.connect();

    // Nuevos pedidos publicados → refrescar feed.
    rt.subscribe('requests');
    _rtUnsub.add(
      rt.on('new_open_request', (_) {
        if (mounted) _load();
      }),
    );

    // Saldo en vivo.
    final uid = await InsForgeClient().getCurrentUserId();
    if (uid != null) {
      _walletChannel = 'wallet:$uid';
      rt.subscribe(_walletChannel!);
      _rtUnsub.add(
        rt.on('balance_changed', (payload) {
          final b = (payload['balance'] as num?)?.toInt();
          if (mounted && b != null) setState(() => _balance = b);
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final off in _rtUnsub) {
      off();
    }
    RealtimeService.instance.unsubscribe('requests');
    if (_walletChannel != null) {
      RealtimeService.instance.unsubscribe(_walletChannel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _feedService.getAvailableRequests(allCategories: _allCategories),
      _creditService.getBalance(),
    ]);
    if (!mounted) return;
    setState(() {
      _requests = results[0] as List<AvailableRequest>;
      _balance = results[1] as int;
      _loading = false;
    });
  }

  Future<void> _toggleScope(bool allCategories) async {
    if (_allCategories == allCategories) return;
    setState(() => _allCategories = allCategories);
    await _load();
  }

  Future<void> _apply(AvailableRequest req) async {
    if (_applying.contains(req.id)) return;

    // Pedir mensaje + presupuesto antes de postular.
    final data = await showModalBottomSheet<_PostularData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PostularSheet(categoryName: req.categoryName),
    );
    if (data == null || !mounted) return;

    setState(() => _applying.add(req.id));

    final result = await _feedService.applyToRequest(
      req.id,
      message: data.message,
      proposedPrice: data.price,
    );

    if (!mounted) return;
    setState(() => _applying.remove(req.id));

    if (result.success) {
      showAppToast(
        context,
        message: result.message ?? 'Postulación enviada.',
        type: ToastType.success,
      );
      setState(() {
        _requests = _requests.where((r) => r.id != req.id).toList();
        if (result.balance != null) _balance = result.balance!;
      });
    } else {
      showAppToast(
        context,
        message: result.message ?? 'No se pudo postular.',
        type: result.error == 'insufficient_credits'
            ? ToastType.warning
            : ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _OrdersHeader(
                  topPadding: topPadding,
                  available: _requests.length,
                  balance: _balance,
                ),
              ),
              SliverToBoxAdapter(
                child: _ScopeToggle(
                  allCategories: _allCategories,
                  onChanged: _toggleScope,
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_requests.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(allCategories: _allCategories),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList.separated(
                    itemCount: _requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final req = _requests[i];
                      return _RequestCard(
                        request: req,
                        applying: _applying.contains(req.id),
                        onApply: () => _apply(req),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER OSCURO
// ═══════════════════════════════════════════════════════════
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.topPadding,
    required this.available,
    required this.balance,
  });

  final double topPadding;
  final int available;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 12, bottom: 24),
      color: const Color(0xFF1D2939),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar: saldo + menú ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _CreditPill(balance: balance),
                const Spacer(),
                _HeaderIcon(icon: Icons.notifications_outlined),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => showAppMenuSheet(context),
                  child: _HeaderIcon(icon: Icons.menu_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Card de pedidos disponibles ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3E50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$available ${available == 1 ? "pedido disponible" : "pedidos disponibles"}',
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '¿Listo para conectar? 📣',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
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

class _CreditPill extends StatelessWidget {
  const _CreditPill({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFC107), size: 18),
          const SizedBox(width: 6),
          Text(
            '$balance créditos',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOGGLE Mi categoría / Todos
// ═══════════════════════════════════════════════════════════
class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.allCategories, required this.onChanged});

  final bool allCategories;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          _ToggleChip(
            label: 'Mi categoría',
            selected: !allCategories,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 10),
          _ToggleChip(
            label: 'Todos',
            selected: allCategories,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.neutral600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ESTADO VACÍO
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.allCategories});

  final bool allCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.neutral400),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos disponibles',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            allCategories
                ? 'Por ahora no hay pedidos en tu zona. Vuelve más tarde.'
                : 'No hay pedidos de tu categoría. Prueba con "Todos".',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TARJETA DE PEDIDO DISPONIBLE
// ═══════════════════════════════════════════════════════════
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.applying,
    required this.onApply,
  });

  final AvailableRequest request;
  final bool applying;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Categoría + distancia ──
          Row(
            children: [
              Text(request.categoryEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.categoryName,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (request.distanceKm != null)
                Text(
                  '${request.distanceKm!.toStringAsFixed(1)} km',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Descripción ──
          Text(
            request.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.neutral600,
            ),
          ),

          const SizedBox(height: 8),

          // ── Distrito ──
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.neutral500,
              ),
              const SizedBox(width: 4),
              Text(
                request.districtName,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.neutral500,
                ),
              ),
              if (request.needsInvoice) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Factura',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.neutral500,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 12),

          // ── Botón Postular ──
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: applying ? null : onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
              ),
              child: applying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Postular (1 crédito)',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHEET DE POSTULACIÓN (mensaje + presupuesto)
// ═══════════════════════════════════════════════════════════
class _PostularData {
  const _PostularData({this.message, this.price});
  final String? message;
  final num? price;
}

class _PostularSheet extends StatefulWidget {
  const _PostularSheet({required this.categoryName});

  final String categoryName;

  @override
  State<_PostularSheet> createState() => _PostularSheetState();
}

class _PostularSheetState extends State<_PostularSheet> {
  final _msgController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final msg = _msgController.text.trim();
    final price = num.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    Navigator.of(
      context,
    ).pop(_PostularData(message: msg.isEmpty ? null : msg, price: price));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Postular a ${widget.categoryName}',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cuéntale al cliente por qué puedes ayudarlo y tu presupuesto. Cuesta 1 crédito.',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _msgController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ej: Tengo 5 años de experiencia, puedo ir mañana...',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: 'S/ ',
              hintText: 'Presupuesto (opcional)',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Enviar postulación',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
