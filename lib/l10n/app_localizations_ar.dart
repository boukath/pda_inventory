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

  @override
  String get rfidScanner => 'ماسح RFID';

  @override
  String get rfidSweep => 'مسح RFID';

  @override
  String get clearScans => 'مسح السجلات';

  @override
  String get scannedItems => 'العناصر الممسوحة';

  @override
  String get scanningActive => 'المسح نشط... تجول في الممر';

  @override
  String get pressToStartScanning => 'اضغط لبدء المسح';

  @override
  String get unknownTag => 'علامة غير معروفة';

  @override
  String get finishAndReview => 'إنهاء ومراجعة';

  @override
  String get sessionComplete => 'اكتملت الجلسة';

  @override
  String get reviewItems => 'مراجعة العناصر';

  @override
  String get readyToReview => 'هل أنت مستعد للمراجعة والحفظ في قاعدة البيانات؟';

  @override
  String get reconciliation => 'التسوية والمطابقة';

  @override
  String get commitInventory => 'تأكيد الجرد';

  @override
  String get match => 'متطابق';

  @override
  String get missing => 'مفقود';

  @override
  String get overstock => 'فائض';

  @override
  String get unknown => 'غير معروف';

  @override
  String get expected => 'المتوقع: ';

  @override
  String get found => 'الموجود: ';

  @override
  String get inventoryUpdatedSuccess => 'تم تحديث المخزون بنجاح!';

  @override
  String get enterpriseCatalog => 'كتالوج الشركة';

  @override
  String get enterpriseCatalogSub => 'قائمة منتجات المورد العالمية';

  @override
  String get rfidScannerSub => 'مسح جماعي مستمر';

  @override
  String get rfidInventory => 'جرد RFID';

  @override
  String get rfidInventorySub => 'تتبع المخزون والعدد';

  @override
  String get rfidReview => 'مراجعة RFID';

  @override
  String get rfidReviewSub => 'مراجعة وحفظ العلامات الممسوحة';

  @override
  String get registerTag => 'تسجيل علامة';

  @override
  String get registerTagSub => 'ربط علامة RFID جديدة بباركود';

  @override
  String get allFilter => 'الكل';

  @override
  String get addCustomField => 'إضافة حقل مخصص';

  @override
  String get customFieldHint => 'مثال: الضمان، عمر البطارية';

  @override
  String get addFieldBtn => 'إضافة حقل';

  @override
  String get scanEpcWarning => 'الرجاء مسح علامة EPC أولاً!';

  @override
  String get productNameRequired => 'اسم المنتج مطلوب!';

  @override
  String get productSavedSuccess => 'تم حفظ المنتج بنجاح!';

  @override
  String get registerRfidProduct => 'تسجيل منتج RFID';

  @override
  String get customFieldsTitle => 'حقول مخصصة';

  @override
  String get retailApparel => '👔 تجزئة (ملابس)';

  @override
  String get marketGrocery => '🛒 سوق (بقالة)';

  @override
  String get hardwareTagLink => 'ربط العلامة المادية';

  @override
  String get scannedEpcCode => 'رمز EPC الممسوح';

  @override
  String get stopScanning => 'إيقاف المسح';

  @override
  String get scanRfidLabel => 'مسح علامة RFID';

  @override
  String get coreIdentification => 'التعريف الأساسي';

  @override
  String get productNameReqLabel => 'اسم المنتج (مطلوب)';

  @override
  String get skuInternalCode => 'SKU (رمز داخلي)';

  @override
  String get barcodeUpc => 'الباركود (UPC/EAN)';

  @override
  String get brandName => 'اسم العلامة التجارية';

  @override
  String get subCategory => 'فئة فرعية';

  @override
  String get apparelDetails => 'تفاصيل الملابس (تجزئة)';

  @override
  String get sizeLabel => 'المقاس (S, M, 32x34)';

  @override
  String get colorLabel => 'اللون';

  @override
  String get genderDept => 'الجنس / القسم';

  @override
  String get seasonLabel => 'الموسم (صيف 26)';

  @override
  String get materialLabel => 'المادة (100% قطن)';

  @override
  String get consumableDetails => 'تفاصيل استهلاكية (سوق)';

  @override
  String get batchLot => 'رقم الدفعة / اللوط';

  @override
  String get productionDate => 'تاريخ الإنتاج (YYYY-MM-DD)';

  @override
  String get expirationDate => 'تاريخ الانتهاء (YYYY-MM-DD)';

  @override
  String get weightVolume => 'الوزن / الحجم (مثال 500 جم)';

  @override
  String get pricingSuppliers => 'التسعير والموردين';

  @override
  String get sellingPriceMsrp => 'سعر البيع';

  @override
  String get supplierItemCode => 'رمز صنف المورد';

  @override
  String get inventoryLocation => 'المخزون والموقع';

  @override
  String get currentStockQty => 'كمية المخزون الحالية';

  @override
  String get zoneAisle => 'المنطقة / الممر (مثال: ممر 4)';

  @override
  String get saveEnterpriseProduct => 'حفظ المنتج المؤسسي';
}
