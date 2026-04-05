// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'BoitexScan';

  @override
  String get home => 'Accueil';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get inventory => 'Inventaire';

  @override
  String get exportCsv => 'Exporter CSV';

  @override
  String get barcode => 'Code-barres';

  @override
  String get productName => 'Nom du produit';

  @override
  String get sellingPrice => 'Prix de vente';

  @override
  String get costPrice => 'Prix d\'achat';

  @override
  String get category => 'Catégorie';

  @override
  String get stock => 'Stock actuel';

  @override
  String get save => 'Enregistrer';

  @override
  String get success => 'Succès !';

  @override
  String get errorDuplicate =>
      'Un produit avec ce code-barres ou ce nom existe déjà !';

  @override
  String get productNotFound => 'Produit non trouvé !';

  @override
  String get updateStock => 'Mettre à jour le stock';

  @override
  String get newStock => 'Nouveau stock';

  @override
  String get searchHint => 'Scanner ou taper un nom...';

  @override
  String get exportTitle => 'Exporter les données';

  @override
  String get totalItems => 'Total des articles';

  @override
  String get totalValue => 'Valeur totale du stock';

  @override
  String get generateCsv => 'Générer et partager CSV';

  @override
  String get exporting => 'Génération du fichier...';

  @override
  String get exportAll => 'Inventaire Global';

  @override
  String get exportLowStock => 'À Commander (Stock Faible)';

  @override
  String get exportCategories => 'Résumé par Catégorie';

  @override
  String get exportDeadStock => 'Stock Mort (0 Inventaire)';

  @override
  String get printLabels => 'Imprimer Étiquettes';

  @override
  String get selectPrinter => 'Sélectionner l\'imprimante';

  @override
  String get connect => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get printCopies => 'Nombre de copies';

  @override
  String get printBtn => 'IMPRIMER ÉTIQUETTES';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterLowStock => 'Stock Faible';

  @override
  String get filterOutStock => 'Rupture de Stock';

  @override
  String get noProductsFound => 'Aucun produit trouvé.';

  @override
  String get simpleMenuTitle => 'Tableau de Bord';

  @override
  String get reception => 'Réception';

  @override
  String get bon => 'Bons / Commandes';

  @override
  String get comingSoon => 'Bientôt disponible !';

  @override
  String get readyToScan =>
      'Prêt à scanner...\nPointez le PDA vers le code-barres.';

  @override
  String get developerMode => 'Mode Développeur';

  @override
  String get enterAdminPin => 'Saisir le code PIN';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get cancel => 'Annuler';

  @override
  String get incorrectPin => 'Code PIN incorrect';

  @override
  String get scannedItem => 'Scanné : ';
}
