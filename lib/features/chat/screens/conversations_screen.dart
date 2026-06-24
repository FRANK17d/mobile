import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/navigation/unauth_header.dart';
import '../../auth/services/auth_store.dart';
import '../../client/home/widgets/client_menu_sheet.dart';
import '../../client/notifications/screens/client_notifications_screen.dart';
import '../services/chat_service.dart';
import 'chat_thread_screen.dart';

/// Pantalla de conversaciones / lista de chats 1:1 (cliente ↔ técnico).
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSnapshot>(
      valueListenable: AuthStore.instance.notifier,
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          return const _ConversationsView();
        }
        return const _UnauthenticatedMessagesView();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista NO autenticada
// ─────────────────────────────────────────────────────────
class _UnauthenticatedMessagesView extends StatelessWidget {
  const _UnauthenticatedMessagesView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            const UnauthHeader(title: 'Mensajes'),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 56,
                        color: AppColors.neutral300,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Inicia sesión para ver tus mensajes',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────
// Vista autenticada (lista de chats real)
// ─────────────────────────────────────────────────────────
class _ConversationsView extends StatefulWidget {
  const _ConversationsView();

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  final ChatService _service = ChatService();
  List<Conversation> _conversations = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getMyConversations();
    if (!mounted) return;
    setState(() {
      _conversations = list;
      _loading = false;
    });
  }

  Future<void> _openThread(Conversation c) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatThreadScreen(conversationId: c.id, title: c.otherFirstName),
      ),
    );
    _load(); // refrescar último mensaje al volver
  }

  void _openNotifications() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const ClientNotificationsScreen(),
      ),
    );
  }

  void _openMenu() {
    showClientMenuSheet(context, profileData: AuthStore.instance.value.profile);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Column(
          children: [
            // ── Header oscuro (mismo estilo que Pedidos) ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(color: Color(0xFF1D2939)),
              child: Row(
                children: [
                  Text(
                    'Mensajes',
                    style: AppTypography.headingLarge.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _HeaderCircleButton(
                    icon: Icons.notifications_outlined,
                    onTap: _openNotifications,
                  ),
                  const SizedBox(width: 10),
                  _HeaderCircleButton(
                    icon: Icons.menu_rounded,
                    onTap: _openMenu,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _conversations.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _conversations.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          color: AppColors.neutral200,
                          indent: 80,
                        ),
                        itemBuilder: (_, i) => _ConversationTile(
                          conversation: _conversations[i],
                          onTap: () => _openThread(_conversations[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
        Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes conversaciones',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aparecerán cuando un técnico postule a tu pedido.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botón circular del header oscuro (campana / menú).
class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        child: Center(child: Icon(icon, size: 22, color: Colors.white)),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.neutral200,
        backgroundImage: c.otherAvatarUrl != null
            ? CachedNetworkImageProvider(c.otherAvatarUrl!)
            : null,
        child: c.otherAvatarUrl == null
            ? const Icon(Icons.person, color: AppColors.neutral500)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              c.otherFirstName,
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${c.categoryEmoji} ${c.requestTitle}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          c.lastBody ?? 'Conversación iniciada',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
