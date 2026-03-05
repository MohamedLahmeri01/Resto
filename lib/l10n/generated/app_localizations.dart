import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('fr'),
    Locale('ar'),
  ];

  /// Application title
  ///
  /// In fr, this message translates to:
  /// **'Resto — Gestion de Restaurant'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @pin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pin;

  /// No description provided for @pinLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par PIN'**
  String get pinLogin;

  /// No description provided for @emailLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion par e-mail'**
  String get emailLogin;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'Email ou mot de passe incorrect'**
  String get loginError;

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Veuillez vous reconnecter.'**
  String get sessionExpired;

  /// No description provided for @unauthorizedAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès non autorisé'**
  String get unauthorizedAccess;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @pos.
  ///
  /// In fr, this message translates to:
  /// **'Point de Vente'**
  String get pos;

  /// No description provided for @orders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// No description provided for @tables.
  ///
  /// In fr, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @menu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @kitchen.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get kitchen;

  /// No description provided for @kds.
  ///
  /// In fr, this message translates to:
  /// **'Écran Cuisine (KDS)'**
  String get kds;

  /// No description provided for @inventory.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventory;

  /// No description provided for @staff.
  ///
  /// In fr, this message translates to:
  /// **'Personnel'**
  String get staff;

  /// No description provided for @reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @customers.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get customers;

  /// No description provided for @payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get payments;

  /// No description provided for @reservations.
  ///
  /// In fr, this message translates to:
  /// **'Réservations'**
  String get reservations;

  /// No description provided for @revenueToday.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires aujourd\'hui'**
  String get revenueToday;

  /// No description provided for @coversServed.
  ///
  /// In fr, this message translates to:
  /// **'Couverts servis'**
  String get coversServed;

  /// No description provided for @avgSpendPerCover.
  ///
  /// In fr, this message translates to:
  /// **'Dépense moyenne par couvert'**
  String get avgSpendPerCover;

  /// No description provided for @pendingOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes en attente'**
  String get pendingOrders;

  /// No description provided for @tableTurnRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de rotation des tables'**
  String get tableTurnRate;

  /// No description provided for @kitchenThroughput.
  ///
  /// In fr, this message translates to:
  /// **'Débit cuisine'**
  String get kitchenThroughput;

  /// No description provided for @newOrder.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get newOrder;

  /// No description provided for @orderNumber.
  ///
  /// In fr, this message translates to:
  /// **'Commande N°{number}'**
  String orderNumber(String number);

  /// No description provided for @addItem.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l\'article'**
  String get removeItem;

  /// No description provided for @orderNotes.
  ///
  /// In fr, this message translates to:
  /// **'Notes de commande'**
  String get orderNotes;

  /// No description provided for @specialRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes spéciales'**
  String get specialRequests;

  /// No description provided for @sendToKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer en cuisine'**
  String get sendToKitchen;

  /// No description provided for @holdOrder.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en attente'**
  String get holdOrder;

  /// No description provided for @fireOrder.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la commande'**
  String get fireOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get cancelOrder;

  /// No description provided for @completeOrder.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser la commande'**
  String get completeOrder;

  /// No description provided for @orderPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Commande passée'**
  String get orderPlaced;

  /// No description provided for @orderPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get orderPreparing;

  /// No description provided for @orderReady.
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get orderReady;

  /// No description provided for @orderServed.
  ///
  /// In fr, this message translates to:
  /// **'Servie'**
  String get orderServed;

  /// No description provided for @orderCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get orderCompleted;

  /// No description provided for @orderCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderCancelled;

  /// No description provided for @orderDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get orderDraft;

  /// No description provided for @dineIn.
  ///
  /// In fr, this message translates to:
  /// **'Sur place'**
  String get dineIn;

  /// No description provided for @takeaway.
  ///
  /// In fr, this message translates to:
  /// **'À emporter'**
  String get takeaway;

  /// No description provided for @delivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get delivery;

  /// No description provided for @tableNumber.
  ///
  /// In fr, this message translates to:
  /// **'Table {number}'**
  String tableNumber(String number);

  /// No description provided for @tableAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get tableAvailable;

  /// No description provided for @tableOccupied.
  ///
  /// In fr, this message translates to:
  /// **'Occupée'**
  String get tableOccupied;

  /// No description provided for @tableReserved.
  ///
  /// In fr, this message translates to:
  /// **'Réservée'**
  String get tableReserved;

  /// No description provided for @tableNeedsCleaning.
  ///
  /// In fr, this message translates to:
  /// **'À nettoyer'**
  String get tableNeedsCleaning;

  /// No description provided for @mergeTable.
  ///
  /// In fr, this message translates to:
  /// **'Fusionner les tables'**
  String get mergeTable;

  /// No description provided for @splitTable.
  ///
  /// In fr, this message translates to:
  /// **'Séparer les tables'**
  String get splitTable;

  /// No description provided for @seats.
  ///
  /// In fr, this message translates to:
  /// **'{count} places'**
  String seats(int count);

  /// No description provided for @floorPlan.
  ///
  /// In fr, this message translates to:
  /// **'Plan de salle'**
  String get floorPlan;

  /// No description provided for @section.
  ///
  /// In fr, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @floor.
  ///
  /// In fr, this message translates to:
  /// **'Étage'**
  String get floor;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @items.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get items;

  /// No description provided for @modifiers.
  ///
  /// In fr, this message translates to:
  /// **'Modificateurs'**
  String get modifiers;

  /// No description provided for @variants.
  ///
  /// In fr, this message translates to:
  /// **'Variantes'**
  String get variants;

  /// No description provided for @addCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get addCategory;

  /// No description provided for @addItem2.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get addItem2;

  /// No description provided for @editItem.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'article'**
  String get editItem;

  /// No description provided for @itemName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'article'**
  String get itemName;

  /// No description provided for @itemDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get itemDescription;

  /// No description provided for @itemPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get itemPrice;

  /// No description provided for @itemPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get itemPhoto;

  /// No description provided for @allergens.
  ///
  /// In fr, this message translates to:
  /// **'Allergènes'**
  String get allergens;

  /// No description provided for @calories.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @markUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Marquer indisponible (86)'**
  String get markUnavailable;

  /// No description provided for @markAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Marquer disponible'**
  String get markAvailable;

  /// No description provided for @unavailable86.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible (86)'**
  String get unavailable86;

  /// No description provided for @scheduledMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu programmé'**
  String get scheduledMenu;

  /// No description provided for @payment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get payment;

  /// No description provided for @cash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get card;

  /// No description provided for @qrPay.
  ///
  /// In fr, this message translates to:
  /// **'Paiement QR'**
  String get qrPay;

  /// No description provided for @voucher.
  ///
  /// In fr, this message translates to:
  /// **'Bon'**
  String get voucher;

  /// No description provided for @giftCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte cadeau'**
  String get giftCard;

  /// No description provided for @splitBill.
  ///
  /// In fr, this message translates to:
  /// **'Partager l\'addition'**
  String get splitBill;

  /// No description provided for @splitByItem.
  ///
  /// In fr, this message translates to:
  /// **'Par article'**
  String get splitByItem;

  /// No description provided for @splitBySeat.
  ///
  /// In fr, this message translates to:
  /// **'Par couvert'**
  String get splitBySeat;

  /// No description provided for @splitByPercentage.
  ///
  /// In fr, this message translates to:
  /// **'Par pourcentage'**
  String get splitByPercentage;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In fr, this message translates to:
  /// **'TVA'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get discount;

  /// No description provided for @amountDue.
  ///
  /// In fr, this message translates to:
  /// **'Montant dû'**
  String get amountDue;

  /// No description provided for @amountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant payé'**
  String get amountPaid;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie à rendre'**
  String get change;

  /// No description provided for @processPayment.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get processPayment;

  /// No description provided for @refund.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get refund;

  /// No description provided for @void2.
  ///
  /// In fr, this message translates to:
  /// **'Annulation'**
  String get void2;

  /// No description provided for @receipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get receipt;

  /// No description provided for @printReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer le reçu'**
  String get printReceipt;

  /// No description provided for @emailReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le reçu par e-mail'**
  String get emailReceipt;

  /// No description provided for @kdsStation.
  ///
  /// In fr, this message translates to:
  /// **'Station {name}'**
  String kdsStation(String name);

  /// No description provided for @bump.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get bump;

  /// No description provided for @recall.
  ///
  /// In fr, this message translates to:
  /// **'Rappeler'**
  String get recall;

  /// No description provided for @allStations.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les stations'**
  String get allStations;

  /// No description provided for @grill.
  ///
  /// In fr, this message translates to:
  /// **'Grill'**
  String get grill;

  /// No description provided for @cold.
  ///
  /// In fr, this message translates to:
  /// **'Froid'**
  String get cold;

  /// No description provided for @prep.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get prep;

  /// No description provided for @pastry.
  ///
  /// In fr, this message translates to:
  /// **'Pâtisserie'**
  String get pastry;

  /// No description provided for @bar.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get bar;

  /// No description provided for @expo.
  ///
  /// In fr, this message translates to:
  /// **'Expédition'**
  String get expo;

  /// No description provided for @cookTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de cuisson'**
  String get cookTime;

  /// No description provided for @targetTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps cible'**
  String get targetTime;

  /// No description provided for @elapsed.
  ///
  /// In fr, this message translates to:
  /// **'Temps écoulé'**
  String get elapsed;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @staffName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'employé'**
  String get staffName;

  /// No description provided for @staffRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get staffRole;

  /// No description provided for @assignPin.
  ///
  /// In fr, this message translates to:
  /// **'Attribuer un PIN'**
  String get assignPin;

  /// No description provided for @sendOnboardingLink.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le lien d\'inscription'**
  String get sendOnboardingLink;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get admin;

  /// No description provided for @manager.
  ///
  /// In fr, this message translates to:
  /// **'Gérant'**
  String get manager;

  /// No description provided for @cashier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get cashier;

  /// No description provided for @waiter.
  ///
  /// In fr, this message translates to:
  /// **'Serveur'**
  String get waiter;

  /// No description provided for @chef.
  ///
  /// In fr, this message translates to:
  /// **'Chef cuisinier'**
  String get chef;

  /// No description provided for @inventoryClerk.
  ///
  /// In fr, this message translates to:
  /// **'Magasinier'**
  String get inventoryClerk;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get warning;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @customRange.
  ///
  /// In fr, this message translates to:
  /// **'Période personnalisée'**
  String get customRange;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @switchLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer de langue'**
  String get switchLanguage;

  /// No description provided for @offlineMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode hors ligne'**
  String get offlineMode;

  /// No description provided for @offlineBanner.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors ligne. Les données seront synchronisées automatiquement.'**
  String get offlineBanner;

  /// No description provided for @syncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation terminée'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la synchronisation'**
  String get syncFailed;

  /// No description provided for @managerAuthRequired.
  ///
  /// In fr, this message translates to:
  /// **'Autorisation du gérant requise'**
  String get managerAuthRequired;

  /// No description provided for @enterManagerPin.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le PIN du gérant'**
  String get enterManagerPin;

  /// No description provided for @currencySymbol.
  ///
  /// In fr, this message translates to:
  /// **'DA'**
  String get currencySymbol;

  /// No description provided for @priceFormat.
  ///
  /// In fr, this message translates to:
  /// **'{amount} DA'**
  String priceFormat(String amount);

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet élément ?'**
  String get confirmDeleteMessage;

  /// No description provided for @confirmCancelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler cette commande ?'**
  String get confirmCancelOrder;

  /// No description provided for @itemCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun article} =1{1 article} other{{count} articles}}'**
  String itemCount(int count);
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
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
