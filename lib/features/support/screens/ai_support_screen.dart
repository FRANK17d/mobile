import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/feedback/app_toast.dart';
import '../../auth/services/auth_store.dart';
import '../services/support_ticket_service.dart';

class AiSupportScreen extends StatefulWidget {
  const AiSupportScreen({super.key});

  @override
  State<AiSupportScreen> createState() => _AiSupportScreenState();
}

class _AiSupportScreenState extends State<AiSupportScreen> {
  final AiService _ai = AiService();
  final SupportTicketService _tickets = SupportTicketService();
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  bool _creatingTicket = false;
  String? _ticketId;

  VoidCallback? _rtOff;
  String? _ticketChannel;
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text: '¡Hola! Soy el asistente de TOKE+. ¿En qué puedo ayudarte?',
        isUser: false,
      ),
    );
    _loadExistingTicket();
  }

  /// Retoma el último ticket del usuario (persistencia) y se suscribe a sus
  /// mensajes en vivo (respuestas del admin).
  Future<void> _loadExistingTicket() async {
    final ticket = await _tickets.getLatestTicket();
    // Solo retoma una conversación activa; los tickets cerrados no se recargan
    // (se empieza un chat nuevo con la IA).
    if (ticket == null || ticket.status == 'closed' || !mounted) return;
    // Hay un ticket: mostramos el skeleton mientras llega el historial.
    setState(() => _loadingHistory = true);
    final msgs = await _tickets.getMessages(ticket.id);
    if (!mounted) return;
    setState(() {
      _loadingHistory = false;
      _ticketId = ticket.id;
      for (final m in msgs) {
        _messages.add(_ChatMessage(text: m.body, isUser: !m.isAdmin));
      }
    });
    _subscribeTicket(ticket.id);
    _scrollToBottom();
  }

  /// Suscribe el chat al canal del ticket para recibir respuestas del admin.
  Future<void> _subscribeTicket(String ticketId) async {
    if (_ticketChannel != null) return;
    _ticketChannel = 'ticket:$ticketId';
    final rt = RealtimeService.instance;
    await rt.connect();
    rt.subscribe(_ticketChannel!);
    _rtOff = rt.on('new_ticket_message', (payload) {
      if (!mounted) return;
      // Solo los mensajes del admin (los propios ya están en pantalla).
      if (payload['is_admin'] != true) return;
      final body = payload['body'] as String?;
      if (body == null || body.isEmpty) return;
      setState(() => _messages.add(_ChatMessage(text: body, isUser: false)));
      _scrollToBottom();
    });
  }

  List<Map<String, String>> _buildHistory() {
    return _messages
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
    });
    _input.clear();
    _scrollToBottom();

    // Si ya hay un ticket, el chat es con el agente humano (admin): el mensaje
    // se guarda en el ticket y el admin lo ve en el panel.
    if (_ticketId != null) {
      final ok = await _tickets.sendMessage(_ticketId!, text);
      if (!mounted) return;
      setState(() => _sending = false);
      if (!ok) {
        showAppToast(
          context,
          message: 'No se pudo enviar el mensaje. Intenta de nuevo.',
          type: ToastType.error,
        );
      }
      return;
    }

    // Sin ticket: asistente con IA.
    final history = _buildHistory();
    final response = await _ai.supportChat(
      text,
      history: history.sublist(0, history.length - 1),
    );

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text:
              response ??
              'Lo siento, no pude procesar tu consulta. Intenta de nuevo.',
          isUser: false,
        ),
      );
      _sending = false;
    });
    _scrollToBottom();
  }

  Future<void> _createHumanTicket() async {
    if (_creatingTicket || _ticketId != null) return;

    if (!AuthStore.instance.value.isAuthenticated) {
      showAppToast(
        context,
        message: 'Inicia sesión para crear un ticket de soporte.',
        type: ToastType.warning,
      );
      return;
    }

    final userMessages = _messages
        .where((m) => m.isUser)
        .map((m) => m.text)
        .toList();
    final lastMessage = userMessages.isEmpty
        ? 'Necesito ayuda con TOKE+.'
        : userMessages.last;
    // Guardamos solo lo que escribió el usuario como primer mensaje del ticket.
    // (Antes se guardaba toda la transcripción, lo que hacía que el texto del
    // asistente apareciera dentro de la burbuja del usuario al recargar.)
    final firstMessage = userMessages.isEmpty
        ? lastMessage
        : userMessages.join('\n\n');

    setState(() => _creatingTicket = true);
    final ticketId = await _tickets.createTicket(
      subject: lastMessage,
      message: firstMessage,
      category: 'mobile_support',
    );

    if (!mounted) return;
    setState(() {
      _creatingTicket = false;
      _ticketId = ticketId;
      if (ticketId != null) {
        _messages.add(
          const _ChatMessage(
            text:
                'Listo, creé un ticket para soporte humano. Un administrador te '
                'responderá por aquí mismo.',
            isUser: false,
          ),
        );
      }
    });
    if (ticketId != null) _subscribeTicket(ticketId);

    showAppToast(
      context,
      message: ticketId != null
          ? 'Ticket creado correctamente.'
          : 'No se pudo crear el ticket. Intenta de nuevo.',
      type: ticketId != null ? ToastType.success : ToastType.error,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _rtOff?.call();
    if (_ticketChannel != null) {
      RealtimeService.instance.unsubscribe(_ticketChannel!);
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Soporte TOKE+',
                style: AppTypography.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _HumanSupportCard(
              creating: _creatingTicket,
              created: _ticketId != null,
              onCreateTicket: _createHumanTicket,
            ),
            Expanded(
              child: _loadingHistory
                  ? const _ChatSkeleton()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(message: _messages[i]);
                      },
                    ),
            ),
            _Composer(controller: _input, sending: _sending, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _HumanSupportCard extends StatelessWidget {
  const _HumanSupportCard({
    required this.creating,
    required this.created,
    required this.onCreateTicket,
  });

  final bool creating;
  final bool created;
  final VoidCallback onCreateTicket;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  created ? 'Ticket enviado' : '¿Necesitas soporte humano?',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  created
                      ? 'El equipo revisará tu caso desde el panel admin.'
                      : 'Crea un ticket con esta conversación como contexto.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: creating || created ? null : onCreateTicket,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.neutral300,
              minimumSize: const Size(86, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(created ? 'Creado' : 'Crear'),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.neutral200),
        ),
        child: Text(
          message.text,
          style: AppTypography.bodyMedium.copyWith(
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, child) => Opacity(opacity: 0.3 + 0.7 * v, child: child),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.neutral400,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Skeleton animado mientras se carga el historial del ticket.
class _ChatSkeleton extends StatefulWidget {
  const _ChatSkeleton();

  @override
  State<_ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<_ChatSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  // Burbujas placeholder: (¿es del usuario?, ancho relativo).
  static const List<(bool, double)> _bubbles = [
    (false, 0.62),
    (true, 0.45),
    (false, 0.72),
    (false, 0.5),
    (true, 0.58),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final opacity = 0.4 + 0.4 * _ctrl.value;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final (isUser, w) in _bubbles)
              Align(
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    height: 44,
                    width: width * w,
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.neutral200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.neutral200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe tu consulta...',
                  filled: true,
                  fillColor: AppColors.backgroundTertiary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
