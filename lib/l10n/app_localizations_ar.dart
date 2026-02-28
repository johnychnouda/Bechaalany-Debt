// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بيشعلاني كونكت';

  @override
  String get navDashboard => 'لوحة التحكم';

  @override
  String get navCustomers => 'العملاء';

  @override
  String get navProducts => 'المنتجات';

  @override
  String get navActivities => 'السجل';

  @override
  String get navAdmin => 'الإدارة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get dashboardWelcomeBack => 'مرحباً بعودتك';

  @override
  String get financialAnalysis => 'التحليل المالي';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get fromProductProfitMargins => 'من هوامش ربح المنتجات';

  @override
  String get potentialRevenue => 'الإيرادات المحتملة';

  @override
  String get fromUnpaidAmounts => 'من المبالغ غير المسددة';

  @override
  String get totalDebts => 'إجمالي الديون';

  @override
  String get outstandingAmounts => 'المبالغ المتبقية';

  @override
  String get totalPayments => 'إجمالي المدفوعات';

  @override
  String get fromCustomerPayments => 'من مدفوعات العملاء';

  @override
  String get totalCustomersAndDebtors => 'إجمالي العملاء والمدينين';

  @override
  String get customersWithDebts => 'عملاء لديهم ديون';

  @override
  String get totalCustomers => 'إجمالي العملاء';

  @override
  String get noCustomersAddedYet =>
      'لم تتم إضافة عملاء بعد. أضف أول عميل للبدء!';

  @override
  String percentCustomersPendingDebts(String percent) {
    return '$percent٪ من العملاء لديهم ديون معلقة';
  }

  @override
  String get topDebtors => 'أكبر المدينين';

  @override
  String get noOutstandingDebts => 'لا توجد ديون معلقة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get sectionAccount => 'الحساب';

  @override
  String get sectionAppearance => 'المظهر';

  @override
  String get sectionBusinessSettings => 'إعدادات العمل';

  @override
  String get sectionWhatsAppAutomation => 'رسائل واتساب التلقائية';

  @override
  String get sectionDataManagement => 'إدارة البيانات';

  @override
  String get sectionAppInfo => 'معلومات التطبيق';

  @override
  String get accessStatus => 'حالة الوصول';

  @override
  String get accessStatusSubtitle =>
      'عرض حالة وصولك والتواصل مع الدعم عند الحاجة';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutSubtitle => 'تسجيل الخروج من حسابك';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle => 'حذف حسابك وجميع البيانات نهائياً';

  @override
  String get deleteAccountDialogMessage =>
      'سيتم حذف حسابك وجميع البيانات المرتبطة به نهائياً، بما في ذلك:\n\n• جميع العملاء والديون\n• جميع الأنشطة وسجلات الدفع\n• جميع النسخ الاحتياطية\n• جميع الإعدادات والتفضيلات\n\nلا يمكن التراجع عن هذا الإجراء.';

  @override
  String get finalConfirmation => 'التأكيد النهائي';

  @override
  String get finalConfirmationDeleteMessage =>
      'هذه آخر فرصة للإلغاء. سيتم حذف حسابك وجميع البيانات نهائياً. لا يمكن التراجع عن ذلك.';

  @override
  String get language => 'اللغة';

  @override
  String get languageSubtitle => 'لغة التطبيق (العربية أو الإنجليزية)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeSubtitle => 'استخدام المظهر الداكن';

  @override
  String get businessName => 'اسم العمل';

  @override
  String get businessNameSubtitle => 'تعيين اسم عملك للإيصالات والرسائل';

  @override
  String get currencyAndRates => 'العملة وأسعار الصرف';

  @override
  String get currencyAndRatesSubtitle => 'ضبط إعدادات العملة والأسعار';

  @override
  String get enableAutomatedMessages => 'تفعيل الرسائل التلقائية';

  @override
  String get enableAutomatedMessagesSubtitle =>
      'إرسال رسائل واتساب لتسويات الديون وتذكيرات الدفع';

  @override
  String get sendPaymentReminders => 'إرسال تذكيرات الدفع';

  @override
  String get sendPaymentRemindersSubtitle =>
      'إرسال تذكيرات واتساب يدوياً للعملاء الذين لديهم ديون متبقية';

  @override
  String get paymentRemindersTitle => 'تذكيرات الدفع';

  @override
  String get clearSelection => 'مسح';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get paymentRemindersCustomerCountOne => 'عميل واحد لديه ديون معلقة';

  @override
  String paymentRemindersCustomerCountOther(String count) {
    return '$count عملاء لديهم ديون معلقة';
  }

  @override
  String get paymentRemindersSelectedOne => 'عميل واحد محدد';

  @override
  String paymentRemindersSelectedOther(String count) {
    return '$count عملاء محددين';
  }

  @override
  String get sendReminders => 'إرسال التذكيرات';

  @override
  String get allClear => 'كل شيء واضح!';

  @override
  String get noCustomersOutstandingDebts => 'لا يوجد عملاء لديهم ديون معلقة';

  @override
  String get sendPaymentReminderDialogTitle => 'إرسال تذكير بالدفع';

  @override
  String get batchReminderSubtitle =>
      'سيتم إرسال هذه الرسالة عبر واتساب لجميع العملاء المحددين';

  @override
  String get enterCustomMessage => 'أدخل رسالتك المخصصة...';

  @override
  String sendToCount(String count) {
    return 'إرسال إلى $count';
  }

  @override
  String get allRemindersSentSuccess => 'تم إرسال جميع التذكيرات بنجاح!';

  @override
  String sentToCountOfTotal(String success, String total) {
    return 'تم الإرسال إلى $success من أصل $total عملاء';
  }

  @override
  String batchRemindersFailed(String message) {
    return 'فشل إرسال تذكيرات الدفع الجماعية: $message';
  }

  @override
  String get warning => 'تحذير';

  @override
  String get clearDebtsAndActivities => 'مسح الديون والسجل';

  @override
  String get clearDebtsAndActivitiesSubtitle =>
      'إزالة جميع الديون والسجلات والمدفوعات';

  @override
  String get dataRecovery => 'استعادة البيانات';

  @override
  String get dataRecoverySubtitle => 'استعادة البيانات من النسخ الاحتياطية';

  @override
  String get manualBackup => 'نسخ احتياطي يدوي';

  @override
  String get createBackup => 'إنشاء نسخة احتياطية';

  @override
  String get backupButton => 'نسخ';

  @override
  String get automaticBackup => 'نسخ احتياطي تلقائي';

  @override
  String get dailyBackupAt12AM => 'نسخ احتياطي يومي عند ١٢ صباحاً';

  @override
  String nextBackupIn(String time) {
    return 'النسخ الاحتياطي التالي خلال: $time';
  }

  @override
  String get hoursShort => 'س';

  @override
  String get minutesShort => 'د';

  @override
  String get secondsShort => 'ث';

  @override
  String lastBackup(String time) {
    return 'آخر نسخ احتياطي: $time';
  }

  @override
  String get never => 'أبداً';

  @override
  String get availableBackups => 'النسخ الاحتياطية المتاحة';

  @override
  String get noBackupsAvailable =>
      'لا توجد نسخ احتياطية. أنشئ أول نسخة احتياطية للبدء.';

  @override
  String get signInToViewBackups =>
      'يرجى تسجيل الدخول لعرض وإدارة النسخ الاحتياطية.';

  @override
  String get automaticBackupLabel => 'نسخ احتياطي تلقائي';

  @override
  String get manualBackupLabel => 'نسخ احتياطي يدوي';

  @override
  String get restore => 'استعادة';

  @override
  String get restoreData => 'استعادة البيانات';

  @override
  String get restoreDataConfirm =>
      'سيستبدل هذا جميع البيانات الحالية بالنسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String get deleteBackup => 'حذف النسخة الاحتياطية';

  @override
  String get deleteBackupConfirm =>
      'سيؤدي هذا إلى حذف ملف النسخة الاحتياطية نهائياً. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String get developer => 'المطور';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get ok => 'موافق';

  @override
  String get success => 'تم بنجاح';

  @override
  String get error => 'خطأ';

  @override
  String get businessNameDialogTitle => 'اسم العمل';

  @override
  String get businessNameDialogHint =>
      'سيظهر اسم عملك على الإيصالات وتذكيرات الدفع وجميع تواصلات العملاء.';

  @override
  String get enterBusinessName => 'أدخل اسم عملك';

  @override
  String get businessNameRequired => 'اسم العمل مطلوب';

  @override
  String get businessNameUpdated => 'تم تحديث اسم العمل بنجاح.';

  @override
  String businessNameUpdateFailed(String message) {
    return 'فشل تحديث اسم العمل: $message';
  }

  @override
  String get appInfoTitle => 'معلومات التطبيق';

  @override
  String get appInfoName => 'تطبيق ديون بيشعلاني';

  @override
  String get appInfoDescription =>
      'تطبيق شامل لإدارة الديون وتتبع ديون العملاء والمدفوعات وإيرادات العمل.';

  @override
  String get appInfoFeaturesTitle => 'المميزات:';

  @override
  String get appInfoFeaturesList =>
      '• تتبع ديون العملاء\n• إدارة المدفوعات\n• حسابات الإيرادات\n• كتالوج المنتجات\n• أتمتة واتساب\n• النسخ الاحتياطي واستعادة البيانات';

  @override
  String get clearDebtsDialogTitle => 'مسح الديون والسجل';

  @override
  String get clearDebtsDialogContent =>
      'سيؤدي هذا إلى حذف جميع الديون والسجلات والمدفوعات نهائياً. سيتم الاحتفاظ بالمنتجات والعملاء. لا يمكن التراجع عن هذا الإجراء.\n\nهل أنت متأكد من المتابعة؟';

  @override
  String get clearDebtsButton => 'مسح الديون';

  @override
  String get clearDebtsSuccess =>
      'تم مسح جميع الديون والسجلات والمدفوعات بنجاح. تم الاحتفاظ بالمنتجات والعملاء.';

  @override
  String get signInTitleBechaalany => 'بيشعلاني ';

  @override
  String get signInTitleConnect => 'كونكت';

  @override
  String get signInSubtitle => 'سجّل الدخول بحساب Google أو Apple للبدء';

  @override
  String get signInSubtitleGoogleOnly => 'سجّل الدخول بحساب Google للبدء';

  @override
  String get signingIn => 'جاري تسجيل الدخول...';

  @override
  String get continueWithGoogle => 'المتابعة مع Google';

  @override
  String get continueWithApple => 'المتابعة مع Apple';

  @override
  String get googleSignInCancelled => 'تم إلغاء تسجيل الدخول عبر Google';

  @override
  String googleSignInFailed(String message) {
    return 'فشل تسجيل الدخول عبر Google: $message';
  }

  @override
  String get appleSignInCancelled => 'تم إلغاء تسجيل الدخول عبر Apple';

  @override
  String get appleSignInCancelledTryAgain =>
      'تم إلغاء تسجيل الدخول عبر Apple. يرجى المحاولة مرة أخرى.';

  @override
  String get appleSignInNotAvailable =>
      'تسجيل الدخول عبر Apple غير متاح. تحقق من إعدادات جهازك.';

  @override
  String get networkError => 'خطأ في الشبكة. تحقق من اتصال الإنترنت.';

  @override
  String get appleSignInFailed =>
      'فشل تسجيل الدخول عبر Apple. يرجى المحاولة مرة أخرى أو استخدام Google.';

  @override
  String get requiredSetupTitle => 'الإعداد المطلوب';

  @override
  String get requiredSetupSubtitle => 'أكمل التالي لبدء استخدام التطبيق';

  @override
  String get requiredSetupHeaderTitle => 'لنُعد التطبيق معك';

  @override
  String get requiredSetupHeaderSubtitle => 'خطوتان فقط — تستغرق أقل من دقيقة.';

  @override
  String get shopName => 'اسم المحل';

  @override
  String get shopNameLabel => 'ما اسم محلك أو عملك؟';

  @override
  String get shopNameHint => 'يظهر على الإيصالات';

  @override
  String get shopNamePlaceholder => 'مثال: متجري';

  @override
  String get exchangeRate => 'سعر الصرف';

  @override
  String get exchangeRateLabel => 'كم يساوي 1 دولار بالليرة الآن؟';

  @override
  String get exchangeRateHint => 'أدخل الرقم فقط';

  @override
  String get exchangeRatePlaceholder => 'مثال: 89000';

  @override
  String get continueButton => 'متابعة';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get couldNotLoadValues => 'تعذر تحميل القيم الحالية.';

  @override
  String get addShopNameToContinue => 'أضف اسم المحل للمتابعة.';

  @override
  String get enterValidExchangeRate => 'أدخل سعر صرف صحيح (رقم أكبر من صفر).';

  @override
  String get enterRateToContinue =>
      'أدخل سعر الصرف الحالي (مثال: 89000) للمتابعة.';

  @override
  String get settingsHint =>
      'يمكنك تغيير هذه الإعدادات في أي وقت من الإعدادات.';

  @override
  String get saveFailedTryAgain => 'فشل الحفظ. يرجى المحاولة مرة أخرى.';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get setupSaved => 'تم حفظ الإعداد. يمكنك بدء استخدام التطبيق.';

  @override
  String setupSaveFailed(String message) {
    return 'فشل الحفظ: $message';
  }

  @override
  String get searchByNameOrId => 'البحث بالاسم أو المعرّف';

  @override
  String get customersTitle => 'العملاء';

  @override
  String customersCount(String count) {
    return '$count عملاء';
  }

  @override
  String get customerCountOne => 'عميل واحد';

  @override
  String get noCustomersYet => 'لا يوجد عملاء بعد';

  @override
  String get noCustomersFound => 'لم يتم العثور على عملاء';

  @override
  String get startByAddingFirstCustomer => 'ابدأ بإضافة أول عميل';

  @override
  String get tryAdjustingSearchCriteria => 'جرّب تعديل معايير البحث';

  @override
  String get deleteCustomer => 'حذف العميل';

  @override
  String deleteCustomerConfirmWithDebts(String count) {
    return 'هذا العميل لديه $count دين/ديون. حذف العميل سيحذف جميع الديون المرتبطة. هل أنت متأكد؟';
  }

  @override
  String get deleteCustomerConfirm => 'هل أنت متأكد من حذف هذا العميل؟';

  @override
  String deleteCustomerConfirmWithName(String name) {
    return 'هل أنت متأكد من حذف $name؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get delete => 'حذف';

  @override
  String get searchProducts => 'البحث في المنتجات...';

  @override
  String get filterAll => 'الكل';

  @override
  String get refresh => 'تحديث';

  @override
  String get noCategoriesFound => 'لم يتم العثور على تصنيفات';

  @override
  String get addCategoriesToGetStarted => 'أضف تصنيفات للبدء';

  @override
  String get noProductsFound => 'لم يتم العثور على منتجات';

  @override
  String get tryAdjustingSearchTerms => 'جرّب تعديل كلمات البحث';

  @override
  String get addProductsToGetStarted => 'أضف منتجات للبدء';

  @override
  String addProductsToCategoryToGetStarted(String category) {
    return 'أضف منتجات إلى $category للبدء';
  }

  @override
  String noProductsInCategory(String category) {
    return 'لا توجد منتجات في $category';
  }

  @override
  String get categoryNotFound => 'التصنيف غير موجود';

  @override
  String get activityHistory => 'سجل النشاط';

  @override
  String get generateMonthlyReport => 'إنشاء التقرير الشهري';

  @override
  String get daily => 'يومي';

  @override
  String get weekly => 'أسبوعي';

  @override
  String get monthly => 'شهري';

  @override
  String get yearly => 'سنوي';

  @override
  String get todaysActivity => 'نشاط اليوم';

  @override
  String weeklyActivityRange(String start, String end) {
    return 'النشاط الأسبوعي - $start - $end';
  }

  @override
  String monthlyActivityMonth(String monthYear) {
    return 'النشاط الشهري - $monthYear';
  }

  @override
  String yearlyActivityYear(String year) {
    return 'النشاط السنوي - $year';
  }

  @override
  String get totalPaid => 'إجمالي المدفوع';

  @override
  String get noActivityToday =>
      'لا يوجد نشاط اليوم\nأضف ديوناً أو قم بالدفع لرؤية النشاط هنا';

  @override
  String get noActivityThisWeek =>
      'لا يوجد نشاط هذا الأسبوع\nأضف ديوناً أو قم بالدفع لرؤية النشاط هنا';

  @override
  String get noActivityThisMonth =>
      'لا يوجد نشاط هذا الشهر\nأضف ديوناً أو قم بالدفع لرؤية النشاط هنا';

  @override
  String get noActivityThisYear =>
      'لا يوجد نشاط هذه السنة\nأضف ديوناً أو قم بالدفع لرؤية النشاط هنا';

  @override
  String noActivitiesFoundForQuery(String query) {
    return 'لم يتم العثور على أنشطة لـ \"$query\"';
  }

  @override
  String todayAtTime(String time) {
    return 'اليوم عند $time';
  }

  @override
  String yesterdayAtTime(String time) {
    return 'أمس عند $time';
  }

  @override
  String dateAtTime(String date, String time) {
    return '$date عند $time';
  }

  @override
  String get adminDashboard => 'لوحة تحكم المشرف';

  @override
  String get dashboardOverview => 'نظرة عامة على اللوحة';

  @override
  String get monitorUserStatistics => 'مراقبة إحصائيات المستخدمين';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get totalUsers => 'إجمالي المستخدمين';

  @override
  String get allRegisteredUsers => 'جميع المستخدمين المسجلين';

  @override
  String get active => 'نشط';

  @override
  String get activeAccess => 'وصول نشط';

  @override
  String get trial => 'تجريبي';

  @override
  String get onTrialPeriod => 'في الفترة التجريبية';

  @override
  String get expired => 'منتهي';

  @override
  String get expiredAccess => 'وصول منتهي';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get viewManageAllUsers => 'عرض وإدارة جميع المستخدمين';

  @override
  String get loadingDashboard => 'جاري تحميل اللوحة...';

  @override
  String get unableToLoadDashboard => 'تعذر تحميل اللوحة';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noUsersInSystem => 'لا يوجد مستخدمون في النظام بعد';

  @override
  String get noUsersYetSubtitle =>
      'ستظهر إحصائيات المستخدمين هنا عند بدء التسجيل.';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get searchByEmailOrName => 'البحث بالبريد أو الاسم...';

  @override
  String get monthlyFilter => 'شهري';

  @override
  String get yearlyFilter => 'سنوي';

  @override
  String userSummaryCounts(
    String all,
    String trial,
    String monthly,
    String yearly,
    String expired,
  ) {
    return 'الكل: $all • تجريبي: $trial • شهري: $monthly • سنوي: $yearly • منتهي: $expired';
  }

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get noUsersMatchSearch => 'لا يوجد مستخدمون يطابقون بحثك';

  @override
  String get noTrialUsersFound => 'لم يتم العثور على مستخدمين تجريبيين';

  @override
  String get noMonthlyUsersFound => 'لم يتم العثور على مستخدمين شهريين';

  @override
  String get noYearlyUsersFound => 'لم يتم العثور على مستخدمين سنويين';

  @override
  String get noExpiredUsersFound => 'لم يتم العثور على مستخدمين منتهين';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get noAdminPermissions => 'ليس لديك صلاحيات المشرف لعرض هذه الصفحة.';

  @override
  String get trialExpired => 'انتهت الفترة التجريبية';

  @override
  String get cancelled => 'ملغى';

  @override
  String get activeStatus => 'نشط';

  @override
  String get permissionDenied => 'تم رفض الإذن';

  @override
  String get permissionDeniedMessage =>
      'ليس لديك إذن للوصول إلى بيانات المستخدمين. تأكد من أن حسابك معرّف كمشرف في Firestore.';

  @override
  String get addCustomer => 'إضافة عميل';

  @override
  String get editCustomer => 'تعديل العميل';

  @override
  String get updateCustomer => 'تحديث العميل';

  @override
  String get customerInformation => 'معلومات العميل';

  @override
  String get financialSummary => 'الملخص المالي';

  @override
  String get customerId => 'معرّف العميل';

  @override
  String get customerIdRequired => 'معرّف العميل *';

  @override
  String get enterCustomerId => 'أدخل معرّف العميل';

  @override
  String get pleaseEnterCustomerId => 'يرجى إدخال معرّف العميل';

  @override
  String get customerIdAlreadyExists => 'معرّف العميل موجود مسبقاً';

  @override
  String get customerIdInvalidChars =>
      'معرّف العميل يمكن أن يحتوي على حروف وأرقام وشرطة سفلية وشرطة فقط';

  @override
  String get thisCustomerIdAlreadyExists => 'معرّف العميل هذا موجود مسبقاً';

  @override
  String get fullName => 'الاسم الكامل *';

  @override
  String get enterCustomerName => 'أدخل اسم العميل';

  @override
  String get pleaseEnterCustomerName => 'يرجى إدخال اسم العميل';

  @override
  String get phoneNumber => 'رقم الهاتف *';

  @override
  String get enterPhoneNumber => 'أدخل رقم الهاتف';

  @override
  String get pleaseEnterPhoneNumber => 'يرجى إدخال رقم الهاتف';

  @override
  String get validPhoneNumber => 'يرجى إدخال رقم هاتف صحيح (8 أرقام على الأقل)';

  @override
  String get thisPhoneNumberAlreadyExists => 'رقم الهاتف هذا موجود مسبقاً';

  @override
  String get duplicatePhoneNumber => 'رقم هاتف مكرر';

  @override
  String duplicatePhoneMessage(String phone, String name, String id) {
    return 'رقم الهاتف \"$phone\" مستخدم بالفعل من قبل العميل \"$name\" (المعرّف: $id).\n\nهل تريد المتابعة بهذا الرقم؟';
  }

  @override
  String get emailAddress => 'البريد الإلكتروني';

  @override
  String get enterEmailOptional => 'أدخل البريد (اختياري)';

  @override
  String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get validEmailDomain => 'يرجى إدخال نطاق بريد إلكتروني صحيح';

  @override
  String get thisEmailAlreadyUsed => 'هذا البريد مستخدم من قبل عميل آخر';

  @override
  String get address => 'العنوان';

  @override
  String get enterAddressOptional => 'أدخل العنوان (اختياري)';

  @override
  String get add => 'إضافة';

  @override
  String get addCategory => 'إضافة تصنيف';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get deleteCategory => 'حذف التصنيف';

  @override
  String get deleteProduct => 'حذف المنتج';

  @override
  String get categoryName => 'اسم التصنيف';

  @override
  String get categoryNameHint => 'مثال: إلكترونيات';

  @override
  String get selectCategory => 'اختر التصنيف';

  @override
  String get chooseCategoryToAddSubcategory =>
      'اختر تصنيفاً لإضافة صنف فرعي إليه:';

  @override
  String subcategoriesCount(String count) {
    return '$count أصناف فرعية';
  }

  @override
  String addSubcategoryTo(String name) {
    return 'إضافة صنف فرعي إلى $name';
  }

  @override
  String get subcategoryName => 'اسم الصنف الفرعي';

  @override
  String get subcategoryNameHint => 'مثال: آيفون';

  @override
  String get currencyLabel => 'العملة';

  @override
  String get costPrice => 'سعر التكلفة';

  @override
  String get sellingPrice => 'سعر البيع';

  @override
  String get productCost => 'التكلفة';

  @override
  String get productPrice => 'السعر';

  @override
  String get productRevenue => 'الإيراد';

  @override
  String get productLoss => 'الخسارة';

  @override
  String get enterCostPrice => 'أدخل سعر التكلفة';

  @override
  String get enterSellingPrice => 'أدخل سعر البيع';

  @override
  String get exchangeRateRequired => 'سعر الصرف مطلوب';

  @override
  String get setExchangeRateInSettings =>
      'يرجى تعيين سعر الصرف في إعدادات العملة قبل إضافة منتجات بالليرة.';

  @override
  String get goToSettings => 'الذهاب إلى الإعدادات';

  @override
  String get confirm => 'تأكيد';

  @override
  String get editCategoryName => 'تعديل اسم التصنيف';

  @override
  String get categoryNameExists => 'اسم التصنيف موجود';

  @override
  String get addDebtFromProduct => 'إضافة دين من منتج';

  @override
  String get customerLabel => 'العميل';

  @override
  String get categoryLabel => 'التصنيف';

  @override
  String get productLabel => 'المنتج';

  @override
  String get selectProduct => 'اختر المنتج';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get selectProductAboveToViewDetails =>
      'اختر منتجاً أعلاه لعرض التفاصيل';

  @override
  String get addDebt => 'إضافة دين';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get quantity => 'الكمية';

  @override
  String get totalAmount => 'المبلغ الإجمالي';

  @override
  String get notSelected => 'لم يتم الاختيار';

  @override
  String get addProductsToCategoryInProductsTab =>
      'أضف منتجات لهذا التصنيف من تبويب المنتجات.';

  @override
  String get productPurchases => 'مشتريات المنتجات';

  @override
  String productsCount(String count) {
    return '$count منتجات';
  }

  @override
  String get makePayment => 'إجراء الدفع';

  @override
  String get totalPending => 'المبلغ المعلق';

  @override
  String createdOnDateAtTime(String date, String time) {
    return 'تم الإنشاء في $date عند $time';
  }

  @override
  String get timeAm => 'ص';

  @override
  String get timePm => 'م';

  @override
  String get customerReceipt => 'إيصال العميل';

  @override
  String get generatedOn => 'تم الإنشاء في';

  @override
  String get accountSummary => 'ملخص الحساب';

  @override
  String get totalOriginal => 'الإجمالي الأصلي';

  @override
  String get remaining => 'المتبقي';

  @override
  String get transactionHistory => 'سجل المعاملات';

  @override
  String get generatedBy => 'تم الإنشاء بواسطة';

  @override
  String get receiptFor => 'إيصال لـ';

  @override
  String pageOf(String current, String total) {
    return 'صفحة $current من $total';
  }

  @override
  String get idLabel => 'المعرّف';

  @override
  String get partialPayment => 'دفعة جزئية';

  @override
  String get outstandingDebt => 'دين معلق';

  @override
  String get newDebt => 'دين جديد';

  @override
  String get fullyPaid => 'مدفوع بالكامل';

  @override
  String get debtPaid => 'تم السداد';

  @override
  String get activity => 'نشاط';

  @override
  String get deleteDebt => 'حذف الدين';

  @override
  String get deleteDebtConfirm => 'هل أنت متأكد أنك تريد حذف هذا الدين؟';

  @override
  String get debtDetails => 'تفاصيل الدين:';

  @override
  String get amountLabel => 'المبلغ:';

  @override
  String get deleteDebtCannotUndo => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get monthlyActivityReport => 'تقرير النشاط الشهري';

  @override
  String get reportSummary => 'الملخص';

  @override
  String get transactionsLabel => 'المعاملات';

  @override
  String get activityDetails => 'تفاصيل النشاط';

  @override
  String get userDetails => 'تفاصيل المستخدم';

  @override
  String get loadingUserDetails => 'جاري تحميل تفاصيل المستخدم…';

  @override
  String get currentStatus => 'الحالة الحالية';

  @override
  String get actions => 'الإجراءات';

  @override
  String get updating => 'جاري التحديث…';

  @override
  String get grantAccess => 'منح الوصول';

  @override
  String get grantAccessDescription =>
      'منح وصول مستمر لهذا المستخدم. اختر المدة.';

  @override
  String get oneMonth => 'شهر واحد';

  @override
  String get oneYear => 'سنة واحدة';

  @override
  String get revokeAccess => 'سحب الوصول';

  @override
  String get revokeAccessDescription =>
      'تعليق هذا الحساب مؤقتاً. يمكن للمستخدم التواصل معك في حال وجود مشكلة.';

  @override
  String get revokeAccessConfirm =>
      'هل أنت متأكد أنك تريد سحب وصول هذا المستخدم؟';

  @override
  String get revoke => 'سحب';

  @override
  String accessGrantedSuccess(String duration) {
    return 'تم منح الوصول بنجاح ($duration)!';
  }

  @override
  String failedToGrantAccess(String error) {
    return 'فشل منح الوصول: $error';
  }

  @override
  String get accessRevokedSuccess => 'تم سحب الوصول بنجاح!';

  @override
  String failedToRevokeAccess(String error) {
    return 'فشل سحب الوصول: $error';
  }

  @override
  String get noAccessData => 'لا توجد بيانات وصول';

  @override
  String get status => 'الحالة';

  @override
  String get trialStarted => 'بداية الفترة التجريبية';

  @override
  String get trialEnds => 'نهاية الفترة التجريبية';

  @override
  String get accessStarted => 'بداية الوصول';

  @override
  String get accessEnds => 'نهاية الوصول';

  @override
  String get accessPeriod => 'فترة الوصول';

  @override
  String updatedDate(String date) {
    return 'تم التحديث $date';
  }

  @override
  String get dateExpired => '(منتهي)';

  @override
  String get dateDaysLeftOne => '(يوم واحد متبقي)';

  @override
  String dateDaysLeftOther(String count) {
    return '($count أيام متبقية)';
  }

  @override
  String get oneMonthLabel => 'شهر واحد';

  @override
  String get oneYearLabel => 'سنة واحدة';

  @override
  String get requestAccess => 'طلب الوصول';

  @override
  String get freeTrial => 'تجربة مجانية';

  @override
  String get accessExpired => 'انتهى الوصول';

  @override
  String get accessCancelled => 'تم إلغاء الوصول';

  @override
  String get trialDetails => 'تفاصيل التجربة';

  @override
  String get trialPeriod => 'فترة التجربة';

  @override
  String daysRemaining(String count) {
    return '$count أيام متبقية';
  }

  @override
  String get accessDetails => 'تفاصيل الوصول';

  @override
  String get yourAccessExpired => 'انتهى وصولك';

  @override
  String get yourAccessCancelled => 'تم إلغاء وصولك';

  @override
  String get expiredContactMessage =>
      'إذا كنت تعتقد أن هذا خطأ أو تحتاج مساعدة في حسابك، تواصل مع المسؤول للحصول على الدعم.';

  @override
  String get contactAdministrator => 'التواصل مع المسؤول';

  @override
  String get accessStatusAndRenewals => 'حالة الوصول والتجديد';

  @override
  String get requestAccessInfoMessage =>
      'إذا انتهت فترة تجربتك أو وصولك ولا يزال لا يمكنك استخدام التطبيق، يمكنك التواصل مع المسؤول للمساعدة في إصلاح حسابك.';

  @override
  String get welcomeToBechaalany => 'مرحباً بك في تطبيق بيشعلاني للديون';

  @override
  String get welcomeNoDataMessage =>
      'التطبيق مجاني بالكامل ومتاح لجميع المستخدمين المسجلين. إذا واجهت مشكلة في الوصول إلى بياناتك، يمكنك التواصل مع المسؤول للحصول على الدعم الفني.';

  @override
  String get whatsApp => 'واتساب';

  @override
  String get phone => 'هاتف';
}
