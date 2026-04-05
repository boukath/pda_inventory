import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BoitexScan'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count'**
  String get inventory;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get stock;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @errorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A product with this barcode or name already exists!'**
  String get errorDuplicate;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found!'**
  String get productNotFound;

  /// No description provided for @updateStock.
  ///
  /// In en, this message translates to:
  /// **'Update Stock'**
  String get updateStock;

  /// No description provided for @newStock.
  ///
  /// In en, this message translates to:
  /// **'New Stock Count'**
  String get newStock;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode or Type Name...'**
  String get searchHint;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportTitle;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Unique Items'**
  String get totalItems;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Inventory Value'**
  String get totalValue;

  /// No description provided for @generateCsv.
  ///
  /// In en, this message translates to:
  /// **'Generate & Share CSV'**
  String get generateCsv;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Generating file...'**
  String get exporting;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Complete Inventory'**
  String get exportAll;

  /// No description provided for @exportLowStock.
  ///
  /// In en, this message translates to:
  /// **'Reorder List (Low Stock)'**
  String get exportLowStock;

  /// No description provided for @exportCategories.
  ///
  /// In en, this message translates to:
  /// **'Category Financial Summary'**
  String get exportCategories;

  /// No description provided for @exportDeadStock.
  ///
  /// In en, this message translates to:
  /// **'Dead Stock (0 Inventory)'**
  String get exportDeadStock;

  /// No description provided for @printLabels.
  ///
  /// In en, this message translates to:
  /// **'Print Labels'**
  String get printLabels;

  /// No description provided for @selectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Select Printer'**
  String get selectPrinter;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @printCopies.
  ///
  /// In en, this message translates to:
  /// **'Number of Copies'**
  String get printCopies;

  /// No description provided for @printBtn.
  ///
  /// In en, this message translates to:
  /// **'PRINT LABELS'**
  String get printBtn;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get filterLowStock;

  /// No description provided for @filterOutStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get filterOutStock;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProductsFound;

  /// No description provided for @simpleMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Scanner Dashboard'**
  String get simpleMenuTitle;

  /// No description provided for @reception.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get reception;

  /// No description provided for @bon.
  ///
  /// In en, this message translates to:
  /// **'Orders / Vouchers'**
  String get bon;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon!'**
  String get comingSoon;

  /// No description provided for @readyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan...\nPoint PDA at barcode.'**
  String get readyToScan;

  /// No description provided for @developerMode.
  ///
  /// In en, this message translates to:
  /// **'Developer Mode'**
  String get developerMode;

  /// No description provided for @enterAdminPin.
  ///
  /// In en, this message translates to:
  /// **'Enter Admin PIN'**
  String get enterAdminPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @scannedItem.
  ///
  /// In en, this message translates to:
  /// **'Scanned: '**
  String get scannedItem;

  /// No description provided for @toggleCount.
  ///
  /// In en, this message translates to:
  /// **'COUNT (+1)'**
  String get toggleCount;

  /// No description provided for @toggleCheck.
  ///
  /// In en, this message translates to:
  /// **'CHECK (INFO)'**
  String get toggleCheck;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
