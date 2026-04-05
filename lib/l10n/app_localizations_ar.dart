// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'جهاز السوق';

  @override
  String get home => 'الرئيسية';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get inventory => 'جرد المخزون';

  @override
  String get exportCsv => 'تصدير CSV';

  @override
  String get barcode => 'الباركود';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get sellingPrice => 'سعر البيع';

  @override
  String get costPrice => 'سعر الشراء';

  @override
  String get category => 'الفئة';

  @override
  String get stock => 'المخزون الحالي';

  @override
  String get save => 'حفظ';

  @override
  String get success => 'نجاح!';

  @override
  String get errorDuplicate => 'يوجد منتج بهذا الباركود أو الاسم بالفعل!';

  @override
  String get productNotFound => 'المنتج غير موجود!';

  @override
  String get updateStock => 'تحديث المخزون';

  @override
  String get newStock => 'كمية المخزون الجديدة';

  @override
  String get searchHint => 'امسح الباركود أو اكتب الاسم...';

  @override
  String get exportTitle => 'تصدير البيانات';

  @override
  String get totalItems => 'إجمالي الأصناف';

  @override
  String get totalValue => 'قيمة المخزون الإجمالية';

  @override
  String get generateCsv => 'إنشاء ومشاركة CSV';

  @override
  String get exporting => 'جاري إنشاء الملف...';

  @override
  String get exportAll => 'الجرد الشامل';

  @override
  String get exportLowStock => 'قائمة الطلبات (نقص المخزون)';

  @override
  String get exportCategories => 'ملخص مالي حسب الفئة';

  @override
  String get exportDeadStock => 'المخزون الميت (رصيد 0)';

  @override
  String get printLabels => 'طباعة الملصقات';

  @override
  String get selectPrinter => 'اختر الطابعة';

  @override
  String get connect => 'اتصال';

  @override
  String get disconnect => 'فصل';

  @override
  String get printCopies => 'عدد النسخ';

  @override
  String get printBtn => 'طباعة الملصقات';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterLowStock => 'مخزون منخفض';

  @override
  String get filterOutStock => 'نفاد المخزون';

  @override
  String get noProductsFound => 'لم يتم العثور على أي منتج.';

  @override
  String get simpleMenuTitle => 'لوحة تحكم المسح';

  @override
  String get reception => 'استلام البضائع';

  @override
  String get bon => 'السندات / الطلبيات';

  @override
  String get comingSoon => 'قريباً!';

  @override
  String get readyToScan => 'جاهز للمسح...\nقم بتوجيه الجهاز نحو الباركود.';

  @override
  String get developerMode => 'وضع المطور';

  @override
  String get enterAdminPin => 'أدخل رمز المسؤول';

  @override
  String get unlock => 'فتح';

  @override
  String get cancel => 'إلغاء';

  @override
  String get incorrectPin => 'الرمز غير صحيح';

  @override
  String get scannedItem => 'تم مسح: ';

  @override
  String get toggleCount => 'العد (+1)';

  @override
  String get toggleCheck => 'تحقق (معلومات)';

  @override
  String get receiveProductTitle => 'استلام منتج';

  @override
  String get quantityReceived => 'الكمية المستلمة';

  @override
  String get supplierComment => 'المورد / تعليق';

  @override
  String get receivingLogTitle => 'سجل الاستلام';

  @override
  String get readyToReceiveHint => 'جاهز للاستلام.\nامسح منتجًا للبدء.';

  @override
  String get supplierPrefix => 'المورد: ';

  @override
  String get supplierNone => 'لا يوجد';

  @override
  String get finalizeAndSaveOrder => 'إنهاء وحفظ الطلب';

  @override
  String get orderSavedSuccess => 'تم حفظ الطلب بنجاح!';

  @override
  String get noOrdersFound =>
      'لم يتم العثور على طلبات.\nقم بحفظ جلسة جرد أولاً!';

  @override
  String get qty => 'الكمية';

  @override
  String get manualEntryTitle => 'إدخال يدوي';

  @override
  String get date => 'التاريخ';
}
