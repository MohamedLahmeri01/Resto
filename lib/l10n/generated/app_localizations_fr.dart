// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Resto — Gestion de Restaurant';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get pin => 'Code PIN';

  @override
  String get pinLogin => 'Connexion par PIN';

  @override
  String get emailLogin => 'Connexion par e-mail';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get loginError => 'Email ou mot de passe incorrect';

  @override
  String get sessionExpired => 'Session expirée. Veuillez vous reconnecter.';

  @override
  String get unauthorizedAccess => 'Accès non autorisé';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get pos => 'Point de Vente';

  @override
  String get orders => 'Commandes';

  @override
  String get tables => 'Tables';

  @override
  String get menu => 'Menu';

  @override
  String get kitchen => 'Cuisine';

  @override
  String get kds => 'Écran Cuisine (KDS)';

  @override
  String get inventory => 'Inventaire';

  @override
  String get staff => 'Personnel';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get customers => 'Clients';

  @override
  String get payments => 'Paiements';

  @override
  String get reservations => 'Réservations';

  @override
  String get revenueToday => 'Chiffre d\'affaires aujourd\'hui';

  @override
  String get coversServed => 'Couverts servis';

  @override
  String get avgSpendPerCover => 'Dépense moyenne par couvert';

  @override
  String get pendingOrders => 'Commandes en attente';

  @override
  String get tableTurnRate => 'Taux de rotation des tables';

  @override
  String get kitchenThroughput => 'Débit cuisine';

  @override
  String get newOrder => 'Nouvelle commande';

  @override
  String orderNumber(String number) {
    return 'Commande N°$number';
  }

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get removeItem => 'Retirer l\'article';

  @override
  String get orderNotes => 'Notes de commande';

  @override
  String get specialRequests => 'Demandes spéciales';

  @override
  String get sendToKitchen => 'Envoyer en cuisine';

  @override
  String get holdOrder => 'Mettre en attente';

  @override
  String get fireOrder => 'Lancer la commande';

  @override
  String get cancelOrder => 'Annuler la commande';

  @override
  String get completeOrder => 'Finaliser la commande';

  @override
  String get orderPlaced => 'Commande passée';

  @override
  String get orderPreparing => 'En préparation';

  @override
  String get orderReady => 'Prête';

  @override
  String get orderServed => 'Servie';

  @override
  String get orderCompleted => 'Terminée';

  @override
  String get orderCancelled => 'Annulée';

  @override
  String get orderDraft => 'Brouillon';

  @override
  String get dineIn => 'Sur place';

  @override
  String get takeaway => 'À emporter';

  @override
  String get delivery => 'Livraison';

  @override
  String tableNumber(String number) {
    return 'Table $number';
  }

  @override
  String get tableAvailable => 'Disponible';

  @override
  String get tableOccupied => 'Occupée';

  @override
  String get tableReserved => 'Réservée';

  @override
  String get tableNeedsCleaning => 'À nettoyer';

  @override
  String get mergeTable => 'Fusionner les tables';

  @override
  String get splitTable => 'Séparer les tables';

  @override
  String seats(int count) {
    return '$count places';
  }

  @override
  String get floorPlan => 'Plan de salle';

  @override
  String get section => 'Section';

  @override
  String get floor => 'Étage';

  @override
  String get categories => 'Catégories';

  @override
  String get items => 'Articles';

  @override
  String get modifiers => 'Modificateurs';

  @override
  String get variants => 'Variantes';

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get addItem2 => 'Ajouter un article';

  @override
  String get editItem => 'Modifier l\'article';

  @override
  String get itemName => 'Nom de l\'article';

  @override
  String get itemDescription => 'Description';

  @override
  String get itemPrice => 'Prix';

  @override
  String get itemPhoto => 'Photo';

  @override
  String get allergens => 'Allergènes';

  @override
  String get calories => 'Calories';

  @override
  String get markUnavailable => 'Marquer indisponible (86)';

  @override
  String get markAvailable => 'Marquer disponible';

  @override
  String get unavailable86 => 'Indisponible (86)';

  @override
  String get scheduledMenu => 'Menu programmé';

  @override
  String get payment => 'Paiement';

  @override
  String get cash => 'Espèces';

  @override
  String get card => 'Carte';

  @override
  String get qrPay => 'Paiement QR';

  @override
  String get voucher => 'Bon';

  @override
  String get giftCard => 'Carte cadeau';

  @override
  String get splitBill => 'Partager l\'addition';

  @override
  String get splitByItem => 'Par article';

  @override
  String get splitBySeat => 'Par couvert';

  @override
  String get splitByPercentage => 'Par pourcentage';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get tax => 'TVA';

  @override
  String get discount => 'Remise';

  @override
  String get amountDue => 'Montant dû';

  @override
  String get amountPaid => 'Montant payé';

  @override
  String get change => 'Monnaie à rendre';

  @override
  String get processPayment => 'Encaisser';

  @override
  String get refund => 'Remboursement';

  @override
  String get void2 => 'Annulation';

  @override
  String get receipt => 'Reçu';

  @override
  String get printReceipt => 'Imprimer le reçu';

  @override
  String get emailReceipt => 'Envoyer le reçu par e-mail';

  @override
  String kdsStation(String name) {
    return 'Station $name';
  }

  @override
  String get bump => 'Valider';

  @override
  String get recall => 'Rappeler';

  @override
  String get allStations => 'Toutes les stations';

  @override
  String get grill => 'Grill';

  @override
  String get cold => 'Froid';

  @override
  String get prep => 'Préparation';

  @override
  String get pastry => 'Pâtisserie';

  @override
  String get bar => 'Bar';

  @override
  String get expo => 'Expédition';

  @override
  String get cookTime => 'Temps de cuisson';

  @override
  String get targetTime => 'Temps cible';

  @override
  String get elapsed => 'Temps écoulé';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get staffName => 'Nom de l\'employé';

  @override
  String get staffRole => 'Rôle';

  @override
  String get assignPin => 'Attribuer un PIN';

  @override
  String get sendOnboardingLink => 'Envoyer le lien d\'inscription';

  @override
  String get admin => 'Administrateur';

  @override
  String get manager => 'Gérant';

  @override
  String get cashier => 'Caissier';

  @override
  String get waiter => 'Serveur';

  @override
  String get chef => 'Chef cuisinier';

  @override
  String get inventoryClerk => 'Magasinier';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get search => 'Rechercher';

  @override
  String get filter => 'Filtrer';

  @override
  String get refresh => 'Actualiser';

  @override
  String get loading => 'Chargement...';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get warning => 'Avertissement';

  @override
  String get retry => 'Réessayer';

  @override
  String get close => 'Fermer';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get ok => 'OK';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get customRange => 'Période personnalisée';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get switchLanguage => 'Changer de langue';

  @override
  String get offlineMode => 'Mode hors ligne';

  @override
  String get offlineBanner =>
      'Vous êtes hors ligne. Les données seront synchronisées automatiquement.';

  @override
  String get syncing => 'Synchronisation en cours...';

  @override
  String get syncComplete => 'Synchronisation terminée';

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String get managerAuthRequired => 'Autorisation du gérant requise';

  @override
  String get enterManagerPin => 'Entrez le PIN du gérant';

  @override
  String get currencySymbol => 'DA';

  @override
  String priceFormat(String amount) {
    return '$amount DA';
  }

  @override
  String get confirmDeleteTitle => 'Confirmer la suppression';

  @override
  String get confirmDeleteMessage =>
      'Êtes-vous sûr de vouloir supprimer cet élément ?';

  @override
  String get confirmCancelOrder =>
      'Êtes-vous sûr de vouloir annuler cette commande ?';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }
}
