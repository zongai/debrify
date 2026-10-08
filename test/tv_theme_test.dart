import 'package:debrify/theme/tv_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('context.tv falls back to defaults without extension', (
    tester,
  ) async {
    late TvTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            resolved = context.tv;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved.space.railGap, TvTheme.defaults.space.railGap);
    expect(resolved.focus.scale, greaterThan(1.0));
  });

  testWidgets('extension is readable from Theme', (tester) async {
    const custom = TvTheme(
      space: TvSpace(railGap: 40),
      focus: TvFocusTokens(scale: 1.08),
    );
    late TvTheme resolved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[custom],
        ),
        home: Builder(
          builder: (context) {
            resolved = context.tv;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved.space.railGap, 40);
    expect(resolved.focus.scale, 1.08);
  });

  testWidgets('TvFocusChrome builds without error when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[TvTheme.defaults],
        ),
        home: const TvFocusChrome(
          focused: true,
          child: SizedBox(width: 40, height: 60),
        ),
      ),
    );
    expect(find.byType(TvFocusChrome), findsOneWidget);
    expect(find.byType(AnimatedScale), findsOneWidget);
  });
}
