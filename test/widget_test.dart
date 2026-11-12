// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/l10n/app_language.dart' as app_language;
import 'package:aman_app/screens/auth_flow.dart';

void main() {
  testWidgets('onboarding screen shows welcome content', (
    WidgetTester tester,
  ) async {
    app_language.AppLanguage.locale.value = const Locale('en');
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('language switch updates all text and page direction', (
    WidgetTester tester,
  ) async {
    app_language.AppLanguage.locale.value = const Locale('en');
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: app_language.AppLanguage.locale,
        builder: (context, locale, _) => MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(
            body: Column(
              children: [
                app_language.LanguageSwitchButton(),
                app_language.Text('الرئيسية'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Home'))),
      TextDirection.ltr,
    );

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('الرئيسية'))),
      TextDirection.rtl,
    );
    expect(find.text('English'), findsOneWidget);

    app_language.AppLanguage.locale.value = const Locale('en');
  });
}
