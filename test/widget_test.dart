import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:guagua/main.dart';

void main() {
  testWidgets('GuaguaApp loads successfully on Desktop without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: GuaguaApp(),
      ),
    );

    expect(find.textContaining('Guagua POS'), findsWidgets);
  });

  testWidgets('GuaguaApp loads successfully on Mobile Android without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: GuaguaApp(),
      ),
    );

    expect(find.textContaining('Guagua POS'), findsWidgets);
  });
}
