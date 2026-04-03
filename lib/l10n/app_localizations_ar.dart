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
  String get disconnect => 'قطع الاتصال';

  @override
  String get printCopies => 'عدد النسخ';

  @override
  String get printBtn => 'طباعة الملصقات';
}
