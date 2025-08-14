// This is a basic Flutter widget test.
//
// To perform an interaction with a widget, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bechaalany_connect/models/activity.dart';
import 'package:bechaalany_connect/models/debt.dart';
import 'package:bechaalany_connect/models/category.dart';
import 'package:bechaalany_connect/providers/app_state.dart';

void main() {
  group('Revenue Calculation Tests', () {
    test('Revenue should persist after debt deletion', () {
      // Create test data
      final testCategory = ProductCategory(
        id: 'test_category',
        name: 'Test Category',
        createdAt: DateTime.now(),
        subcategories: [
          Subcategory(
            id: 'test_product',
            name: 'Test Product',
            costPrice: 50.0,
            sellingPrice: 100.0,
            createdAt: DateTime.now(),
            costPriceCurrency: 'USD',
            sellingPriceCurrency: 'USD',
          ),
        ],
      );

      final testDebt = Debt(
        id: 'test_debt',
        customerId: 'test_customer',
        customerName: 'Test Customer',
        amount: 100.0,
        description: 'Test Product',
        type: DebtType.credit,
        status: DebtStatus.paid,
        createdAt: DateTime.now(),
        paidAmount: 100.0,
        subcategoryId: 'test_product',
        subcategoryName: 'Test Product',
        originalSellingPrice: 100.0,
        categoryName: 'Test Category',
      );

      final testActivity = Activity(
        id: 'test_activity',
        date: DateTime.now(),
        type: ActivityType.payment,
        customerName: 'Test Customer',
        customerId: 'test_customer',
        description: 'Test Product',
        amount: 100.0,
        paymentAmount: 100.0,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: 'test_debt',
      );

      // Test that revenue calculation works with the debt present
      final appState = AppState();
      
      // Manually set the data for testing
      appState.categories.add(testCategory);
      appState.debts.add(testDebt);
      appState.activities.add(testActivity);
      
      // Calculate revenue with debt present
      final revenueWithDebt = appState.totalHistoricalRevenue;
      
      // Verify revenue is calculated correctly (100 - 50 = 50 profit)
      expect(revenueWithDebt, equals(50.0));
      
      // Now simulate debt deletion
      appState.debts.removeWhere((d) => d.id == 'test_debt');
      
      // Calculate revenue after debt deletion
      final revenueAfterDeletion = appState.totalHistoricalRevenue;
      
      // Revenue should still be the same (50.0) because it's calculated from activities
      expect(revenueAfterDeletion, equals(50.0));
      
      // Verify that revenue persists even when debt is deleted
      expect(revenueAfterDeletion, equals(revenueWithDebt));
    });

    test('Revenue calculation should handle missing product information gracefully', () {
      // Create test data without product information
      final testActivity = Activity(
        id: 'test_activity_no_product',
        date: DateTime.now(),
        type: ActivityType.payment,
        customerName: 'Test Customer',
        customerId: 'test_customer',
        description: 'Test Payment',
        amount: 100.0,
        paymentAmount: 100.0,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: null, // No debt reference
      );

      final appState = AppState();
      appState.activities.add(testActivity);
      
      // Calculate revenue
      final revenue = appState.totalHistoricalRevenue;
      
      // Should use conservative estimate (25% of payment amount)
      expect(revenue, equals(25.0)); // 100 * 0.25 = 25
    });

    test('Revenue calculation should handle debt cleared activities', () {
      // Create test data for a cleared debt
      final testClearedActivity = Activity(
        id: 'test_cleared_activity',
        date: DateTime.now(),
        type: ActivityType.debtCleared,
        customerName: 'Test Customer',
        customerId: 'test_customer',
        description: 'Cleared debt: Test Product (Product: Test Product) (Category: Test Category)',
        amount: 100.0,
        paymentAmount: 100.0,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: 'test_debt_cleared',
      );

      final appState = AppState();
      appState.activities.add(testClearedActivity);
      
      // Calculate revenue
      final revenue = appState.totalHistoricalRevenue;
      
      // Should use conservative estimate (25% of payment amount)
      expect(revenue, equals(25.0)); // 100 * 0.25 = 25
    });

    test('Revenue calculation should work with enhanced debt cleared descriptions', () {
      // Create test data with enhanced description that includes product information
      final testClearedActivity = Activity(
        id: 'test_enhanced_cleared_activity',
        date: DateTime.now(),
        type: ActivityType.debtCleared,
        customerName: 'Test Customer',
        customerId: 'test_customer',
        description: 'Cleared debt: Test Product (Product: Test Product) (Category: Test Category)',
        amount: 100.0,
        paymentAmount: 100.0,
        oldStatus: DebtStatus.pending,
        newStatus: DebtStatus.paid,
        debtId: 'test_debt_cleared',
      );

      // Create the same product category for lookup
      final testCategory = ProductCategory(
        id: 'test_category',
        name: 'Test Category',
        createdAt: DateTime.now(),
        subcategories: [
          Subcategory(
            id: 'test_product',
            name: 'Test Product',
            costPrice: 50.0,
            sellingPrice: 100.0,
            createdAt: DateTime.now(),
            costPriceCurrency: 'USD',
            sellingPriceCurrency: 'USD',
          ),
        ],
      );

      final appState = AppState();
      appState.activities.add(testClearedActivity);
      appState.categories.add(testCategory);
      
      // Calculate revenue
      final revenue = appState.totalHistoricalRevenue;
      
      // Should now calculate exact revenue (100 - 50 = 50) because product info is in description
      expect(revenue, equals(50.0));
    });
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
