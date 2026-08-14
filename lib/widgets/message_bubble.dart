import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../app_theme.dart';
import '../models/chat_models.dart';
import 'forge_logo.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final maxWidth = MediaQuery.sizeOf(context).width > 800 ? 720.0 : double.infinity;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.only(left: isUser ? 52 : 0, right: isUser ? 0 : 52, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) const ForgeLogo(compact: true),
              if (!isUser) const SizedBox(width: 12),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(17, 15, 11, 10),
                  decoration: BoxDecoration(
                    color: isUser ? OxygenForgeTheme.violet.withValues(alpha: 0.18) : OxygenForgeTheme.panel,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 18),
                    ),
                    border: Border.all(
                      color: isUser ? OxygenForgeTheme.violet.withValues(alpha: 0.35) : OxygenForgeTheme.line,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        softLineBreak: true,
                        styleSheet: _markdownStyle(context),
                        onTapLink: (text, href, title) {
                          if (href == null) return;
                          Clipboard.setData(ClipboardData(text: href));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Bağlantı panoya kopyalandı: $href')),
                          );
                        },
                      ),
                      if (!isUser && message.provider != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 12, color: OxygenForgeTheme.violetBright),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${message.provider!.label}  ·  ${message.model ?? message.provider!.defaultModel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 10.5),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: message.text));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Markdown yanıtı panoya kopyalandı.')),
                                );
                              },
                              tooltip: 'Markdown kopyala',
                              icon: const Icon(Icons.copy_rounded, size: 15, color: OxygenForgeTheme.muted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return MarkdownStyleSheet(
      p: base.copyWith(color: OxygenForgeTheme.text, fontSize: 14.5, height: 1.55),
      strong: base.copyWith(color: OxygenForgeTheme.text, fontSize: 14.5, height: 1.55, fontWeight: FontWeight.w800),
      em: base.copyWith(color: OxygenForgeTheme.violetBright, fontSize: 14.5, height: 1.55, fontStyle: FontStyle.italic),
      h1: base.copyWith(color: OxygenForgeTheme.text, fontSize: 23, height: 1.2, fontWeight: FontWeight.w800),
      h2: base.copyWith(color: OxygenForgeTheme.text, fontSize: 19, height: 1.25, fontWeight: FontWeight.w800),
      h3: base.copyWith(color: OxygenForgeTheme.text, fontSize: 16, height: 1.3, fontWeight: FontWeight.w800),
      listBullet: base.copyWith(color: OxygenForgeTheme.violetBright, fontSize: 14.5),
      blockquote: base.copyWith(color: OxygenForgeTheme.muted, fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      blockquoteDecoration: BoxDecoration(
        color: OxygenForgeTheme.violet.withValues(alpha: 0.08),
        border: const Border(left: BorderSide(color: OxygenForgeTheme.violetBright, width: 3)),
      ),
      code: const TextStyle(color: OxygenForgeTheme.cyan, fontSize: 12.5, fontFamily: 'monospace'),
      codeblockPadding: const EdgeInsets.all(14),
      codeblockDecoration: BoxDecoration(
        color: OxygenForgeTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OxygenForgeTheme.line),
      ),
      horizontalRuleDecoration: const BoxDecoration(border: Border(top: BorderSide(color: OxygenForgeTheme.line))),
      blockSpacing: 10,
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ForgeLogo(compact: true),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: OxygenForgeTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: OxygenForgeTheme.line),
          ),
          child: const SizedBox(
            width: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Dot(delay: 0),
                _Dot(delay: 120),
                _Dot(delay: 240),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.25, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(color: OxygenForgeTheme.violetBright, shape: BoxShape.circle),
      ),
    );
  }
}
