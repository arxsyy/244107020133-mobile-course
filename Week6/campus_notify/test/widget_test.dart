import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_notify/pages/login_page.dart';

void main() {
  testWidgets('menampilkan halaman login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Campus Notification App'), findsOneWidget);
  });
}