import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/realtime_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/feedback/app_toast.dart';
import '../../booking/screens/booking_screen.dart';
import '../services/request_service.dart';

/// Lista los técnicos que postularon a un pedido y permite elegir uno.
class RequestApplicantsScreen extends StatefulWidget {
  const RequestApplicantsScreen({
    super.key,
    required this.requestId,
    required this.requestTitle,
  });

  final String requestId;
  final String requestTitle;

  @override
  State<RequestApplicantsScreen> createState() =>
      _RequestApplicantsScreenState();
}

class _RequestApplicantsScreenState extends State<RequestApplicantsScreen> {
  final RequestService _service = RequestService();

  List<Applicant> _applicants = const [];
  bool _loading = true;
  String? _accepting;

  VoidCallback? _rtOff;
  late final String _channel = 'request:${widget.requestId}';

  @override
  void initState() {
    super.initState();
    _load();
    _setupRealtime();
  }

  Future<void> _setupRealtime() async {
    final rt = RealtimeService.instance;
    await rt.connect();
    rt.subscribe(_channel);
    _rtOff = rt.on('new_application', (_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _rtOff?.call();
    RealtimeService.instance.unsubscribe(_channel);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.getRequestApplications(widget.requestId);
    if (!mounted) return;
    setState(() {
      _applicants = list;
      _loading = false;
    });
  }

  Future<void> _accept(Applicant a) async {
    setState(() => _accepting = a.applicationId);
    final ok = await _service.acceptApplication(a.applicationId);
    if (!mounted) return;
    setState(() => _accepting = null);

    if (ok) {
      showAppToast(
        context,
        message: 'Elegiste a ${a.firstName}. Agenda la visita.',
        type: ToastType.success,
      );
      // Navigate to booking screen so client can schedule the appointment
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            requestId: widget.requestId,
            technicianName: [a.firstName, a.lastName].where((s) => s != null && s.isNotEmpty).join(' '),
            technicianId: a.technicianId,
          ),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      showAppToast(
        context,
        message: 'No se pudo asignar. Intenta de nuevo.',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyAccepted = _applicants.any((a) => a.status == 'accepted');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'Postulaciones',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _applicants.isEmpty
            ? _empty()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.screenPaddingH),
                  itemCount: _applicants.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) {
                    if (i == 0) return const _DirectPaymentNotice();
                    final applicant = _applicants[i - 1];
                    return _ApplicantCard(
                      applicant: applicant,
                      accepting: _accepting == applicant.applicationId,
                      // Si ya hay uno aceptado, deshabilitar el resto.
                      disabled: anyAccepted && applicant.status != 'accepted',
                      onAccept: () => _accept(applicant),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_outlined, size: 56, color: AppColors.neutral400),
            const SizedBox(height: 16),
            Text(
              'Aún no hay postulaciones',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando un técnico de tu zona se postule, aparecerá aquí.',
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

class _DirectPaymentNotice extends StatelessWidget {
  const _DirectPaymentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFFFD99A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB7791F)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Al elegir un técnico, coordina el trabajo por chat. El pago se acuerda y realiza directamente con él; TOKE+ no retiene ese dinero.',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF744210),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.applicant,
    required this.accepting,
    required this.disabled,
    required this.onAccept,
  });

  final Applicant applicant;
  final bool accepting;
  final bool disabled;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final isAccepted = applicant.status == 'accepted';
    final fullName = [
      applicant.firstName,
      applicant.lastName ?? '',
    ].where((s) => s.isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isAccepted ? AppColors.primary : AppColors.neutral200,
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.neutral200,
                backgroundImage: applicant.avatarUrl != null
                    ? CachedNetworkImageProvider(applicant.avatarUrl!)
                    : null,
                child: applicant.avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.neutral500)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isEmpty ? 'Técnico' : fullName,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (applicant.avgRating ?? 0).toStringAsFixed(1),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${applicant.totalJobs ?? 0} trabajos',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (applicant.proposedPrice != null)
                Text(
                  'S/ ${applicant.proposedPrice}',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (applicant.message != null && applicant.message!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              applicant.message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: (disabled || isAccepted || accepting)
                  ? null
                  : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAccepted
                    ? const Color(0xFF2ECC71)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: accepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isAccepted ? 'Elegido ✓' : 'Elegir este técnico',
                      style: AppTypography.buttonMedium.copyWith(
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
