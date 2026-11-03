import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// A robust widget that renders mixed Bengali/English text and LaTeX math formulas.
/// Formulas enclosed in $...$ (inline) or $$...$$ (display) are rendered using KaTeX.
class MathTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? mathColor;
  final bool selectable;

  const MathTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.mathColor,
    this.selectable = false,
  });

  /// Cleans up common OCR or typo errors in LaTeX expressions
  static String cleanTeX(String raw) {
    var cleaned = raw
        .replaceAll(r'\vert\}', r'\vert ')
        .replaceAll(r'\vert}', r'\vert ')
        .replaceAll(r'\vert{}', r'\vert ')
        .replaceAll(r'\lvert\}', r'\lvert ')
        .replaceAll(r'\lvert}', r'\lvert ')
        .replaceAll(r'\rvert\}', r'\rvert ')
        .replaceAll(r'\rvert}', r'\rvert ')
        .trim();

    // Fix unbalanced braces if any
    int openCount = 0;
    int closeCount = 0;
    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '{' && (i == 0 || cleaned[i - 1] != '\\')) openCount++;
      if (cleaned[i] == '}' && (i == 0 || cleaned[i - 1] != '\\')) closeCount++;
    }

    if (closeCount > openCount) {
      // Remove surplus trailing }
      while (closeCount > openCount && cleaned.endsWith('}')) {
        cleaned = cleaned.substring(0, cleaned.length - 1).trim();
        closeCount--;
      }
    } else if (openCount > closeCount) {
      cleaned = cleaned + ('}' * (openCount - closeCount));
    }

    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    // Quick check: if there is no dollar sign, render standard text
    if (!text.contains(r'$')) {
      if (selectable) {
        return SelectableText(text, style: style, textAlign: textAlign);
      }
      return Text(text, style: style, textAlign: textAlign);
    }

    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    final mathStyleColor = mathColor ?? effectiveStyle.color;
    final mathTextStyle = effectiveStyle.copyWith(color: mathStyleColor);

    // Regex to match $$display$$ or $inline$
    final regex = RegExp(r'(\$\$[\s\S]+?\$\$|\$[^$]+?\$)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: style, textAlign: textAlign);
    }

    // Check if the entire string is just one single math block
    final trimmed = text.trim();
    if (matches.length == 1 &&
        matches.first.start == 0 &&
        matches.first.end == text.length) {
      final isDisplay = trimmed.startsWith(r'$$') && trimmed.endsWith(r'$$');
      final inner = isDisplay
          ? trimmed.substring(2, trimmed.length - 2)
          : trimmed.substring(1, trimmed.length - 1);
      final cleaned = cleanTeX(inner);

      return Math.tex(
        cleaned,
        textStyle: mathTextStyle,
        mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
        onErrorFallback: (err) => Text(text, style: effectiveStyle, textAlign: textAlign),
      );
    }

    // Mixed text and math
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: effectiveStyle,
          ),
        );
      }

      final matchedStr = match.group(0)!;
      final isDisplay = matchedStr.startsWith(r'$$');
      final inner = isDisplay
          ? matchedStr.substring(2, matchedStr.length - 2)
          : matchedStr.substring(1, matchedStr.length - 1);
      final cleaned = cleanTeX(inner);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Math.tex(
              cleaned,
              textStyle: mathTextStyle,
              mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
              onErrorFallback: (err) => Text(matchedStr, style: effectiveStyle),
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: effectiveStyle,
        ),
      );
    }

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
    );
  }
}

