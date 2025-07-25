import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  Map<String, String> _localizedStrings = {};
  
  Future<bool> load() async {
    try {
      if (locale.languageCode == 'ar') {
        _localizedStrings = _arabicStrings;
      } else {
        _localizedStrings = _englishStrings;
      }
      return true;
    } catch (e) {
      print('Error loading localization: $e');
      return false;
    }
  }
  
  static const Map<String, String> _englishStrings = {
    'appTitle': 'Bechaalany Debt',
    'settings': 'Settings',
    'customers': 'Customers',
    'debts': 'Debts',
    'home': 'Home',
    'addCustomer': 'Add Customer',
    'addDebt': 'Add Debt',
    'editCustomer': 'Edit Customer',
    'editDebt': 'Edit Debt',
    'deleteCustomer': 'Delete Customer',
    'deleteDebt': 'Delete Debt',
    'markAsPaid': 'Mark as Paid',
    'viewDetails': 'View Details',
    'edit': 'Edit',
    'delete': 'Delete',
    'cancel': 'Cancel',
    'save': 'Save',
    'confirm': 'Confirm',
    'ok': 'OK',
    'done': 'Done',
    'back': 'Back',
    'next': 'Next',
    'search': 'Search',
    'clear': 'Clear',
    'noData': 'No data found',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'warning': 'Warning',
    'info': 'Information',
    'customerName': 'Customer Name',
    'customerPhone': 'Phone Number',
    'customerEmail': 'Email',
    'customerId': 'Customer ID',
    'customerAddress': 'Address',
    'customerNotes': 'Notes',
    'debtAmount': 'Amount',
    'debtDescription': 'Description',
    'debtDueDate': 'Due Date',
    'debtType': 'Type',
    'debtStatus': 'Status',
    'debtCustomer': 'Customer',
    'debtCreatedAt': 'Created At',
    'debtPaidAt': 'Paid At',
    'totalDebt': 'Total Debt',
    'totalPaid': 'Total Paid',
    'pendingDebts': 'Pending Debts',
    'overdueDebts': 'Overdue Debts',
    'totalCustomers': 'Total Customers',
    'averageDebtAmount': 'Average Debt Amount',
    'securityAndAuthentication': 'Security & Authentication',
    'faceIdTouchId': 'Face ID / Touch ID',
    'useBiometricAuthentication': 'Use biometric authentication',
    'appLockTimeout': 'App Lock Timeout',
    'pinCodeProtection': 'PIN Code Protection',
    'setAppAccessPin': 'Set app access PIN',
    'appPreferences': 'App Preferences',
    'darkMode': 'Dark Mode',
    'useDarkAppearance': 'Use dark appearance',
    'autoSync': 'Auto Sync',
    'syncDataAutomatically': 'Sync data automatically',
    'language': 'Language',
    'notifications': 'Notifications',
    'receiveAppNotifications': 'Receive app notifications',
    'paymentDueReminders': 'Payment Due Reminders',
    'remindBeforePaymentsDue': 'Remind before payments due',
    'overdueNotifications': 'Overdue Notifications',
    'notifyAboutOverduePayments': 'Notify about overdue payments',
    'weeklyReports': 'Weekly Reports',
    'receiveWeeklySummaries': 'Receive weekly summaries',
    'monthlyReports': 'Monthly Reports',
    'receiveMonthlySummaries': 'Receive monthly summaries',
    'quietHours': 'Quiet Hours',
    'silenceNotifications': 'Silence notifications',
    'notificationPriority': 'Notification Priority',
    'quietHoursTime': 'Quiet Hours Time',
    'notificationSettings': 'Notification Settings',
    'customizeNotifications': 'Customize notifications',
    'dataAndStorage': 'Data & Storage',
    'iCloudSync': 'iCloud Sync',
    'syncDataToICloud': 'Sync data to iCloud',
    'autoBackupFrequency': 'Auto Backup Frequency',
    'storageUsage': 'Storage Usage',
    'exportFormat': 'Export Format',
    'exportType': 'Export Type',
    'exportData': 'Export Data',
    'importData': 'Import Data',
    'backupData': 'Backup Data',
    'clearAllData': 'Clear All Data',
    'deleteAllData': 'Delete all data',
    'syncAndIntegration': 'Sync & Integration',
    'multiDeviceSync': 'Multi-Device Sync',
    'syncAcrossDevices': 'Sync across devices',
    'offlineMode': 'Offline Mode',
    'workWithoutInternet': 'Work without internet',
    'calendarIntegration': 'Calendar Integration',
    'syncWithCalendar': 'Sync with calendar',
    'conflictResolution': 'Conflict Resolution',
    'handleSyncConflicts': 'Handle sync conflicts',
    'dataManagement': 'Data Management',
    'dataValidation': 'Data Validation',
    'validateInputData': 'Validate input data',
    'duplicateDetection': 'Duplicate Detection',
    'detectDuplicateEntries': 'Detect duplicate entries',
    'auditTrail': 'Audit Trail',
    'trackDataChanges': 'Track data changes',
    'customReports': 'Custom Reports',
    'enableCustomReporting': 'Enable custom reporting',
    'accessibilityAndPlatform': 'Accessibility & Platform',
    'ipadOptimizations': 'iPad Optimizations',
    'enhancedIpadInterface': 'Enhanced iPad interface',
    'largeTextSupport': 'Large Text Support',
    'systemLargeText': 'System large text',
    'reduceMotion': 'Reduce Motion',
    'respectMotionPreferences': 'Respect motion preferences',
    'supportAndAbout': 'Support & About',
    'helpAndSupport': 'Help & Support',
    'getHelp': 'Get help',
    'contactUs': 'Contact Us',
    'sendFeedback': 'Send feedback',
    'licenses': 'Licenses',
    'openSourceLicenses': 'Open source licenses',
    'comingSoon': 'Coming Soon',
    'featureWillBeAvailable': 'This feature will be available in a future update.',
    'thisActionCannotBeUndone': 'This action cannot be undone.',
    'areYouSure': 'Are you sure?',
    'operationCompleted': 'Operation completed successfully',
    'operationFailed': 'Operation failed',
    'selectLanguage': 'Select Language',
    'selectAction': 'Select an action',
    'optional': 'Optional',
    'pleaseEnterName': 'Please enter a name',
    'pleaseEnterPhone': 'Please enter a phone number',
    'pleaseEnterValidEmail': 'Please enter a valid email address',
    'pleaseEnterCustomerId': 'Please enter a customer ID',
    'customerIdHelper': 'Enter a unique customer ID',
    'english': 'English',
    'arabic': 'Arabic',
    'high': 'High',
    'normal': 'Normal',
    'low': 'Low',
    'daily': 'Daily',
    'weekly': 'Weekly',
    'monthly': 'Monthly',
    'csv': 'CSV',
    'pdf': 'PDF',
    'excel': 'Excel',
    'json': 'JSON',
    'allData': 'All Data',
    'customersOnly': 'Customers Only',
    'debtsOnly': 'Debts Only',
    'oneMinute': '1 minute',
    'fiveMinutes': '5 minutes',
    'fifteenMinutes': '15 minutes',
    'thirtyMinutes': '30 minutes',
    'oneHour': '1 hour',
    'never': 'Never',
    'setPinCode': 'Set PIN Code',
    'enterPinCode': 'Enter a 4-digit PIN code to protect your app.',
    'enterPin': 'Enter PIN',
    'enterFourDigitPin': 'Enter a 4-digit PIN:',
    'pinCodeSet': 'PIN code set successfully',
    'pinProtectionDisabled': 'PIN protection disabled',
    'disablePin': 'Disable PIN',
    'areYouSureDisablePin': 'Are you sure you want to disable PIN protection?',
    'configureQuietHours': 'Configure quiet hours to silence notifications during specific times.',
    'setQuietHours': 'Set Quiet Hours',
    'to': 'to',
    'storageDetails': 'Storage Details',
    'backups': 'Backups',
    'total': 'Total',
    'items': 'items',
    'files': 'files',
    'exportingData': 'Exporting {type} to {format}...',
    'exportCompleted': 'Export completed successfully',
    'importingData': 'Importing data...',
    'importCompleted': 'Import completed successfully',
    'creatingBackup': 'Creating backup...',
    'backupCreated': 'Backup created successfully',
    'noSyncConflicts': 'No sync conflicts found. All data is up to date.',
    'featureEnabled': '{feature} enabled',
    'featureDisabled': '{feature} disabled',
    'needHelp': 'Need help? Contact our support team or check our documentation.',
    'contactSupport': 'Contact Support',
    'sendUsFeedback': 'Send us feedback or report issues.',
    'openingEmailClient': 'Opening email client...',
    'sendEmail': 'Send Email',
    'openSourceLicensesInfo': 'This app uses the following open source libraries:\n\n• Flutter\n• Cupertino Icons\n• Shared Preferences\n\nAll licenses are available at our GitHub repository.',
    'customerDeleted': 'Customer deleted successfully',
    'failedToDeleteCustomer': 'Failed to delete customer: {error}',
    'debtMarkedAsPaid': 'Debt marked as paid successfully',
    'failedToMarkAsPaid': 'Failed to mark debt as paid: {error}',
    'debtDeleted': 'Debt deleted successfully',
    'failedToDeleteDebt': 'Failed to delete debt: {error}',
    'allDataCleared': 'All data cleared successfully',
    'failedToClearData': 'Failed to clear data: {error}',
    'thisCustomerHasDebts': 'This customer has {count} debt(s). Deleting the customer will also delete all associated debts. Are you sure?',
    'areYouSureDeleteCustomer': 'Are you sure you want to delete this customer?',
    'areYouSureMarkAsPaid': 'Are you sure you want to mark this debt as paid?\n\nCustomer: {customerName}\nAmount: \${amount}',
    'areYouSureDeleteDebt': 'Are you sure you want to delete this debt?',
    'thisActionWillPermanentlyDelete': 'This action will permanently delete all customers and debts. This action cannot be undone. Are you sure you want to continue?',
    'searchByNamePhoneIdEmail': 'Search by name, phone, ID, or email...',
    'searchByNameDescription': 'Search by name or description...',
    'noCustomersFound': 'No customers found',
    'addNewCustomerToGetStarted': 'Add a new customer to get started',
    'noDebtsFound': 'No debts found',
    'addNewDebtToGetStarted': 'Add a new debt to get started',
    'all': 'All',
    'pending': 'Pending',
    'paid': 'Paid',
    'overdue': 'Overdue',
    'personal': 'Personal',
    'business': 'Business',
    'loan': 'Loan',
    'credit': 'Credit',
    'other': 'Other',
  };
  
  static const Map<String, String> _arabicStrings = {
    'appTitle': 'تطبيق بچعلاني للديون',
    'settings': 'الإعدادات',
    'customers': 'العملاء',
    'debts': 'الديون',
    'home': 'الرئيسية',
    'addCustomer': 'إضافة عميل',
    'addDebt': 'إضافة دين',
    'editCustomer': 'تعديل العميل',
    'editDebt': 'تعديل الدين',
    'deleteCustomer': 'حذف العميل',
    'deleteDebt': 'حذف الدين',
    'markAsPaid': 'تحديد كمدفوع',
    'viewDetails': 'عرض التفاصيل',
    'edit': 'تعديل',
    'delete': 'حذف',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'confirm': 'تأكيد',
    'ok': 'موافق',
    'done': 'تم',
    'back': 'رجوع',
    'next': 'التالي',
    'search': 'بحث',
    'clear': 'مسح',
    'noData': 'لا توجد بيانات',
    'loading': 'جاري التحميل...',
    'error': 'خطأ',
    'success': 'نجح',
    'warning': 'تحذير',
    'info': 'معلومات',
    'customerName': 'اسم العميل',
    'customerPhone': 'رقم الهاتف',
    'customerEmail': 'البريد الإلكتروني',
    'customerId': 'معرف العميل',
    'customerAddress': 'العنوان',
    'customerNotes': 'ملاحظات',
    'debtAmount': 'المبلغ',
    'debtDescription': 'الوصف',
    'debtDueDate': 'تاريخ الاستحقاق',
    'debtType': 'النوع',
    'debtStatus': 'الحالة',
    'debtCustomer': 'العميل',
    'debtCreatedAt': 'تاريخ الإنشاء',
    'debtPaidAt': 'تاريخ الدفع',
    'totalDebt': 'إجمالي الديون',
    'totalPaid': 'إجمالي المدفوع',
    'pendingDebts': 'الديون المعلقة',
    'overdueDebts': 'الديون المتأخرة',
    'totalCustomers': 'إجمالي العملاء',
    'averageDebtAmount': 'متوسط مبلغ الدين',
    'securityAndAuthentication': 'الأمان والمصادقة',
    'faceIdTouchId': 'Face ID / Touch ID',
    'useBiometricAuthentication': 'استخدام المصادقة البيومترية',
    'appLockTimeout': 'مهلة قفل التطبيق',
    'pinCodeProtection': 'حماية رمز PIN',
    'setAppAccessPin': 'تعيين رمز PIN للوصول للتطبيق',
    'appPreferences': 'تفضيلات التطبيق',
    'darkMode': 'الوضع المظلم',
    'useDarkAppearance': 'استخدام المظهر المظلم',
    'autoSync': 'المزامنة التلقائية',
    'syncDataAutomatically': 'مزامنة البيانات تلقائياً',
    'language': 'اللغة',
    'notifications': 'الإشعارات',
    'receiveAppNotifications': 'استلام إشعارات التطبيق',
    'paymentDueReminders': 'تذكيرات استحقاق الدفع',
    'remindBeforePaymentsDue': 'تذكير قبل استحقاق المدفوعات',
    'overdueNotifications': 'إشعارات التأخير',
    'notifyAboutOverduePayments': 'إشعار بالمدفوعات المتأخرة',
    'weeklyReports': 'التقارير الأسبوعية',
    'receiveWeeklySummaries': 'استلام ملخصات أسبوعية',
    'monthlyReports': 'التقارير الشهرية',
    'receiveMonthlySummaries': 'استلام ملخصات شهرية',
    'quietHours': 'ساعات الهدوء',
    'silenceNotifications': 'كتم الإشعارات',
    'notificationPriority': 'أولوية الإشعارات',
    'quietHoursTime': 'وقت ساعات الهدوء',
    'notificationSettings': 'إعدادات الإشعارات',
    'customizeNotifications': 'تخصيص الإشعارات',
    'dataAndStorage': 'البيانات والتخزين',
    'iCloudSync': 'مزامنة iCloud',
    'syncDataToICloud': 'مزامنة البيانات إلى iCloud',
    'autoBackupFrequency': 'تكرار النسخ الاحتياطي التلقائي',
    'storageUsage': 'استخدام التخزين',
    'exportFormat': 'تنسيق التصدير',
    'exportType': 'نوع التصدير',
    'exportData': 'تصدير البيانات',
    'importData': 'استيراد البيانات',
    'backupData': 'نسخ احتياطي للبيانات',
    'clearAllData': 'مسح جميع البيانات',
    'deleteAllData': 'حذف جميع البيانات',
    'syncAndIntegration': 'المزامنة والتكامل',
    'multiDeviceSync': 'مزامنة متعددة الأجهزة',
    'syncAcrossDevices': 'مزامنة عبر الأجهزة',
    'offlineMode': 'الوضع غير المتصل',
    'workWithoutInternet': 'العمل بدون إنترنت',
    'calendarIntegration': 'تكامل التقويم',
    'syncWithCalendar': 'مزامنة مع التقويم',
    'conflictResolution': 'حل التعارضات',
    'handleSyncConflicts': 'معالجة تعارضات المزامنة',
    'dataManagement': 'إدارة البيانات',
    'dataValidation': 'التحقق من صحة البيانات',
    'validateInputData': 'التحقق من صحة بيانات الإدخال',
    'duplicateDetection': 'كشف التكرار',
    'detectDuplicateEntries': 'كشف المدخلات المكررة',
    'auditTrail': 'مسار التدقيق',
    'trackDataChanges': 'تتبع تغييرات البيانات',
    'customReports': 'التقارير المخصصة',
    'enableCustomReporting': 'تمكين التقارير المخصصة',
    'accessibilityAndPlatform': 'إمكانية الوصول والمنصة',
    'ipadOptimizations': 'تحسينات iPad',
    'enhancedIpadInterface': 'واجهة iPad محسنة',
    'largeTextSupport': 'دعم النص الكبير',
    'systemLargeText': 'النص الكبير للنظام',
    'reduceMotion': 'تقليل الحركة',
    'respectMotionPreferences': 'احترام تفضيلات الحركة',
    'supportAndAbout': 'الدعم وحول',
    'helpAndSupport': 'المساعدة والدعم',
    'getHelp': 'احصل على مساعدة',
    'contactUs': 'اتصل بنا',
    'sendFeedback': 'إرسال ملاحظات',
    'licenses': 'التراخيص',
    'openSourceLicenses': 'تراخيص المصدر المفتوح',
    'comingSoon': 'قريباً',
    'featureWillBeAvailable': 'ستكون هذه الميزة متاحة في تحديث مستقبلي.',
    'thisActionCannotBeUndone': 'لا يمكن التراجع عن هذا الإجراء.',
    'areYouSure': 'هل أنت متأكد؟',
    'operationCompleted': 'تم إكمال العملية بنجاح',
    'operationFailed': 'فشلت العملية',
    'selectLanguage': 'اختر اللغة',
    'selectAction': 'اختر إجراء',
    'optional': 'اختياري',
    'pleaseEnterName': 'يرجى إدخال اسم',
    'pleaseEnterPhone': 'يرجى إدخال رقم هاتف',
    'pleaseEnterValidEmail': 'يرجى إدخال عنوان بريد إلكتروني صحيح',
    'pleaseEnterCustomerId': 'يرجى إدخال معرف العميل',
    'customerIdHelper': 'أدخل معرف عميل فريد',
    'english': 'الإنجليزية',
    'arabic': 'العربية',
    'high': 'عالية',
    'normal': 'عادية',
    'low': 'منخفضة',
    'daily': 'يومي',
    'weekly': 'أسبوعي',
    'monthly': 'شهري',
    'csv': 'CSV',
    'pdf': 'PDF',
    'excel': 'Excel',
    'json': 'JSON',
    'allData': 'جميع البيانات',
    'customersOnly': 'العملاء فقط',
    'debtsOnly': 'الديون فقط',
    'oneMinute': 'دقيقة واحدة',
    'fiveMinutes': '5 دقائق',
    'fifteenMinutes': '15 دقيقة',
    'thirtyMinutes': '30 دقيقة',
    'oneHour': 'ساعة واحدة',
    'never': 'أبداً',
    'setPinCode': 'تعيين رمز PIN',
    'enterPinCode': 'أدخل رمز PIN مكون من 4 أرقام لحماية تطبيقك.',
    'enterPin': 'أدخل رمز PIN',
    'enterFourDigitPin': 'أدخل رمز PIN مكون من 4 أرقام:',
    'pinCodeSet': 'تم تعيين رمز PIN بنجاح',
    'pinProtectionDisabled': 'تم تعطيل حماية رمز PIN',
    'disablePin': 'تعطيل رمز PIN',
    'areYouSureDisablePin': 'هل أنت متأكد من أنك تريد تعطيل حماية رمز PIN؟',
    'configureQuietHours': 'قم بتكوين ساعات الهدوء لكتم الإشعارات خلال أوقات محددة.',
    'setQuietHours': 'تعيين ساعات الهدوء',
    'to': 'إلى',
    'storageDetails': 'تفاصيل التخزين',
    'backups': 'النسخ الاحتياطية',
    'total': 'الإجمالي',
    'items': 'عناصر',
    'files': 'ملفات',
    'exportingData': 'جاري تصدير {type} إلى {format}...',
    'exportCompleted': 'تم إكمال التصدير بنجاح',
    'importingData': 'جاري استيراد البيانات...',
    'importCompleted': 'تم إكمال الاستيراد بنجاح',
    'creatingBackup': 'جاري إنشاء نسخة احتياطية...',
    'backupCreated': 'تم إنشاء النسخة الاحتياطية بنجاح',
    'noSyncConflicts': 'لم يتم العثور على تعارضات في المزامنة. جميع البيانات محدثة.',
    'featureEnabled': 'تم تمكين {feature}',
    'featureDisabled': 'تم تعطيل {feature}',
    'needHelp': 'تحتاج مساعدة؟ اتصل بفريق الدعم أو تحقق من وثائقنا.',
    'contactSupport': 'اتصل بالدعم',
    'sendUsFeedback': 'أرسل لنا ملاحظات أو أبلغ عن مشاكل.',
    'openingEmailClient': 'جاري فتح عميل البريد الإلكتروني...',
    'sendEmail': 'إرسال بريد إلكتروني',
    'openSourceLicensesInfo': 'يستخدم هذا التطبيق المكتبات مفتوحة المصدر التالية:\n\n• Flutter\n• Cupertino Icons\n• Shared Preferences\n\nجميع التراخيص متاحة في مستودع GitHub الخاص بنا.',
    'customerDeleted': 'تم حذف العميل بنجاح',
    'failedToDeleteCustomer': 'فشل في حذف العميل: {error}',
    'debtMarkedAsPaid': 'تم تحديد الدين كمدفوع بنجاح',
    'failedToMarkAsPaid': 'فشل في تحديد الدين كمدفوع: {error}',
    'debtDeleted': 'تم حذف الدين بنجاح',
    'failedToDeleteDebt': 'فشل في حذف الدين: {error}',
    'allDataCleared': 'تم مسح جميع البيانات بنجاح',
    'failedToClearData': 'فشل في مسح البيانات: {error}',
    'thisCustomerHasDebts': 'هذا العميل لديه {count} دين(ديون). حذف العميل سيؤدي أيضاً إلى حذف جميع الديون المرتبطة. هل أنت متأكد؟',
    'areYouSureDeleteCustomer': 'هل أنت متأكد من أنك تريد حذف هذا العميل؟',
    'areYouSureMarkAsPaid': 'هل أنت متأكد من أنك تريد تحديد هذا الدين كمدفوع؟\n\nالعميل: {customerName}\nالمبلغ: {amount} د.ك',
    'areYouSureDeleteDebt': 'هل أنت متأكد من أنك تريد حذف هذا الدين؟',
    'thisActionWillPermanentlyDelete': 'سيؤدي هذا الإجراء إلى حذف جميع العملاء والديون نهائياً. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد من أنك تريد المتابعة؟',
    'searchByNamePhoneIdEmail': 'البحث بالاسم أو الهاتف أو المعرف أو البريد الإلكتروني...',
    'searchByNameDescription': 'البحث بالاسم أو الوصف...',
    'noCustomersFound': 'لم يتم العثور على عملاء',
    'addNewCustomerToGetStarted': 'أضف عميلاً جديداً للبدء',
    'noDebtsFound': 'لم يتم العثور على ديون',
    'addNewDebtToGetStarted': 'أضف ديناً جديداً للبدء',
    'all': 'الكل',
    'pending': 'معلق',
    'paid': 'مدفوع',
    'overdue': 'متأخر',
    'personal': 'شخصي',
    'business': 'تجاري',
    'loan': 'قرض',
    'credit': 'ائتمان',
    'other': 'آخر',
  };
  
  String translate(String key, [Map<String, String>? args]) {
    String value = _localizedStrings[key] ?? key;
    
    if (args != null) {
      args.forEach((argKey, argValue) {
        value = value.replaceAll('{$argKey}', argValue);
      });
    }
    
    return value;
  }
  
  // Convenience methods for common translations
  String get appTitle => translate('appTitle');
  String get settings => translate('settings');
  String get customers => translate('customers');
  String get debts => translate('debts');
  String get home => translate('home');
  String get addCustomer => translate('addCustomer');
  String get addDebt => translate('addDebt');
  String get editCustomer => translate('editCustomer');
  String get editDebt => translate('editDebt');
  String get deleteCustomer => translate('deleteCustomer');
  String get deleteDebt => translate('deleteDebt');
  String get markAsPaid => translate('markAsPaid');
  String get viewDetails => translate('viewDetails');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get confirm => translate('confirm');
  String get ok => translate('ok');
  String get done => translate('done');
  String get back => translate('back');
  String get next => translate('next');
  String get search => translate('search');
  String get clear => translate('clear');
  String get noData => translate('noData');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get info => translate('info');
  
  // Customer related
  String get customerName => translate('customerName');
  String get customerPhone => translate('customerPhone');
  String get customerEmail => translate('customerEmail');
  String get customerId => translate('customerId');
  String get customerAddress => translate('customerAddress');
  String get customerNotes => translate('customerNotes');
  
  // Debt related
  String get debtAmount => translate('debtAmount');
  String get debtDescription => translate('debtDescription');
  String get debtDueDate => translate('debtDueDate');
  String get debtType => translate('debtType');
  String get debtStatus => translate('debtStatus');
  String get debtCustomer => translate('debtCustomer');
  String get debtCreatedAt => translate('debtCreatedAt');
  String get debtPaidAt => translate('debtPaidAt');
  
  // Statistics
  String get totalDebt => translate('totalDebt');
  String get totalPaid => translate('totalPaid');
  String get pendingDebts => translate('pendingDebts');
  String get overdueDebts => translate('overdueDebts');
  String get totalCustomers => translate('totalCustomers');
  String get averageDebtAmount => translate('averageDebtAmount');
  
  // Settings
  String get securityAndAuthentication => translate('securityAndAuthentication');
  String get faceIdTouchId => translate('faceIdTouchId');
  String get useBiometricAuthentication => translate('useBiometricAuthentication');
  String get appLockTimeout => translate('appLockTimeout');
  String get pinCodeProtection => translate('pinCodeProtection');
  String get setAppAccessPin => translate('setAppAccessPin');
  
  String get appPreferences => translate('appPreferences');
  String get darkMode => translate('darkMode');
  String get useDarkAppearance => translate('useDarkAppearance');
  String get autoSync => translate('autoSync');
  String get syncDataAutomatically => translate('syncDataAutomatically');
  String get language => translate('language');
  
  String get notifications => translate('notifications');
  String get receiveAppNotifications => translate('receiveAppNotifications');
  String get paymentDueReminders => translate('paymentDueReminders');
  String get remindBeforePaymentsDue => translate('remindBeforePaymentsDue');
  String get overdueNotifications => translate('overdueNotifications');
  String get notifyAboutOverduePayments => translate('notifyAboutOverduePayments');
  String get weeklyReports => translate('weeklyReports');
  String get receiveWeeklySummaries => translate('receiveWeeklySummaries');
  String get monthlyReports => translate('monthlyReports');
  String get receiveMonthlySummaries => translate('receiveMonthlySummaries');
  String get quietHours => translate('quietHours');
  String get silenceNotifications => translate('silenceNotifications');
  String get notificationPriority => translate('notificationPriority');
  String get quietHoursTime => translate('quietHoursTime');
  String get notificationSettings => translate('notificationSettings');
  String get customizeNotifications => translate('customizeNotifications');
  
  String get dataAndStorage => translate('dataAndStorage');
  String get iCloudSync => translate('iCloudSync');
  String get syncDataToICloud => translate('syncDataToICloud');
  String get autoBackupFrequency => translate('autoBackupFrequency');
  String get storageUsage => translate('storageUsage');
  String get exportFormat => translate('exportFormat');
  String get exportType => translate('exportType');
  String get exportData => translate('exportData');
  String get importData => translate('importData');
  String get backupData => translate('backupData');
  String get clearAllData => translate('clearAllData');
  String get deleteAllData => translate('deleteAllData');
  
  String get syncAndIntegration => translate('syncAndIntegration');
  String get multiDeviceSync => translate('multiDeviceSync');
  String get syncAcrossDevices => translate('syncAcrossDevices');
  String get offlineMode => translate('offlineMode');
  String get workWithoutInternet => translate('workWithoutInternet');
  String get calendarIntegration => translate('calendarIntegration');
  String get syncWithCalendar => translate('syncWithCalendar');
  String get conflictResolution => translate('conflictResolution');
  String get handleSyncConflicts => translate('handleSyncConflicts');
  
  String get dataManagement => translate('dataManagement');
  String get dataValidation => translate('dataValidation');
  String get validateInputData => translate('validateInputData');
  String get duplicateDetection => translate('duplicateDetection');
  String get detectDuplicateEntries => translate('detectDuplicateEntries');
  String get auditTrail => translate('auditTrail');
  String get trackDataChanges => translate('trackDataChanges');
  String get customReports => translate('customReports');
  String get enableCustomReporting => translate('enableCustomReporting');
  
  String get accessibilityAndPlatform => translate('accessibilityAndPlatform');
  String get ipadOptimizations => translate('ipadOptimizations');
  String get enhancedIpadInterface => translate('enhancedIpadInterface');
  String get largeTextSupport => translate('largeTextSupport');
  String get systemLargeText => translate('systemLargeText');
  String get reduceMotion => translate('reduceMotion');
  String get respectMotionPreferences => translate('respectMotionPreferences');
  
  String get supportAndAbout => translate('supportAndAbout');
  String get helpAndSupport => translate('helpAndSupport');
  String get getHelp => translate('getHelp');
  String get contactUs => translate('contactUs');
  String get sendFeedback => translate('sendFeedback');
  String get licenses => translate('licenses');
  String get openSourceLicenses => translate('openSourceLicenses');
  
  // Messages
  String get comingSoon => translate('comingSoon');
  String get featureWillBeAvailable => translate('featureWillBeAvailable');
  String get thisActionCannotBeUndone => translate('thisActionCannotBeUndone');
  String get areYouSure => translate('areYouSure');
  String get operationCompleted => translate('operationCompleted');
  String get operationFailed => translate('operationFailed');
  
  // Languages
  String get selectLanguage => translate('selectLanguage');
  String get selectAction => translate('selectAction');
  String get optional => translate('optional');
  String get pleaseEnterName => translate('pleaseEnterName');
  String get pleaseEnterPhone => translate('pleaseEnterPhone');
  String get pleaseEnterValidEmail => translate('pleaseEnterValidEmail');
  String get pleaseEnterCustomerId => translate('pleaseEnterCustomerId');
  String get customerIdHelper => translate('customerIdHelper');
  String get english => translate('english');
  String get arabic => translate('arabic');
  
  // Priorities
  String get high => translate('high');
  String get normal => translate('normal');
  String get low => translate('low');
  
  // Frequencies
  String get daily => translate('daily');
  String get weekly => translate('weekly');
  String get monthly => translate('monthly');
  
  // Formats
  String get csv => translate('csv');
  String get pdf => translate('pdf');
  String get excel => translate('excel');
  String get json => translate('json');
  
  // Types
  String get allData => translate('allData');
  String get customersOnly => translate('customersOnly');
  String get debtsOnly => translate('debtsOnly');
  
  // Timeouts
  String get oneMinute => translate('oneMinute');
  String get fiveMinutes => translate('fiveMinutes');
  String get fifteenMinutes => translate('fifteenMinutes');
  String get thirtyMinutes => translate('thirtyMinutes');
  String get oneHour => translate('oneHour');
  String get never => translate('never');
  
  // PIN related
  String get setPinCode => translate('setPinCode');
  String get enterPinCode => translate('enterPinCode');
  String get enterPin => translate('enterPin');
  String get enterFourDigitPin => translate('enterFourDigitPin');
  String get pinCodeSet => translate('pinCodeSet');
  String get pinProtectionDisabled => translate('pinProtectionDisabled');
  String get disablePin => translate('disablePin');
  String get areYouSureDisablePin => translate('areYouSureDisablePin');
  
  // Quiet hours
  String get configureQuietHours => translate('configureQuietHours');
  String get setQuietHours => translate('setQuietHours');
  String get to => translate('to');
  
  // Storage
  String get storageDetails => translate('storageDetails');
  String get backups => translate('backups');
  String get total => translate('total');
  String get items => translate('items');
  String get files => translate('files');
  
  // Operations
  String exportingData(String type, String format) => translate('exportingData', {'type': type, 'format': format});
  String get exportCompleted => translate('exportCompleted');
  String get importingData => translate('importingData');
  String get importCompleted => translate('importCompleted');
  String get creatingBackup => translate('creatingBackup');
  String get backupCreated => translate('backupCreated');
  String get noSyncConflicts => translate('noSyncConflicts');
  
  // Features
  String featureEnabled(String feature) => translate('featureEnabled', {'feature': feature});
  String featureDisabled(String feature) => translate('featureDisabled', {'feature': feature});
  
  // Support
  String get needHelp => translate('needHelp');
  String get contactSupport => translate('contactSupport');
  String get sendUsFeedback => translate('sendUsFeedback');
  String get openingEmailClient => translate('openingEmailClient');
  String get sendEmail => translate('sendEmail');
  
  String get openSourceLicensesInfo => translate('openSourceLicensesInfo');
  
  // Success/Error messages
  String get customerDeleted => translate('customerDeleted');
  String failedToDeleteCustomer(String error) => translate('failedToDeleteCustomer', {'error': error});
  String get debtMarkedAsPaid => translate('debtMarkedAsPaid');
  String failedToMarkAsPaid(String error) => translate('failedToMarkAsPaid', {'error': error});
  String get debtDeleted => translate('debtDeleted');
  String failedToDeleteDebt(String error) => translate('failedToDeleteDebt', {'error': error});
  String get allDataCleared => translate('allDataCleared');
  String failedToClearData(String error) => translate('failedToClearData', {'error': error});
  
  // Confirmation messages
  String thisCustomerHasDebts(int count) => translate('thisCustomerHasDebts', {'count': count.toString()});
  String get areYouSureDeleteCustomer => translate('areYouSureDeleteCustomer');
  String areYouSureMarkAsPaid(String customerName, String amount) => translate('areYouSureMarkAsPaid', {'customerName': customerName, 'amount': amount});
  String get areYouSureDeleteDebt => translate('areYouSureDeleteDebt');
  String get thisActionWillPermanentlyDelete => translate('thisActionWillPermanentlyDelete');
  
  // Search and empty states
  String get searchByNamePhoneIdEmail => translate('searchByNamePhoneIdEmail');
  String get searchByNameDescription => translate('searchByNameDescription');
  String get noCustomersFound => translate('noCustomersFound');
  String get addNewCustomerToGetStarted => translate('addNewCustomerToGetStarted');
  String get noDebtsFound => translate('noDebtsFound');
  String get addNewDebtToGetStarted => translate('addNewDebtToGetStarted');
  
  // Status
  String get all => translate('all');
  String get pending => translate('pending');
  String get paid => translate('paid');
  String get overdue => translate('overdue');
  
  // Types
  String get personal => translate('personal');
  String get business => translate('business');
  String get loan => translate('loan');
  String get credit => translate('credit');
  String get other => translate('other');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
} 