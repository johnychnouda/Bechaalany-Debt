// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bechaalany Connect';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navProducts => 'Products';

  @override
  String get navActivities => 'Activities';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navSettings => 'Settings';

  @override
  String get dashboardWelcomeBack => 'Welcome back';

  @override
  String get financialAnalysis => 'Financial Analysis';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get fromProductProfitMargins => 'From product profit margins';

  @override
  String get potentialRevenue => 'Potential Revenue';

  @override
  String get fromUnpaidAmounts => 'From unpaid amounts';

  @override
  String get totalDebts => 'Total Debts';

  @override
  String get outstandingAmounts => 'Outstanding amounts';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get fromCustomerPayments => 'From customer payments';

  @override
  String get totalCustomersAndDebtors => 'Total Customers and Debtors';

  @override
  String get customersWithDebts => 'Customers with Debts';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get noCustomersAddedYet =>
      'No customers added yet. Add your first customer to get started!';

  @override
  String percentCustomersPendingDebts(String percent) {
    return '$percent% of customers have pending debts';
  }

  @override
  String get topDebtors => 'Top Debtors';

  @override
  String get noOutstandingDebts => 'No outstanding debts';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionBusinessSettings => 'Business Settings';

  @override
  String get sectionWhatsAppAutomation => 'WhatsApp Automation';

  @override
  String get sectionDataManagement => 'Data Management';

  @override
  String get sectionAppInfo => 'App Info';

  @override
  String get accessStatus => 'Access Status';

  @override
  String get accessStatusSubtitle =>
      'View your access status and contact support if needed';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutSubtitle => 'Sign out of your account';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get deleteAccountDialogMessage =>
      'This will permanently delete your account and all associated data including:\n\n• All customers and debts\n• All activities and payment records\n• All backups\n• All settings and preferences\n\nThis action cannot be undone.';

  @override
  String get finalConfirmation => 'Final Confirmation';

  @override
  String get finalConfirmationDeleteMessage =>
      'This is your last chance to cancel. Your account and all data will be permanently deleted. This cannot be undone.';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'App language (English or Arabic)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Use dark appearance';

  @override
  String get businessName => 'Business Name';

  @override
  String get businessNameSubtitle =>
      'Set your business name for receipts and messages';

  @override
  String get currencyAndRates => 'Currency & Exchange Rates';

  @override
  String get currencyAndRatesSubtitle =>
      'Configure currency settings and rates';

  @override
  String get enableAutomatedMessages => 'Enable Automated Messages';

  @override
  String get enableAutomatedMessagesSubtitle =>
      'Send WhatsApp messages for debt settlements and payment reminders';

  @override
  String get sendPaymentReminders => 'Send Payment Reminders';

  @override
  String get sendPaymentRemindersSubtitle =>
      'Manually send WhatsApp reminders to customers with remaining debts';

  @override
  String get paymentRemindersTitle => 'Payment Reminders';

  @override
  String get clearSelection => 'Clear';

  @override
  String get selectAll => 'Select All';

  @override
  String get paymentRemindersCustomerCountOne =>
      '1 customer with outstanding debts';

  @override
  String paymentRemindersCustomerCountOther(String count) {
    return '$count customers with outstanding debts';
  }

  @override
  String get paymentRemindersSelectedOne => '1 customer selected';

  @override
  String paymentRemindersSelectedOther(String count) {
    return '$count customers selected';
  }

  @override
  String get sendReminders => 'Send Reminders';

  @override
  String get allClear => 'All clear!';

  @override
  String get noCustomersOutstandingDebts =>
      'No customers have outstanding debts';

  @override
  String get sendPaymentReminderDialogTitle => 'Send Payment Reminder';

  @override
  String get batchReminderSubtitle =>
      'This message will be sent via WhatsApp to all selected customers';

  @override
  String get enterCustomMessage => 'Enter your custom message...';

  @override
  String sendToCount(String count) {
    return 'Send to $count';
  }

  @override
  String get allRemindersSentSuccess => 'All reminders sent successfully!';

  @override
  String sentToCountOfTotal(String success, String total) {
    return 'Sent to $success out of $total customers';
  }

  @override
  String batchRemindersFailed(String message) {
    return 'Failed to send batch payment reminders: $message';
  }

  @override
  String get warning => 'Warning';

  @override
  String get clearDebtsAndActivities => 'Clear Debts & Activities';

  @override
  String get clearDebtsAndActivitiesSubtitle =>
      'Remove all debts, activities, and payment records';

  @override
  String get dataRecovery => 'Data Recovery';

  @override
  String get dataRecoverySubtitle => 'Recover data from backups';

  @override
  String get manualBackup => 'Manual Backup';

  @override
  String get createBackup => 'Create Backup';

  @override
  String get backupButton => 'Backup';

  @override
  String get automaticBackup => 'Automatic Backup';

  @override
  String get dailyBackupAt12AM => 'Daily Backup at 12 AM';

  @override
  String nextBackupIn(String time) {
    return 'Next backup in: $time';
  }

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShort => 'm';

  @override
  String get secondsShort => 's';

  @override
  String lastBackup(String time) {
    return 'Last backup: $time';
  }

  @override
  String get never => 'Never';

  @override
  String get availableBackups => 'Available Backups';

  @override
  String get noBackupsAvailable =>
      'No backups available. Create your first backup to get started.';

  @override
  String get signInToViewBackups =>
      'Please sign in to view and manage your backups.';

  @override
  String get automaticBackupLabel => 'Automatic backup';

  @override
  String get manualBackupLabel => 'Manual backup';

  @override
  String get restore => 'Restore';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreDataConfirm =>
      'This will replace all current data with the backup. This action cannot be undone. Are you sure?';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get deleteBackupConfirm =>
      'This will permanently delete the backup file. This action cannot be undone. Are you sure?';

  @override
  String get developer => 'Developer';

  @override
  String get appVersion => 'App Version';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get ok => 'OK';

  @override
  String get success => 'Success';

  @override
  String get error => 'Error';

  @override
  String get businessNameDialogTitle => 'Business Name';

  @override
  String get businessNameDialogHint =>
      'Your business name will appear on receipts, payment reminders, and all customer communications.';

  @override
  String get enterBusinessName => 'Enter your business name';

  @override
  String get businessNameRequired => 'Business name is required';

  @override
  String get businessNameUpdated =>
      'Business name has been updated successfully.';

  @override
  String businessNameUpdateFailed(String message) {
    return 'Failed to update business name: $message';
  }

  @override
  String get appInfoTitle => 'App Information';

  @override
  String get appInfoName => 'Bechaalany Debt App';

  @override
  String get appInfoDescription =>
      'A comprehensive debt management application for tracking customer debts, payments, and business revenue.';

  @override
  String get appInfoFeaturesTitle => 'Features:';

  @override
  String get appInfoFeaturesList =>
      '• Customer debt tracking\n• Payment management\n• Revenue calculations\n• Product catalog\n• WhatsApp automation\n• Data backup & recovery';

  @override
  String get clearDebtsDialogTitle => 'Clear Debts & Activities';

  @override
  String get clearDebtsDialogContent =>
      'This will permanently delete all debts, activities, and payment records. Products and customers will be preserved. This action cannot be undone.\n\nAre you sure you want to proceed?';

  @override
  String get clearDebtsButton => 'Clear Debts';

  @override
  String get clearDebtsSuccess =>
      'All debts, activities, and payment records have been cleared successfully. Products and customers have been preserved.';

  @override
  String get signInTitleBechaalany => 'Bechaalany ';

  @override
  String get signInTitleConnect => 'Connect';

  @override
  String get signInSubtitle =>
      'Sign in with your Google or Apple account to get started';

  @override
  String get signInSubtitleGoogleOnly =>
      'Sign in with your Google account to get started';

  @override
  String get signingIn => 'Signing you in...';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get googleSignInCancelled => 'Google sign-in was cancelled';

  @override
  String googleSignInFailed(String message) {
    return 'Google sign-in failed: $message';
  }

  @override
  String get appleSignInCancelled => 'Apple sign-in was cancelled';

  @override
  String get appleSignInCancelledTryAgain =>
      'Apple sign-in was cancelled. Please try again.';

  @override
  String get appleSignInNotAvailable =>
      'Apple Sign-In is not available. Please check your device settings.';

  @override
  String get networkError =>
      'Network error. Please check your internet connection.';

  @override
  String get appleSignInFailed =>
      'Apple sign-in failed. Please try again or use Google Sign-In instead.';

  @override
  String get requiredSetupTitle => 'Required Setup';

  @override
  String get requiredSetupSubtitle =>
      'Complete the following to start using the app';

  @override
  String get requiredSetupHeaderTitle => 'Let\'s get you set up';

  @override
  String get requiredSetupHeaderSubtitle =>
      'Just two things — takes less than a minute.';

  @override
  String get shopName => 'Shop Name';

  @override
  String get shopNameLabel => 'What\'s your shop or business name?';

  @override
  String get shopNameHint => 'Shown on receipts';

  @override
  String get shopNamePlaceholder => 'e.g. My Shop';

  @override
  String get exchangeRate => 'Exchange Rate';

  @override
  String get exchangeRateLabel => 'What\'s 1 USD in LBP right now?';

  @override
  String get exchangeRateHint => 'Enter the number only';

  @override
  String get exchangeRatePlaceholder => 'e.g. 89,000';

  @override
  String get continueButton => 'Continue';

  @override
  String get getStarted => 'Get started';

  @override
  String get couldNotLoadValues => 'Could not load current values.';

  @override
  String get addShopNameToContinue => 'Add your shop name to continue.';

  @override
  String get enterValidExchangeRate =>
      'Please enter a valid exchange rate (number greater than 0).';

  @override
  String get enterRateToContinue =>
      'Enter the current rate (e.g. 89,000) to continue.';

  @override
  String get settingsHint => 'You can change these anytime in Settings.';

  @override
  String get saveFailedTryAgain => 'Failed to save. Please try again.';

  @override
  String get saving => 'Saving...';

  @override
  String get setupSaved => 'Setup saved. You can start using the app.';

  @override
  String setupSaveFailed(String message) {
    return 'Failed to save: $message';
  }

  @override
  String get searchByNameOrId => 'Search by name or ID';

  @override
  String get customersTitle => 'Customers';

  @override
  String customersCount(String count) {
    return '$count customers';
  }

  @override
  String get customerCountOne => '1 customer';

  @override
  String get noCustomersYet => 'No customers yet';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get startByAddingFirstCustomer =>
      'Start by adding your first customer';

  @override
  String get tryAdjustingSearchCriteria => 'Try adjusting your search criteria';

  @override
  String get deleteCustomer => 'Delete Customer';

  @override
  String deleteCustomerConfirmWithDebts(String count) {
    return 'This customer has $count debt(s). Deleting the customer will also delete all associated debts. Are you sure?';
  }

  @override
  String get deleteCustomerConfirm =>
      'Are you sure you want to delete this customer?';

  @override
  String deleteCustomerConfirmWithName(String name) {
    return 'Are you sure you want to delete $name? This action cannot be undone.';
  }

  @override
  String get viewDetails => 'View Details';

  @override
  String get delete => 'Delete';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get filterAll => 'All';

  @override
  String get refresh => 'Refresh';

  @override
  String get noCategoriesFound => 'No categories found';

  @override
  String get addCategoriesToGetStarted => 'Add categories to get started';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get tryAdjustingSearchTerms => 'Try adjusting your search terms';

  @override
  String get addProductsToGetStarted => 'Add products to get started';

  @override
  String addProductsToCategoryToGetStarted(String category) {
    return 'Add products to $category to get started';
  }

  @override
  String noProductsInCategory(String category) {
    return 'No products in $category';
  }

  @override
  String get categoryNotFound => 'Category not found';

  @override
  String get activityHistory => 'Activity History';

  @override
  String get generateMonthlyReport => 'Generate Monthly Report';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get todaysActivity => 'Today\'s Activity';

  @override
  String weeklyActivityRange(String start, String end) {
    return 'Weekly Activity - $start - $end';
  }

  @override
  String monthlyActivityMonth(String monthYear) {
    return 'Monthly Activity - $monthYear';
  }

  @override
  String yearlyActivityYear(String year) {
    return 'Yearly Activity - $year';
  }

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get noActivityToday =>
      'No activity today\nAdd debts or make payments to see activity here';

  @override
  String get noActivityThisWeek =>
      'No activity this week\nAdd debts or make payments to see activity here';

  @override
  String get noActivityThisMonth =>
      'No activity this month\nAdd debts or make payments to see activity here';

  @override
  String get noActivityThisYear =>
      'No activity this year\nAdd debts or make payments to see activity here';

  @override
  String noActivitiesFoundForQuery(String query) {
    return 'No activities found for \"$query\"';
  }

  @override
  String todayAtTime(String time) {
    return 'Today at $time';
  }

  @override
  String yesterdayAtTime(String time) {
    return 'Yesterday at $time';
  }

  @override
  String dateAtTime(String date, String time) {
    return '$date at $time';
  }

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get dashboardOverview => 'Dashboard Overview';

  @override
  String get monitorUserStatistics => 'Monitor your user statistics';

  @override
  String get overview => 'Overview';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get allRegisteredUsers => 'All registered users';

  @override
  String get active => 'Active';

  @override
  String get activeAccess => 'Active access';

  @override
  String get trial => 'Trial';

  @override
  String get onTrialPeriod => 'On trial period';

  @override
  String get expired => 'Expired';

  @override
  String get expiredAccess => 'Expired access';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get viewManageAllUsers => 'View & manage all users';

  @override
  String get loadingDashboard => 'Loading dashboard...';

  @override
  String get unableToLoadDashboard => 'Unable to Load Dashboard';

  @override
  String get retry => 'Retry';

  @override
  String get noUsersInSystem => 'No users in the system yet';

  @override
  String get noUsersYetSubtitle =>
      'User statistics will appear here once users start registering.';

  @override
  String get userManagement => 'User Management';

  @override
  String get searchByEmailOrName => 'Search by email or name...';

  @override
  String get monthlyFilter => 'Monthly';

  @override
  String get yearlyFilter => 'Yearly';

  @override
  String userSummaryCounts(
    String all,
    String trial,
    String monthly,
    String yearly,
    String expired,
  ) {
    return 'All: $all • Trial: $trial • Monthly: $monthly • Yearly: $yearly • Expired: $expired';
  }

  @override
  String get noUsersFound => 'No users found';

  @override
  String get noUsersMatchSearch => 'No users match your search';

  @override
  String get noTrialUsersFound => 'No trial users found';

  @override
  String get noMonthlyUsersFound => 'No monthly users found';

  @override
  String get noYearlyUsersFound => 'No yearly users found';

  @override
  String get noExpiredUsersFound => 'No expired users found';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get noAdminPermissions =>
      'You do not have admin permissions to view this page.';

  @override
  String get trialExpired => 'Trial Expired';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get activeStatus => 'Active';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedMessage =>
      'You do not have permission to access user data. Please ensure your account is marked as admin in Firestore.';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get updateCustomer => 'Update Customer';

  @override
  String get customerInformation => 'Customer Information';

  @override
  String get financialSummary => 'Financial Summary';

  @override
  String get customerId => 'Customer ID';

  @override
  String get customerIdRequired => 'Customer ID *';

  @override
  String get enterCustomerId => 'Enter customer ID';

  @override
  String get pleaseEnterCustomerId => 'Please enter customer ID';

  @override
  String get customerIdAlreadyExists => 'Customer ID already exists';

  @override
  String get customerIdInvalidChars =>
      'Customer ID can only contain letters, numbers, underscore, and hyphen';

  @override
  String get thisCustomerIdAlreadyExists => 'This Customer ID already exists';

  @override
  String get fullName => 'Full Name *';

  @override
  String get enterCustomerName => 'Enter customer name';

  @override
  String get pleaseEnterCustomerName => 'Please enter customer name';

  @override
  String get phoneNumber => 'Phone Number *';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get validPhoneNumber =>
      'Please enter a valid phone number (minimum 8 digits)';

  @override
  String get thisPhoneNumberAlreadyExists => 'This phone number already exists';

  @override
  String get duplicatePhoneNumber => 'Duplicate Phone Number';

  @override
  String duplicatePhoneMessage(String phone, String name, String id) {
    return 'The phone number \"$phone\" is already used by customer \"$name\" (ID: $id).\n\nDo you want to continue with this phone number?';
  }

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmailOptional => 'Enter email (optional)';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get validEmailDomain => 'Please enter a valid email domain';

  @override
  String get thisEmailAlreadyUsed =>
      'This email is already used by another customer';

  @override
  String get address => 'Address';

  @override
  String get enterAddressOptional => 'Enter address (optional)';

  @override
  String get add => 'Add';

  @override
  String get addCategory => 'Add Category';

  @override
  String get addProduct => 'Add Product';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'e.g., Electronics';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get chooseCategoryToAddSubcategory =>
      'Choose a category to add a subcategory to:';

  @override
  String subcategoriesCount(String count) {
    return '$count subcategories';
  }

  @override
  String addSubcategoryTo(String name) {
    return 'Add Subcategory to $name';
  }

  @override
  String get subcategoryName => 'Subcategory Name';

  @override
  String get subcategoryNameHint => 'e.g., iPhone';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get productCost => 'Cost';

  @override
  String get productPrice => 'Price';

  @override
  String get productRevenue => 'Revenue';

  @override
  String get productLoss => 'Loss';

  @override
  String get enterCostPrice => 'Enter cost price';

  @override
  String get enterSellingPrice => 'Enter selling price';

  @override
  String get exchangeRateRequired => 'Exchange Rate Required';

  @override
  String get setExchangeRateInSettings =>
      'Please set an exchange rate in Currency Settings before adding products with LBP.';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get confirm => 'Confirm';

  @override
  String get editCategoryName => 'Edit Category Name';

  @override
  String get categoryNameExists => 'Category Name Exists';

  @override
  String get addDebtFromProduct => 'Add Debt from Product';

  @override
  String get customerLabel => 'Customer';

  @override
  String get categoryLabel => 'Category';

  @override
  String get productLabel => 'Product';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get productDetails => 'Product Details';

  @override
  String get selectProductAboveToViewDetails =>
      'Select a product above to view details';

  @override
  String get addDebt => 'Add Debt';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get notSelected => 'Not selected';

  @override
  String get addProductsToCategoryInProductsTab =>
      'Add products to this category in the Products tab.';

  @override
  String get productPurchases => 'Product Purchases';

  @override
  String productsCount(String count) {
    return '$count products';
  }

  @override
  String get makePayment => 'Make Payment';

  @override
  String get totalPending => 'Total Pending';

  @override
  String createdOnDateAtTime(String date, String time) {
    return 'Created on $date at $time';
  }

  @override
  String get timeAm => 'AM';

  @override
  String get timePm => 'PM';

  @override
  String get customerReceipt => 'Customer Receipt';

  @override
  String get generatedOn => 'Generated on';

  @override
  String get accountSummary => 'Account Summary';

  @override
  String get totalOriginal => 'Total Original';

  @override
  String get remaining => 'Remaining';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get generatedBy => 'Generated by';

  @override
  String get receiptFor => 'Receipt for';

  @override
  String pageOf(String current, String total) {
    return 'Page $current of $total';
  }

  @override
  String get idLabel => 'ID';

  @override
  String get partialPayment => 'Partial Payment';

  @override
  String get outstandingDebt => 'Outstanding Debt';

  @override
  String get newDebt => 'New Debt';

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String get debtPaid => 'Debt Paid';

  @override
  String get activity => 'Activity';

  @override
  String get deleteDebt => 'Delete Debt';

  @override
  String get deleteDebtConfirm => 'Are you sure you want to delete this debt?';

  @override
  String get debtDetails => 'Debt Details:';

  @override
  String get amountLabel => 'Amount:';

  @override
  String get deleteDebtCannotUndo => 'This action cannot be undone.';

  @override
  String get monthlyActivityReport => 'Monthly Activity Report';

  @override
  String get reportSummary => 'Summary';

  @override
  String get transactionsLabel => 'Transactions';

  @override
  String get activityDetails => 'Activity Details';

  @override
  String get userDetails => 'User Details';

  @override
  String get loadingUserDetails => 'Loading user details…';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get actions => 'Actions';

  @override
  String get updating => 'Updating…';

  @override
  String get grantAccess => 'Grant Access';

  @override
  String get grantAccessDescription =>
      'Grant continued access to this user. Choose duration.';

  @override
  String get oneMonth => '1 Month';

  @override
  String get oneYear => '1 Year';

  @override
  String get revokeAccess => 'Revoke Access';

  @override
  String get revokeAccessDescription =>
      'Temporarily suspend this account. The user can contact you if there is an issue.';

  @override
  String get revokeAccessConfirm =>
      'Are you sure you want to revoke this user\'s access?';

  @override
  String get revoke => 'Revoke';

  @override
  String accessGrantedSuccess(String duration) {
    return 'Access granted successfully ($duration)!';
  }

  @override
  String failedToGrantAccess(String error) {
    return 'Failed to grant access: $error';
  }

  @override
  String get accessRevokedSuccess => 'Access revoked successfully!';

  @override
  String failedToRevokeAccess(String error) {
    return 'Failed to revoke access: $error';
  }

  @override
  String get noAccessData => 'No access data';

  @override
  String get status => 'Status';

  @override
  String get trialStarted => 'Trial Started';

  @override
  String get trialEnds => 'Trial Ends';

  @override
  String get accessStarted => 'Access Started';

  @override
  String get accessEnds => 'Access Ends';

  @override
  String get accessPeriod => 'Access Period';

  @override
  String updatedDate(String date) {
    return 'Updated $date';
  }

  @override
  String get dateExpired => '(Expired)';

  @override
  String get dateDaysLeftOne => '(1 day left)';

  @override
  String dateDaysLeftOther(String count) {
    return '($count days left)';
  }

  @override
  String get oneMonthLabel => '1 month';

  @override
  String get oneYearLabel => '1 year';

  @override
  String get requestAccess => 'Request Access';

  @override
  String get freeTrial => 'Free Trial';

  @override
  String get accessExpired => 'Access Expired';

  @override
  String get accessCancelled => 'Access Cancelled';

  @override
  String get trialDetails => 'Trial details';

  @override
  String get trialPeriod => 'Trial period';

  @override
  String daysRemaining(String count) {
    return '$count days remaining';
  }

  @override
  String get accessDetails => 'Access details';

  @override
  String get yourAccessExpired => 'Your access has expired';

  @override
  String get yourAccessCancelled => 'Your access has been cancelled';

  @override
  String get expiredContactMessage =>
      'If you believe this is a mistake or need help with your account, contact the administrator for support.';

  @override
  String get contactAdministrator => 'Contact Administrator';

  @override
  String get accessStatusAndRenewals => 'Access status and renewals';

  @override
  String get requestAccessInfoMessage =>
      'If your trial or access period ends and you still cannot use the app, you can contact the administrator for help fixing your account.';

  @override
  String get welcomeToBechaalany => 'Welcome to Bechaalany Debt App';

  @override
  String get welcomeNoDataMessage =>
      'The app is completely free and available to all signed-in users. If you ever have trouble accessing your data, you can contact the administrator for technical support.';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get phone => 'Phone';
}
