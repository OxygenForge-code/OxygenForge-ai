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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final thinking = message.thinking?.trim();
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
      bottomLeft: Radius.circular(isUser ? 22 : 7),
      bottomRight: Radius.circular(isUser ? 7 : 22),
    );

    return TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(isUser ? 18 * (1 - progress) : -18 * (1 - progress), 12 * (1 - progress)),
          child: child,
        ),
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.only(left: isUser ? 46 : 0, right: isUser ? 0 : 46, bottom: 22),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser && message.thinkingDuration != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 42, bottom: 7),
                    child: _ThinkingDurationBadge(duration: message.thinkingDuration!),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isUser) const ForgeLogo(compact: true),
                    if (!isUser) const SizedBox(width: 10),
                    Flexible(
                      child: FrostedPanel(
                        padding: const EdgeInsets.fromLTRB(17, 13, 12, 11),
                        borderRadius: bubbleRadius,
                        blur: 26,
                        color: isUser ? const Color(0x35FFFFFF) : OxygenForgeTheme.glass,
                        borderColor: isUser ? OxygenForgeTheme.glassEdge : OxygenForgeTheme.glassEdgeSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isUser ? Icons.person_outline_rounded : Icons.auto_awesome_rounded, size: 12, color: isUser ? Colors.white : OxygenForgeTheme.muted),
                            const SizedBox(width: 5),
                            Text(isUser ? 'SEN' : 'OXYGENFORGE', style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.05)),
                            const Spacer(),
                            Text(_formatTime(message.createdAt), style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 9),
                        if (message.text.trim().isNotEmpty)
                          _ProgressiveMarkdown(
                            text: message.text,
                            animate: !isUser && !reduceMotion,
                            styleSheet: _markdownStyle(context),
                            onTapLink: (text, href, title) {
                              if (href == null) return;
                              Clipboard.setData(ClipboardData(text: href));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Bağlantı panoya kopyalandı: $href')),
                              );
                            },
                          ),
                        if (!isUser && thinking != null && thinking.isNotEmpty) ...[
                          if (message.text.trim().isNotEmpty) const SizedBox(height: 12),
                          _ThinkingPanel(thinking: thinking),
                        ],
                        if (!isUser && message.provider != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, size: 12, color: OxygenForgeTheme.violetBright),
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
                                  final contentToCopy = thinking != null && thinking.isNotEmpty
                                      ? '${message.text}\n\n## Düşünme süreci\n$thinking'
                                      : message.text;
                                  await Clipboard.setData(ClipboardData(text: contentToCopy));
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Markdown yanıtı panoya kopyalandı.')),
                                  );
                                },
                                tooltip: 'Yanıtı kopyala',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return MarkdownStyleSheet(
      p: base.copyWith(color: OxygenForgeTheme.text, fontSize: 14.8, height: 1.58),
      strong: base.copyWith(color: OxygenForgeTheme.text, fontSize: 14.8, height: 1.58, fontWeight: FontWeight.w800),
      em: base.copyWith(color: OxygenForgeTheme.violetBright, fontSize: 14.8, height: 1.58, fontStyle: FontStyle.italic),
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

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ThinkingDurationBadge extends StatelessWidget {
  const _ThinkingDurationBadge({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final seconds = duration.inMilliseconds / 1000;
    final label = seconds < 1 ? '${seconds.toStringAsFixed(1)} sn' : '${seconds.toStringAsFixed(1)} sn düşündü';
    return FrostedPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: BorderRadius.circular(999),
      blur: 12,
      color: OxygenForgeTheme.glassSoft,
      borderColor: OxygenForgeTheme.glassEdge,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology_alt_rounded, size: 13, color: OxygenForgeTheme.text),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: OxygenForgeTheme.text, fontSize: 10.5, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ProgressiveMarkdown extends StatefulWidget {
  const _ProgressiveMarkdown({
    required this.text,
    required this.animate,
    required this.styleSheet,
    required this.onTapLink,
  });

  final String text;
  final bool animate;
  final MarkdownStyleSheet styleSheet;
  final void Function(String text, String? href, String? title) onTapLink;

  @override
  State<_ProgressiveMarkdown> createState() => _ProgressiveMarkdownState();
}

class _ProgressiveMarkdownState extends State<_ProgressiveMarkdown> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _duration => Duration(milliseconds: (widget.text.length * 8).clamp(420, 2100));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _controller.forward();
        });
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _ProgressiveMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.animate != widget.animate) {
      _controller.duration = _duration;
      _controller.value = widget.animate ? 0 : 1;
      if (widget.animate) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final visibleLength = (_controller.value * widget.text.length).ceil().clamp(0, widget.text.length);
        final visibleText = widget.text.substring(0, visibleLength);
        return MarkdownBody(
          data: visibleText,
          selectable: _controller.isCompleted,
          softLineBreak: true,
          styleSheet: widget.styleSheet,
          onTapLink: widget.onTapLink,
        );
      },
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
  var _expanded = true;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final thinkingStyle = MarkdownStyleSheet(
      p: base.copyWith(color: OxygenForgeTheme.muted, fontSize: 12.5, height: 1.5),
      strong: base.copyWith(color: OxygenForgeTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
      code: const TextStyle(color: OxygenForgeTheme.text, fontSize: 11.5, fontFamily: 'monospace'),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: OxygenForgeTheme.ink,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OxygenForgeTheme.line),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: OxygenForgeTheme.text.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OxygenForgeTheme.text.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.psychology_alt_rounded, size: 16, color: OxygenForgeTheme.text),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Modelin düşünme süreci', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: OxygenForgeTheme.muted),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: MarkdownBody(data: widget.thinking, selectable: true, styleSheet: thinkingStyle),
                  )
                : const SizedBox.shrink(),
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 760));
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const _DotMark();
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 0.72, end: 1.22).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.25, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
        child: const _DotMark(),
      ),
    );
  }
}

class _DotMark extends StatelessWidget {
  const _DotMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(color: OxygenForgeTheme.violetBright, shape: BoxShape.circle),
    );
  }
}
