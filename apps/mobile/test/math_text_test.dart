import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:classroom/shared/components/math_text_widget.dart';

void main() {
  testWidgets('renders pure math text correctly', (tester) async {
    const raw = r'$90^\circ$';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathTextWidget(text: raw),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('renders mixed Bengali text and math correctly without crash', (tester) async {
    const mixed = r'$\vert}\vec{P} + \vec{Q}\vert{} = \vert{} \vec{P} - \vec{Q}\vert{}$ হলে, $\vec{P}$ ও $\vec{Q}$ এর মধ্যবর্তী কোণ $\alpha$ কত?';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathTextWidget(text: mixed),
        ),
      ),
    );

    // There should be multiple Math widgets for each math span
    expect(find.byType(Math), findsWidgets);
    expect(find.textContaining('হলে'), findsOneWidget);
  });

  testWidgets('renders plain text without math correctly', (tester) async {
    const plain = 'কোনটি স্কেলার রাশি?';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathTextWidget(text: plain),
        ),
      ),
    );

    expect(find.byType(Math), findsNothing);
    expect(find.text(plain), findsOneWidget);
  });
}
