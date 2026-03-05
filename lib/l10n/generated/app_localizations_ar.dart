// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'رستو — إدارة المطعم';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get pin => 'الرمز السري';

  @override
  String get pinLogin => 'الدخول بالرمز السري';

  @override
  String get emailLogin => 'الدخول بالبريد الإلكتروني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get loginError => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get sessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get unauthorizedAccess => 'وصول غير مصرح به';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get pos => 'نقطة البيع';

  @override
  String get orders => 'الطلبات';

  @override
  String get tables => 'الطاولات';

  @override
  String get menu => 'القائمة';

  @override
  String get kitchen => 'المطبخ';

  @override
  String get kds => 'شاشة المطبخ';

  @override
  String get inventory => 'المخزون';

  @override
  String get staff => 'الموظفون';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get customers => 'العملاء';

  @override
  String get payments => 'المدفوعات';

  @override
  String get reservations => 'الحجوزات';

  @override
  String get revenueToday => 'إيرادات اليوم';

  @override
  String get coversServed => 'الأغطية المقدمة';

  @override
  String get avgSpendPerCover => 'متوسط الإنفاق لكل غطاء';

  @override
  String get pendingOrders => 'الطلبات المعلقة';

  @override
  String get tableTurnRate => 'معدل دوران الطاولات';

  @override
  String get kitchenThroughput => 'إنتاجية المطبخ';

  @override
  String get newOrder => 'طلب جديد';

  @override
  String orderNumber(String number) {
    return 'طلب رقم $number';
  }

  @override
  String get addItem => 'إضافة صنف';

  @override
  String get removeItem => 'إزالة الصنف';

  @override
  String get orderNotes => 'ملاحظات الطلب';

  @override
  String get specialRequests => 'طلبات خاصة';

  @override
  String get sendToKitchen => 'إرسال للمطبخ';

  @override
  String get holdOrder => 'تعليق الطلب';

  @override
  String get fireOrder => 'بدء الطلب';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get completeOrder => 'إتمام الطلب';

  @override
  String get orderPlaced => 'تم الطلب';

  @override
  String get orderPreparing => 'قيد التحضير';

  @override
  String get orderReady => 'جاهز';

  @override
  String get orderServed => 'تم التقديم';

  @override
  String get orderCompleted => 'مكتمل';

  @override
  String get orderCancelled => 'ملغى';

  @override
  String get orderDraft => 'مسودة';

  @override
  String get dineIn => 'في المطعم';

  @override
  String get takeaway => 'للأخذ';

  @override
  String get delivery => 'توصيل';

  @override
  String tableNumber(String number) {
    return 'طاولة $number';
  }

  @override
  String get tableAvailable => 'متاحة';

  @override
  String get tableOccupied => 'مشغولة';

  @override
  String get tableReserved => 'محجوزة';

  @override
  String get tableNeedsCleaning => 'تحتاج تنظيف';

  @override
  String get mergeTable => 'دمج الطاولات';

  @override
  String get splitTable => 'فصل الطاولات';

  @override
  String seats(int count) {
    return '$count مقاعد';
  }

  @override
  String get floorPlan => 'مخطط القاعة';

  @override
  String get section => 'القسم';

  @override
  String get floor => 'الطابق';

  @override
  String get categories => 'الفئات';

  @override
  String get items => 'الأصناف';

  @override
  String get modifiers => 'الإضافات';

  @override
  String get variants => 'المتغيرات';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get addItem2 => 'إضافة صنف';

  @override
  String get editItem => 'تعديل الصنف';

  @override
  String get itemName => 'اسم الصنف';

  @override
  String get itemDescription => 'الوصف';

  @override
  String get itemPrice => 'السعر';

  @override
  String get itemPhoto => 'الصورة';

  @override
  String get allergens => 'مسببات الحساسية';

  @override
  String get calories => 'السعرات الحرارية';

  @override
  String get markUnavailable => 'تحديد غير متوفر (86)';

  @override
  String get markAvailable => 'تحديد متوفر';

  @override
  String get unavailable86 => 'غير متوفر (86)';

  @override
  String get scheduledMenu => 'قائمة مجدولة';

  @override
  String get payment => 'الدفع';

  @override
  String get cash => 'نقدي';

  @override
  String get card => 'بطاقة';

  @override
  String get qrPay => 'دفع QR';

  @override
  String get voucher => 'قسيمة';

  @override
  String get giftCard => 'بطاقة هدية';

  @override
  String get splitBill => 'تقسيم الفاتورة';

  @override
  String get splitByItem => 'حسب الصنف';

  @override
  String get splitBySeat => 'حسب المقعد';

  @override
  String get splitByPercentage => 'حسب النسبة';

  @override
  String get total => 'الإجمالي';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get tax => 'الضريبة';

  @override
  String get discount => 'خصم';

  @override
  String get amountDue => 'المبلغ المستحق';

  @override
  String get amountPaid => 'المبلغ المدفوع';

  @override
  String get change => 'الباقي';

  @override
  String get processPayment => 'تنفيذ الدفع';

  @override
  String get refund => 'استرجاع';

  @override
  String get void2 => 'إلغاء';

  @override
  String get receipt => 'إيصال';

  @override
  String get printReceipt => 'طباعة الإيصال';

  @override
  String get emailReceipt => 'إرسال الإيصال بالبريد';

  @override
  String kdsStation(String name) {
    return 'محطة $name';
  }

  @override
  String get bump => 'تمت';

  @override
  String get recall => 'استرجاع';

  @override
  String get allStations => 'جميع المحطات';

  @override
  String get grill => 'شواء';

  @override
  String get cold => 'بارد';

  @override
  String get prep => 'تحضير';

  @override
  String get pastry => 'حلويات';

  @override
  String get bar => 'بار';

  @override
  String get expo => 'تجهيز';

  @override
  String get cookTime => 'وقت الطهي';

  @override
  String get targetTime => 'الوقت المستهدف';

  @override
  String get elapsed => 'الوقت المنقضي';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get staffName => 'اسم الموظف';

  @override
  String get staffRole => 'الدور';

  @override
  String get assignPin => 'تعيين الرمز السري';

  @override
  String get sendOnboardingLink => 'إرسال رابط التسجيل';

  @override
  String get admin => 'مدير';

  @override
  String get manager => 'مشرف';

  @override
  String get cashier => 'أمين صندوق';

  @override
  String get waiter => 'نادل';

  @override
  String get chef => 'طاهٍ';

  @override
  String get inventoryClerk => 'أمين مخزن';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get search => 'بحث';

  @override
  String get filter => 'تصفية';

  @override
  String get refresh => 'تحديث';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get warning => 'تحذير';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get ok => 'حسناً';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get customRange => 'فترة مخصصة';

  @override
  String get language => 'اللغة';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get switchLanguage => 'تغيير اللغة';

  @override
  String get offlineMode => 'وضع عدم الاتصال';

  @override
  String get offlineBanner => 'أنت غير متصل. سيتم مزامنة البيانات تلقائياً.';

  @override
  String get syncing => 'جاري المزامنة...';

  @override
  String get syncComplete => 'اكتملت المزامنة';

  @override
  String get syncFailed => 'فشلت المزامنة';

  @override
  String get managerAuthRequired => 'مطلوب تصريح المشرف';

  @override
  String get enterManagerPin => 'أدخل الرمز السري للمشرف';

  @override
  String get currencySymbol => 'د.ج';

  @override
  String priceFormat(String amount) {
    return '$amount د.ج';
  }

  @override
  String get confirmDeleteTitle => 'تأكيد الحذف';

  @override
  String get confirmDeleteMessage => 'هل أنت متأكد من حذف هذا العنصر؟';

  @override
  String get confirmCancelOrder => 'هل أنت متأكد من إلغاء هذا الطلب؟';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صنف',
      many: '$count صنفاً',
      few: '$count أصناف',
      two: 'صنفان',
      one: 'صنف واحد',
      zero: 'لا أصناف',
    );
    return '$_temp0';
  }
}
