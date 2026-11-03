import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../core/security/screen_protection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/empty_state.dart';
import '../../lessons/data/lessons_repository.dart';

class ClassNoteScreen extends ConsumerStatefulWidget {
  final String materialId;
  final LessonMaterialItem? initialMaterial;

  const ClassNoteScreen({
    super.key,
    required this.materialId,
    this.initialMaterial,
  });

  @override
  ConsumerState<ClassNoteScreen> createState() => _ClassNoteScreenState();
}

class _ClassNoteScreenState extends ConsumerState<ClassNoteScreen> {
  LessonMaterialItem? _material;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ScreenProtectionService.enableProtection();
    _material = widget.initialMaterial;
    _loadNote();
  }

  @override
  void dispose() {
    ScreenProtectionService.disableProtection();
    super.dispose();
  }

  Future<void> _loadNote() async {
    if (_material == null) {
      try {
        _material = await ref
            .read(lessonsRepositoryProvider)
            .getMaterialById(widget.materialId);
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_material == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ক্লাস নোট')),
        body: const EmptyStateWidget(
          title: 'নোট পাওয়া যায়নি',
          description: 'অনুরোধকৃত ক্লাস নোটটি খুঁজে পাওয়া যায়নি।',
        ),
      );
    }

    final content = _material!.contentMd ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_material!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: content.isEmpty
          ? const EmptyStateWidget(
              icon: LucideIcons.bookOpen,
              title: 'কোনো লেখা নেই',
              description: 'এই ক্লাস নোটে এখনো কোনো বিবরণ বা নোট যোগ করা হয়নি।',
            )
          : Markdown(
              data: content,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary600),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.neutral900),
                h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                p: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.neutral800),
                code: const TextStyle(
                  backgroundColor: AppColors.neutral100,
                  color: AppColors.primary700,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              builders: {
                'latex': LatexElementBuilder(),
              },
              extensionSet: md.ExtensionSet.gitHubFlavored,
            ),
    );
  }
}

class LatexElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    return Math.tex(
      text,
      textStyle: preferredStyle,
      mathStyle: MathStyle.display,
    );
  }
}
