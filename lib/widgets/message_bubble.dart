import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../app_theme.dart';
import '../models/chat_models.dart';
import 'forge_logo.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key, this.onReuse});

  final ChatMessage message;
  final ValueChanged<String>? onReuse;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final thinking = message.thinking?.trim();
    final maxWidth = MediaQuery.sizeOf(context).width > 800
        ? 720.0
        : double.infinity;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 5),
      bottomRight: Radius.circular(isUser ? 5 : 18),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.only(
            left: isUser ? 40 : 0,
            right: isUser ? 0 : 40,
            bottom: 14,
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isUser && message.thinkingDuration != null)
                Padding(
                  padding: const EdgeInsets.only(left: 34, bottom: 6),
                  child: _ThinkingDurationBadge(
                    duration: message.thinkingDuration!,
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isUser) const ForgeLogo(compact: true),
                  if (!isUser) const SizedBox(width: 9),
                  Flexible(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x2D3A7BFF), Color(0x1BFFFFFF)],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF18181B), Color(0xFF0F0F11)],
                              ),
                        borderRadius: radius,
                        border: Border.all(
                          color: isUser
                              ? const Color(0x536DA4FF)
                              : OxygenForgeTheme.surfaceStroke,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x28000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 11, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isUser ? 'SEN' : 'OXYGENFORGE',
                                  style: const TextStyle(
                                    color: OxygenForgeTheme.muted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(message.createdAt),
                                  style: const TextStyle(
                                    color: OxygenForgeTheme.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            if (message.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              MarkdownBody(
                                data: message.text,
                                selectable: true,
                                softLineBreak: true,
                                styleSheet: _markdownStyle(context),
                                onTapLink: (text, href, title) =>
                                    _copyLink(context, href),
                              ),
                            ],
                            if (!isUser &&
                                thinking != null &&
                                thinking.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _ThinkingPanel(thinking: thinking),
                            ],
                            if (!isUser && message.provider != null) ...[
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${message.provider!.label} · ${message.model ?? message.provider!.defaultModel}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: OxygenForgeTheme.muted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _copyMessage(
                                      context,
                                      message.text,
                                      thinking,
                                    ),
                                    tooltip: 'Yanıtı kopyala',
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 15,
                                      color: OxygenForgeTheme.muted,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    onPressed: onReuse == null
                                        ? null
                                        : () => onReuse!(
                                            'Bu yanıtı temel alarak devam et:\n\n${message.text}\n\n',
                                          ),
                                    tooltip: 'Yanıtı yeniden kullan',
                                    icon: const Icon(
                                      Icons.reply_rounded,
                                      size: 15,
                                      color: OxygenForgeTheme.muted,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyLink(BuildContext context, String? href) {
    if (href == null) return;
    Clipboard.setData(ClipboardData(text: href));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bağlantı panoya kopyalandı: $href')),
    );
  }

  Future<void> _copyMessage(
    BuildContext context,
    String text,
    String? thinking,
  ) async {
    final content = thinking == null || thinking.isEmpty
        ? text
        : '$text\n\n## Düşünme süreci\n$thinking';
    await Clipboard.setData(ClipboardData(text: content));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Yanıt panoya kopyalandı.')));
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return MarkdownStyleSheet(
      p: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 14.5,
        height: 1.55,
      ),
      strong: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 14.5,
        height: 1.55,
        fontWeight: FontWeight.w800,
      ),
      em: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 14.5,
        height: 1.55,
        fontStyle: FontStyle.italic,
      ),
      h1: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      h2: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
      h3: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w800,
      ),
      listBullet: base.copyWith(color: OxygenForgeTheme.text, fontSize: 14.5),
      blockquote: base.copyWith(
        color: OxygenForgeTheme.muted,
        fontSize: 14,
        height: 1.5,
        fontStyle: FontStyle.italic,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      blockquoteDecoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: OxygenForgeTheme.muted, width: 2),
        ),
      ),
      code: const TextStyle(
        color: OxygenForgeTheme.text,
        fontSize: 12.5,
        fontFamily: 'monospace',
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OxygenForgeTheme.line),
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: OxygenForgeTheme.line)),
      ),
      blockSpacing: 9,
    );
  }

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _ThinkingDurationBadge extends StatelessWidget {
  const _ThinkingDurationBadge({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final seconds = duration.inMilliseconds / 1000;
    final label = seconds < 1
        ? '${seconds.toStringAsFixed(1)} sn'
        : '${seconds.toStringAsFixed(1)} sn düşündü';
    return Text(
      label,
      style: const TextStyle(
        color: OxygenForgeTheme.muted,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ThinkingPanel extends StatefulWidget {
  const _ThinkingPanel({required this.thinking});

  final String thinking;

  @override
  State<_ThinkingPanel> createState() => _ThinkingPanelState();
}

class _ThinkingPanelState extends State<_ThinkingPanel> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final style = MarkdownStyleSheet(
      p: base.copyWith(
        color: OxygenForgeTheme.muted,
        fontSize: 12.5,
        height: 1.5,
      ),
      strong: base.copyWith(
        color: OxygenForgeTheme.text,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      code: const TextStyle(
        color: OxygenForgeTheme.text,
        fontSize: 11.5,
        fontFamily: 'monospace',
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x0EFFFFFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_alt_outlined,
                    size: 15,
                    color: OxygenForgeTheme.muted,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Düşünme süreci',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: OxygenForgeTheme.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: MarkdownBody(
                data: widget.thinking,
                selectable: true,
                styleSheet: style,
              ),
            ),
        ],
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ForgeLogo(compact: true),
        SizedBox(width: 10),
        Text(
          'Yanıt hazırlanıyor…',
          style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 13),
        ),
      ],
    );
  }
}
