import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/navigation/app_menu_sheet.dart';
import '../../../core/responsive/master_detail.dart';

/// Pantalla de conversaciones / lista de chats.
/// En tablet: master-detail con lista de chats y chat activo.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  // TODO: reemplazar con estado real de autenticacion
  static const _isAuthenticated = false;

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return _AuthenticatedMessagesView(
        selectedIndex: _selectedIndex,
        onSelect: (index) => setState(() => _selectedIndex = index),
      );
    }
    return const _UnauthenticatedMessagesView();
  }
}

// ─────────────────────────────────────────────────────────
// Vista NO autenticada (empty state mismo estilo que orders)
// ─────────────────────────────────────────────────────────
class _UnauthenticatedMessagesView extends StatelessWidget {
  const _UnauthenticatedMessagesView();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            // ── Header oscuro ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: topPadding + 16,
                left: 20,
                right: 20,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1D2939),
              ),
              child: Column(
                children: [
                  // ── Top bar: titulo + boton Entrar + menu ──
                  Row(
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
                      _EntrarButton(onTap: () {
                        context.push(AppRoutes.login);
                      }),
                      const SizedBox(width: 10),
                      _HeaderMenuButton(onTap: () {
                        showAppMenuSheet(context);
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Barra de busqueda ──
                  Container(
                    width: double.infinity,
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3B4F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Buscar conversaciones',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido blanco con bordes redondeados arriba ──
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tus mensajes aparecerán aquí',
                            textAlign: TextAlign.center,
                            style: AppTypography.headingLarge.copyWith(
                              color: const Color(0xFF162033),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cuando contrates un servicio o un técnico '
                            'te responda, podrás chatear directamente '
                            'desde aquí. Rápido y seguro.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: const Color(0xFF6B7280),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _ExplorarServiciosButton(onTap: () {
                            // TODO: navegar a explorar servicios
                          }),
                        ],
                      ),
                    ),
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
// Boton "Entrar"
// ─────────────────────────────────────────────────────────
class _EntrarButton extends StatelessWidget {
  const _EntrarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          'Entrar',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton menu hamburguesa
// ─────────────────────────────────────────────────────────
class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton({required this.onTap});

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
        child: const Center(
          child: Icon(Icons.menu_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Boton "Explorar servicios"
// ─────────────────────────────────────────────────────────
class _ExplorarServiciosButton extends StatelessWidget {
  const _ExplorarServiciosButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Text(
          'Explorar servicios',
          style: AppTypography.headingSmall.copyWith(
            color: const Color(0xFF1D2939),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista autenticada (con lista de chats)
// ─────────────────────────────────────────────────────────
class _AuthenticatedMessagesView extends StatelessWidget {
  const _AuthenticatedMessagesView({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: MasterDetailLayout(
        master: _ConversationsList(
          selectedIndex: selectedIndex,
          onSelect: onSelect,
        ),
        detail: selectedIndex != null
            ? _ChatView(conversation: _mockConversations[selectedIndex!])
            : null,
        detailPlaceholder: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 64, color: AppColors.neutral300),
              const SizedBox(height: 16),
              Text(
                'Selecciona una conversacion',
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Lista de conversaciones
// ─────────────────────────────────────────────────────────
class _ConversationsList extends StatelessWidget {
  const _ConversationsList({this.selectedIndex, required this.onSelect});

  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: _mockConversations.length,
      itemBuilder: (context, index) {
        final conv = _mockConversations[index];
        final isSelected = selectedIndex == index;

        return InkWell(
          onTap: () => onSelect(index),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: isSelected ? AppColors.primarySurface : Colors.transparent,
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutral200,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.neutral400, size: 28),
                    ),
                    if (conv.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            border: Border.all(
                              color: AppColors.surfaceWhite,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              conv.name,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: conv.unreadCount > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            conv.time,
                            style: AppTypography.caption.copyWith(
                              color: conv.unreadCount > 0
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.lastMessage,
                              style: AppTypography.bodySmall.copyWith(
                                color: conv.unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: conv.unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Text(
                                '${conv.unreadCount}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Vista de chat individual
// ─────────────────────────────────────────────────────────
class _ChatView extends StatelessWidget {
  const _ChatView({required this.conversation});

  final _ConversationData conversation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            boxShadow: AppShadows.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neutral200,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.neutral400, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conversation.name, style: AppTypography.titleSmall),
                  Text(
                    conversation.isOnline ? 'En linea' : 'Desconectado',
                    style: AppTypography.caption.copyWith(
                      color: conversation.isOnline
                          ? AppColors.success
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.phone_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Messages area
        Expanded(
          child: Container(
            color: AppColors.backgroundSecondary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxBubbleWidth = constraints.maxWidth * 0.7;
                final messages = [
                  (
                    text: 'Hola, necesito ayuda con la instalacion',
                    isMe: false,
                    time: '10:30 AM'
                  ),
                  (
                    text: 'Claro, puedo ir hoy a las 3pm. Te queda bien?',
                    isMe: true,
                    time: '10:32 AM'
                  ),
                  (
                    text:
                        'Perfecto! Te espero. La direccion es Av. Libertador 123',
                    isMe: false,
                    time: '10:33 AM'
                  ),
                  (
                    text: 'Anotado. Llevo todas las herramientas necesarias.',
                    isMe: true,
                    time: '10:35 AM'
                  ),
                ];
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubble(
                    text: messages[i].text,
                    isMe: messages[i].isMe,
                    time: messages[i].time,
                    maxWidth: maxBubbleWidth,
                  ),
                );
              },
            ),
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            boxShadow: AppShadows.xs,
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded),
                  onPressed: () {},
                  color: AppColors.textSecondary,
                ),
                Expanded(
                  child: Container(
                    height: 42,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Center(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () {},
                    color: AppColors.textInverse,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.maxWidth,
  });

  final String text;
  final bool isMe;
  final String time;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusMd),
          ),
          boxShadow: AppShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isMe ? AppColors.textInverse : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: AppTypography.caption.copyWith(
                color: isMe
                    ? AppColors.textInverse.withValues(alpha: 0.7)
                    : AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mock data
class _ConversationData {
  const _ConversationData({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
}

const _mockConversations = [
  _ConversationData(
    name: 'Carlos Rodriguez',
    lastMessage: 'Perfecto, llego en 15 minutos',
    time: '10:35',
    unreadCount: 2,
    isOnline: true,
  ),
  _ConversationData(
    name: 'Maria Gonzalez',
    lastMessage: 'El presupuesto es de \$60',
    time: '9:20',
    unreadCount: 0,
    isOnline: true,
  ),
  _ConversationData(
    name: 'Jose Martinez',
    lastMessage: 'Trabajo completado! Gracias',
    time: 'Ayer',
    unreadCount: 0,
    isOnline: false,
  ),
  _ConversationData(
    name: 'Ana Lopez',
    lastMessage: 'Puedo ir el viernes a las 10am',
    time: 'Lun',
    unreadCount: 1,
    isOnline: false,
  ),
];
