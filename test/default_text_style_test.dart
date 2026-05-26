import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bechaalany_connect/widgets/app_default_text_style.dart';
import 'package:bechaalany_connect/widgets/cupertino_material_page_scaffold.dart';

void main() {
  testWidgets('CupertinoMaterialPageScaffold text has no error underline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const CupertinoMaterialPageScaffold(
          child: SafeArea(
            child: Text('No yellow underline'),
          ),
        ),
      ),
    );

    final element = tester.element(find.text('No yellow underline'));
    final defaultStyle = DefaultTextStyle.of(element);
    expect(defaultStyle.style.decoration, TextDecoration.none);
    expect(defaultStyle.style.decorationColor, Colors.transparent);
  });

  testWidgets('AppDefaultTextStyle.wrap overrides MaterialApp error style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        builder: (context, child) => AppDefaultTextStyle.wrap(context, child!),
        home: const CupertinoPageScaffold(
          child: SafeArea(
            child: Text('Wrapped text'),
          ),
        ),
      ),
    );

    final element = tester.element(find.text('Wrapped text'));
    final defaultStyle = DefaultTextStyle.of(element);
    expect(defaultStyle.style.decoration, TextDecoration.none);
    expect(defaultStyle.style.decorationColor, Colors.transparent);
  });
}
