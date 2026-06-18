import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/ai_service.dart';
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

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text: '¡Hola! Soy el asistente de TOKE+. ¿En qué puedo ayudarte?',
        isUser: false,
      ),
    );
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
    final transcript = _messages
        .map((m) => '${m.isUser ? 'Usuario' : 'Asistente'}: ${m.text}')
        .join('\n\n');

    setState(() => _creatingTicket = true);
    final ticketId = await _tickets.createTicket(
      subject: lastMessage,
      message: transcript.isEmpty ? lastMessage : transcript,
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
                'Listo, creé un ticket para soporte humano. Un administrador revisará tu caso desde el panel.',
            isUser: false,
          ),
        );
      }
    });

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
              child: ListView.builder(
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
