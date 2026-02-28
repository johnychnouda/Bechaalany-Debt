import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bechaalany Connect'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get navActivities;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dashboardWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get dashboardWelcomeBack;

  /// No description provided for @financialAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Financial Analysis'**
  String get financialAnalysis;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @fromProductProfitMargins.
  ///
  /// In en, this message translates to:
  /// **'From product profit margins'**
  String get fromProductProfitMargins;

  /// No description provided for @potentialRevenue.
  ///
  /// In en, this message translates to:
  /// **'Potential Revenue'**
  String get potentialRevenue;

  /// No description provided for @fromUnpaidAmounts.
  ///
  /// In en, this message translates to:
  /// **'From unpaid amounts'**
  String get fromUnpaidAmounts;

  /// No description provided for @totalDebts.
  ///
  /// In en, this message translates to:
  /// **'Total Debts'**
  String get totalDebts;

  /// No description provided for @outstandingAmounts.
  ///
  /// In en, this message translates to:
  /// **'Outstanding amounts'**
  String get outstandingAmounts;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @fromCustomerPayments.
  ///
  /// In en, this message translates to:
  /// **'From customer payments'**
  String get fromCustomerPayments;

  /// No description provided for @totalCustomersAndDebtors.
  ///
  /// In en, this message translates to:
  /// **'Total Customers and Debtors'**
  String get totalCustomersAndDebtors;

  /// No description provided for @customersWithDebts.
  ///
  /// In en, this message translates to:
  /// **'Customers with Debts'**
  String get customersWithDebts;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @noCustomersAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No customers added yet. Add your first customer to get started!'**
  String get noCustomersAddedYet;

  /// No description provided for @percentCustomersPendingDebts.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of customers have pending debts'**
  String percentCustomersPendingDebts(String percent);

  /// No description provided for @topDebtors.
  ///
  /// In en, this message translates to:
  /// **'Top Debtors'**
  String get topDebtors;

  /// No description provided for @noOutstandingDebts.
  ///
  /// In en, this message translates to:
  /// **'No outstanding debts'**
  String get noOutstandingDebts;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @sectionBusinessSettings.
  ///
  /// In en, this message translates to:
  /// **'Business Settings'**
  String get sectionBusinessSettings;

  /// No description provided for @sectionWhatsAppAutomation.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Automation'**
  String get sectionWhatsAppAutomation;

  /// No description provided for @sectionDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get sectionDataManagement;

  /// No description provided for @sectionAppInfo.
  ///
  /// In en, this message translates to:
  /// **'App Info'**
  String get sectionAppInfo;

  /// No description provided for @accessStatus.
  ///
  /// In en, this message translates to:
  /// **'Access Status'**
  String get accessStatus;

  /// No description provided for @accessStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your access status and contact support if needed'**
  String get accessStatusSubtitle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutSubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data including:\n\n• All customers and debts\n• All activities and payment records\n• All backups\n• All settings and preferences\n\nThis action cannot be undone.'**
  String get deleteAccountDialogMessage;

  /// No description provided for @finalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get finalConfirmation;

  /// No description provided for @finalConfirmationDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your last chance to cancel. Your account and all data will be permanently deleted. This cannot be undone.'**
  String get finalConfirmationDeleteMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language (English or Arabic)'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark appearance'**
  String get darkModeSubtitle;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your business name for receipts and messages'**
  String get businessNameSubtitle;

  /// No description provided for @currencyAndRates.
  ///
  /// In en, this message translates to:
  /// **'Currency & Exchange Rates'**
  String get currencyAndRates;

  /// No description provided for @currencyAndRatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure currency settings and rates'**
  String get currencyAndRatesSubtitle;

  /// No description provided for @enableAutomatedMessages.
  ///
  /// In en, this message translates to:
  /// **'Enable Automated Messages'**
  String get enableAutomatedMessages;

  /// No description provided for @enableAutomatedMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp messages for debt settlements and payment reminders'**
  String get enableAutomatedMessagesSubtitle;

  /// No description provided for @sendPaymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Payment Reminders'**
  String get sendPaymentReminders;

  /// No description provided for @sendPaymentRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually send WhatsApp reminders to customers with remaining debts'**
  String get sendPaymentRemindersSubtitle;

  /// No description provided for @paymentRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminders'**
  String get paymentRemindersTitle;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @paymentRemindersCustomerCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 customer with outstanding debts'**
  String get paymentRemindersCustomerCountOne;

  /// No description provided for @paymentRemindersCustomerCountOther.
  ///
  /// In en, this message translates to:
  /// **'{count} customers with outstanding debts'**
  String paymentRemindersCustomerCountOther(String count);

  /// No description provided for @paymentRemindersSelectedOne.
  ///
  /// In en, this message translates to:
  /// **'1 customer selected'**
  String get paymentRemindersSelectedOne;

  /// No description provided for @paymentRemindersSelectedOther.
  ///
  /// In en, this message translates to:
  /// **'{count} customers selected'**
  String paymentRemindersSelectedOther(String count);

  /// No description provided for @sendReminders.
  ///
  /// In en, this message translates to:
  /// **'Send Reminders'**
  String get sendReminders;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClear;

  /// No description provided for @noCustomersOutstandingDebts.
  ///
  /// In en, this message translates to:
  /// **'No customers have outstanding debts'**
  String get noCustomersOutstandingDebts;

  /// No description provided for @sendPaymentReminderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Payment Reminder'**
  String get sendPaymentReminderDialogTitle;

  /// No description provided for @batchReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This message will be sent via WhatsApp to all selected customers'**
  String get batchReminderSubtitle;

  /// No description provided for @enterCustomMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your custom message...'**
  String get enterCustomMessage;

  /// No description provided for @sendToCount.
  ///
  /// In en, this message translates to:
  /// **'Send to {count}'**
  String sendToCount(String count);

  /// No description provided for @allRemindersSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'All reminders sent successfully!'**
  String get allRemindersSentSuccess;

  /// No description provided for @sentToCountOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Sent to {success} out of {total} customers'**
  String sentToCountOfTotal(String success, String total);

  /// No description provided for @batchRemindersFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send batch payment reminders: {message}'**
  String batchRemindersFailed(String message);

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @clearDebtsAndActivities.
  ///
  /// In en, this message translates to:
  /// **'Clear Debts & Activities'**
  String get clearDebtsAndActivities;

  /// No description provided for @clearDebtsAndActivitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all debts, activities, and payment records'**
  String get clearDebtsAndActivitiesSubtitle;

  /// No description provided for @dataRecovery.
  ///
  /// In en, this message translates to:
  /// **'Data Recovery'**
  String get dataRecovery;

  /// No description provided for @dataRecoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover data from backups'**
  String get dataRecoverySubtitle;

  /// No description provided for @manualBackup.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get manualBackup;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @backupButton.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupButton;

  /// No description provided for @automaticBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backup'**
  String get automaticBackup;

  /// No description provided for @dailyBackupAt12AM.
  ///
  /// In en, this message translates to:
  /// **'Daily Backup at 12 AM'**
  String get dailyBackupAt12AM;

  /// No description provided for @nextBackupIn.
  ///
  /// In en, this message translates to:
  /// **'Next backup in: {time}'**
  String nextBackupIn(String time);

  /// No description provided for @hoursShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get secondsShort;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {time}'**
  String lastBackup(String time);

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @availableBackups.
  ///
  /// In en, this message translates to:
  /// **'Available Backups'**
  String get availableBackups;

  /// No description provided for @noBackupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No backups available. Create your first backup to get started.'**
  String get noBackupsAvailable;

  /// No description provided for @signInToViewBackups.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view and manage your backups.'**
  String get signInToViewBackups;

  /// No description provided for @automaticBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get automaticBackupLabel;

  /// No description provided for @manualBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual backup'**
  String get manualBackupLabel;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @restoreDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data with the backup. This action cannot be undone. Are you sure?'**
  String get restoreDataConfirm;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup'**
  String get deleteBackup;

  /// No description provided for @deleteBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the backup file. This action cannot be undone. Are you sure?'**
  String get deleteBackupConfirm;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @businessNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessNameDialogTitle;

  /// No description provided for @businessNameDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Your business name will appear on receipts, payment reminders, and all customer communications.'**
  String get businessNameDialogHint;

  /// No description provided for @enterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get enterBusinessName;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @businessNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Business name has been updated successfully.'**
  String get businessNameUpdated;

  /// No description provided for @businessNameUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update business name: {message}'**
  String businessNameUpdateFailed(String message);

  /// No description provided for @appInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInfoTitle;

  /// No description provided for @appInfoName.
  ///
  /// In en, this message translates to:
  /// **'Bechaalany Debt App'**
  String get appInfoName;

  /// No description provided for @appInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive debt management application for tracking customer debts, payments, and business revenue.'**
  String get appInfoDescription;

  /// No description provided for @appInfoFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Features:'**
  String get appInfoFeaturesTitle;

  /// No description provided for @appInfoFeaturesList.
  ///
  /// In en, this message translates to:
  /// **'• Customer debt tracking\n• Payment management\n• Revenue calculations\n• Product catalog\n• WhatsApp automation\n• Data backup & recovery'**
  String get appInfoFeaturesList;

  /// No description provided for @clearDebtsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Debts & Activities'**
  String get clearDebtsDialogTitle;

  /// No description provided for @clearDebtsDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all debts, activities, and payment records. Products and customers will be preserved. This action cannot be undone.\n\nAre you sure you want to proceed?'**
  String get clearDebtsDialogContent;

  /// No description provided for @clearDebtsButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Debts'**
  String get clearDebtsButton;

  /// No description provided for @clearDebtsSuccess.
  ///
  /// In en, this message translates to:
  /// **'All debts, activities, and payment records have been cleared successfully. Products and customers have been preserved.'**
  String get clearDebtsSuccess;

  /// No description provided for @signInTitleBechaalany.
  ///
  /// In en, this message translates to:
  /// **'Bechaalany '**
  String get signInTitleBechaalany;

  /// No description provided for @signInTitleConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get signInTitleConnect;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google or Apple account to get started'**
  String get signInSubtitle;

  /// No description provided for @signInSubtitleGoogleOnly.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account to get started'**
  String get signInSubtitleGoogleOnly;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in...'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled'**
  String get googleSignInCancelled;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed: {message}'**
  String googleSignInFailed(String message);

  /// No description provided for @appleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was cancelled'**
  String get appleSignInCancelled;

  /// No description provided for @appleSignInCancelledTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in was cancelled. Please try again.'**
  String get appleSignInCancelledTryAgain;

  /// No description provided for @appleSignInNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In is not available. Please check your device settings.'**
  String get appleSignInNotAvailable;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection.'**
  String get networkError;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again or use Google Sign-In instead.'**
  String get appleSignInFailed;

  /// No description provided for @requiredSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Required Setup'**
  String get requiredSetupTitle;

  /// No description provided for @requiredSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete the following to start using the app'**
  String get requiredSetupSubtitle;

  /// No description provided for @requiredSetupHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you set up'**
  String get requiredSetupHeaderTitle;

  /// No description provided for @requiredSetupHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just two things — takes less than a minute.'**
  String get requiredSetupHeaderSubtitle;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @shopNameLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s your shop or business name?'**
  String get shopNameLabel;

  /// No description provided for @shopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on receipts'**
  String get shopNameHint;

  /// No description provided for @shopNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Shop'**
  String get shopNamePlaceholder;

  /// No description provided for @exchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get exchangeRate;

  /// No description provided for @exchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s 1 USD in LBP right now?'**
  String get exchangeRateLabel;

  /// No description provided for @exchangeRateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the number only'**
  String get exchangeRateHint;

  /// No description provided for @exchangeRatePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 89,000'**
  String get exchangeRatePlaceholder;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @couldNotLoadValues.
  ///
  /// In en, this message translates to:
  /// **'Could not load current values.'**
  String get couldNotLoadValues;

  /// No description provided for @addShopNameToContinue.
  ///
  /// In en, this message translates to:
  /// **'Add your shop name to continue.'**
  String get addShopNameToContinue;

  /// No description provided for @enterValidExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid exchange rate (number greater than 0).'**
  String get enterValidExchangeRate;

  /// No description provided for @enterRateToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter the current rate (e.g. 89,000) to continue.'**
  String get enterRateToContinue;

  /// No description provided for @settingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can change these anytime in Settings.'**
  String get settingsHint;

  /// No description provided for @saveFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get saveFailedTryAgain;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @setupSaved.
  ///
  /// In en, this message translates to:
  /// **'Setup saved. You can start using the app.'**
  String get setupSaved;

  /// No description provided for @setupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {message}'**
  String setupSaveFailed(String message);

  /// No description provided for @searchByNameOrId.
  ///
  /// In en, this message translates to:
  /// **'Search by name or ID'**
  String get searchByNameOrId;

  /// No description provided for @customersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customersTitle;

  /// No description provided for @customersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customers'**
  String customersCount(String count);

  /// No description provided for @customerCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 customer'**
  String get customerCountOne;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @startByAddingFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first customer'**
  String get startByAddingFirstCustomer;

  /// No description provided for @tryAdjustingSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search criteria'**
  String get tryAdjustingSearchCriteria;

  /// No description provided for @deleteCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delete Customer'**
  String get deleteCustomer;

  /// No description provided for @deleteCustomerConfirmWithDebts.
  ///
  /// In en, this message translates to:
  /// **'This customer has {count} debt(s). Deleting the customer will also delete all associated debts. Are you sure?'**
  String deleteCustomerConfirmWithDebts(String count);

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this customer?'**
  String get deleteCustomerConfirm;

  /// No description provided for @deleteCustomerConfirmWithName.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}? This action cannot be undone.'**
  String deleteCustomerConfirmWithName(String name);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @addCategoriesToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add categories to get started'**
  String get addCategoriesToGetStarted;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @addProductsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add products to get started'**
  String get addProductsToGetStarted;

  /// No description provided for @addProductsToCategoryToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add products to {category} to get started'**
  String addProductsToCategoryToGetStarted(String category);

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in {category}'**
  String noProductsInCategory(String category);

  /// No description provided for @categoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get categoryNotFound;

  /// No description provided for @activityHistory.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activityHistory;

  /// No description provided for @generateMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Monthly Report'**
  String get generateMonthlyReport;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @todaysActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get todaysActivity;

  /// No description provided for @weeklyActivityRange.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity - {start} - {end}'**
  String weeklyActivityRange(String start, String end);

  /// No description provided for @monthlyActivityMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity - {monthYear}'**
  String monthlyActivityMonth(String monthYear);

  /// No description provided for @yearlyActivityYear.
  ///
  /// In en, this message translates to:
  /// **'Yearly Activity - {year}'**
  String yearlyActivityYear(String year);

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @noActivityToday.
  ///
  /// In en, this message translates to:
  /// **'No activity today\nAdd debts or make payments to see activity here'**
  String get noActivityToday;

  /// No description provided for @noActivityThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No activity this week\nAdd debts or make payments to see activity here'**
  String get noActivityThisWeek;

  /// No description provided for @noActivityThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No activity this month\nAdd debts or make payments to see activity here'**
  String get noActivityThisMonth;

  /// No description provided for @noActivityThisYear.
  ///
  /// In en, this message translates to:
  /// **'No activity this year\nAdd debts or make payments to see activity here'**
  String get noActivityThisYear;

  /// No description provided for @noActivitiesFoundForQuery.
  ///
  /// In en, this message translates to:
  /// **'No activities found for \"{query}\"'**
  String noActivitiesFoundForQuery(String query);

  /// No description provided for @todayAtTime.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAtTime(String time);

  /// No description provided for @yesterdayAtTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {time}'**
  String yesterdayAtTime(String time);

  /// No description provided for @dateAtTime.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String dateAtTime(String date, String time);

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @monitorUserStatistics.
  ///
  /// In en, this message translates to:
  /// **'Monitor your user statistics'**
  String get monitorUserStatistics;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @allRegisteredUsers.
  ///
  /// In en, this message translates to:
  /// **'All registered users'**
  String get allRegisteredUsers;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activeAccess.
  ///
  /// In en, this message translates to:
  /// **'Active access'**
  String get activeAccess;

  /// No description provided for @trial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trial;

  /// No description provided for @onTrialPeriod.
  ///
  /// In en, this message translates to:
  /// **'On trial period'**
  String get onTrialPeriod;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiredAccess.
  ///
  /// In en, this message translates to:
  /// **'Expired access'**
  String get expiredAccess;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @viewManageAllUsers.
  ///
  /// In en, this message translates to:
  /// **'View & manage all users'**
  String get viewManageAllUsers;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @unableToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to Load Dashboard'**
  String get unableToLoadDashboard;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noUsersInSystem.
  ///
  /// In en, this message translates to:
  /// **'No users in the system yet'**
  String get noUsersInSystem;

  /// No description provided for @noUsersYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User statistics will appear here once users start registering.'**
  String get noUsersYetSubtitle;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @searchByEmailOrName.
  ///
  /// In en, this message translates to:
  /// **'Search by email or name...'**
  String get searchByEmailOrName;

  /// No description provided for @monthlyFilter.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyFilter;

  /// No description provided for @yearlyFilter.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearlyFilter;

  /// No description provided for @userSummaryCounts.
  ///
  /// In en, this message translates to:
  /// **'All: {all} • Trial: {trial} • Monthly: {monthly} • Yearly: {yearly} • Expired: {expired}'**
  String userSummaryCounts(
    String all,
    String trial,
    String monthly,
    String yearly,
    String expired,
  );

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @noUsersMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No users match your search'**
  String get noUsersMatchSearch;

  /// No description provided for @noTrialUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No trial users found'**
  String get noTrialUsersFound;

  /// No description provided for @noMonthlyUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No monthly users found'**
  String get noMonthlyUsersFound;

  /// No description provided for @noYearlyUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No yearly users found'**
  String get noYearlyUsersFound;

  /// No description provided for @noExpiredUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No expired users found'**
  String get noExpiredUsersFound;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @noAdminPermissions.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin permissions to view this page.'**
  String get noAdminPermissions;

  /// No description provided for @trialExpired.
  ///
  /// In en, this message translates to:
  /// **'Trial Expired'**
  String get trialExpired;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access user data. Please ensure your account is marked as admin in Firestore.'**
  String get permissionDeniedMessage;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @updateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Update Customer'**
  String get updateCustomer;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerId;

  /// No description provided for @customerIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer ID *'**
  String get customerIdRequired;

  /// No description provided for @enterCustomerId.
  ///
  /// In en, this message translates to:
  /// **'Enter customer ID'**
  String get enterCustomerId;

  /// No description provided for @pleaseEnterCustomerId.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer ID'**
  String get pleaseEnterCustomerId;

  /// No description provided for @customerIdAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Customer ID already exists'**
  String get customerIdAlreadyExists;

  /// No description provided for @customerIdInvalidChars.
  ///
  /// In en, this message translates to:
  /// **'Customer ID can only contain letters, numbers, underscore, and hyphen'**
  String get customerIdInvalidChars;

  /// No description provided for @thisCustomerIdAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This Customer ID already exists'**
  String get thisCustomerIdAlreadyExists;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullName;

  /// No description provided for @enterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get enterCustomerName;

  /// No description provided for @pleaseEnterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get pleaseEnterCustomerName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @validPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number (minimum 8 digits)'**
  String get validPhoneNumber;

  /// No description provided for @thisPhoneNumberAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This phone number already exists'**
  String get thisPhoneNumberAlreadyExists;

  /// No description provided for @duplicatePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Phone Number'**
  String get duplicatePhoneNumber;

  /// No description provided for @duplicatePhoneMessage.
  ///
  /// In en, this message translates to:
  /// **'The phone number \"{phone}\" is already used by customer \"{name}\" (ID: {id}).\n\nDo you want to continue with this phone number?'**
  String duplicatePhoneMessage(String phone, String name, String id);

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmailOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter email (optional)'**
  String get enterEmailOptional;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @validEmailDomain.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email domain'**
  String get validEmailDomain;

  /// No description provided for @thisEmailAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This email is already used by another customer'**
  String get thisEmailAlreadyUsed;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @enterAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter address (optional)'**
  String get enterAddressOptional;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Electronics'**
  String get categoryNameHint;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @chooseCategoryToAddSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category to add a subcategory to:'**
  String get chooseCategoryToAddSubcategory;

  /// No description provided for @subcategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} subcategories'**
  String subcategoriesCount(String count);

  /// No description provided for @addSubcategoryTo.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory to {name}'**
  String addSubcategoryTo(String name);

  /// No description provided for @subcategoryName.
  ///
  /// In en, this message translates to:
  /// **'Subcategory Name'**
  String get subcategoryName;

  /// No description provided for @subcategoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., iPhone'**
  String get subcategoryNameHint;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @productCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get productCost;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// No description provided for @productRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get productRevenue;

  /// No description provided for @productLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get productLoss;

  /// No description provided for @enterCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter cost price'**
  String get enterCostPrice;

  /// No description provided for @enterSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter selling price'**
  String get enterSellingPrice;

  /// No description provided for @exchangeRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate Required'**
  String get exchangeRateRequired;

  /// No description provided for @setExchangeRateInSettings.
  ///
  /// In en, this message translates to:
  /// **'Please set an exchange rate in Currency Settings before adding products with LBP.'**
  String get setExchangeRateInSettings;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @editCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Edit Category Name'**
  String get editCategoryName;

  /// No description provided for @categoryNameExists.
  ///
  /// In en, this message translates to:
  /// **'Category Name Exists'**
  String get categoryNameExists;

  /// No description provided for @addDebtFromProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Debt from Product'**
  String get addDebtFromProduct;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @selectProductAboveToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Select a product above to view details'**
  String get selectProductAboveToViewDetails;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @addProductsToCategoryInProductsTab.
  ///
  /// In en, this message translates to:
  /// **'Add products to this category in the Products tab.'**
  String get addProductsToCategoryInProductsTab;

  /// No description provided for @productPurchases.
  ///
  /// In en, this message translates to:
  /// **'Product Purchases'**
  String get productPurchases;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productsCount(String count);

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Make Payment'**
  String get makePayment;

  /// No description provided for @totalPending.
  ///
  /// In en, this message translates to:
  /// **'Total Pending'**
  String get totalPending;

  /// No description provided for @createdOnDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'Created on {date} at {time}'**
  String createdOnDateAtTime(String date, String time);

  /// No description provided for @timeAm.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get timeAm;

  /// No description provided for @timePm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get timePm;

  /// No description provided for @customerReceipt.
  ///
  /// In en, this message translates to:
  /// **'Customer Receipt'**
  String get customerReceipt;

  /// No description provided for @generatedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on'**
  String get generatedOn;

  /// No description provided for @accountSummary.
  ///
  /// In en, this message translates to:
  /// **'Account Summary'**
  String get accountSummary;

  /// No description provided for @totalOriginal.
  ///
  /// In en, this message translates to:
  /// **'Total Original'**
  String get totalOriginal;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @generatedBy.
  ///
  /// In en, this message translates to:
  /// **'Generated by'**
  String get generatedBy;

  /// No description provided for @receiptFor.
  ///
  /// In en, this message translates to:
  /// **'Receipt for'**
  String get receiptFor;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(String current, String total);

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @partialPayment.
  ///
  /// In en, this message translates to:
  /// **'Partial Payment'**
  String get partialPayment;

  /// No description provided for @outstandingDebt.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Debt'**
  String get outstandingDebt;

  /// No description provided for @newDebt.
  ///
  /// In en, this message translates to:
  /// **'New Debt'**
  String get newDebt;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @debtPaid.
  ///
  /// In en, this message translates to:
  /// **'Debt Paid'**
  String get debtPaid;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @deleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Delete Debt'**
  String get deleteDebt;

  /// No description provided for @deleteDebtConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this debt?'**
  String get deleteDebtConfirm;

  /// No description provided for @debtDetails.
  ///
  /// In en, this message translates to:
  /// **'Debt Details:'**
  String get debtDetails;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount:'**
  String get amountLabel;

  /// No description provided for @deleteDebtCannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteDebtCannotUndo;

  /// No description provided for @monthlyActivityReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Activity Report'**
  String get monthlyActivityReport;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportSummary;

  /// No description provided for @transactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsLabel;

  /// No description provided for @activityDetails.
  ///
  /// In en, this message translates to:
  /// **'Activity Details'**
  String get activityDetails;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// No description provided for @loadingUserDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading user details…'**
  String get loadingUserDetails;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get grantAccess;

  /// No description provided for @grantAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Grant continued access to this user. Choose duration.'**
  String get grantAccessDescription;

  /// No description provided for @oneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get oneMonth;

  /// No description provided for @oneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get oneYear;

  /// No description provided for @revokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Revoke Access'**
  String get revokeAccess;

  /// No description provided for @revokeAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Temporarily suspend this account. The user can contact you if there is an issue.'**
  String get revokeAccessDescription;

  /// No description provided for @revokeAccessConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to revoke this user\'s access?'**
  String get revokeAccessConfirm;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @accessGrantedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Access granted successfully ({duration})!'**
  String accessGrantedSuccess(String duration);

  /// No description provided for @failedToGrantAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to grant access: {error}'**
  String failedToGrantAccess(String error);

  /// No description provided for @accessRevokedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Access revoked successfully!'**
  String get accessRevokedSuccess;

  /// No description provided for @failedToRevokeAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke access: {error}'**
  String failedToRevokeAccess(String error);

  /// No description provided for @noAccessData.
  ///
  /// In en, this message translates to:
  /// **'No access data'**
  String get noAccessData;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @trialStarted.
  ///
  /// In en, this message translates to:
  /// **'Trial Started'**
  String get trialStarted;

  /// No description provided for @trialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial Ends'**
  String get trialEnds;

  /// No description provided for @accessStarted.
  ///
  /// In en, this message translates to:
  /// **'Access Started'**
  String get accessStarted;

  /// No description provided for @accessEnds.
  ///
  /// In en, this message translates to:
  /// **'Access Ends'**
  String get accessEnds;

  /// No description provided for @accessPeriod.
  ///
  /// In en, this message translates to:
  /// **'Access Period'**
  String get accessPeriod;

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedDate(String date);

  /// No description provided for @dateExpired.
  ///
  /// In en, this message translates to:
  /// **'(Expired)'**
  String get dateExpired;

  /// No description provided for @dateDaysLeftOne.
  ///
  /// In en, this message translates to:
  /// **'(1 day left)'**
  String get dateDaysLeftOne;

  /// No description provided for @dateDaysLeftOther.
  ///
  /// In en, this message translates to:
  /// **'({count} days left)'**
  String dateDaysLeftOther(String count);

  /// No description provided for @oneMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get oneMonthLabel;

  /// No description provided for @oneYearLabel.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get oneYearLabel;

  /// No description provided for @requestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request Access'**
  String get requestAccess;

  /// No description provided for @freeTrial.
  ///
  /// In en, this message translates to:
  /// **'Free Trial'**
  String get freeTrial;

  /// No description provided for @accessExpired.
  ///
  /// In en, this message translates to:
  /// **'Access Expired'**
  String get accessExpired;

  /// No description provided for @accessCancelled.
  ///
  /// In en, this message translates to:
  /// **'Access Cancelled'**
  String get accessCancelled;

  /// No description provided for @trialDetails.
  ///
  /// In en, this message translates to:
  /// **'Trial details'**
  String get trialDetails;

  /// No description provided for @trialPeriod.
  ///
  /// In en, this message translates to:
  /// **'Trial period'**
  String get trialPeriod;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} days remaining'**
  String daysRemaining(String count);

  /// No description provided for @accessDetails.
  ///
  /// In en, this message translates to:
  /// **'Access details'**
  String get accessDetails;

  /// No description provided for @yourAccessExpired.
  ///
  /// In en, this message translates to:
  /// **'Your access has expired'**
  String get yourAccessExpired;

  /// No description provided for @yourAccessCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your access has been cancelled'**
  String get yourAccessCancelled;

  /// No description provided for @expiredContactMessage.
  ///
  /// In en, this message translates to:
  /// **'If you believe this is a mistake or need help with your account, contact the administrator for support.'**
  String get expiredContactMessage;

  /// No description provided for @contactAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Contact Administrator'**
  String get contactAdministrator;

  /// No description provided for @accessStatusAndRenewals.
  ///
  /// In en, this message translates to:
  /// **'Access status and renewals'**
  String get accessStatusAndRenewals;

  /// No description provided for @requestAccessInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'If your trial or access period ends and you still cannot use the app, you can contact the administrator for help fixing your account.'**
  String get requestAccessInfoMessage;

  /// No description provided for @welcomeToBechaalany.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bechaalany Debt App'**
  String get welcomeToBechaalany;

  /// No description provided for @welcomeNoDataMessage.
  ///
  /// In en, this message translates to:
  /// **'The app is completely free and available to all signed-in users. If you ever have trouble accessing your data, you can contact the administrator for technical support.'**
  String get welcomeNoDataMessage;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
