import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/main.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/notification_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/purchase_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/services/accessibility_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('NemuruApp launches successfully', (WidgetTester tester) async {
    // Initialize test dependencies
    final preferencesService = PreferencesService();
    await preferencesService.init();
    
    final notificationService = NotificationService();
    final subscriptionService = SubscriptionService(preferencesService);
    final purchaseService = PurchaseService();
    final chatLogService = ChatLogService();
    final accessibilityService = AccessibilityService();
    
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => preferencesService),
          Provider(create: (_) => notificationService),
          ChangeNotifierProvider(create: (_) => subscriptionService),
          ChangeNotifierProvider(create: (_) => purchaseService),
          ChangeNotifierProvider(create: (_) => chatLogService),
          ChangeNotifierProvider(create: (_) => accessibilityService),
        ],
        child: const NemuruApp(),
      ),
    );

    // Verify that the app launches
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}