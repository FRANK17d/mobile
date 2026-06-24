import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/insforge_client.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../account/services/credit_service.dart';
import '../services/technician_feed_service.dart';

enum TechnicianRequestsScope { recommended, all }

class TechnicianRequestsListScreen extends StatefulWidget {
  const TechnicianRequestsListScreen({
    super.key,
    this.initialScope = TechnicianRequestsScope.recommended,
    this.focusSearch = false,
  });

  final TechnicianRequestsScope initialScope;
  final bool focusSearch;

  @override
  State<TechnicianRequestsListScreen> createState() =>
      _TechnicianRequestsListScreenState();
}

class _TechnicianRequestsListScreenState
    extends State<TechnicianRequestsListScreen> {
  final TechnicianFeedService _feedService = TechnicianFeedService();
  final CreditService _creditService = CreditService();
  final TextEditingController _searchController = TextEditingController();

  List<AvailableRequest> _requests = const [];
  int _balance = 0;
  bool _loading = true;
  late TechnicianRequestsScope _scope = widget.initialScope;
  String _query = '';
  final Set<String> _applying = {};

  final List<VoidCallback> _rtUnsub = [];
  String? _walletChannel;

  bool get _showingAll => _scope == TechnicianRequestsScope.all;

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final off in _rtUnsub) {
      off();
    }
    RealtimeService.instance.unsubscribe('requests');
    if (_walletChannel != null) {
      RealtimeService.instance.unsubscribe(_walletChannel!);
    }
    super.dispose();
  }

  Future<void> _setupRealtime() async {
    final rt = RealtimeService.instance;
    await rt.connect();

    rt.subscribe('requests');
    _rtUnsub.add(
      rt.on('new_open_request', (_) {
        if (mounted) _load(silent: true);
      }),
    );

    final uid = await InsForgeClient().getCurrentUserId();
    if (uid != null) {
      _walletChannel = 'wallet:$uid';
      rt.subscribe(_walletChannel!);
      _rtUnsub.add(
        rt.on('balance_changed', (payload) {
          final balance = (payload['balance'] as num?)?.toInt();
          if (mounted && balance != null) setState(() => _balance = balance);
        }),
      );
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    final results = await Future.wait([
      _feedService.getAvailableRequests(
        allCategories: _showingAll,
        allZones: _showingAll,
      ),
      _creditService.getBalance(),
    ]);
    if (!mounted) return;
    setState(() {
      _requests = results[0] as List<AvailableRequest>;
      _balance = results[1] as int;
      _loading = false;
    });
  }

  Future<void> _changeScope(TechnicianRequestsScope scope) async {
    if (_scope == scope) return;
    setState(() => _scope = scope);
    await _load();
  }

  List<AvailableRequest> get _filteredRequests {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _requests;
    return _requests.where((request) {
      return request.title.toLowerCase().contains(q) ||
          request.description.toLowerCase().contains(q) ||
          request.categoryName.toLowerCase().contains(q) ||
          request.districtName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _apply(AvailableRequest request) async {
    if (_applying.contains(request.id)) return;

    final data = await showModalBottomSheet<_PostularData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PostularSheet(categoryName: request.categoryName),
    );
    if (data == null || !mounted) return;

    setState(() => _applying.add(request.id));
    final result = await _feedService.applyToRequest(
      request.id,
      message: data.message,
      proposedPrice: data.price,
    );
    if (!mounted) return;

    setState(() => _applying.remove(request.id));
    if (result.success) {
      showAppToast(
        context,
        message: result.message ?? 'Postulación enviada.',
        type: ToastType.success,
      );
      setState(() {
        _requests = _requests.where((r) => r.id != request.id).toList();
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
    final filtered = _filteredRequests;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0.5,
          scrolledUnderElevation: 0.5,
          shadowColor: AppColors.neutral200,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Text(
            'Pedidos',
            style: AppTypography.headingSmall.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _CreditPill(balance: _balance),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _SearchField(
                controller: _searchController,
                autofocus: widget.focusSearch,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            _ScopeChips(scope: _scope, onChanged: _changeScope),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? _EmptyState(hasSearch: _query.trim().isNotEmpty)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _load(silent: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = filtered[index];
                          return _RequestCard(
                            request: request,
                            applying: _applying.contains(request.id),
                            onApply: () => _apply(request),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.autofocus,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Escribir para buscar...',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeChips extends StatelessWidget {
  const _ScopeChips({required this.scope, required this.onChanged});

  final TechnicianRequestsScope scope;
  final ValueChanged<TechnicianRequestsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        children: [
          _ScopeChip(
            label: 'Recomendado para vos',
            selected: scope == TechnicianRequestsScope.recommended,
            onTap: () => onChanged(TechnicianRequestsScope.recommended),
          ),
          const SizedBox(width: 8),
          _ScopeChip(
            label: 'Todos',
            selected: scope == TechnicianRequestsScope.all,
            onTap: () => onChanged(TechnicianRequestsScope.all),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral300,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFC107), size: 17),
          const SizedBox(width: 5),
          Text(
            '$balance',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.inbox_outlined,
              size: 56,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'No encontramos pedidos'
                  : 'No hay pedidos disponibles',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? 'Prueba con otra palabra o borra la búsqueda.'
                  : 'Vuelve más tarde para ver nuevos pedidos.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final title = request.title.isEmpty ? request.categoryName : request.title;
    final distance = request.distanceKm == null
        ? null
        : '${request.distanceKm!.toStringAsFixed(1)} km';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  request.categoryEmoji,
                  style: const TextStyle(fontSize: 23),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '#${request.id.replaceAll('-', '').substring(0, 4).toUpperCase()}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.location_on_outlined,
                text: request.districtName,
              ),
              if (distance != null)
                _MetaChip(icon: Icons.near_me_outlined, text: distance),
              if (request.needsInvoice)
                const _MetaChip(
                  icon: Icons.receipt_long_outlined,
                  text: 'Factura',
                ),
            ],
          ),
          const SizedBox(height: 14),
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
                      'Postularme',
                      style: AppTypography.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.neutral500),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _messageController.text.trim();
    final price = num.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );
    Navigator.of(context).pop(
      _PostularData(message: message.isEmpty ? null : message, price: price),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Postular a ${widget.categoryName}',
              style: AppTypography.headingSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuéntale al cliente por qué puedes ayudarlo y tu presupuesto. Cuesta 1 crédito.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                  style: AppTypography.buttonMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
