import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renomada/shared/widgets/app_header.dart';

void main() {
  testWidgets('AppHeader subtitle is clickable', (WidgetTester tester) async {
    bool subtitleTapped = false;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              title: 'Explorar',
              subtitle: 'Madrid, España',
              onSubtitleTap: () {
                subtitleTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify subtitle is rendered
    expect(find.text('Madrid, España'), findsOneWidget);

    // Tap the subtitle text
    await tester.tap(find.text('Madrid, España'));
    await tester.pumpAndSettle();

    // Verify the callback was triggered
    expect(subtitleTapped, isTrue);
  });
}
