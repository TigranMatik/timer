import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timer/main.dart';

void main() {
  testWidgets('App should render with bottom navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());
    
    // Verify the MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify bottom navigation bar is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    
    // Verify all navigation items are present
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
} 