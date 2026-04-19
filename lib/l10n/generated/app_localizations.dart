import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @emailCannotBeChangedHere.
  ///
  /// In en, this message translates to:
  /// **'  Email cannot be changed here'**
  String get emailCannotBeChangedHere;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'& up'**
  String get up;

  /// No description provided for @andIConfirmThatIMeet.
  ///
  /// In en, this message translates to:
  /// **', and I confirm that I meet all the requirements listed above.'**
  String get andIConfirmThatIMeet;

  /// No description provided for @andIUnderstandThatMyApplication.
  ///
  /// In en, this message translates to:
  /// **', and I understand that my application will be reviewed by the admin team.'**
  String get andIUnderstandThatMyApplication;

  /// No description provided for @abc1234.
  ///
  /// In en, this message translates to:
  /// **'ABC-1234'**
  String get abc1234;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @acceptingOrders.
  ///
  /// In en, this message translates to:
  /// **'Accepting Orders'**
  String get acceptingOrders;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @accessDenied2.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied2;

  /// No description provided for @accessDeniedAdminPrivilegesRequired.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Admin privileges required.'**
  String get accessDeniedAdminPrivilegesRequired;

  /// No description provided for @accessDeniedDriverPrivilegesRequired.
  ///
  /// In en, this message translates to:
  /// **'Access denied. Driver privileges required.'**
  String get accessDeniedDriverPrivilegesRequired;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountCreatedPleaseVerifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created! Please verify your email.'**
  String get accountCreatedPleaseVerifyYourEmail;

  /// No description provided for @acrossAllDrivers.
  ///
  /// In en, this message translates to:
  /// **'Across all drivers'**
  String get acrossAllDrivers;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @activeHours.
  ///
  /// In en, this message translates to:
  /// **'Active Hours'**
  String get activeHours;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active Today'**
  String get activeToday;

  /// No description provided for @activeUsers.
  ///
  /// In en, this message translates to:
  /// **'Active Users'**
  String get activeUsers;

  /// No description provided for @adBanner.
  ///
  /// In en, this message translates to:
  /// **'Ad Banner'**
  String get adBanner;

  /// No description provided for @adBannerPreview.
  ///
  /// In en, this message translates to:
  /// **'Ad Banner Preview'**
  String get adBannerPreview;

  /// No description provided for @adDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ad deleted successfully'**
  String get adDeletedSuccessfully;

  /// No description provided for @adTitle.
  ///
  /// In en, this message translates to:
  /// **'Ad Title'**
  String get adTitle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get addACommentOptional;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @addNewBannerPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add new banner/promotion'**
  String get addNewBannerPromotion;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add new product'**
  String get addNewProduct;

  /// No description provided for @addNewStore.
  ///
  /// In en, this message translates to:
  /// **'Add new store'**
  String get addNewStore;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addPlan.
  ///
  /// In en, this message translates to:
  /// **'Add Plan'**
  String get addPlan;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @addProduct2.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct2;

  /// No description provided for @addStore.
  ///
  /// In en, this message translates to:
  /// **'Add Store'**
  String get addStore;

  /// No description provided for @addSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory'**
  String get addSubcategory;

  /// No description provided for @addThumbnailOptional.
  ///
  /// In en, this message translates to:
  /// **'Add thumbnail (optional)'**
  String get addThumbnailOptional;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @addYourDeliveryAddressesForFaster.
  ///
  /// In en, this message translates to:
  /// **'Add your delivery addresses for faster checkout'**
  String get addYourDeliveryAddressesForFaster;

  /// No description provided for @addYourFirstAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Your First Address'**
  String get addYourFirstAddress;

  /// No description provided for @addYourFirstProductToStart.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start selling'**
  String get addYourFirstProductToStart;

  /// No description provided for @addEditCategories.
  ///
  /// In en, this message translates to:
  /// **'Add/edit categories'**
  String get addEditCategories;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressAdded.
  ///
  /// In en, this message translates to:
  /// **'Address added'**
  String get addressAdded;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @addressDetails.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetails;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address Label'**
  String get addressLabel;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin Access Required'**
  String get adminAccessRequired;

  /// No description provided for @adminCategories.
  ///
  /// In en, this message translates to:
  /// **'Admin Categories'**
  String get adminCategories;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminMode.
  ///
  /// In en, this message translates to:
  /// **'Admin Mode'**
  String get adminMode;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @adminCategories2.
  ///
  /// In en, this message translates to:
  /// **'Admin • Categories'**
  String get adminCategories2;

  /// No description provided for @adsPromotions.
  ///
  /// In en, this message translates to:
  /// **'Ads & Promotions'**
  String get adsPromotions;

  /// No description provided for @adsManagement.
  ///
  /// In en, this message translates to:
  /// **'Ads Management'**
  String get adsManagement;

  /// No description provided for @adsManager.
  ///
  /// In en, this message translates to:
  /// **'Ads Manager'**
  String get adsManager;

  /// No description provided for @aiMate.
  ///
  /// In en, this message translates to:
  /// **'AI Mate'**
  String get aiMate;

  /// No description provided for @aiMateYourSmartAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Mate – Your smart assistant'**
  String get aiMateYourSmartAssistant;

  /// No description provided for @aiRequestTimedOutPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'AI request timed out. Please try again.'**
  String get aiRequestTimedOutPleaseTry;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allDriverApplicationsHaveBeenProcessed.
  ///
  /// In en, this message translates to:
  /// **'All driver applications have been processed.'**
  String get allDriverApplicationsHaveBeenProcessed;

  /// No description provided for @allMerchantApplicationsHaveBeenProcessed.
  ///
  /// In en, this message translates to:
  /// **'All merchant applications have been processed.'**
  String get allMerchantApplicationsHaveBeenProcessed;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @allServicesRunningNormally.
  ///
  /// In en, this message translates to:
  /// **'All services running normally'**
  String get allServicesRunningNormally;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All-Time'**
  String get allTime;

  /// No description provided for @allTimeCompleted.
  ///
  /// In en, this message translates to:
  /// **'All-time completed'**
  String get allTimeCompleted;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @analyticsOverview.
  ///
  /// In en, this message translates to:
  /// **'Analytics Overview'**
  String get analyticsOverview;

  /// No description provided for @anyAdditionalInformationYouWouldLike.
  ///
  /// In en, this message translates to:
  /// **'Any additional information you would like to provide'**
  String get anyAdditionalInformationYouWouldLike;

  /// No description provided for @appConfiguration.
  ///
  /// In en, this message translates to:
  /// **'App Configuration'**
  String get appConfiguration;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// No description provided for @applicationSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully!'**
  String get applicationSubmittedSuccessfully;

  /// No description provided for @applications.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applications;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @applyAsMerchant.
  ///
  /// In en, this message translates to:
  /// **'Apply as Merchant'**
  String get applyAsMerchant;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approveDriver.
  ///
  /// In en, this message translates to:
  /// **'Approve Driver'**
  String get approveDriver;

  /// No description provided for @approveMerchant.
  ///
  /// In en, this message translates to:
  /// **'Approve Merchant'**
  String get approveMerchant;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveConversation.
  ///
  /// In en, this message translates to:
  /// **'Archive Conversation'**
  String get archiveConversation;

  /// No description provided for @areYouSureYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this booking?'**
  String get areYouSureYouWantTo;

  /// No description provided for @areYouSureYouWantTo2.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get areYouSureYouWantTo2;

  /// No description provided for @areYouSureYouWantTo3.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your subscription?'**
  String get areYouSureYouWantTo3;

  /// No description provided for @areYouSureYouWantTo4.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ad?'**
  String get areYouSureYouWantTo4;

  /// No description provided for @areYouSureYouWantTo5.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from your cart?'**
  String get areYouSureYouWantTo5;

  /// No description provided for @areYouSureYouWantTo6.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureYouWantTo6;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @askAiCheapItalianFoodOpen.
  ///
  /// In en, this message translates to:
  /// **'Ask AI: \"cheap Italian food open now\"'**
  String get askAiCheapItalianFoodOpen;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriver;

  /// No description provided for @assignOrders.
  ///
  /// In en, this message translates to:
  /// **'Assign Orders'**
  String get assignOrders;

  /// No description provided for @assignOrdersToDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Orders to Driver'**
  String get assignOrdersToDriver;

  /// No description provided for @assignToAStoreCategoryOr.
  ///
  /// In en, this message translates to:
  /// **'Assign to a store category or leave empty'**
  String get assignToAStoreCategoryOr;

  /// No description provided for @assignToStore.
  ///
  /// In en, this message translates to:
  /// **'Assign to Store *'**
  String get assignToStore;

  /// No description provided for @assignedOrders.
  ///
  /// In en, this message translates to:
  /// **'Assigned Orders'**
  String get assignedOrders;

  /// No description provided for @assigningOrders.
  ///
  /// In en, this message translates to:
  /// **'Assigning orders...'**
  String get assigningOrders;

  /// No description provided for @assignmentBlockedDriverIsNoLonger.
  ///
  /// In en, this message translates to:
  /// **'Assignment blocked — driver is no longer available'**
  String get assignmentBlockedDriverIsNoLonger;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @avgOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Value'**
  String get avgOrderValue;

  /// No description provided for @avgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg/Order'**
  String get avgOrder;

  /// No description provided for @awaitingAssignment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting assignment'**
  String get awaitingAssignment;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @backToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to App'**
  String get backToApp;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @baseFare.
  ///
  /// In en, this message translates to:
  /// **'Base Fare'**
  String get baseFare;

  /// No description provided for @becomeADriver.
  ///
  /// In en, this message translates to:
  /// **'Become a Driver'**
  String get becomeADriver;

  /// No description provided for @becomeAMerchant.
  ///
  /// In en, this message translates to:
  /// **'Become a Merchant'**
  String get becomeAMerchant;

  /// No description provided for @becomeAPartner.
  ///
  /// In en, this message translates to:
  /// **'Become a Partner'**
  String get becomeAPartner;

  /// No description provided for @billingCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing Cycle'**
  String get billingCycle;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @bookService.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookingCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Booking created successfully'**
  String get bookingCreatedSuccessfully;

  /// No description provided for @broadcastMessageToAllUsers.
  ///
  /// In en, this message translates to:
  /// **'Broadcast message to all users'**
  String get broadcastMessageToAllUsers;

  /// No description provided for @browseAllStores.
  ///
  /// In en, this message translates to:
  /// **'Browse all stores'**
  String get browseAllStores;

  /// No description provided for @browseApp.
  ///
  /// In en, this message translates to:
  /// **'Browse App'**
  String get browseApp;

  /// No description provided for @browseItemsAndAddThemTo.
  ///
  /// In en, this message translates to:
  /// **'Browse items and add them to your cart.'**
  String get browseItemsAndAddThemTo;

  /// No description provided for @browseProducts.
  ///
  /// In en, this message translates to:
  /// **'Browse products'**
  String get browseProducts;

  /// No description provided for @browseStoresAndTapTheHeart.
  ///
  /// In en, this message translates to:
  /// **'Browse stores and tap the heart icon to save products here'**
  String get browseStoresAndTapTheHeart;

  /// No description provided for @browseTheMarketplaceAndSaveListings.
  ///
  /// In en, this message translates to:
  /// **'Browse the marketplace and save listings you like'**
  String get browseTheMarketplaceAndSaveListings;

  /// No description provided for @buildingFloorApartmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Building, floor, apartment (optional)'**
  String get buildingFloorApartmentOptional;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress;

  /// No description provided for @businessAddress2.
  ///
  /// In en, this message translates to:
  /// **'Business Address *'**
  String get businessAddress2;

  /// No description provided for @businessDescription.
  ///
  /// In en, this message translates to:
  /// **'Business Description'**
  String get businessDescription;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @businessName2.
  ///
  /// In en, this message translates to:
  /// **'Business Name *'**
  String get businessName2;

  /// No description provided for @busy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get busy;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callRider.
  ///
  /// In en, this message translates to:
  /// **'Call rider'**
  String get callRider;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @campaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaigns;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cancelBooking.
  ///
  /// In en, this message translates to:
  /// **'Cancel Booking'**
  String get cancelBooking;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @cancelOrder2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order?'**
  String get cancelOrder2;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get cancelSubscription;

  /// No description provided for @cancelYourSubscriptionPermanently.
  ///
  /// In en, this message translates to:
  /// **'Cancel your subscription permanently'**
  String get cancelYourSubscriptionPermanently;

  /// No description provided for @cannotAddItemProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Cannot add item — product not found'**
  String get cannotAddItemProductNotFound;

  /// No description provided for @cannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete'**
  String get cannotDelete;

  /// No description provided for @cannotIdentifyStoreForThisOrder.
  ///
  /// In en, this message translates to:
  /// **'Cannot identify store for this order'**
  String get cannotIdentifyStoreForThisOrder;

  /// No description provided for @carousel.
  ///
  /// In en, this message translates to:
  /// **'Carousel'**
  String get carousel;

  /// No description provided for @cartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get cartCleared;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoriesAreCreatedWhenYouAdd.
  ///
  /// In en, this message translates to:
  /// **'Categories are created when you add products with categories'**
  String get categoriesAreCreatedWhenYouAdd;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptional;

  /// No description provided for @categoryCreated.
  ///
  /// In en, this message translates to:
  /// **'Category created'**
  String get categoryCreated;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name *'**
  String get categoryName;

  /// No description provided for @categoryOrderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category order updated'**
  String get categoryOrderUpdated;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Category Type'**
  String get categoryType;

  /// No description provided for @categoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Category updated'**
  String get categoryUpdated;

  /// No description provided for @centerOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get centerOnMyLocation;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changeProfilePhoto;

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatWithOurAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'Chat with our AI assistant'**
  String get chatWithOurAiAssistant;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @checkAdminStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Admin Status'**
  String get checkAdminStatus;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseHowYouWantToPartner.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to partner with us'**
  String get chooseHowYouWantToPartner;

  /// No description provided for @chooseImageSource.
  ///
  /// In en, this message translates to:
  /// **'Choose Image Source'**
  String get chooseImageSource;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @clearCart2.
  ///
  /// In en, this message translates to:
  /// **'Clear cart'**
  String get clearCart2;

  /// No description provided for @clearConversation.
  ///
  /// In en, this message translates to:
  /// **'Clear Conversation'**
  String get clearConversation;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @clearLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear location'**
  String get clearLocation;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get collection;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @confirmCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cash Collected'**
  String get confirmCashCollected;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmSubscription.
  ///
  /// In en, this message translates to:
  /// **'Confirm Subscription'**
  String get confirmSubscription;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contentManagement.
  ///
  /// In en, this message translates to:
  /// **'Content Management'**
  String get contentManagement;

  /// No description provided for @contentRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Content refreshed'**
  String get contentRefreshed;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @conversationArchived.
  ///
  /// In en, this message translates to:
  /// **'Conversation archived'**
  String get conversationArchived;

  /// No description provided for @couldNotDetermineLocationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Could not determine location coordinates'**
  String get couldNotDetermineLocationCoordinates;

  /// No description provided for @couldNotGetCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get current location'**
  String get couldNotGetCurrentLocation;

  /// No description provided for @couldNotLaunchPhoneDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer'**
  String get couldNotLaunchPhoneDialer;

  /// No description provided for @couldNotOpenDialerCall961.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer. Call +961 81-483570'**
  String get couldNotOpenDialerCall961;

  /// No description provided for @couldNotOpenProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not open product'**
  String get couldNotOpenProduct;

  /// No description provided for @couldNotOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get couldNotOpenWhatsapp;

  /// No description provided for @couldNotOpenWhatsappPleaseContact.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Please contact +961 81-483570'**
  String get couldNotOpenWhatsappPleaseContact;

  /// No description provided for @couldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read file.'**
  String get couldNotReadFile;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAd.
  ///
  /// In en, this message translates to:
  /// **'Create Ad'**
  String get createAd;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Create Listing'**
  String get createListing;

  /// No description provided for @createNewStore.
  ///
  /// In en, this message translates to:
  /// **'Create New Store'**
  String get createNewStore;

  /// No description provided for @createProduct.
  ///
  /// In en, this message translates to:
  /// **'Create Product'**
  String get createProduct;

  /// No description provided for @createStore.
  ///
  /// In en, this message translates to:
  /// **'Create Store'**
  String get createStore;

  /// No description provided for @createStoreCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Store Category'**
  String get createStoreCategory;

  /// No description provided for @createYourFirstStoreToStart.
  ///
  /// In en, this message translates to:
  /// **'Create your first store to start selling'**
  String get createYourFirstStoreToStart;

  /// No description provided for @createYourStoreListProductsAnd.
  ///
  /// In en, this message translates to:
  /// **'Create your store, list products, and start selling'**
  String get createYourStoreListProductsAnd;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @currentlyClosed.
  ///
  /// In en, this message translates to:
  /// **'Currently Closed'**
  String get currentlyClosed;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customerInsights.
  ///
  /// In en, this message translates to:
  /// **'Customer Insights'**
  String get customerInsights;

  /// No description provided for @customerRating.
  ///
  /// In en, this message translates to:
  /// **'Customer Rating'**
  String get customerRating;

  /// No description provided for @customerRatingsWillAppearHereAfter.
  ///
  /// In en, this message translates to:
  /// **'Customer ratings will appear here after deliveries'**
  String get customerRatingsWillAppearHereAfter;

  /// No description provided for @customizeDesign.
  ///
  /// In en, this message translates to:
  /// **'Customize Design'**
  String get customizeDesign;

  /// No description provided for @customizeStoreDesign.
  ///
  /// In en, this message translates to:
  /// **'Customize Store Design'**
  String get customizeStoreDesign;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get dailyGoals;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @dataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get dataPrivacy;

  /// No description provided for @dataExportRequestSubmittedYouWill.
  ///
  /// In en, this message translates to:
  /// **'Data export request submitted. You will receive an email.'**
  String get dataExportRequestSubmittedYouWill;

  /// No description provided for @deepLinkDestination.
  ///
  /// In en, this message translates to:
  /// **'Deep Link Destination'**
  String get deepLinkDestination;

  /// No description provided for @deepLinking.
  ///
  /// In en, this message translates to:
  /// **'Deep Linking'**
  String get deepLinking;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAd.
  ///
  /// In en, this message translates to:
  /// **'Delete Ad'**
  String get deleteAd;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address?'**
  String get deleteAddress;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get deleteListing;

  /// No description provided for @deleteListing2.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing2;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete Plan'**
  String get deletePlan;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @deleteProduct2.
  ///
  /// In en, this message translates to:
  /// **'Delete Product?'**
  String get deleteProduct2;

  /// No description provided for @deleteSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Subcategory'**
  String get deleteSubcategory;

  /// No description provided for @deliverOrdersSetYourOwnSchedule.
  ///
  /// In en, this message translates to:
  /// **'Deliver orders, set your own schedule, earn money'**
  String get deliverOrdersSetYourOwnSchedule;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'DELIVER TO'**
  String get deliverTo;

  /// No description provided for @deliverTo2.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo2;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryAddresses.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Addresses'**
  String get deliveryAddresses;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @deliveryAssignments.
  ///
  /// In en, this message translates to:
  /// **'Delivery Assignments'**
  String get deliveryAssignments;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @deliveryFeeStillCalculatingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee still calculating, please wait'**
  String get deliveryFeeStillCalculatingPleaseWait;

  /// No description provided for @deliveryGoal.
  ///
  /// In en, this message translates to:
  /// **'Delivery Goal'**
  String get deliveryGoal;

  /// No description provided for @deliveryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instructions'**
  String get deliveryInstructions;

  /// No description provided for @deliveryInstructions2.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY INSTRUCTIONS'**
  String get deliveryInstructions2;

  /// No description provided for @deliveryOptions.
  ///
  /// In en, this message translates to:
  /// **'Delivery Options'**
  String get deliveryOptions;

  /// No description provided for @deliveryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Delivery Preferences'**
  String get deliveryPreferences;

  /// No description provided for @deliveryPreferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Delivery preferences saved!'**
  String get deliveryPreferencesSaved;

  /// No description provided for @deliveryRevenue.
  ///
  /// In en, this message translates to:
  /// **'Delivery Revenue'**
  String get deliveryRevenue;

  /// No description provided for @describeYourBusinessOptional.
  ///
  /// In en, this message translates to:
  /// **'Describe your business (optional)'**
  String get describeYourBusinessOptional;

  /// No description provided for @describeYourBusinessProductsServicesEtc.
  ///
  /// In en, this message translates to:
  /// **'Describe your business (products, services, etc.)'**
  String get describeYourBusinessProductsServicesEtc;

  /// No description provided for @describeYourRelevantExperience.
  ///
  /// In en, this message translates to:
  /// **'Describe your relevant experience'**
  String get describeYourRelevantExperience;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @detectAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Detect automatically'**
  String get detectAutomatically;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @downloadCsvTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download CSV Template'**
  String get downloadCsvTemplate;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get downloadMyData;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @downloadYourOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Download your order history'**
  String get downloadYourOrderHistory;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @driverAgreement.
  ///
  /// In en, this message translates to:
  /// **'Driver Agreement'**
  String get driverAgreement;

  /// No description provided for @driverApplicationPending.
  ///
  /// In en, this message translates to:
  /// **'Driver Application Pending'**
  String get driverApplicationPending;

  /// No description provided for @driverAssign.
  ///
  /// In en, this message translates to:
  /// **'Driver Assign'**
  String get driverAssign;

  /// No description provided for @driverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver Assigned'**
  String get driverAssigned;

  /// No description provided for @driverAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned successfully'**
  String get driverAssignedSuccessfully;

  /// No description provided for @driverLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Driver License Number'**
  String get driverLicenseNumber;

  /// No description provided for @driverMode.
  ///
  /// In en, this message translates to:
  /// **'Driver Mode'**
  String get driverMode;

  /// No description provided for @driverRated.
  ///
  /// In en, this message translates to:
  /// **'Driver Rated'**
  String get driverRated;

  /// No description provided for @driverRoleRemovedUserIsNow.
  ///
  /// In en, this message translates to:
  /// **'Driver role removed. User is now a customer.'**
  String get driverRoleRemovedUserIsNow;

  /// No description provided for @driverUtilization.
  ///
  /// In en, this message translates to:
  /// **'Driver Utilization'**
  String get driverUtilization;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @eGGardenTools.
  ///
  /// In en, this message translates to:
  /// **'e.g. Garden & Tools'**
  String get eGGardenTools;

  /// No description provided for @eGGardenTools2.
  ///
  /// In en, this message translates to:
  /// **'e.g. garden_tools'**
  String get eGGardenTools2;

  /// No description provided for @eGYardBuildPalette.
  ///
  /// In en, this message translates to:
  /// **'e.g. yard, build, palette'**
  String get eGYardBuildPalette;

  /// No description provided for @eGBurgersDrinks.
  ///
  /// In en, this message translates to:
  /// **'e.g., Burgers, Drinks'**
  String get eGBurgersDrinks;

  /// No description provided for @eGBurgersDrinksDesserts.
  ///
  /// In en, this message translates to:
  /// **'e.g., Burgers, Drinks, Desserts'**
  String get eGBurgersDrinksDesserts;

  /// No description provided for @eGFragileItemsKeepUpright.
  ///
  /// In en, this message translates to:
  /// **'e.g., Fragile items, keep upright'**
  String get eGFragileItemsKeepUpright;

  /// No description provided for @eGGateCode1234Second.
  ///
  /// In en, this message translates to:
  /// **'e.g., Gate code: 1234, Second floor...'**
  String get eGGateCode1234Second;

  /// No description provided for @eGMissingDocumentsInvalidInformation.
  ///
  /// In en, this message translates to:
  /// **'e.g., Missing documents, Invalid information...'**
  String get eGMissingDocumentsInvalidInformation;

  /// No description provided for @earningsGoal.
  ///
  /// In en, this message translates to:
  /// **'Earnings Goal'**
  String get earningsGoal;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @editModeOn.
  ///
  /// In en, this message translates to:
  /// **'Edit mode ON'**
  String get editModeOn;

  /// No description provided for @editNow.
  ///
  /// In en, this message translates to:
  /// **'Edit Now'**
  String get editNow;

  /// No description provided for @editOverlaySystem.
  ///
  /// In en, this message translates to:
  /// **'Edit Overlay System'**
  String get editOverlaySystem;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editStore.
  ///
  /// In en, this message translates to:
  /// **'Edit Store'**
  String get editStore;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address *'**
  String get emailAddress;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @emergencyControls.
  ///
  /// In en, this message translates to:
  /// **'Emergency Controls'**
  String get emergencyControls;

  /// No description provided for @emergencyOrderCancel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Order Cancel'**
  String get emergencyOrderCancel;

  /// No description provided for @enableEditMode.
  ///
  /// In en, this message translates to:
  /// **'Enable edit mode'**
  String get enableEditMode;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @enterAddressToCalculate.
  ///
  /// In en, this message translates to:
  /// **'Enter address to calculate'**
  String get enterAddressToCalculate;

  /// No description provided for @enterAlertMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter alert message...'**
  String get enterAlertMessage;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromoCode;

  /// No description provided for @enterYourBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your business address'**
  String get enterYourBusinessAddress;

  /// No description provided for @enterYourBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get enterYourBusinessName;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @enterYourLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your license number'**
  String get enterYourLicenseNumber;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @errorLoadingListings.
  ///
  /// In en, this message translates to:
  /// **'Error loading listings'**
  String get errorLoadingListings;

  /// No description provided for @errorLoadingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Order'**
  String get errorLoadingOrder;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Orders'**
  String get errorLoadingOrders;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportingOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Exporting order history...'**
  String get exportingOrderHistory;

  /// No description provided for @externalUrl.
  ///
  /// In en, this message translates to:
  /// **'External URL'**
  String get externalUrl;

  /// No description provided for @failedToCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel subscription'**
  String get failedToCancelSubscription;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get failedToLoad;

  /// No description provided for @failedToLoadCart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cart'**
  String get failedToLoadCart;

  /// No description provided for @failedToLoadStores.
  ///
  /// In en, this message translates to:
  /// **'Failed to load stores'**
  String get failedToLoadStores;

  /// No description provided for @failedToPauseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to pause subscription'**
  String get failedToPauseSubscription;

  /// No description provided for @failedToResumeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to resume subscription'**
  String get failedToResumeSubscription;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @featuredProduct.
  ///
  /// In en, this message translates to:
  /// **'Featured Product'**
  String get featuredProduct;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterDriversOrders.
  ///
  /// In en, this message translates to:
  /// **'Filter drivers & orders'**
  String get filterDriversOrders;

  /// No description provided for @filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter Options'**
  String get filterOptions;

  /// No description provided for @filterUsers.
  ///
  /// In en, this message translates to:
  /// **'Filter Users'**
  String get filterUsers;

  /// No description provided for @fitAllMarkers.
  ///
  /// In en, this message translates to:
  /// **'Fit all markers'**
  String get fitAllMarkers;

  /// No description provided for @fixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get fixed;

  /// No description provided for @fixedBanner.
  ///
  /// In en, this message translates to:
  /// **'Fixed Banner'**
  String get fixedBanner;

  /// No description provided for @floorAptBuildingOptional.
  ///
  /// In en, this message translates to:
  /// **'Floor, apt, building (optional)'**
  String get floorAptBuildingOptional;

  /// No description provided for @formatContent.
  ///
  /// In en, this message translates to:
  /// **'Format & Content'**
  String get formatContent;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get fullAddress;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @fullName2.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullName2;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @galleryOrCamera.
  ///
  /// In en, this message translates to:
  /// **'Gallery or Camera'**
  String get galleryOrCamera;

  /// No description provided for @globalHome.
  ///
  /// In en, this message translates to:
  /// **'Global Home'**
  String get globalHome;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @goToMainApp.
  ///
  /// In en, this message translates to:
  /// **'Go to Main App'**
  String get goToMainApp;

  /// No description provided for @hasSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Has subcategories'**
  String get hasSubcategories;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpTips.
  ///
  /// In en, this message translates to:
  /// **'Help & Tips'**
  String get helpTips;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @iconName.
  ///
  /// In en, this message translates to:
  /// **'Icon Name'**
  String get iconName;

  /// No description provided for @idLowercaseNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'ID (lowercase, no spaces)'**
  String get idLowercaseNoSpaces;

  /// No description provided for @idAndNameAreRequired.
  ///
  /// In en, this message translates to:
  /// **'ID and Name are required'**
  String get idAndNameAreRequired;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @imageUpload.
  ///
  /// In en, this message translates to:
  /// **'Image Upload'**
  String get imageUpload;

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get importPreview;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Balance'**
  String get insufficientBalance;

  /// No description provided for @inviteFriendsToKjDelivery.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to KJ Delivery'**
  String get inviteFriendsToKjDelivery;

  /// No description provided for @inviteLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied to clipboard!'**
  String get inviteLinkCopiedToClipboard;

  /// No description provided for @itemRemovedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Item removed from cart'**
  String get itemRemovedFromCart;

  /// No description provided for @itemsAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Items added to cart'**
  String get itemsAddedToCart;

  /// No description provided for @itemsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Items Unavailable'**
  String get itemsUnavailable;

  /// No description provided for @kjDeliveryStore.
  ///
  /// In en, this message translates to:
  /// **'KJ Delivery Store'**
  String get kjDeliveryStore;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @learnWhatAiMateCanDo.
  ///
  /// In en, this message translates to:
  /// **'Learn what AI Mate can do'**
  String get learnWhatAiMateCanDo;

  /// No description provided for @leaveACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Leave a comment (optional)'**
  String get leaveACommentOptional;

  /// No description provided for @leaveEmptyForDefaultCalculation.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for default calculation'**
  String get leaveEmptyForDefaultCalculation;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @linkTarget.
  ///
  /// In en, this message translates to:
  /// **'Link Target'**
  String get linkTarget;

  /// No description provided for @linkType.
  ///
  /// In en, this message translates to:
  /// **'Link Type'**
  String get linkType;

  /// No description provided for @listingApproved.
  ///
  /// In en, this message translates to:
  /// **'Listing approved'**
  String get listingApproved;

  /// No description provided for @listingCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Listing created successfully!'**
  String get listingCreatedSuccessfully;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logisticsManagement.
  ///
  /// In en, this message translates to:
  /// **'Logistics Management'**
  String get logisticsManagement;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @makeModelYearAndLicensePlate.
  ///
  /// In en, this message translates to:
  /// **'Make, model, year, and license plate'**
  String get makeModelYearAndLicensePlate;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @manageProduct.
  ///
  /// In en, this message translates to:
  /// **'Manage Product'**
  String get manageProduct;

  /// No description provided for @manageSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Manage subcategories'**
  String get manageSubcategories;

  /// No description provided for @manageSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscriptions'**
  String get manageSubscriptions;

  /// No description provided for @manageYourStoresProductsOrders.
  ///
  /// In en, this message translates to:
  /// **'Manage your stores, products & orders'**
  String get manageYourStoresProductsOrders;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @markAsSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as Sold'**
  String get markAsSold;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get markDelivered;

  /// No description provided for @markPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark Picked Up'**
  String get markPickedUp;

  /// No description provided for @markReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Mark Ready for Pickup'**
  String get markReadyForPickup;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @marketingTools.
  ///
  /// In en, this message translates to:
  /// **'Marketing Tools'**
  String get marketingTools;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @marketplaceAdUpdated.
  ///
  /// In en, this message translates to:
  /// **'Marketplace ad updated!'**
  String get marketplaceAdUpdated;

  /// No description provided for @marketplaceImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Marketplace image updated!'**
  String get marketplaceImageUpdated;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @maxQuantityReached.
  ///
  /// In en, this message translates to:
  /// **'Max quantity reached'**
  String get maxQuantityReached;

  /// No description provided for @mealPlanning.
  ///
  /// In en, this message translates to:
  /// **'Meal Planning'**
  String get mealPlanning;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @merchantAgreement.
  ///
  /// In en, this message translates to:
  /// **'Merchant Agreement'**
  String get merchantAgreement;

  /// No description provided for @merchantApplicationPending.
  ///
  /// In en, this message translates to:
  /// **'Merchant Application Pending'**
  String get merchantApplicationPending;

  /// No description provided for @merchantDashboard.
  ///
  /// In en, this message translates to:
  /// **'Merchant Dashboard'**
  String get merchantDashboard;

  /// No description provided for @merchantReview.
  ///
  /// In en, this message translates to:
  /// **'Merchant Review'**
  String get merchantReview;

  /// No description provided for @merchantRoleRemovedUserIsNow.
  ///
  /// In en, this message translates to:
  /// **'Merchant role removed. User is now a customer.'**
  String get merchantRoleRemovedUserIsNow;

  /// No description provided for @merchants.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get merchants;

  /// No description provided for @messageRider.
  ///
  /// In en, this message translates to:
  /// **'Message rider'**
  String get messageRider;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @microphonePermissionIsRequiredForVoice.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice input'**
  String get microphonePermissionIsRequiredForVoice;

  /// No description provided for @microphonePermissionIsRequiredForVoice2.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for voice search'**
  String get microphonePermissionIsRequiredForVoice2;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyEarningsTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Earnings Trend'**
  String get monthlyEarningsTrend;

  /// No description provided for @monthlySummary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Summary'**
  String get monthlySummary;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @myAds.
  ///
  /// In en, this message translates to:
  /// **'My Ads'**
  String get myAds;

  /// No description provided for @myStore.
  ///
  /// In en, this message translates to:
  /// **'My Store'**
  String get myStore;

  /// No description provided for @myStores.
  ///
  /// In en, this message translates to:
  /// **'My Stores'**
  String get myStores;

  /// No description provided for @nameAndPriceAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and price are required'**
  String get nameAndPriceAreRequired;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @newDeliveryRequest.
  ///
  /// In en, this message translates to:
  /// **'New Delivery Request'**
  String get newDeliveryRequest;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order!'**
  String get newOrder;

  /// No description provided for @newOrdersWillAppearHereWhen.
  ///
  /// In en, this message translates to:
  /// **'New orders will appear here when assigned to you'**
  String get newOrdersWillAppearHereWhen;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newStore.
  ///
  /// In en, this message translates to:
  /// **'New Store'**
  String get newStore;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noActiveDriversOnlineCannotAssign.
  ///
  /// In en, this message translates to:
  /// **'No active drivers online — cannot assign order'**
  String get noActiveDriversOnlineCannotAssign;

  /// No description provided for @noAssignedOrders.
  ///
  /// In en, this message translates to:
  /// **'No Assigned Orders'**
  String get noAssignedOrders;

  /// No description provided for @noCategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get noCategoriesFound;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noCategoriesYet2.
  ///
  /// In en, this message translates to:
  /// **'No Categories Yet'**
  String get noCategoriesYet2;

  /// No description provided for @noCategoryDirectToStore.
  ///
  /// In en, this message translates to:
  /// **'No category (direct to store)'**
  String get noCategoryDirectToStore;

  /// No description provided for @noCustomerDataYet.
  ///
  /// In en, this message translates to:
  /// **'No customer data yet'**
  String get noCustomerDataYet;

  /// No description provided for @noDeliveryFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No delivery favorites yet'**
  String get noDeliveryFavoritesYet;

  /// No description provided for @noDriverProfileFoundApplyAs.
  ///
  /// In en, this message translates to:
  /// **'No driver profile found. Apply as a driver first.'**
  String get noDriverProfileFoundApplyAs;

  /// No description provided for @noEarningsDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No earnings data available'**
  String get noEarningsDataAvailable;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @noItemsFoundInThisOrder.
  ///
  /// In en, this message translates to:
  /// **'No items found in this order'**
  String get noItemsFoundInThisOrder;

  /// No description provided for @noListingsFound.
  ///
  /// In en, this message translates to:
  /// **'No listings found'**
  String get noListingsFound;

  /// No description provided for @noMarketplaceFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No marketplace favorites yet'**
  String get noMarketplaceFavoritesYet;

  /// No description provided for @noMerchantAccount.
  ///
  /// In en, this message translates to:
  /// **'No Merchant Account'**
  String get noMerchantAccount;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrders;

  /// No description provided for @noOrdersToExport.
  ///
  /// In en, this message translates to:
  /// **'No orders to export'**
  String get noOrdersToExport;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @noOrdersYet2.
  ///
  /// In en, this message translates to:
  /// **'No Orders Yet'**
  String get noOrdersYet2;

  /// No description provided for @noPendingDriverApplications.
  ///
  /// In en, this message translates to:
  /// **'No Pending Driver Applications'**
  String get noPendingDriverApplications;

  /// No description provided for @noPendingMerchantApplications.
  ///
  /// In en, this message translates to:
  /// **'No Pending Merchant Applications'**
  String get noPendingMerchantApplications;

  /// No description provided for @noPhoneNumberAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available'**
  String get noPhoneNumberAvailable;

  /// No description provided for @noProductRowsFound.
  ///
  /// In en, this message translates to:
  /// **'No product rows found.'**
  String get noProductRowsFound;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No Products Yet'**
  String get noProductsYet;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No Reviews Yet'**
  String get noReviewsYet;

  /// No description provided for @noSalesDataYetForThe.
  ///
  /// In en, this message translates to:
  /// **'No sales data yet for the last 7 days'**
  String get noSalesDataYetForThe;

  /// No description provided for @noSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'No Saved Addresses'**
  String get noSavedAddresses;

  /// No description provided for @noStoresFound.
  ///
  /// In en, this message translates to:
  /// **'No stores found'**
  String get noStoresFound;

  /// No description provided for @noStoresInThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No stores in this category'**
  String get noStoresInThisCategory;

  /// No description provided for @noStoresYet.
  ///
  /// In en, this message translates to:
  /// **'No Stores Yet'**
  String get noStoresYet;

  /// No description provided for @noSubcategoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No subcategories found'**
  String get noSubcategoriesFound;

  /// No description provided for @noSubcategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No subcategories yet'**
  String get noSubcategoriesYet;

  /// No description provided for @noSubscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'No subscription plans'**
  String get noSubscriptionPlans;

  /// No description provided for @noUnassignedOrdersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No unassigned orders available'**
  String get noUnassignedOrdersAvailable;

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifyAllCustomersAboutThisAd.
  ///
  /// In en, this message translates to:
  /// **'Notify all customers about this ad'**
  String get notifyAllCustomersAboutThisAd;

  /// No description provided for @nutritionFacts.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Facts'**
  String get nutritionFacts;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @onlineDrivers.
  ///
  /// In en, this message translates to:
  /// **'Online Drivers'**
  String get onlineDrivers;

  /// No description provided for @openAdminControls.
  ///
  /// In en, this message translates to:
  /// **'Open admin controls'**
  String get openAdminControls;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @operatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAccepted;

  /// No description provided for @orderAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully!'**
  String get orderAcceptedSuccessfully;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderExpired.
  ///
  /// In en, this message translates to:
  /// **'Order expired'**
  String get orderExpired;

  /// No description provided for @orderManagement.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order Not Found'**
  String get orderNotFound;

  /// No description provided for @orderNotifications.
  ///
  /// In en, this message translates to:
  /// **'Order Notifications'**
  String get orderNotifications;

  /// No description provided for @orderOperations.
  ///
  /// In en, this message translates to:
  /// **'Order Operations'**
  String get orderOperations;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @orderProgress.
  ///
  /// In en, this message translates to:
  /// **'Order Progress'**
  String get orderProgress;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @orderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order saved!'**
  String get orderSaved;

  /// No description provided for @orderStatusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Order Status Breakdown'**
  String get orderStatusBreakdown;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @orderTracking.
  ///
  /// In en, this message translates to:
  /// **'Order Tracking'**
  String get orderTracking;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @ordersWillAppearHereWhenCustomers.
  ///
  /// In en, this message translates to:
  /// **'Orders will appear here when customers place them'**
  String get ordersWillAppearHereWhenCustomers;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original Price: '**
  String get originalPrice;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMustBeAtLeast6.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pauseSubscription.
  ///
  /// In en, this message translates to:
  /// **'Pause Subscription'**
  String get pauseSubscription;

  /// No description provided for @payTheDriverWhenYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Pay the driver when your order arrives. Please have the exact amount ready.'**
  String get payTheDriverWhenYourOrder;

  /// No description provided for @payWhenYourOrderArrives.
  ///
  /// In en, this message translates to:
  /// **'Pay when your order arrives'**
  String get payWhenYourOrderArrives;

  /// No description provided for @paymentBilling.
  ///
  /// In en, this message translates to:
  /// **'Payment & Billing'**
  String get paymentBilling;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @peakOrderHours.
  ///
  /// In en, this message translates to:
  /// **'Peak Order Hours'**
  String get peakOrderHours;

  /// No description provided for @pendingApprovals.
  ///
  /// In en, this message translates to:
  /// **'Pending Approvals'**
  String get pendingApprovals;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @performanceDashboard.
  ///
  /// In en, this message translates to:
  /// **'Performance Dashboard'**
  String get performanceDashboard;

  /// No description provided for @performanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get performanceMetrics;

  /// No description provided for @permanentlyDeleteYourAccountAndData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get permanentlyDeleteYourAccountAndData;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumber2.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumber2;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @planDeleted.
  ///
  /// In en, this message translates to:
  /// **'Plan deleted'**
  String get planDeleted;

  /// No description provided for @planMealsGetGroceryListsAdd.
  ///
  /// In en, this message translates to:
  /// **'Plan meals, get grocery lists & add to cart'**
  String get planMealsGetGroceryListsAdd;

  /// No description provided for @planName.
  ///
  /// In en, this message translates to:
  /// **'Plan Name *'**
  String get planName;

  /// No description provided for @planType.
  ///
  /// In en, this message translates to:
  /// **'Plan Type *'**
  String get planType;

  /// No description provided for @pleaseAcceptTheTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get pleaseAcceptTheTermsAndConditions;

  /// No description provided for @pleaseAddAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one image'**
  String get pleaseAddAtLeastOneImage;

  /// No description provided for @pleaseCompleteEmailVerificationToAccess.
  ///
  /// In en, this message translates to:
  /// **'Please complete email verification to access the app'**
  String get pleaseCompleteEmailVerificationToAccess;

  /// No description provided for @pleaseCompletePhoneVerificationToAccess.
  ///
  /// In en, this message translates to:
  /// **'Please complete phone verification to access the app'**
  String get pleaseCompletePhoneVerificationToAccess;

  /// No description provided for @pleaseEnterADeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a delivery address'**
  String get pleaseEnterADeliveryAddress;

  /// No description provided for @pleaseEnterAMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a message'**
  String get pleaseEnterAMessage;

  /// No description provided for @pleaseEnterAPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get pleaseEnterAPhoneNumber;

  /// No description provided for @pleaseLogInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get pleaseLogInToContinue;

  /// No description provided for @pleaseLoginToContactSeller.
  ///
  /// In en, this message translates to:
  /// **'Please login to contact seller'**
  String get pleaseLoginToContactSeller;

  /// No description provided for @pleaseProvideAReasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection (optional):'**
  String get pleaseProvideAReasonForRejection;

  /// No description provided for @pleaseSelectACategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectACategory;

  /// No description provided for @pleaseSelectAStore.
  ///
  /// In en, this message translates to:
  /// **'Please select a store'**
  String get pleaseSelectAStore;

  /// No description provided for @pleaseSelectDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select date and time'**
  String get pleaseSelectDateAndTime;

  /// No description provided for @pleaseSignInToCreateA.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to create a listing'**
  String get pleaseSignInToCreateA;

  /// No description provided for @pleaseTypeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please type DELETE to confirm'**
  String get pleaseTypeDeleteToConfirm;

  /// No description provided for @popularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get popularCategories;

  /// No description provided for @postListing.
  ///
  /// In en, this message translates to:
  /// **'Post Listing'**
  String get postListing;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved!'**
  String get preferencesSaved;

  /// No description provided for @preferredDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Delivery Time'**
  String get preferredDeliveryTime;

  /// No description provided for @prepTimeMin.
  ///
  /// In en, this message translates to:
  /// **'Prep Time (min)'**
  String get prepTimeMin;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @price2.
  ///
  /// In en, this message translates to:
  /// **'Price *'**
  String get price2;

  /// No description provided for @priceIsNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Price is negotiable'**
  String get priceIsNegotiable;

  /// No description provided for @priceIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceIsRequired;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @primaryShowOnHomeRow.
  ///
  /// In en, this message translates to:
  /// **'Primary (show on home row)'**
  String get primaryShowOnHomeRow;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @priorityOrders.
  ///
  /// In en, this message translates to:
  /// **'Priority Orders'**
  String get priorityOrders;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccessfully;

  /// No description provided for @productCreated.
  ///
  /// In en, this message translates to:
  /// **'Product created'**
  String get productCreated;

  /// No description provided for @productCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product created successfully!'**
  String get productCreatedSuccessfully;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeleted;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productName;

  /// No description provided for @productNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameIsRequired;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @productNotFoundTrySearchingManually.
  ///
  /// In en, this message translates to:
  /// **'Product not found. Try searching manually.'**
  String get productNotFoundTrySearchingManually;

  /// No description provided for @productOverview.
  ///
  /// In en, this message translates to:
  /// **'Product Overview'**
  String get productOverview;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profilePhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed'**
  String get profilePhotoRemoved;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @provideAReasonForRejection.
  ///
  /// In en, this message translates to:
  /// **'Provide a reason for rejection'**
  String get provideAReasonForRejection;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @rateOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate Order'**
  String get rateOrder;

  /// No description provided for @rateService.
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get rateService;

  /// No description provided for @rateThisStore.
  ///
  /// In en, this message translates to:
  /// **'Rate This Store'**
  String get rateThisStore;

  /// No description provided for @rateYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Driver'**
  String get rateYourDriver;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted'**
  String get ratingSubmitted;

  /// No description provided for @reapply.
  ///
  /// In en, this message translates to:
  /// **'Reapply'**
  String get reapply;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshStores.
  ///
  /// In en, this message translates to:
  /// **'Refresh stores'**
  String get refreshStores;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectDriver.
  ///
  /// In en, this message translates to:
  /// **'Reject Driver'**
  String get rejectDriver;

  /// No description provided for @rejectMerchant.
  ///
  /// In en, this message translates to:
  /// **'Reject Merchant'**
  String get rejectMerchant;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequest;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeAddress.
  ///
  /// In en, this message translates to:
  /// **'Remove Address'**
  String get removeAddress;

  /// No description provided for @removeDriver.
  ///
  /// In en, this message translates to:
  /// **'Remove Driver'**
  String get removeDriver;

  /// No description provided for @removeDriverRole.
  ///
  /// In en, this message translates to:
  /// **'Remove Driver Role'**
  String get removeDriverRole;

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove Favorite'**
  String get removeFavorite;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeMerchant.
  ///
  /// In en, this message translates to:
  /// **'Remove Merchant'**
  String get removeMerchant;

  /// No description provided for @removeMerchantRole.
  ///
  /// In en, this message translates to:
  /// **'Remove Merchant Role'**
  String get removeMerchantRole;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @removeSale.
  ///
  /// In en, this message translates to:
  /// **'Remove Sale'**
  String get removeSale;

  /// No description provided for @removedFromCart.
  ///
  /// In en, this message translates to:
  /// **'Removed from cart'**
  String get removedFromCart;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @reorderItems.
  ///
  /// In en, this message translates to:
  /// **'Reorder Items'**
  String get reorderItems;

  /// No description provided for @repeatCustomers.
  ///
  /// In en, this message translates to:
  /// **'Repeat Customers'**
  String get repeatCustomers;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @requestACopyOfYourPersonal.
  ///
  /// In en, this message translates to:
  /// **'Request a copy of your personal data'**
  String get requestACopyOfYourPersonal;

  /// No description provided for @requestApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request approved successfully'**
  String get requestApprovedSuccessfully;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @requiresImmediateAttention.
  ///
  /// In en, this message translates to:
  /// **'Requires immediate attention'**
  String get requiresImmediateAttention;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetReSeed.
  ///
  /// In en, this message translates to:
  /// **'Reset & Re-seed'**
  String get resetReSeed;

  /// No description provided for @resetDemoData.
  ///
  /// In en, this message translates to:
  /// **'Reset Demo Data?'**
  String get resetDemoData;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset Password via Email'**
  String get resetPasswordViaEmail;

  /// No description provided for @resumeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Resume Subscription'**
  String get resumeSubscription;

  /// No description provided for @resumeYourPausedSubscription.
  ///
  /// In en, this message translates to:
  /// **'Resume your paused subscription'**
  String get resumeYourPausedSubscription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @revenueBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Revenue Breakdown'**
  String get revenueBreakdown;

  /// No description provided for @revenueSummary.
  ///
  /// In en, this message translates to:
  /// **'Revenue Summary'**
  String get revenueSummary;

  /// No description provided for @reviewOptional.
  ///
  /// In en, this message translates to:
  /// **'Review (Optional)'**
  String get reviewOptional;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @ringDoorbellLeaveAtDoorEtc.
  ///
  /// In en, this message translates to:
  /// **'Ring doorbell, leave at door, etc.'**
  String get ringDoorbellLeaveAtDoorEtc;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleRequests.
  ///
  /// In en, this message translates to:
  /// **'Role Requests'**
  String get roleRequests;

  /// No description provided for @rotating.
  ///
  /// In en, this message translates to:
  /// **'Rotating'**
  String get rotating;

  /// No description provided for @rotatingBanner.
  ///
  /// In en, this message translates to:
  /// **'Rotating Banner'**
  String get rotatingBanner;

  /// No description provided for @rpcResetComplete.
  ///
  /// In en, this message translates to:
  /// **'RPC Reset Complete'**
  String get rpcResetComplete;

  /// No description provided for @salePricing.
  ///
  /// In en, this message translates to:
  /// **'Sale / Pricing'**
  String get salePricing;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @salesCharts.
  ///
  /// In en, this message translates to:
  /// **'Sales Charts'**
  String get salesCharts;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveAdBanner.
  ///
  /// In en, this message translates to:
  /// **'Save Ad Banner'**
  String get saveAdBanner;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saveDesign.
  ///
  /// In en, this message translates to:
  /// **'Save Design'**
  String get saveDesign;

  /// No description provided for @saveOrder.
  ///
  /// In en, this message translates to:
  /// **'Save Order'**
  String get saveOrder;

  /// No description provided for @savePreferences.
  ///
  /// In en, this message translates to:
  /// **'Save Preferences'**
  String get savePreferences;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @scheduleOptional.
  ///
  /// In en, this message translates to:
  /// **'Schedule (Optional)'**
  String get scheduleOptional;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchByNameEmailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or phone'**
  String get searchByNameEmailOrPhone;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get searchCategories;

  /// No description provided for @searchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search category'**
  String get searchCategory;

  /// No description provided for @searchCityOrArea.
  ///
  /// In en, this message translates to:
  /// **'Search city or area...'**
  String get searchCityOrArea;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @searchListings.
  ///
  /// In en, this message translates to:
  /// **'Search listings...'**
  String get searchListings;

  /// No description provided for @searchOrTapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Search or tap to select location'**
  String get searchOrTapToSelectLocation;

  /// No description provided for @searchOrdersProductsOrDates.
  ///
  /// In en, this message translates to:
  /// **'Search orders, products, or dates...'**
  String get searchOrdersProductsOrDates;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProducts;

  /// No description provided for @searchStoreByName.
  ///
  /// In en, this message translates to:
  /// **'Search store by name'**
  String get searchStoreByName;

  /// No description provided for @searchStores.
  ///
  /// In en, this message translates to:
  /// **'Search stores...'**
  String get searchStores;

  /// No description provided for @searchSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Search subcategory'**
  String get searchSubcategory;

  /// No description provided for @search2.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search2;

  /// No description provided for @seedingComplete.
  ///
  /// In en, this message translates to:
  /// **'Seeding Complete'**
  String get seedingComplete;

  /// No description provided for @selectACategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectACategory;

  /// No description provided for @selectAdFormat.
  ///
  /// In en, this message translates to:
  /// **'Select Ad Format'**
  String get selectAdFormat;

  /// No description provided for @selectBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Select business type'**
  String get selectBusinessType;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select Driver'**
  String get selectDriver;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @sellerHasNoPhoneNumberOn.
  ///
  /// In en, this message translates to:
  /// **'Seller has no phone number on file'**
  String get sellerHasNoPhoneNumberOn;

  /// No description provided for @sellerHasNoWhatsappNumberOn.
  ///
  /// In en, this message translates to:
  /// **'Seller has no WhatsApp number on file'**
  String get sellerHasNoWhatsappNumberOn;

  /// No description provided for @sendAPasswordResetLinkTo.
  ///
  /// In en, this message translates to:
  /// **'Send a password reset link to your email'**
  String get sendAPasswordResetLinkTo;

  /// No description provided for @sendAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Alert'**
  String get sendAlert;

  /// No description provided for @sendPushNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Push Notification'**
  String get sendPushNotification;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @sendSystemAlert.
  ///
  /// In en, this message translates to:
  /// **'Send System Alert'**
  String get sendSystemAlert;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @serviceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Service not found'**
  String get serviceNotFound;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @setAsDefault2.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault2;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @shareOrder.
  ///
  /// In en, this message translates to:
  /// **'Share Order'**
  String get shareOrder;

  /// No description provided for @shareProduct.
  ///
  /// In en, this message translates to:
  /// **'Share Product'**
  String get shareProduct;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @shoppingCart.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart'**
  String get shoppingCart;

  /// No description provided for @shoppingCart2.
  ///
  /// In en, this message translates to:
  /// **'Shopping Cart'**
  String get shoppingCart2;

  /// No description provided for @showAllLebanon.
  ///
  /// In en, this message translates to:
  /// **'Show All Lebanon'**
  String get showAllLebanon;

  /// No description provided for @showAllLocations.
  ///
  /// In en, this message translates to:
  /// **'Show all locations'**
  String get showAllLocations;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get showInactive;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutAllOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Sign Out All Other Devices'**
  String get signOutAllOtherDevices;

  /// No description provided for @signOutOfYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfYourAccount;

  /// No description provided for @signOutOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Other Devices'**
  String get signOutOtherDevices;

  /// No description provided for @signOutOthers.
  ///
  /// In en, this message translates to:
  /// **'Sign Out Others'**
  String get signOutOthers;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signedOutOfAllOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Signed out of all other devices'**
  String get signedOutOfAllOtherDevices;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @someItemsInYourCartAre.
  ///
  /// In en, this message translates to:
  /// **'Some items in your cart are currently unavailable. Please remove them first.'**
  String get someItemsInYourCartAre;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @specialHandling.
  ///
  /// In en, this message translates to:
  /// **'Special Handling'**
  String get specialHandling;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @specialRequestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Special Requests (Optional)'**
  String get specialRequestsOptional;

  /// No description provided for @specificCategory.
  ///
  /// In en, this message translates to:
  /// **'Specific Category'**
  String get specificCategory;

  /// No description provided for @specificProduct.
  ///
  /// In en, this message translates to:
  /// **'Specific Product'**
  String get specificProduct;

  /// No description provided for @specificStore.
  ///
  /// In en, this message translates to:
  /// **'Specific Store'**
  String get specificStore;

  /// No description provided for @spendingSummary.
  ///
  /// In en, this message translates to:
  /// **'Spending Summary'**
  String get spendingSummary;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @startAFreshChat.
  ///
  /// In en, this message translates to:
  /// **'Start a fresh chat'**
  String get startAFreshChat;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startShopping.
  ///
  /// In en, this message translates to:
  /// **'Start Shopping'**
  String get startShopping;

  /// No description provided for @startVoiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Start Voice Search'**
  String get startVoiceSearch;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @stockQty.
  ///
  /// In en, this message translates to:
  /// **'Stock Qty'**
  String get stockQty;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @storeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Store created successfully!'**
  String get storeCreatedSuccessfully;

  /// No description provided for @storeDesignUpdated.
  ///
  /// In en, this message translates to:
  /// **'Store design updated!'**
  String get storeDesignUpdated;

  /// No description provided for @storeInformation.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInformation;

  /// No description provided for @storeLocationDeliveryZone.
  ///
  /// In en, this message translates to:
  /// **'Store Location & Delivery Zone'**
  String get storeLocationDeliveryZone;

  /// No description provided for @storeManagement.
  ///
  /// In en, this message translates to:
  /// **'Store Management'**
  String get storeManagement;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name *'**
  String get storeName;

  /// No description provided for @storeNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Store name is required'**
  String get storeNameIsRequired;

  /// No description provided for @storeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Store Not Found'**
  String get storeNotFound;

  /// No description provided for @storeSettings.
  ///
  /// In en, this message translates to:
  /// **'Store Settings'**
  String get storeSettings;

  /// No description provided for @storeSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Store settings saved!'**
  String get storeSettingsSaved;

  /// No description provided for @storeType.
  ///
  /// In en, this message translates to:
  /// **'Store Type *'**
  String get storeType;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @storesAssignedToThisCategoryWill.
  ///
  /// In en, this message translates to:
  /// **'Stores assigned to this category will appear here.'**
  String get storesAssignedToThisCategoryWill;

  /// No description provided for @storesWillAppearHereOnceCreated.
  ///
  /// In en, this message translates to:
  /// **'Stores will appear here once created'**
  String get storesWillAppearHereOnceCreated;

  /// No description provided for @subcategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Subcategory (optional)'**
  String get subcategoryOptional;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionPaused.
  ///
  /// In en, this message translates to:
  /// **'Subscription paused'**
  String get subscriptionPaused;

  /// No description provided for @subscriptionResumed.
  ///
  /// In en, this message translates to:
  /// **'Subscription resumed'**
  String get subscriptionResumed;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @systemAlert.
  ///
  /// In en, this message translates to:
  /// **'System Alert'**
  String get systemAlert;

  /// No description provided for @systemAlertSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'System alert sent successfully!'**
  String get systemAlertSentSuccessfully;

  /// No description provided for @systemOperational.
  ///
  /// In en, this message translates to:
  /// **'System Operational'**
  String get systemOperational;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @tapToCreateYourFirstPlan.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first plan'**
  String get tapToCreateYourFirstPlan;

  /// No description provided for @tapOnTheMapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap on the map to select a location'**
  String get tapOnTheMapToSelect;

  /// No description provided for @tapToAddImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get tapToAddImage;

  /// No description provided for @tapToChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to change image'**
  String get tapToChangeImage;

  /// No description provided for @tapToPickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick on map'**
  String get tapToPickOnMap;

  /// No description provided for @tapToSelectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Tap to select from gallery'**
  String get tapToSelectFromGallery;

  /// No description provided for @targetType.
  ///
  /// In en, this message translates to:
  /// **'Target Type'**
  String get targetType;

  /// No description provided for @targetingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Targeting & Schedule'**
  String get targetingSchedule;

  /// No description provided for @targetingRules.
  ///
  /// In en, this message translates to:
  /// **'Targeting Rules'**
  String get targetingRules;

  /// No description provided for @taxesAndDeliveryFeeCalculatedAt.
  ///
  /// In en, this message translates to:
  /// **'Taxes and delivery fee calculated at checkout'**
  String get taxesAndDeliveryFeeCalculatedAt;

  /// No description provided for @templateSavedToTempFolder.
  ///
  /// In en, this message translates to:
  /// **'Template saved to temp folder!'**
  String get templateSavedToTempFolder;

  /// No description provided for @temporarilyPauseYourSubscription.
  ///
  /// In en, this message translates to:
  /// **'Temporarily pause your subscription'**
  String get temporarilyPauseYourSubscription;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @testCustomerView.
  ///
  /// In en, this message translates to:
  /// **'Test customer view'**
  String get testCustomerView;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @thisActionIsPermanentAndCannot.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data, orders, and preferences will be deleted.'**
  String get thisActionIsPermanentAndCannot;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisProductIsCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This product is currently unavailable'**
  String get thisProductIsCurrentlyUnavailable;

  /// No description provided for @thisWillPermanentlyRemoveTheCategory.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the category. Continue?'**
  String get thisWillPermanentlyRemoveTheCategory;

  /// No description provided for @thisWillSignYouOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'This will sign you out everywhere except here'**
  String get thisWillSignYouOutEverywhere;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @tipsToGetReviews.
  ///
  /// In en, this message translates to:
  /// **'Tips to Get Reviews'**
  String get tipsToGetReviews;

  /// No description provided for @titleName.
  ///
  /// In en, this message translates to:
  /// **'Title / Name'**
  String get titleName;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @todaySEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todaySEarnings;

  /// No description provided for @todaySOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todaySOrders;

  /// No description provided for @todaySRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todaySRevenue;

  /// No description provided for @toggleOrderQueue.
  ///
  /// In en, this message translates to:
  /// **'Toggle Order Queue'**
  String get toggleOrderQueue;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Total Deliveries'**
  String get totalDeliveries;

  /// No description provided for @totalDeliveryRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Delivery Revenue'**
  String get totalDeliveryRevenue;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalStores.
  ///
  /// In en, this message translates to:
  /// **'Total Stores'**
  String get totalStores;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @trackOnGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Track on Google Maps'**
  String get trackOnGoogleMaps;

  /// No description provided for @tryADifferentCategoryOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different category or search term'**
  String get tryADifferentCategoryOrSearch;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @unableToStartVoiceRecordingPlease.
  ///
  /// In en, this message translates to:
  /// **'Unable to start voice recording. Please try again.'**
  String get unableToStartVoiceRecordingPlease;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @uniqueCustomers.
  ///
  /// In en, this message translates to:
  /// **'Unique Customers'**
  String get uniqueCustomers;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @updateYourAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get updateYourAccountPassword;

  /// No description provided for @updateYourPersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updateYourPersonalInformation;

  /// No description provided for @uploadAdImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Ad Image'**
  String get uploadAdImage;

  /// No description provided for @uploadingMarketplaceImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading marketplace image...'**
  String get uploadingMarketplaceImage;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User profile'**
  String get userProfile;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @vehiclePlateNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Plate Number'**
  String get vehiclePlateNumber;

  /// No description provided for @verificationCodeSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your email'**
  String get verificationCodeSentToYourEmail;

  /// No description provided for @verificationCodeSentToYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to your phone'**
  String get verificationCodeSentToYourPhone;

  /// No description provided for @viewCancelActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'View & cancel active orders'**
  String get viewCancelActiveOrders;

  /// No description provided for @viewAllAds.
  ///
  /// In en, this message translates to:
  /// **'View all ads'**
  String get viewAllAds;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View Analytics'**
  String get viewAnalytics;

  /// No description provided for @viewAndManageYourListings.
  ///
  /// In en, this message translates to:
  /// **'View and manage your listings'**
  String get viewAndManageYourListings;

  /// No description provided for @viewAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'View as Customer'**
  String get viewAsCustomer;

  /// No description provided for @viewAssignedOrdersStartDeliveries.
  ///
  /// In en, this message translates to:
  /// **'View assigned orders & start deliveries'**
  String get viewAssignedOrdersStartDeliveries;

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'View Cart'**
  String get viewCart;

  /// No description provided for @viewCustomerHome.
  ///
  /// In en, this message translates to:
  /// **'View Customer Home'**
  String get viewCustomerHome;

  /// No description provided for @viewMarketplace.
  ///
  /// In en, this message translates to:
  /// **'View Marketplace'**
  String get viewMarketplace;

  /// No description provided for @viewOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'View Order History'**
  String get viewOrderHistory;

  /// No description provided for @viewSimilar.
  ///
  /// In en, this message translates to:
  /// **'View Similar'**
  String get viewSimilar;

  /// No description provided for @visibleToUsers.
  ///
  /// In en, this message translates to:
  /// **'Visible to users'**
  String get visibleToUsers;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @weeklyEarningsTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Earnings Trend'**
  String get weeklyEarningsTrend;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly Summary'**
  String get weeklySummary;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @youAlreadyRatedThisDelivery.
  ///
  /// In en, this message translates to:
  /// **'You already rated this delivery'**
  String get youAlreadyRatedThisDelivery;

  /// No description provided for @youAlreadyRatedThisStore.
  ///
  /// In en, this message translates to:
  /// **'You already rated this store'**
  String get youAlreadyRatedThisStore;

  /// No description provided for @youCanOnlyRateDeliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'You can only rate delivered orders'**
  String get youCanOnlyRateDeliveredOrders;

  /// No description provided for @youCannotMessageYourOwnListing.
  ///
  /// In en, this message translates to:
  /// **'You cannot message your own listing'**
  String get youCannotMessageYourOwnListing;

  /// No description provided for @youDoNotHaveAdminPrivileges.
  ///
  /// In en, this message translates to:
  /// **'You do not have admin privileges.'**
  String get youDoNotHaveAdminPrivileges;

  /// No description provided for @youDoNotHavePermissionTo.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page'**
  String get youDoNotHavePermissionTo;

  /// No description provided for @youMightAlsoLike.
  ///
  /// In en, this message translates to:
  /// **'You might also like'**
  String get youMightAlsoLike;

  /// No description provided for @youMustBeLoggedInTo.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to upload images'**
  String get youMustBeLoggedInTo;

  /// No description provided for @youNeedToApplyAsA.
  ///
  /// In en, this message translates to:
  /// **'You need to apply as a merchant first'**
  String get youNeedToApplyAsA;

  /// No description provided for @yourCartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get yourCartIsEmpty;

  /// No description provided for @yourConversations.
  ///
  /// In en, this message translates to:
  /// **'Your conversations'**
  String get yourConversations;

  /// No description provided for @yourDriver.
  ///
  /// In en, this message translates to:
  /// **'Your Driver'**
  String get yourDriver;

  /// No description provided for @yourDriverApplicationIsUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your driver application is under review'**
  String get yourDriverApplicationIsUnderReview;

  /// No description provided for @yourMerchantApplicationIsUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your merchant application is under review'**
  String get yourMerchantApplicationIsUnderReview;

  /// No description provided for @yourEmailCom.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get yourEmailCom;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'★ Featured'**
  String get featured;

  /// No description provided for @phoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'+961 XX XXX XXX'**
  String get phoneNumberPlaceholder;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @typeText.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get typeText;

  /// No description provided for @aDriverHasBeenAssignedAnd.
  ///
  /// In en, this message translates to:
  /// **'A driver has been assigned and is heading to the store'**
  String get aDriverHasBeenAssignedAnd;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// No description provided for @active2.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active2;

  /// No description provided for @add2.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add2;

  /// No description provided for @addCategory2.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory2;

  /// No description provided for @addGroceryListToCart.
  ///
  /// In en, this message translates to:
  /// **'Add Grocery List to Cart'**
  String get addGroceryListToCart;

  /// No description provided for @addProduct3.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct3;

  /// No description provided for @addSubcategory2.
  ///
  /// In en, this message translates to:
  /// **'Add Subcategory'**
  String get addSubcategory2;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @addingToCart.
  ///
  /// In en, this message translates to:
  /// **'Adding to cart...'**
  String get addingToCart;

  /// No description provided for @addressIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressIsRequired;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @advertisement.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get advertisement;

  /// No description provided for @aiRequestTimedOutPleaseTry2.
  ///
  /// In en, this message translates to:
  /// **'AI request timed out. Please try again.'**
  String get aiRequestTimedOutPleaseTry2;

  /// No description provided for @all2.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all2;

  /// No description provided for @applicationPending.
  ///
  /// In en, this message translates to:
  /// **'Application Pending'**
  String get applicationPending;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejected;

  /// No description provided for @apply2.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply2;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything'**
  String get askAnything;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @assignToCategory.
  ///
  /// In en, this message translates to:
  /// **'Assign to Category'**
  String get assignToCategory;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @banner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get banner;

  /// No description provided for @bicycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get bicycle;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @businessAddressIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Business address is required'**
  String get businessAddressIsRequired;

  /// No description provided for @businessNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameIsRequired;

  /// No description provided for @businessNameMustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Business name must be at least 3 characters'**
  String get businessNameMustBeAtLeast;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @carousel2.
  ///
  /// In en, this message translates to:
  /// **'Carousel'**
  String get carousel2;

  /// No description provided for @category2.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category2;

  /// No description provided for @categoryName2.
  ///
  /// In en, this message translates to:
  /// **'Category Name *'**
  String get categoryName2;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @changeOnMap.
  ///
  /// In en, this message translates to:
  /// **'Change on Map'**
  String get changeOnMap;

  /// No description provided for @closeStore.
  ///
  /// In en, this message translates to:
  /// **'Close Store'**
  String get closeStore;

  /// No description provided for @comparePlans.
  ///
  /// In en, this message translates to:
  /// **'Compare Plans'**
  String get comparePlans;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @create2.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create2;

  /// No description provided for @createMerchant.
  ///
  /// In en, this message translates to:
  /// **'Create Merchant'**
  String get createMerchant;

  /// No description provided for @createNewAd.
  ///
  /// In en, this message translates to:
  /// **'Create New Ad'**
  String get createNewAd;

  /// No description provided for @createPlan.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get createPlan;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @customer2.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer2;

  /// No description provided for @dark2.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark2;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @driver2.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver2;

  /// No description provided for @driverApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Driver approved successfully!'**
  String get driverApprovedSuccessfully;

  /// No description provided for @driverAssigned2.
  ///
  /// In en, this message translates to:
  /// **'Driver Assigned'**
  String get driverAssigned2;

  /// No description provided for @driverRejected.
  ///
  /// In en, this message translates to:
  /// **'Driver rejected'**
  String get driverRejected;

  /// No description provided for @editAd.
  ///
  /// In en, this message translates to:
  /// **'Edit Ad'**
  String get editAd;

  /// No description provided for @editCategory2.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory2;

  /// No description provided for @editPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit Plan'**
  String get editPlan;

  /// No description provided for @editSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Subcategory'**
  String get editSubcategory;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @enterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterAValidEmail;

  /// No description provided for @enterAValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterAValidPrice;

  /// No description provided for @enterYourEmailAndWeLl.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\\\'ll send you a reset link'**
  String get enterYourEmailAndWeLl;

  /// No description provided for @failedToApproveDriver.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve driver'**
  String get failedToApproveDriver;

  /// No description provided for @failedToRejectDriver.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject driver'**
  String get failedToRejectDriver;

  /// No description provided for @failedToRejectMerchant.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject merchant'**
  String get failedToRejectMerchant;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @fullNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameIsRequired;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @hideComparison.
  ///
  /// In en, this message translates to:
  /// **'Hide Comparison'**
  String get hideComparison;

  /// No description provided for @iApologizeButIMHaving.
  ///
  /// In en, this message translates to:
  /// **'I apologize, but I\\\'m having trouble processing your request right now. Please try again.'**
  String get iApologizeButIMHaving;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @inStore.
  ///
  /// In en, this message translates to:
  /// **'In store'**
  String get inStore;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @inactive2.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive2;

  /// No description provided for @inheritedFromParent.
  ///
  /// In en, this message translates to:
  /// **'Inherited from parent'**
  String get inheritedFromParent;

  /// No description provided for @inventory2.
  ///
  /// In en, this message translates to:
  /// **'inventory_2'**
  String get inventory2;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @kjDelivery.
  ///
  /// In en, this message translates to:
  /// **'KJ Delivery'**
  String get kjDelivery;

  /// No description provided for @light2.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light2;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark Available'**
  String get markAvailable;

  /// No description provided for @markUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Mark Unavailable'**
  String get markUnavailable;

  /// No description provided for @marketplaceListing.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Listing'**
  String get marketplaceListing;

  /// No description provided for @merchant2.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant2;

  /// No description provided for @merchantRejected.
  ///
  /// In en, this message translates to:
  /// **'Merchant rejected'**
  String get merchantRejected;

  /// No description provided for @motorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// No description provided for @moveToCart.
  ///
  /// In en, this message translates to:
  /// **'Move to Cart'**
  String get moveToCart;

  /// No description provided for @mustBe0OrHigher.
  ///
  /// In en, this message translates to:
  /// **'Must be 0 or higher'**
  String get mustBe0OrHigher;

  /// No description provided for @mustBeANumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get mustBeANumber;

  /// No description provided for @mustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 2 characters'**
  String get mustBeAtLeast2Characters;

  /// No description provided for @nA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get nA;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @nameMustBeAtLeast3.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters'**
  String get nameMustBeAtLeast3;

  /// No description provided for @navigateToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Customer'**
  String get navigateToCustomer;

  /// No description provided for @navigateToStore.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Store'**
  String get navigateToStore;

  /// No description provided for @newDeliveryRequest2.
  ///
  /// In en, this message translates to:
  /// **'New Delivery Request'**
  String get newDeliveryRequest2;

  /// No description provided for @newOrder2.
  ///
  /// In en, this message translates to:
  /// **'New Order!'**
  String get newOrder2;

  /// No description provided for @no2.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no2;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @offline2.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline2;

  /// No description provided for @online2.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online2;

  /// No description provided for @openStore.
  ///
  /// In en, this message translates to:
  /// **'Open Store'**
  String get openStore;

  /// No description provided for @orderAccepted2.
  ///
  /// In en, this message translates to:
  /// **'Order Accepted'**
  String get orderAccepted2;

  /// No description provided for @orderCancelled2.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get orderCancelled2;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderDelivered;

  /// No description provided for @orderPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order Picked Up'**
  String get orderPickedUp;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @orderRejected2.
  ///
  /// In en, this message translates to:
  /// **'Order Rejected'**
  String get orderRejected2;

  /// No description provided for @outOfStock2.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock2;

  /// No description provided for @parentCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent Category (optional)'**
  String get parentCategoryOptional;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @phoneNumber3.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber3;

  /// No description provided for @phoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// No description provided for @pickOnMap2.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap2;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get pickedUp;

  /// No description provided for @pleaseDescribeYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Please describe your experience'**
  String get pleaseDescribeYourExperience;

  /// No description provided for @pleaseProvideBusinessAddress.
  ///
  /// In en, this message translates to:
  /// **'Please provide business address'**
  String get pleaseProvideBusinessAddress;

  /// No description provided for @pleaseProvideBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Please provide business name'**
  String get pleaseProvideBusinessName;

  /// No description provided for @pleaseProvideVehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Please provide vehicle information'**
  String get pleaseProvideVehicleInformation;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @priceIsRequired2.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceIsRequired2;

  /// No description provided for @priority2.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority2;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @processingYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Processing your order...'**
  String get processingYourOrder;

  /// No description provided for @product2.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product2;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @removeFromFavorites2.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites2;

  /// No description provided for @removeSale2.
  ///
  /// In en, this message translates to:
  /// **'Remove Sale'**
  String get removeSale2;

  /// No description provided for @removedFromFavorites2.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites2;

  /// No description provided for @resetDemoData2.
  ///
  /// In en, this message translates to:
  /// **'Reset Demo Data'**
  String get resetDemoData2;

  /// No description provided for @resetting.
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get resetting;

  /// No description provided for @restaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @save2.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save2;

  /// No description provided for @saveChanges2.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges2;

  /// No description provided for @seedDemoData.
  ///
  /// In en, this message translates to:
  /// **'Seed Demo Data'**
  String get seedDemoData;

  /// No description provided for @seeding.
  ///
  /// In en, this message translates to:
  /// **'Seeding...'**
  String get seeding;

  /// No description provided for @service2.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service2;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @setDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Set Delivery Address'**
  String get setDeliveryAddress;

  /// No description provided for @setItemLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Item Location'**
  String get setItemLocation;

  /// No description provided for @setSearchArea.
  ///
  /// In en, this message translates to:
  /// **'Set Search Area'**
  String get setSearchArea;

  /// No description provided for @setServiceZone.
  ///
  /// In en, this message translates to:
  /// **'Set Service Zone'**
  String get setServiceZone;

  /// No description provided for @setStoreLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Store Location'**
  String get setStoreLocation;

  /// No description provided for @standard2.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard2;

  /// No description provided for @store2.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store2;

  /// No description provided for @storeAcceptedYourOrderAssigningA.
  ///
  /// In en, this message translates to:
  /// **'Store accepted your order, assigning a driver'**
  String get storeAcceptedYourOrderAssigningA;

  /// No description provided for @storeIsNowClosed.
  ///
  /// In en, this message translates to:
  /// **'Store is now closed'**
  String get storeIsNowClosed;

  /// No description provided for @storeIsNowOpen.
  ///
  /// In en, this message translates to:
  /// **'Store is now open'**
  String get storeIsNowOpen;

  /// No description provided for @subcategoryName.
  ///
  /// In en, this message translates to:
  /// **'Subcategory Name *'**
  String get subcategoryName;

  /// No description provided for @subscribe2.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe2;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @suspendAccount.
  ///
  /// In en, this message translates to:
  /// **'Suspend Account'**
  String get suspendAccount;

  /// No description provided for @system2.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system2;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get tapToAddPhoto;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get tapToChangePhoto;

  /// No description provided for @thisOrderHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'This order has been cancelled'**
  String get thisOrderHasBeenCancelled;

  /// No description provided for @thisWillSignYouOutOf.
  ///
  /// In en, this message translates to:
  /// **'This will sign you out of all other devices. You\\\'ll remain signed in here.'**
  String get thisWillSignYouOutOf;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @tryAdjustingYourSearchOrFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to find what you\\\'re looking for'**
  String get tryAdjustingYourSearchOrFilters;

  /// No description provided for @unavailable2.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable2;

  /// No description provided for @unfeature.
  ///
  /// In en, this message translates to:
  /// **'Unfeature'**
  String get unfeature;

  /// No description provided for @unfortunatelyYourOrderWasRejected.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your order was rejected'**
  String get unfortunatelyYourOrderWasRejected;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown location'**
  String get unknownLocation;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updatedCart.
  ///
  /// In en, this message translates to:
  /// **'Updated cart'**
  String get updatedCart;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @yes2.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes2;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @youAreNowOffline.
  ///
  /// In en, this message translates to:
  /// **'You are now offline'**
  String get youAreNowOffline;

  /// No description provided for @youAreNowOnline.
  ///
  /// In en, this message translates to:
  /// **'You are now online'**
  String get youAreNowOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are Offline'**
  String get youAreOffline;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You are Online'**
  String get youAreOnline;

  /// No description provided for @yourOrderHasBeenDeliveredEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered. Enjoy!'**
  String get yourOrderHasBeenDeliveredEnjoy;

  /// No description provided for @yourOrderIsBeingReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Your order is being reviewed by the store'**
  String get yourOrderIsBeingReviewedBy;

  /// No description provided for @yourOrderIsOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your order is on the way to you!'**
  String get yourOrderIsOnTheWay;

  /// No description provided for @atLeast7DigitsForLebanon.
  ///
  /// In en, this message translates to:
  /// **'At least 7 digits for Lebanon'**
  String get atLeast7DigitsForLebanon;

  /// No description provided for @pleaseEnterAValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterAValidNumber;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @needUppercaseLowercaseNumber.
  ///
  /// In en, this message translates to:
  /// **'Need uppercase, lowercase & number'**
  String get needUppercaseLowercaseNumber;

  /// No description provided for @pleaseEnterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterYourFullName;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Location'**
  String get selectDeliveryLocation;

  /// No description provided for @couldNotGetLocationPleaseEnable.
  ///
  /// In en, this message translates to:
  /// **'Could not get location. Please enable GPS.'**
  String get couldNotGetLocationPleaseEnable;

  /// No description provided for @searchOrTapToSelectLocation2.
  ///
  /// In en, this message translates to:
  /// **'Search or tap to select location'**
  String get searchOrTapToSelectLocation2;

  /// No description provided for @admin2.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get admin2;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @customersCanPlaceOrders.
  ///
  /// In en, this message translates to:
  /// **'Customers can place orders'**
  String get customersCanPlaceOrders;

  /// No description provided for @ordersPaused.
  ///
  /// In en, this message translates to:
  /// **'Orders paused'**
  String get ordersPaused;

  /// No description provided for @operatingHours2.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours2;

  /// No description provided for @shownInFeaturedSection.
  ///
  /// In en, this message translates to:
  /// **'Shown in featured section'**
  String get shownInFeaturedSection;

  /// No description provided for @notFeatured.
  ///
  /// In en, this message translates to:
  /// **'Not featured'**
  String get notFeatured;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// No description provided for @ok2.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok2;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get recent;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andText;

  /// No description provided for @n247Support.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get n247Support;

  /// No description provided for @n30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get n30Days;

  /// No description provided for @n7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get n7Days;

  /// No description provided for @n90Days.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get n90Days;

  /// No description provided for @noProductsCurrentlyInInventory.
  ///
  /// In en, this message translates to:
  /// **'(No products currently in inventory)'**
  String get noProductsCurrentlyInInventory;

  /// No description provided for @noStoresCurrentlyListed.
  ///
  /// In en, this message translates to:
  /// **'(No stores currently listed)'**
  String get noStoresCurrentlyListed;

  /// No description provided for @n23Hours.
  ///
  /// In en, this message translates to:
  /// **'2-3 hours'**
  String get n23Hours;

  /// No description provided for @n3045Minutes.
  ///
  /// In en, this message translates to:
  /// **'30-45 minutes'**
  String get n3045Minutes;

  /// No description provided for @aDriverHasBeenAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'A driver has been assigned to your order.'**
  String get aDriverHasBeenAssignedTo;

  /// No description provided for @aFriend.
  ///
  /// In en, this message translates to:
  /// **'A friend'**
  String get aFriend;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @adPreview.
  ///
  /// In en, this message translates to:
  /// **'Ad preview'**
  String get adPreview;

  /// No description provided for @adPreviewImage.
  ///
  /// In en, this message translates to:
  /// **'Ad preview image'**
  String get adPreviewImage;

  /// No description provided for @adSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ad subtitle'**
  String get adSubtitle;

  /// No description provided for @adsBanners.
  ///
  /// In en, this message translates to:
  /// **'Ads / Banners'**
  String get adsBanners;

  /// No description provided for @afternoon125.
  ///
  /// In en, this message translates to:
  /// **'Afternoon (12-5)'**
  String get afternoon125;

  /// No description provided for @allContent.
  ///
  /// In en, this message translates to:
  /// **'All Content'**
  String get allContent;

  /// No description provided for @allListings.
  ///
  /// In en, this message translates to:
  /// **'All Listings'**
  String get allListings;

  /// No description provided for @almostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready...'**
  String get almostReady;

  /// No description provided for @anytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get anytime;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @areYouSureYouWantTo7.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to activate this user account?'**
  String get areYouSureYouWantTo7;

  /// No description provided for @areYouSureYouWantTo8.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend this user account? They will not be able to access the app.'**
  String get areYouSureYouWantTo8;

  /// No description provided for @bakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get bakery;

  /// No description provided for @beTheFirstToCreateA.
  ///
  /// In en, this message translates to:
  /// **'Be the first to create a listing!'**
  String get beTheFirstToCreateA;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beauty;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @browseMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Browse Marketplace'**
  String get browseMarketplace;

  /// No description provided for @browseStores.
  ///
  /// In en, this message translates to:
  /// **'Browse Stores'**
  String get browseStores;

  /// No description provided for @businessesIndustrial.
  ///
  /// In en, this message translates to:
  /// **'Businesses & Industrial'**
  String get businessesIndustrial;

  /// No description provided for @byblosJbeil.
  ///
  /// In en, this message translates to:
  /// **'Byblos (Jbeil)'**
  String get byblosJbeil;

  /// No description provided for @canYouDeliverToAchrafieh.
  ///
  /// In en, this message translates to:
  /// **'Can you deliver to Achrafieh?'**
  String get canYouDeliverToAchrafieh;

  /// No description provided for @canYouNegotiatePrice.
  ///
  /// In en, this message translates to:
  /// **'Can you negotiate price?'**
  String get canYouNegotiatePrice;

  /// No description provided for @cancelledByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by customer'**
  String get cancelledByCustomer;

  /// No description provided for @cheapItalianFoodOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Cheap Italian food open now'**
  String get cheapItalianFoodOpenNow;

  /// No description provided for @cheapItalianFoodOpenNow2.
  ///
  /// In en, this message translates to:
  /// **'cheap Italian food open now'**
  String get cheapItalianFoodOpenNow2;

  /// No description provided for @checkOutOurLatestOffer.
  ///
  /// In en, this message translates to:
  /// **'Check out our latest offer!'**
  String get checkOutOurLatestOffer;

  /// No description provided for @checkOutSpecialOffers.
  ///
  /// In en, this message translates to:
  /// **'Check out special offers'**
  String get checkOutSpecialOffers;

  /// No description provided for @checkingLocation.
  ///
  /// In en, this message translates to:
  /// **'Checking location...'**
  String get checkingLocation;

  /// No description provided for @china.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get china;

  /// No description provided for @cleanersAvailableToday.
  ///
  /// In en, this message translates to:
  /// **'Cleaners available today'**
  String get cleanersAvailableToday;

  /// No description provided for @cleanersAvailableToday2.
  ///
  /// In en, this message translates to:
  /// **'cleaners available today'**
  String get cleanersAvailableToday2;

  /// No description provided for @cleaningServices.
  ///
  /// In en, this message translates to:
  /// **'Cleaning Services'**
  String get cleaningServices;

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @couldNotCalculateExactFeeUsing.
  ///
  /// In en, this message translates to:
  /// **'Could not calculate exact fee, using base rate'**
  String get couldNotCalculateExactFeeUsing;

  /// No description provided for @couldNotDetermineYourEmailPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not determine your email. Please go back and try again.'**
  String get couldNotDetermineYourEmailPlease;

  /// No description provided for @creamyHummusWithOliveOilAnd.
  ///
  /// In en, this message translates to:
  /// **'Creamy hummus with olive oil and pita bread'**
  String get creamyHummusWithOliveOilAnd;

  /// No description provided for @createMerchantProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Merchant Profile'**
  String get createMerchantProfile;

  /// No description provided for @crispyFalafelWithTahiniAndVegetables.
  ///
  /// In en, this message translates to:
  /// **'Crispy falafel with tahini and vegetables'**
  String get crispyFalafelWithTahiniAndVegetables;

  /// No description provided for @crispyGoldenFries.
  ///
  /// In en, this message translates to:
  /// **'Crispy golden fries'**
  String get crispyGoldenFries;

  /// No description provided for @customLocation.
  ///
  /// In en, this message translates to:
  /// **'Custom Location'**
  String get customLocation;

  /// No description provided for @customer1DemoCom.
  ///
  /// In en, this message translates to:
  /// **'customer1@demo.com'**
  String get customer1DemoCom;

  /// No description provided for @customer2DemoCom.
  ///
  /// In en, this message translates to:
  /// **'customer2@demo.com'**
  String get customer2DemoCom;

  /// No description provided for @damour.
  ///
  /// In en, this message translates to:
  /// **'Damour'**
  String get damour;

  /// No description provided for @deepCleaningSanitization.
  ///
  /// In en, this message translates to:
  /// **'Deep Cleaning & Sanitization'**
  String get deepCleaningSanitization;

  /// No description provided for @deirElQamar.
  ///
  /// In en, this message translates to:
  /// **'Deir el Qamar'**
  String get deirElQamar;

  /// No description provided for @deliveryPartnerLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery partner location'**
  String get deliveryPartnerLocation;

  /// No description provided for @demoDataResetSuccessfullyViaRpc.
  ///
  /// In en, this message translates to:
  /// **'Demo data reset successfully via RPC'**
  String get demoDataResetSuccessfullyViaRpc;

  /// No description provided for @demoDataSeedVersionTracker.
  ///
  /// In en, this message translates to:
  /// **'Demo data seed version tracker'**
  String get demoDataSeedVersionTracker;

  /// No description provided for @descriptionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionIsRequired;

  /// No description provided for @dieselDelivery.
  ///
  /// In en, this message translates to:
  /// **'Diesel Delivery'**
  String get dieselDelivery;

  /// No description provided for @diningTableWith6Chairs.
  ///
  /// In en, this message translates to:
  /// **'Dining Table with 6 Chairs'**
  String get diningTableWith6Chairs;

  /// No description provided for @discoverOurTopPicks.
  ///
  /// In en, this message translates to:
  /// **'Discover our top picks'**
  String get discoverOurTopPicks;

  /// No description provided for @disposableProtectiveFaceMasks.
  ///
  /// In en, this message translates to:
  /// **'Disposable protective face masks'**
  String get disposableProtectiveFaceMasks;

  /// No description provided for @douma.
  ///
  /// In en, this message translates to:
  /// **'Douma'**
  String get douma;

  /// No description provided for @driver1DemoCom.
  ///
  /// In en, this message translates to:
  /// **'driver1@demo.com'**
  String get driver1DemoCom;

  /// No description provided for @driver2DemoCom.
  ///
  /// In en, this message translates to:
  /// **'driver2@demo.com'**
  String get driver2DemoCom;

  /// No description provided for @editMerchantProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Merchant Profile'**
  String get editMerchantProfile;

  /// No description provided for @electricianServices.
  ///
  /// In en, this message translates to:
  /// **'Electrician Services'**
  String get electricianServices;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @electronicsAppliances.
  ///
  /// In en, this message translates to:
  /// **'Electronics & Appliances'**
  String get electronicsAppliances;

  /// No description provided for @ensureadminFirstCheck.
  ///
  /// In en, this message translates to:
  /// **'ensureAdmin-first-check'**
  String get ensureadminFirstCheck;

  /// No description provided for @errorLoadingAccountInfoPleaseGo.
  ///
  /// In en, this message translates to:
  /// **'Error loading account info. Please go back and try again.'**
  String get errorLoadingAccountInfoPleaseGo;

  /// No description provided for @errorSendingCodePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error sending code. Please try again.'**
  String get errorSendingCodePleaseTryAgain;

  /// No description provided for @errorSendingVerificationCodePleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Error sending verification code. Please try again.'**
  String get errorSendingVerificationCodePleaseTry;

  /// No description provided for @errorSubmittingApplicationPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error submitting application. Please try again.'**
  String get errorSubmittingApplicationPleaseTryAgain;

  /// No description provided for @errorVerifyingCodePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error verifying code. Please try again.'**
  String get errorVerifyingCodePleaseTryAgain;

  /// No description provided for @evening59.
  ///
  /// In en, this message translates to:
  /// **'Evening (5-9)'**
  String get evening59;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @exploreAllProductCategories.
  ///
  /// In en, this message translates to:
  /// **'Explore all product categories'**
  String get exploreAllProductCategories;

  /// No description provided for @expressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery'**
  String get expressDelivery;

  /// No description provided for @express30.
  ///
  /// In en, this message translates to:
  /// **'express_30'**
  String get express30;

  /// No description provided for @extraNapkinsPlease.
  ///
  /// In en, this message translates to:
  /// **'Extra napkins please'**
  String get extraNapkinsPlease;

  /// No description provided for @extraVirginOliveOil.
  ///
  /// In en, this message translates to:
  /// **'Extra virgin olive oil'**
  String get extraVirginOliveOil;

  /// No description provided for @faceMasks50pcs.
  ///
  /// In en, this message translates to:
  /// **'Face Masks (50pcs)'**
  String get faceMasks50pcs;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @failedToApproveMerchant.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve merchant'**
  String get failedToApproveMerchant;

  /// No description provided for @failedToGenerateMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate meal plan.'**
  String get failedToGenerateMealPlan;

  /// No description provided for @failedToGetAiResponsePlease.
  ///
  /// In en, this message translates to:
  /// **'Failed to get AI response. Please try again.'**
  String get failedToGetAiResponsePlease;

  /// No description provided for @failedToMatchProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to match products'**
  String get failedToMatchProducts;

  /// No description provided for @failedToSaveMerchantProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to save merchant profile'**
  String get failedToSaveMerchantProfile;

  /// No description provided for @failedToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get failedToSendCode;

  /// No description provided for @failedToSendSms.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SMS'**
  String get failedToSendSms;

  /// No description provided for @failedToSubmitApplication.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit application'**
  String get failedToSubmitApplication;

  /// No description provided for @failedToUpdateUserStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user status'**
  String get failedToUpdateUserStatus;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @falafelWrap.
  ///
  /// In en, this message translates to:
  /// **'Falafel Wrap'**
  String get falafelWrap;

  /// No description provided for @farmFreshFreeRangeEggs.
  ///
  /// In en, this message translates to:
  /// **'Farm fresh free range eggs'**
  String get farmFreshFreeRangeEggs;

  /// No description provided for @farmToTableIn24Hours.
  ///
  /// In en, this message translates to:
  /// **'Farm to table in 24 hours'**
  String get farmToTableIn24Hours;

  /// No description provided for @fashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get fashion;

  /// No description provided for @fashionBeauty.
  ///
  /// In en, this message translates to:
  /// **'Fashion & Beauty'**
  String get fashionBeauty;

  /// No description provided for @fastFoodAndSandwiches.
  ///
  /// In en, this message translates to:
  /// **'Fast food and sandwiches'**
  String get fastFoodAndSandwiches;

  /// No description provided for @featuredProducts.
  ///
  /// In en, this message translates to:
  /// **'Featured Products'**
  String get featuredProducts;

  /// No description provided for @firstAidKit.
  ///
  /// In en, this message translates to:
  /// **'First Aid Kit'**
  String get firstAidKit;

  /// No description provided for @fitnessCoaching.
  ///
  /// In en, this message translates to:
  /// **'Fitness coaching'**
  String get fitnessCoaching;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @foodDining.
  ///
  /// In en, this message translates to:
  /// **'Food & Dining'**
  String get foodDining;

  /// No description provided for @france.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get france;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @freeRangeEggs.
  ///
  /// In en, this message translates to:
  /// **'Free Range Eggs'**
  String get freeRangeEggs;

  /// No description provided for @freeRangeEggs12pcs.
  ///
  /// In en, this message translates to:
  /// **'Free Range Eggs (12pcs)'**
  String get freeRangeEggs12pcs;

  /// No description provided for @frenchFries.
  ///
  /// In en, this message translates to:
  /// **'French Fries'**
  String get frenchFries;

  /// No description provided for @freshGroceriesDaily.
  ///
  /// In en, this message translates to:
  /// **'Fresh Groceries Daily'**
  String get freshGroceriesDaily;

  /// No description provided for @freshMarketGrocery.
  ///
  /// In en, this message translates to:
  /// **'Fresh Market Grocery'**
  String get freshMarketGrocery;

  /// No description provided for @freshMilk1l.
  ///
  /// In en, this message translates to:
  /// **'Fresh Milk (1L)'**
  String get freshMilk1l;

  /// No description provided for @freshOrganicBananas.
  ///
  /// In en, this message translates to:
  /// **'Fresh organic bananas'**
  String get freshOrganicBananas;

  /// No description provided for @freshParsleySaladWithTomatoesAnd.
  ///
  /// In en, this message translates to:
  /// **'Fresh parsley salad with tomatoes and bulgur'**
  String get freshParsleySaladWithTomatoesAnd;

  /// No description provided for @freshTomatoes1kg.
  ///
  /// In en, this message translates to:
  /// **'Fresh Tomatoes (1kg)'**
  String get freshTomatoes1kg;

  /// No description provided for @freshVegetablesUnder20.
  ///
  /// In en, this message translates to:
  /// **'fresh vegetables under 20'**
  String get freshVegetablesUnder20;

  /// No description provided for @freshWaterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fresh water delivery'**
  String get freshWaterDelivery;

  /// No description provided for @freshlyBakedWholeWheatBread.
  ///
  /// In en, this message translates to:
  /// **'Freshly baked whole wheat bread'**
  String get freshlyBakedWholeWheatBread;

  /// No description provided for @fuelDeliveryService.
  ///
  /// In en, this message translates to:
  /// **'Fuel delivery service'**
  String get fuelDeliveryService;

  /// No description provided for @fullCreamFreshMilk.
  ///
  /// In en, this message translates to:
  /// **'Full cream fresh milk'**
  String get fullCreamFreshMilk;

  /// No description provided for @furniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get furniture;

  /// No description provided for @furnitureDecor.
  ///
  /// In en, this message translates to:
  /// **'Furniture & Decor'**
  String get furnitureDecor;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @geometryFormattedAddress.
  ///
  /// In en, this message translates to:
  /// **'geometry,formatted_address'**
  String get geometryFormattedAddress;

  /// No description provided for @germany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get germany;

  /// No description provided for @get20OffOnAllItems.
  ///
  /// In en, this message translates to:
  /// **'Get 20% off on all items this week'**
  String get get20OffOnAllItems;

  /// No description provided for @goOnlineToStartEarning.
  ///
  /// In en, this message translates to:
  /// **'Go online to start earning'**
  String get goOnlineToStartEarning;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @grandOpeningSale.
  ///
  /// In en, this message translates to:
  /// **'Grand Opening Sale!'**
  String get grandOpeningSale;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// No description provided for @greaterBeirut.
  ///
  /// In en, this message translates to:
  /// **'Greater Beirut'**
  String get greaterBeirut;

  /// No description provided for @greekYogurt.
  ///
  /// In en, this message translates to:
  /// **'Greek Yogurt'**
  String get greekYogurt;

  /// No description provided for @grilledChickenWithGarlicSaucePickles.
  ///
  /// In en, this message translates to:
  /// **'Grilled chicken with garlic sauce, pickles, and fries'**
  String get grilledChickenWithGarlicSaucePickles;

  /// No description provided for @grilledChickenWithRomaineAndParmesan.
  ///
  /// In en, this message translates to:
  /// **'Grilled chicken with romaine and parmesan'**
  String get grilledChickenWithRomaineAndParmesan;

  /// No description provided for @grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get grocery;

  /// No description provided for @groceryStore.
  ///
  /// In en, this message translates to:
  /// **'Grocery Store'**
  String get groceryStore;

  /// No description provided for @groceryStoreManager.
  ///
  /// In en, this message translates to:
  /// **'Grocery Store Manager'**
  String get groceryStoreManager;

  /// No description provided for @hamraStreetBeirutLebanon.
  ///
  /// In en, this message translates to:
  /// **'Hamra Street, Beirut, Lebanon'**
  String get hamraStreetBeirutLebanon;

  /// No description provided for @hamraBeirut.
  ///
  /// In en, this message translates to:
  /// **'Hamra, Beirut'**
  String get hamraBeirut;

  /// No description provided for @handSanitizer250ml.
  ///
  /// In en, this message translates to:
  /// **'Hand Sanitizer (250ml)'**
  String get handSanitizer250ml;

  /// No description provided for @harissa.
  ///
  /// In en, this message translates to:
  /// **'Harissa'**
  String get harissa;

  /// No description provided for @healthWellness.
  ///
  /// In en, this message translates to:
  /// **'Health & Wellness'**
  String get healthWellness;

  /// No description provided for @healthPlusPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Health Plus Pharmacy'**
  String get healthPlusPharmacy;

  /// No description provided for @hobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get hobbies;

  /// No description provided for @homeRepair.
  ///
  /// In en, this message translates to:
  /// **'Home Repair'**
  String get homeRepair;

  /// No description provided for @howWasYourDeliveryExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your delivery experience?'**
  String get howWasYourDeliveryExperience;

  /// No description provided for @hummusBowl.
  ///
  /// In en, this message translates to:
  /// **'Hummus Bowl'**
  String get hummusBowl;

  /// No description provided for @icedCoffee.
  ///
  /// In en, this message translates to:
  /// **'Iced Coffee'**
  String get icedCoffee;

  /// No description provided for @immuneSystemSupport.
  ///
  /// In en, this message translates to:
  /// **'Immune system support'**
  String get immuneSystemSupport;

  /// No description provided for @india.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get india;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @invalidPromoCodePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code. Please try again.'**
  String get invalidPromoCodePleaseTryAgain;

  /// No description provided for @iphone13ProLikeNew.
  ///
  /// In en, this message translates to:
  /// **'iPhone 13 Pro - Like New'**
  String get iphone13ProLikeNew;

  /// No description provided for @isThisAvailable.
  ///
  /// In en, this message translates to:
  /// **'Is this available?'**
  String get isThisAvailable;

  /// No description provided for @isThisStillAvailable.
  ///
  /// In en, this message translates to:
  /// **'Is this still available?'**
  String get isThisStillAvailable;

  /// No description provided for @japan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get japan;

  /// No description provided for @jezzine.
  ///
  /// In en, this message translates to:
  /// **'Jezzine'**
  String get jezzine;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @juicyBeefPattyWithCheeseAnd.
  ///
  /// In en, this message translates to:
  /// **'Juicy beef patty with cheese and special sauce'**
  String get juicyBeefPattyWithCheeseAnd;

  /// No description provided for @karimNasser.
  ///
  /// In en, this message translates to:
  /// **'Karim Nasser'**
  String get karimNasser;

  /// No description provided for @khalde.
  ///
  /// In en, this message translates to:
  /// **'Khalde'**
  String get khalde;

  /// No description provided for @kidsBabies.
  ///
  /// In en, this message translates to:
  /// **'Kids & Babies'**
  String get kidsBabies;

  /// No description provided for @kjDeliveryServicesLogoWithProfessional.
  ///
  /// In en, this message translates to:
  /// **'KJ Delivery Services logo with professional branding'**
  String get kjDeliveryServicesLogoWithProfessional;

  /// No description provided for @kjDeliveryOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'KJ Delivery — Order History'**
  String get kjDeliveryOrderHistory;

  /// No description provided for @kjStore.
  ///
  /// In en, this message translates to:
  /// **'KJ Store'**
  String get kjStore;

  /// No description provided for @lambChickenAndKaftaWithGrilled.
  ///
  /// In en, this message translates to:
  /// **'Lamb, chicken, and kafta with grilled vegetables'**
  String get lambChickenAndKaftaWithGrilled;

  /// No description provided for @lebaneseMediterranean.
  ///
  /// In en, this message translates to:
  /// **'Lebanese / Mediterranean'**
  String get lebaneseMediterranean;

  /// No description provided for @lebanon.
  ///
  /// In en, this message translates to:
  /// **'Lebanon'**
  String get lebanon;

  /// No description provided for @likeNew.
  ///
  /// In en, this message translates to:
  /// **'Like New'**
  String get likeNew;

  /// No description provided for @loadingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Loading preferences...'**
  String get loadingPreferences;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @locallyGrownRipeTomatoes.
  ///
  /// In en, this message translates to:
  /// **'Locally grown ripe tomatoes'**
  String get locallyGrownRipeTomatoes;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @macbookPro2021M1.
  ///
  /// In en, this message translates to:
  /// **'MacBook Pro 2021 M1'**
  String get macbookPro2021M1;

  /// No description provided for @manualAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Manual adjustment'**
  String get manualAdjustment;

  /// No description provided for @marjayoun.
  ///
  /// In en, this message translates to:
  /// **'Marjayoun'**
  String get marjayoun;

  /// No description provided for @marketplacePromotionalBanner.
  ///
  /// In en, this message translates to:
  /// **'Marketplace promotional banner'**
  String get marketplacePromotionalBanner;

  /// No description provided for @meal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get meal;

  /// No description provided for @mealPlanWasEmptyPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Meal plan was empty. Please try again.'**
  String get mealPlanWasEmptyPleaseTry;

  /// No description provided for @mechanicsWithin5Miles.
  ///
  /// In en, this message translates to:
  /// **'Mechanics within 5 miles'**
  String get mechanicsWithin5Miles;

  /// No description provided for @mechanicsWithin5Miles2.
  ///
  /// In en, this message translates to:
  /// **'mechanics within 5 miles'**
  String get mechanicsWithin5Miles2;

  /// No description provided for @medicationsAndHealthProducts.
  ///
  /// In en, this message translates to:
  /// **'Medications and health products'**
  String get medicationsAndHealthProducts;

  /// No description provided for @mediterraneanDelights.
  ///
  /// In en, this message translates to:
  /// **'Mediterranean Delights'**
  String get mediterraneanDelights;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @merchantApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Merchant approved successfully!'**
  String get merchantApprovedSuccessfully;

  /// No description provided for @merchantProfileCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Merchant profile created successfully'**
  String get merchantProfileCreatedSuccessfully;

  /// No description provided for @merchantProfileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Merchant profile updated successfully'**
  String get merchantProfileUpdatedSuccessfully;

  /// No description provided for @merchant1DemoCom.
  ///
  /// In en, this message translates to:
  /// **'merchant1@demo.com'**
  String get merchant1DemoCom;

  /// No description provided for @merchant2DemoCom.
  ///
  /// In en, this message translates to:
  /// **'merchant2@demo.com'**
  String get merchant2DemoCom;

  /// No description provided for @michaelChen.
  ///
  /// In en, this message translates to:
  /// **'Michael Chen'**
  String get michaelChen;

  /// No description provided for @mixedGrillPlatter.
  ///
  /// In en, this message translates to:
  /// **'Mixed Grill Platter'**
  String get mixedGrillPlatter;

  /// No description provided for @mobilesAccessories.
  ///
  /// In en, this message translates to:
  /// **'Mobiles & Accessories'**
  String get mobilesAccessories;

  /// No description provided for @modernSofaSet3Seater.
  ///
  /// In en, this message translates to:
  /// **'Modern Sofa Set - 3 Seater'**
  String get modernSofaSet3Seater;

  /// No description provided for @morning812.
  ///
  /// In en, this message translates to:
  /// **'Morning (8-12)'**
  String get morning812;

  /// No description provided for @nameEmailPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Name, email, phone number'**
  String get nameEmailPhoneNumber;

  /// No description provided for @newText.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newText;

  /// No description provided for @newDelivery.
  ///
  /// In en, this message translates to:
  /// **'New Delivery'**
  String get newDelivery;

  /// No description provided for @newOrder3.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder3;

  /// No description provided for @newPromotion.
  ///
  /// In en, this message translates to:
  /// **'New Promotion'**
  String get newPromotion;

  /// No description provided for @noAddressSet.
  ///
  /// In en, this message translates to:
  /// **'No address set'**
  String get noAddressSet;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @noGroceryListFound.
  ///
  /// In en, this message translates to:
  /// **'No grocery list found'**
  String get noGroceryListFound;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noProductsInThisCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noProductsInThisCategory;

  /// No description provided for @noStoreSelected.
  ///
  /// In en, this message translates to:
  /// **'No store selected'**
  String get noStoreSelected;

  /// No description provided for @notAcceptingOrders.
  ///
  /// In en, this message translates to:
  /// **'Not Accepting Orders'**
  String get notAcceptingOrders;

  /// No description provided for @notAuthenticatedPleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated. Please sign in again.'**
  String get notAuthenticatedPleaseSignInAgain;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @officeDeskChairSet.
  ///
  /// In en, this message translates to:
  /// **'Office Desk & Chair Set'**
  String get officeDeskChairSet;

  /// No description provided for @oliveOil500ml.
  ///
  /// In en, this message translates to:
  /// **'Olive Oil (500ml)'**
  String get oliveOil500ml;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @openAcceptingOrders.
  ///
  /// In en, this message translates to:
  /// **'Open & Accepting Orders'**
  String get openAcceptingOrders;

  /// No description provided for @orderBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Order Being Prepared'**
  String get orderBeingPrepared;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed!'**
  String get orderConfirmed;

  /// No description provided for @orderDelivered2.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered!'**
  String get orderDelivered2;

  /// No description provided for @orderDetailsShared.
  ///
  /// In en, this message translates to:
  /// **'Order details shared'**
  String get orderDetailsShared;

  /// No description provided for @orderNotFound2.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound2;

  /// No description provided for @orderOnItsWay.
  ///
  /// In en, this message translates to:
  /// **'Order On Its Way!'**
  String get orderOnItsWay;

  /// No description provided for @orderOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Order On The Way'**
  String get orderOnTheWay;

  /// No description provided for @orderReady.
  ///
  /// In en, this message translates to:
  /// **'Order Ready'**
  String get orderReady;

  /// No description provided for @orderReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Order Ready for Pickup'**
  String get orderReadyForPickup;

  /// No description provided for @orderUpdate.
  ///
  /// In en, this message translates to:
  /// **'Order Update'**
  String get orderUpdate;

  /// No description provided for @ordersRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Orders refreshed'**
  String get ordersRefreshed;

  /// No description provided for @organicBananas.
  ///
  /// In en, this message translates to:
  /// **'Organic Bananas'**
  String get organicBananas;

  /// No description provided for @organicBananas1kg.
  ///
  /// In en, this message translates to:
  /// **'Organic Bananas (1kg)'**
  String get organicBananas1kg;

  /// No description provided for @painReliefAndFeverReducer.
  ///
  /// In en, this message translates to:
  /// **'Pain relief and fever reducer'**
  String get painReliefAndFeverReducer;

  /// No description provided for @paracetamol500mg.
  ///
  /// In en, this message translates to:
  /// **'Paracetamol 500mg'**
  String get paracetamol500mg;

  /// No description provided for @personalCookingService.
  ///
  /// In en, this message translates to:
  /// **'Personal cooking service'**
  String get personalCookingService;

  /// No description provided for @personalDriverService.
  ///
  /// In en, this message translates to:
  /// **'Personal driver service'**
  String get personalDriverService;

  /// No description provided for @personalTrainer.
  ///
  /// In en, this message translates to:
  /// **'Personal Trainer'**
  String get personalTrainer;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @pharmacyNearMe.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy near me'**
  String get pharmacyNearMe;

  /// No description provided for @pharmacyNearMe2.
  ///
  /// In en, this message translates to:
  /// **'pharmacy near me'**
  String get pharmacyNearMe2;

  /// No description provided for @planCreated.
  ///
  /// In en, this message translates to:
  /// **'Plan created!'**
  String get planCreated;

  /// No description provided for @planUpdated.
  ///
  /// In en, this message translates to:
  /// **'Plan updated!'**
  String get planUpdated;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @pleaseEnterTheComplete6Digit.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get pleaseEnterTheComplete6Digit;

  /// No description provided for @pleaseRingDoorbell.
  ///
  /// In en, this message translates to:
  /// **'Please ring doorbell'**
  String get pleaseRingDoorbell;

  /// No description provided for @pleaseSelectARoleToApply.
  ///
  /// In en, this message translates to:
  /// **'Please select a role to apply for'**
  String get pleaseSelectARoleToApply;

  /// No description provided for @plumbingRepairServices.
  ///
  /// In en, this message translates to:
  /// **'Plumbing & Repair Services'**
  String get plumbingRepairServices;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @positionBarcodeWithinTheFrame.
  ///
  /// In en, this message translates to:
  /// **'Position barcode within the frame'**
  String get positionBarcodeWithinTheFrame;

  /// No description provided for @preparingYourDelivery.
  ///
  /// In en, this message translates to:
  /// **'Preparing your delivery...'**
  String get preparingYourDelivery;

  /// No description provided for @priceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price High-Low'**
  String get priceHighLow;

  /// No description provided for @priceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price Low-High'**
  String get priceLowHigh;

  /// No description provided for @price3.
  ///
  /// In en, this message translates to:
  /// **'Price: '**
  String get price3;

  /// No description provided for @privateChef.
  ///
  /// In en, this message translates to:
  /// **'Private Chef'**
  String get privateChef;

  /// No description provided for @privateDriver.
  ///
  /// In en, this message translates to:
  /// **'Private Driver'**
  String get privateDriver;

  /// No description provided for @processingYourVoice.
  ///
  /// In en, this message translates to:
  /// **'Processing your voice...'**
  String get processingYourVoice;

  /// No description provided for @processing2.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing2;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get productImage;

  /// No description provided for @productName2.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName2;

  /// No description provided for @professionalHouseCleaning.
  ///
  /// In en, this message translates to:
  /// **'Professional House Cleaning'**
  String get professionalHouseCleaning;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @quickBitesCafe.
  ///
  /// In en, this message translates to:
  /// **'Quick Bites Cafe'**
  String get quickBitesCafe;

  /// No description provided for @quickBitesSpecial.
  ///
  /// In en, this message translates to:
  /// **'Quick Bites Special'**
  String get quickBitesSpecial;

  /// No description provided for @quickRidesAroundTown.
  ///
  /// In en, this message translates to:
  /// **'Quick rides around town'**
  String get quickRidesAroundTown;

  /// No description provided for @raoucheBeirut.
  ///
  /// In en, this message translates to:
  /// **'Raouche, Beirut'**
  String get raoucheBeirut;

  /// No description provided for @readyToAcceptDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Ready to accept deliveries'**
  String get readyToAcceptDeliveries;

  /// No description provided for @receiptDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt downloaded successfully'**
  String get receiptDownloadedSuccessfully;

  /// No description provided for @recentlyViewedProduct.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed product'**
  String get recentlyViewedProduct;

  /// No description provided for @rejectedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Rejected by admin'**
  String get rejectedByAdmin;

  /// No description provided for @removeFromHome.
  ///
  /// In en, this message translates to:
  /// **'Remove from Home'**
  String get removeFromHome;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resetReSeedCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reset & re-seed completed successfully'**
  String get resetReSeedCompletedSuccessfully;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent!'**
  String get resetLinkSent;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @restaurantOwnerAli.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Owner Ali'**
  String get restaurantOwnerAli;

  /// No description provided for @retailShop.
  ///
  /// In en, this message translates to:
  /// **'Retail Shop'**
  String get retailShop;

  /// No description provided for @retailStoresOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Retail stores open now'**
  String get retailStoresOpenNow;

  /// No description provided for @retailStoresOpenNow2.
  ///
  /// In en, this message translates to:
  /// **'retail stores open now'**
  String get retailStoresOpenNow2;

  /// No description provided for @reviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review Order'**
  String get reviewOrder;

  /// No description provided for @roleUpgradeRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Role upgrade request submitted successfully'**
  String get roleUpgradeRequestSubmittedSuccessfully;

  /// No description provided for @saidaSidon.
  ///
  /// In en, this message translates to:
  /// **'Saida (Sidon)'**
  String get saidaSidon;

  /// No description provided for @samsung554kSmartTv.
  ///
  /// In en, this message translates to:
  /// **'Samsung 55\" 4K Smart TV'**
  String get samsung554kSmartTv;

  /// No description provided for @sarahJohnson.
  ///
  /// In en, this message translates to:
  /// **'Sarah Johnson'**
  String get sarahJohnson;

  /// No description provided for @saudiArabia.
  ///
  /// In en, this message translates to:
  /// **'Saudi Arabia'**
  String get saudiArabia;

  /// No description provided for @savedProductImage.
  ///
  /// In en, this message translates to:
  /// **'Saved product image'**
  String get savedProductImage;

  /// No description provided for @scheduledToday.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Today'**
  String get scheduledToday;

  /// No description provided for @scheduledTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Tomorrow'**
  String get scheduledTomorrow;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @searchFailedPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Please try again.'**
  String get searchFailedPleaseTryAgain;

  /// No description provided for @searchProducts2.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts2;

  /// No description provided for @searchingMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Searching marketplace...'**
  String get searchingMarketplace;

  /// No description provided for @selectARating.
  ///
  /// In en, this message translates to:
  /// **'Select a Rating'**
  String get selectARating;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectCollection.
  ///
  /// In en, this message translates to:
  /// **'Select Collection'**
  String get selectCollection;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @selectStore.
  ///
  /// In en, this message translates to:
  /// **'Select Store'**
  String get selectStore;

  /// No description provided for @selectTarget.
  ///
  /// In en, this message translates to:
  /// **'Select Target'**
  String get selectTarget;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @setUpYourMerchantAccount.
  ///
  /// In en, this message translates to:
  /// **'Set up your merchant account'**
  String get setUpYourMerchantAccount;

  /// No description provided for @showOnHome.
  ///
  /// In en, this message translates to:
  /// **'Show on Home'**
  String get showOnHome;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get signupFailed;

  /// No description provided for @sofar.
  ///
  /// In en, this message translates to:
  /// **'Sofar'**
  String get sofar;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @somethingWentWrongPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrongPleaseTryAgain;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort: '**
  String get sort;

  /// No description provided for @sourdoughBread.
  ///
  /// In en, this message translates to:
  /// **'Sourdough Bread'**
  String get sourdoughBread;

  /// No description provided for @specialOffersThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Special Offers This Week'**
  String get specialOffersThisWeek;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @sportsEquipment.
  ///
  /// In en, this message translates to:
  /// **'Sports & Equipment'**
  String get sportsEquipment;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get standardDelivery;

  /// No description provided for @standard2h.
  ///
  /// In en, this message translates to:
  /// **'standard_2h'**
  String get standard2h;

  /// No description provided for @storeClosed.
  ///
  /// In en, this message translates to:
  /// **'Store Closed'**
  String get storeClosed;

  /// No description provided for @storeNotFound2.
  ///
  /// In en, this message translates to:
  /// **'Store not found'**
  String get storeNotFound2;

  /// No description provided for @tabboulehSalad.
  ///
  /// In en, this message translates to:
  /// **'Tabbouleh Salad'**
  String get tabboulehSalad;

  /// No description provided for @tapAStarToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to rate'**
  String get tapAStarToRate;

  /// No description provided for @tapOnMapOrSearchTo.
  ///
  /// In en, this message translates to:
  /// **'Tap on map or search to select'**
  String get tapOnMapOrSearchTo;

  /// No description provided for @tapTheMapOrSearchTo.
  ///
  /// In en, this message translates to:
  /// **'Tap the map or search to pick a location'**
  String get tapTheMapOrSearchTo;

  /// No description provided for @tapToPickLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick location on map'**
  String get tapToPickLocationOnMap;

  /// No description provided for @tapToStartVoiceSearch.
  ///
  /// In en, this message translates to:
  /// **'Tap to start voice search'**
  String get tapToStartVoiceSearch;

  /// No description provided for @tariqElJdideh.
  ///
  /// In en, this message translates to:
  /// **'Tariq el Jdideh'**
  String get tariqElJdideh;

  /// No description provided for @taxi.
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get taxi;

  /// No description provided for @theStore.
  ///
  /// In en, this message translates to:
  /// **'the Store'**
  String get theStore;

  /// No description provided for @tomorrow200Pm600.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow 2:00 PM - 6:00 PM'**
  String get tomorrow200Pm600;

  /// No description provided for @towing.
  ///
  /// In en, this message translates to:
  /// **'Towing'**
  String get towing;

  /// No description provided for @tryExpandingYourSearchAreaOr.
  ///
  /// In en, this message translates to:
  /// **'Try expanding your search area or clearing the location filter'**
  String get tryExpandingYourSearchAreaOr;

  /// No description provided for @trySelectingADifferentCategory.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different category'**
  String get trySelectingADifferentCategory;

  /// No description provided for @understandingYourQuery.
  ///
  /// In en, this message translates to:
  /// **'Understanding your query...'**
  String get understandingYourQuery;

  /// No description provided for @unfortunatelyYourOrderWasRejected2.
  ///
  /// In en, this message translates to:
  /// **'Unfortunately, your order was rejected.'**
  String get unfortunatelyYourOrderWasRejected2;

  /// No description provided for @unitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get unitedKingdom;

  /// No description provided for @unitedStates.
  ///
  /// In en, this message translates to:
  /// **'United States'**
  String get unitedStates;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @unknownAd.
  ///
  /// In en, this message translates to:
  /// **'Unknown Ad'**
  String get unknownAd;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Customer'**
  String get unknownCustomer;

  /// No description provided for @unknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown Item'**
  String get unknownItem;

  /// No description provided for @unknownListing.
  ///
  /// In en, this message translates to:
  /// **'Unknown Listing'**
  String get unknownListing;

  /// No description provided for @unknownPlan.
  ///
  /// In en, this message translates to:
  /// **'Unknown Plan'**
  String get unknownPlan;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @unknownResult.
  ///
  /// In en, this message translates to:
  /// **'Unknown result'**
  String get unknownResult;

  /// No description provided for @unknownSeller.
  ///
  /// In en, this message translates to:
  /// **'Unknown Seller'**
  String get unknownSeller;

  /// No description provided for @unknownStore.
  ///
  /// In en, this message translates to:
  /// **'Unknown Store'**
  String get unknownStore;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @unnamedProduct.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Product'**
  String get unnamedProduct;

  /// No description provided for @unnamedStore.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Store'**
  String get unnamedStore;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @upTo50OffOnSelected.
  ///
  /// In en, this message translates to:
  /// **'Up to 50% off on selected items'**
  String get upTo50OffOnSelected;

  /// No description provided for @updateYourBusinessInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your business information'**
  String get updateYourBusinessInformation;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @userAccountActivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User account activated successfully'**
  String get userAccountActivatedSuccessfully;

  /// No description provided for @userAccountSuspendedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User account suspended successfully'**
  String get userAccountSuspendedSuccessfully;

  /// No description provided for @usingBaseFeeSetExactLocation.
  ///
  /// In en, this message translates to:
  /// **'Using base fee — set exact location for accurate pricing'**
  String get usingBaseFeeSetExactLocation;

  /// No description provided for @vehicleTowingService.
  ///
  /// In en, this message translates to:
  /// **'Vehicle towing service'**
  String get vehicleTowingService;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @verdunStreetBeirut.
  ///
  /// In en, this message translates to:
  /// **'Verdun Street, Beirut'**
  String get verdunStreetBeirut;

  /// No description provided for @verdunBeirut.
  ///
  /// In en, this message translates to:
  /// **'Verdun, Beirut'**
  String get verdunBeirut;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @verificationFailedPleaseCheckTheCode.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please check the code and try again.'**
  String get verificationFailedPleaseCheckTheCode;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get verificationPending;

  /// No description provided for @verifiedMerchant.
  ///
  /// In en, this message translates to:
  /// **'Verified Merchant'**
  String get verifiedMerchant;

  /// No description provided for @vitaminCTablets.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C Tablets'**
  String get vitaminCTablets;

  /// No description provided for @voiceSearchActivated.
  ///
  /// In en, this message translates to:
  /// **'Voice search activated'**
  String get voiceSearchActivated;

  /// No description provided for @voiceSearchHelpsYouFindProducts.
  ///
  /// In en, this message translates to:
  /// **'Voice search helps you find products quickly'**
  String get voiceSearchHelpsYouFindProducts;

  /// No description provided for @waterDelivery.
  ///
  /// In en, this message translates to:
  /// **'Water Delivery'**
  String get waterDelivery;

  /// No description provided for @whatAreasDoYouService.
  ///
  /// In en, this message translates to:
  /// **'What areas do you service?'**
  String get whatAreasDoYouService;

  /// No description provided for @whatIsTheCondition.
  ///
  /// In en, this message translates to:
  /// **'What is the condition?'**
  String get whatIsTheCondition;

  /// No description provided for @whenCanIPickUp.
  ///
  /// In en, this message translates to:
  /// **'When can I pick up?'**
  String get whenCanIPickUp;

  /// No description provided for @whishMoney.
  ///
  /// In en, this message translates to:
  /// **'Whish Money'**
  String get whishMoney;

  /// No description provided for @wholeMilk1l.
  ///
  /// In en, this message translates to:
  /// **'Whole Milk 1L'**
  String get wholeMilk1l;

  /// No description provided for @wholeWheatBread.
  ///
  /// In en, this message translates to:
  /// **'Whole Wheat Bread'**
  String get wholeWheatBread;

  /// No description provided for @yesItIsFeelFreeTo.
  ///
  /// In en, this message translates to:
  /// **'Yes, it is! Feel free to ask any questions.'**
  String get yesItIsFeelFreeTo;

  /// No description provided for @youAlreadyHaveAPendingRole.
  ///
  /// In en, this message translates to:
  /// **'You already have a pending role upgrade request'**
  String get youAlreadyHaveAPendingRole;

  /// No description provided for @yourApplicationIsBeingReviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Your application is being reviewed by our team'**
  String get yourApplicationIsBeingReviewedBy;

  /// No description provided for @yourDeliveryDestination.
  ///
  /// In en, this message translates to:
  /// **'Your delivery destination'**
  String get yourDeliveryDestination;

  /// No description provided for @yourDriverHasPickedUpYour.
  ///
  /// In en, this message translates to:
  /// **'Your driver has picked up your order'**
  String get yourDriverHasPickedUpYour;

  /// No description provided for @yourMerchantApplicationWasRejected.
  ///
  /// In en, this message translates to:
  /// **'Your merchant application was rejected'**
  String get yourMerchantApplicationWasRejected;

  /// No description provided for @yourOrderHasBeenAcceptedBy.
  ///
  /// In en, this message translates to:
  /// **'Your order has been accepted by the store.'**
  String get yourOrderHasBeenAcceptedBy;

  /// No description provided for @yourOrderHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your order has been cancelled'**
  String get yourOrderHasBeenCancelled;

  /// No description provided for @yourOrderHasBeenCancelled2.
  ///
  /// In en, this message translates to:
  /// **'Your order has been cancelled.'**
  String get yourOrderHasBeenCancelled2;

  /// No description provided for @yourOrderHasBeenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your order has been confirmed'**
  String get yourOrderHasBeenConfirmed;

  /// No description provided for @yourOrderHasBeenPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Your order has been picked up by the driver.'**
  String get yourOrderHasBeenPickedUp;

  /// No description provided for @yourOrderIsBeingPrepared.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared'**
  String get yourOrderIsBeingPrepared;

  /// No description provided for @yourOrderIsBeingPreparedBy.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared by the store.'**
  String get yourOrderIsBeingPreparedBy;

  /// No description provided for @yourOrderIsReadyAndWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready and waiting for a driver'**
  String get yourOrderIsReadyAndWaiting;

  /// No description provided for @yourOrderIsReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready for pickup.'**
  String get yourOrderIsReadyForPickup;

  /// No description provided for @yourOrderPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Your order pickup location'**
  String get yourOrderPickupLocation;

  /// No description provided for @yourTrustedPharmacyPartner.
  ///
  /// In en, this message translates to:
  /// **'Your trusted pharmacy partner'**
  String get yourTrustedPharmacyPartner;

  /// No description provided for @zalka.
  ///
  /// In en, this message translates to:
  /// **'Zalka'**
  String get zalka;

  /// No description provided for @zgharta.
  ///
  /// In en, this message translates to:
  /// **'Zgharta'**
  String get zgharta;

  /// No description provided for @editModeEnabledTapEditIcons.
  ///
  /// In en, this message translates to:
  /// **'✏️ Edit mode enabled - tap edit icons to modify content'**
  String get editModeEnabledTapEditIcons;

  /// No description provided for @editModeDisabledViewingAsCustomer.
  ///
  /// In en, this message translates to:
  /// **'👁️ Edit mode disabled - viewing as customer'**
  String get editModeDisabledViewingAsCustomer;

  /// No description provided for @cashOnDelivery2.
  ///
  /// In en, this message translates to:
  /// **'💵 Cash on Delivery'**
  String get cashOnDelivery2;

  /// No description provided for @whishMoney2.
  ///
  /// In en, this message translates to:
  /// **'📱 Whish Money'**
  String get whishMoney2;

  /// No description provided for @n1000Am1200Pm.
  ///
  /// In en, this message translates to:
  /// **'10:00 AM - 12:00 PM'**
  String get n1000Am1200Pm;

  /// No description provided for @n400Pm600Pm.
  ///
  /// In en, this message translates to:
  /// **'4:00 PM - 6:00 PM'**
  String get n400Pm600Pm;

  /// No description provided for @aWorldOfChoiceDelivered.
  ///
  /// In en, this message translates to:
  /// **'A world of choice, delivered.'**
  String get aWorldOfChoiceDelivered;

  /// No description provided for @aiInterpreted.
  ///
  /// In en, this message translates to:
  /// **'AI Interpreted:'**
  String get aiInterpreted;

  /// No description provided for @aiMealPlanning.
  ///
  /// In en, this message translates to:
  /// **'AI Meal Planning'**
  String get aiMealPlanning;

  /// No description provided for @aiReqs.
  ///
  /// In en, this message translates to:
  /// **'AI Reqs'**
  String get aiReqs;

  /// No description provided for @aiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearch;

  /// No description provided for @aiCreatesAPersonalizedMealPlan.
  ///
  /// In en, this message translates to:
  /// **'AI creates a personalized meal plan using products available in KJ Delivery stores'**
  String get aiCreatesAPersonalizedMealPlan;

  /// No description provided for @aanjar.
  ///
  /// In en, this message translates to:
  /// **'Aanjar'**
  String get aanjar;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @acceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance'**
  String get acceptance;

  /// No description provided for @achrafieh.
  ///
  /// In en, this message translates to:
  /// **'Achrafieh'**
  String get achrafieh;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNow;

  /// No description provided for @adAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Ad Analytics'**
  String get adAnalytics;

  /// No description provided for @adSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Ad Subtitle'**
  String get adSubtitle2;

  /// No description provided for @addAllToCart.
  ///
  /// In en, this message translates to:
  /// **'Add All to Cart?'**
  String get addAllToCart;

  /// No description provided for @addBanner.
  ///
  /// In en, this message translates to:
  /// **'Add Banner'**
  String get addBanner;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add New Card'**
  String get addNewCard;

  /// No description provided for @addDeliveryNotesForTheDriver.
  ///
  /// In en, this message translates to:
  /// **'Add delivery notes for the driver (optional)'**
  String get addDeliveryNotesForTheDriver;

  /// No description provided for @address2.
  ///
  /// In en, this message translates to:
  /// **'Address *'**
  String get address2;

  /// No description provided for @adminEditModeOnTapEdit.
  ///
  /// In en, this message translates to:
  /// **'Admin Edit Mode ON — Tap edit icons on sections'**
  String get adminEditModeOnTapEdit;

  /// No description provided for @adminLogout.
  ///
  /// In en, this message translates to:
  /// **'Admin Logout'**
  String get adminLogout;

  /// No description provided for @ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ads;

  /// No description provided for @aley.
  ///
  /// In en, this message translates to:
  /// **'Aley'**
  String get aley;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allCategories2.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories2;

  /// No description provided for @allowLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get allowLocationAccess;

  /// No description provided for @antelias.
  ///
  /// In en, this message translates to:
  /// **'Antelias'**
  String get antelias;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @applicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Application Details'**
  String get applicationDetails;

  /// No description provided for @applicationUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Application Under Review'**
  String get applicationUnderReview;

  /// No description provided for @applicationSubmittedSuccessfullyYouWillBe.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully! You will be notified once reviewed.'**
  String get applicationSubmittedSuccessfullyYouWillBe;

  /// No description provided for @applyAsAMerchantOrDriver.
  ///
  /// In en, this message translates to:
  /// **'Apply as a merchant or driver'**
  String get applyAsAMerchantOrDriver;

  /// No description provided for @applyForRoleUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Apply for Role Upgrade'**
  String get applyForRoleUpgrade;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @areYouSureYouWantTo9.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive this conversation?'**
  String get areYouSureYouWantTo9;

  /// No description provided for @areYouSureYouWantTo10.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this listing?'**
  String get areYouSureYouWantTo10;

  /// No description provided for @areYouSureYouWantTo11.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from admin panel?'**
  String get areYouSureYouWantTo11;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @assignmentBlockedDriverIsNoLonger2.
  ///
  /// In en, this message translates to:
  /// **'Assignment blocked — driver is no longer online. Refresh and try again.'**
  String get assignmentBlockedDriverIsNoLonger2;

  /// No description provided for @availableOrders.
  ///
  /// In en, this message translates to:
  /// **'Available Orders'**
  String get availableOrders;

  /// No description provided for @availablePlans.
  ///
  /// In en, this message translates to:
  /// **'Available Plans'**
  String get availablePlans;

  /// No description provided for @avgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Time'**
  String get avgTime;

  /// No description provided for @baabda.
  ///
  /// In en, this message translates to:
  /// **'Baabda'**
  String get baabda;

  /// No description provided for @baalbek.
  ///
  /// In en, this message translates to:
  /// **'Baalbek'**
  String get baalbek;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @badaro.
  ///
  /// In en, this message translates to:
  /// **'Badaro'**
  String get badaro;

  /// No description provided for @bannerImage.
  ///
  /// In en, this message translates to:
  /// **'Banner Image'**
  String get bannerImage;

  /// No description provided for @barcodeScanner.
  ///
  /// In en, this message translates to:
  /// **'Barcode Scanner'**
  String get barcodeScanner;

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePrice;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @batroun.
  ///
  /// In en, this message translates to:
  /// **'Batroun'**
  String get batroun;

  /// No description provided for @beirut.
  ///
  /// In en, this message translates to:
  /// **'Beirut'**
  String get beirut;

  /// No description provided for @beitMery.
  ///
  /// In en, this message translates to:
  /// **'Beit Mery'**
  String get beitMery;

  /// No description provided for @beiteddine.
  ///
  /// In en, this message translates to:
  /// **'Beiteddine'**
  String get beiteddine;

  /// No description provided for @bhamdoun.
  ///
  /// In en, this message translates to:
  /// **'Bhamdoun'**
  String get bhamdoun;

  /// No description provided for @bikfaya.
  ///
  /// In en, this message translates to:
  /// **'Bikfaya'**
  String get bikfaya;

  /// No description provided for @bintJbeil.
  ///
  /// In en, this message translates to:
  /// **'Bint Jbeil'**
  String get bintJbeil;

  /// No description provided for @bourjHammoud.
  ///
  /// In en, this message translates to:
  /// **'Bourj Hammoud'**
  String get bourjHammoud;

  /// No description provided for @broummana.
  ///
  /// In en, this message translates to:
  /// **'Broummana'**
  String get broummana;

  /// No description provided for @bsharri.
  ///
  /// In en, this message translates to:
  /// **'Bsharri'**
  String get bsharri;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @businessType2.
  ///
  /// In en, this message translates to:
  /// **'Business Type *'**
  String get businessType2;

  /// No description provided for @buy2Get1Free.
  ///
  /// In en, this message translates to:
  /// **'Buy 2 Get 1 FREE'**
  String get buy2Get1Free;

  /// No description provided for @buying.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get buying;

  /// No description provided for @currentPlan2.
  ///
  /// In en, this message translates to:
  /// **'CURRENT PLAN'**
  String get currentPlan2;

  /// No description provided for @callOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Call on Arrival'**
  String get callOnArrival;

  /// No description provided for @cannotAssignOrdersDriverIsOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign orders — driver is offline or not approved'**
  String get cannotAssignOrdersDriverIsOffline;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @changeAdStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Ad Status'**
  String get changeAdStatus;

  /// No description provided for @chatWithUsOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Chat with us on WhatsApp'**
  String get chatWithUsOnWhatsapp;

  /// No description provided for @checkBackLaterForNewDelivery.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new delivery opportunities'**
  String get checkBackLaterForNewDelivery;

  /// No description provided for @checkBackLaterForServiceProviders.
  ///
  /// In en, this message translates to:
  /// **'Check back later for service providers'**
  String get checkBackLaterForServiceProviders;

  /// No description provided for @chekka.
  ///
  /// In en, this message translates to:
  /// **'Chekka'**
  String get chekka;

  /// No description provided for @chouf.
  ///
  /// In en, this message translates to:
  /// **'Chouf'**
  String get chouf;

  /// No description provided for @chtaura.
  ///
  /// In en, this message translates to:
  /// **'Chtaura'**
  String get chtaura;

  /// No description provided for @cleanDrivingRecord.
  ///
  /// In en, this message translates to:
  /// **'Clean driving record'**
  String get cleanDrivingRecord;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get clearFilter;

  /// No description provided for @clicks.
  ///
  /// In en, this message translates to:
  /// **'Clicks'**
  String get clicks;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @connectionIssue.
  ///
  /// In en, this message translates to:
  /// **'Connection Issue'**
  String get connectionIssue;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @contactSeller.
  ///
  /// In en, this message translates to:
  /// **'Contact Seller'**
  String get contactSeller;

  /// No description provided for @contactlessDelivery.
  ///
  /// In en, this message translates to:
  /// **'Contactless Delivery'**
  String get contactlessDelivery;

  /// No description provided for @contentManager.
  ///
  /// In en, this message translates to:
  /// **'Content Manager'**
  String get contentManager;

  /// No description provided for @continueToApp.
  ///
  /// In en, this message translates to:
  /// **'Continue to App'**
  String get continueToApp;

  /// No description provided for @continueYourShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue your shopping'**
  String get continueYourShopping;

  /// No description provided for @conversationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Conversation not found'**
  String get conversationNotFound;

  /// No description provided for @conversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get conversations;

  /// No description provided for @createYourFirstAdToGet.
  ///
  /// In en, this message translates to:
  /// **'Create your first ad to get started'**
  String get createYourFirstAdToGet;

  /// No description provided for @createYourFirstListingToGet.
  ///
  /// In en, this message translates to:
  /// **'Create your first listing to get started'**
  String get createYourFirstListingToGet;

  /// No description provided for @cuisinePreferences.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Preferences'**
  String get cuisinePreferences;

  /// No description provided for @customerSupport247.
  ///
  /// In en, this message translates to:
  /// **'Customer Support 24/7'**
  String get customerSupport247;

  /// No description provided for @customerInsightsWillAppearHereOnce.
  ///
  /// In en, this message translates to:
  /// **'Customer insights will appear here once you receive orders.'**
  String get customerInsightsWillAppearHereOnce;

  /// No description provided for @customerReviewsWillAppearHereOnce.
  ///
  /// In en, this message translates to:
  /// **'Customer reviews will appear here once they start rating your store and products.'**
  String get customerReviewsWillAppearHereOnce;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @dbayeh.
  ///
  /// In en, this message translates to:
  /// **'Dbayeh'**
  String get dbayeh;

  /// No description provided for @dealsOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Deals of the Day'**
  String get dealsOfTheDay;

  /// No description provided for @dealsCouponsFlashSales.
  ///
  /// In en, this message translates to:
  /// **'Deals, coupons, flash sales'**
  String get dealsCouponsFlashSales;

  /// No description provided for @dekwaneh.
  ///
  /// In en, this message translates to:
  /// **'Dekwaneh'**
  String get dekwaneh;

  /// No description provided for @deliverOrdersAndEarnMoneyOn.
  ///
  /// In en, this message translates to:
  /// **'Deliver orders and earn money on your own terms'**
  String get deliverOrdersAndEarnMoneyOn;

  /// No description provided for @deliveryAddresses2.
  ///
  /// In en, this message translates to:
  /// **'Delivery Addresses'**
  String get deliveryAddresses2;

  /// No description provided for @deliveryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Delivery Alerts'**
  String get deliveryAlerts;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @deliveryFeesFromAllActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivery fees from all active orders (cancellations excluded)'**
  String get deliveryFeesFromAllActiveOrders;

  /// No description provided for @demoModeActive.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode Active'**
  String get demoModeActive;

  /// No description provided for @demoDataHasBeenSuccessfullySeeded.
  ///
  /// In en, this message translates to:
  /// **'Demo data has been successfully seeded. Summary:'**
  String get demoDataHasBeenSuccessfullySeeded;

  /// No description provided for @describeYourItemInDetail.
  ///
  /// In en, this message translates to:
  /// **'Describe your item in detail...'**
  String get describeYourItemInDetail;

  /// No description provided for @developerTools.
  ///
  /// In en, this message translates to:
  /// **'Developer Tools'**
  String get developerTools;

  /// No description provided for @didNotReceiveTheCode.
  ///
  /// In en, this message translates to:
  /// **'Did not receive the code?'**
  String get didNotReceiveTheCode;

  /// No description provided for @dietType.
  ///
  /// In en, this message translates to:
  /// **'Diet Type'**
  String get dietType;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @dora.
  ///
  /// In en, this message translates to:
  /// **'Dora'**
  String get dora;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @dragAndDropToChangeOrder.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop to change order'**
  String get dragAndDropToChangeOrder;

  /// No description provided for @driverStatus.
  ///
  /// In en, this message translates to:
  /// **'Driver Status'**
  String get driverStatus;

  /// No description provided for @driverAssignedArrivingSoon.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned, arriving soon'**
  String get driverAssignedArrivingSoon;

  /// No description provided for @driverCallsWhenArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver calls when arriving'**
  String get driverCallsWhenArriving;

  /// No description provided for @driverLeavesOrderAtYourDoor.
  ///
  /// In en, this message translates to:
  /// **'Driver leaves order at your door'**
  String get driverLeavesOrderAtYourDoor;

  /// No description provided for @driverRingsDoorbellOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Driver rings doorbell on arrival'**
  String get driverRingsDoorbellOnArrival;

  /// No description provided for @earnOnYourSchedule.
  ///
  /// In en, this message translates to:
  /// **'Earn on Your Schedule'**
  String get earnOnYourSchedule;

  /// No description provided for @editCart.
  ///
  /// In en, this message translates to:
  /// **'Edit Cart'**
  String get editCart;

  /// No description provided for @editMode.
  ///
  /// In en, this message translates to:
  /// **'Edit Mode'**
  String get editMode;

  /// No description provided for @editSystem.
  ///
  /// In en, this message translates to:
  /// **'Edit System'**
  String get editSystem;

  /// No description provided for @editModeIsOnTapEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit mode is ON - Tap edit icons on supported sections throughout the app'**
  String get editModeIsOnTapEdit;

  /// No description provided for @ehden.
  ///
  /// In en, this message translates to:
  /// **'Ehden'**
  String get ehden;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @enterAddressManually.
  ///
  /// In en, this message translates to:
  /// **'Enter Address Manually'**
  String get enterAddressManually;

  /// No description provided for @enterTheVerificationCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to'**
  String get enterTheVerificationCodeSentTo;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Error Details:'**
  String get errorDetails;

  /// No description provided for @errorLoadingMerchant.
  ///
  /// In en, this message translates to:
  /// **'Error loading merchant'**
  String get errorLoadingMerchant;

  /// No description provided for @errorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get errorLoadingServices;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @estimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated Arrival'**
  String get estimatedArrival;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @exploreMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Explore Marketplace'**
  String get exploreMarketplace;

  /// No description provided for @exploreProducts.
  ///
  /// In en, this message translates to:
  /// **'Explore Products'**
  String get exploreProducts;

  /// No description provided for @failedToDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get failedToDeleteCategory;

  /// No description provided for @failedToDeleteSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete subcategory'**
  String get failedToDeleteSubcategory;

  /// No description provided for @failedToLoadAds.
  ///
  /// In en, this message translates to:
  /// **'Failed to load ads'**
  String get failedToLoadAds;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @failedToLoadListings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load listings'**
  String get failedToLoadListings;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// No description provided for @failedToLoadSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subcategories'**
  String get failedToLoadSubcategories;

  /// No description provided for @failedToLoadSubscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription plans'**
  String get failedToLoadSubscriptionPlans;

  /// No description provided for @failedToProcessRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to process recording.'**
  String get failedToProcessRecording;

  /// No description provided for @failedToProcessVoiceInput.
  ///
  /// In en, this message translates to:
  /// **'Failed to process voice input.'**
  String get failedToProcessVoiceInput;

  /// No description provided for @failedToReorderCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder categories'**
  String get failedToReorderCategories;

  /// No description provided for @failedToReorderSubcategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder subcategories'**
  String get failedToReorderSubcategories;

  /// No description provided for @failedToStartRecordingPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Failed to start recording. Please try again.'**
  String get failedToStartRecordingPleaseTry;

  /// No description provided for @failedToUpdateActiveState.
  ///
  /// In en, this message translates to:
  /// **'Failed to update active state'**
  String get failedToUpdateActiveState;

  /// No description provided for @failedToValidateDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to validate delete'**
  String get failedToValidateDelete;

  /// No description provided for @fallbackColorWhenNoBannerIs.
  ///
  /// In en, this message translates to:
  /// **'Fallback color when no banner is set'**
  String get fallbackColorWhenNoBannerIs;

  /// No description provided for @faraya.
  ///
  /// In en, this message translates to:
  /// **'Faraya'**
  String get faraya;

  /// No description provided for @farmFreshOrganicProduceDeliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Farm-fresh organic produce delivered to your doorstep'**
  String get farmFreshOrganicProduceDeliveredTo;

  /// No description provided for @fastReliableDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fast & Reliable Delivery'**
  String get fastReliableDelivery;

  /// No description provided for @fastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get fastest;

  /// No description provided for @featureComparison.
  ///
  /// In en, this message translates to:
  /// **'Feature Comparison'**
  String get featureComparison;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @fillInTheDetailsBelowName.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below. Name, price, and type are required.'**
  String get fillInTheDetailsBelowName;

  /// No description provided for @filterOrders.
  ///
  /// In en, this message translates to:
  /// **'Filter Orders'**
  String get filterOrders;

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @findEverythingYouNeed.
  ///
  /// In en, this message translates to:
  /// **'Find everything you need'**
  String get findEverythingYouNeed;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @freshOrganicVegetables.
  ///
  /// In en, this message translates to:
  /// **'Fresh Organic Vegetables'**
  String get freshOrganicVegetables;

  /// No description provided for @freshMilkCheeseAndYogurtFrom.
  ///
  /// In en, this message translates to:
  /// **'Fresh milk, cheese, and yogurt from local farms'**
  String get freshMilkCheeseAndYogurtFrom;

  /// No description provided for @fromStoresYouFollow.
  ///
  /// In en, this message translates to:
  /// **'From stores you follow'**
  String get fromStoresYouFollow;

  /// No description provided for @fullSystemManagement.
  ///
  /// In en, this message translates to:
  /// **'Full system management'**
  String get fullSystemManagement;

  /// No description provided for @gemmayzeh.
  ///
  /// In en, this message translates to:
  /// **'Gemmayzeh'**
  String get gemmayzeh;

  /// No description provided for @generateMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Generate Meal Plan'**
  String get generateMealPlan;

  /// No description provided for @getInstantHelpFromOurAi.
  ///
  /// In en, this message translates to:
  /// **'Get instant help from our AI assistant or contact support directly.'**
  String get getInstantHelpFromOurAi;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address...'**
  String get gettingAddress;

  /// No description provided for @groceryList.
  ///
  /// In en, this message translates to:
  /// **'Grocery List'**
  String get groceryList;

  /// No description provided for @halba.
  ///
  /// In en, this message translates to:
  /// **'Halba'**
  String get halba;

  /// No description provided for @hamra.
  ///
  /// In en, this message translates to:
  /// **'Hamra'**
  String get hamra;

  /// No description provided for @hazmieh.
  ///
  /// In en, this message translates to:
  /// **'Hazmieh'**
  String get hazmieh;

  /// No description provided for @hermel.
  ///
  /// In en, this message translates to:
  /// **'Hermel'**
  String get hermel;

  /// No description provided for @heroBanners.
  ///
  /// In en, this message translates to:
  /// **'Hero Banners'**
  String get heroBanners;

  /// No description provided for @householdSize.
  ///
  /// In en, this message translates to:
  /// **'Household Size'**
  String get householdSize;

  /// No description provided for @howToEditContent.
  ///
  /// In en, this message translates to:
  /// **'How to Edit Content'**
  String get howToEditContent;

  /// No description provided for @howWasYourExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience?'**
  String get howWasYourExperience;

  /// No description provided for @iAgreeToTheTermsAnd.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms and conditions and confirm that all information provided is accurate'**
  String get iAgreeToTheTermsAnd;

  /// No description provided for @importProducts.
  ///
  /// In en, this message translates to:
  /// **'Import Products'**
  String get importProducts;

  /// No description provided for @impressions.
  ///
  /// In en, this message translates to:
  /// **'Impressions'**
  String get impressions;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients:'**
  String get ingredients;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @itemsInYourCartOrFavorites.
  ///
  /// In en, this message translates to:
  /// **'Items in your cart or favorites'**
  String get itemsInYourCartOrFavorites;

  /// No description provided for @jalElDib.
  ///
  /// In en, this message translates to:
  /// **'Jal el Dib'**
  String get jalElDib;

  /// No description provided for @joinKjDeliveryAndStartYour.
  ///
  /// In en, this message translates to:
  /// **'Join KJ Delivery and start your journey'**
  String get joinKjDeliveryAndStartYour;

  /// No description provided for @joinOurMarketplaceAndReachThousands.
  ///
  /// In en, this message translates to:
  /// **'Join our marketplace and reach thousands of customers'**
  String get joinOurMarketplaceAndReachThousands;

  /// No description provided for @jounieh.
  ///
  /// In en, this message translates to:
  /// **'Jounieh'**
  String get jounieh;

  /// No description provided for @kaslik.
  ///
  /// In en, this message translates to:
  /// **'Kaslik'**
  String get kaslik;

  /// No description provided for @leaveAtDoor.
  ///
  /// In en, this message translates to:
  /// **'Leave at Door'**
  String get leaveAtDoor;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @lightningFastDeliveryToYourDoorstep.
  ///
  /// In en, this message translates to:
  /// **'Lightning-fast delivery to your doorstep. Fresh groceries delivered in 30 minutes or less, guaranteed.'**
  String get lightningFastDeliveryToYourDoorstep;

  /// No description provided for @listingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Listing not found'**
  String get listingNotFound;

  /// No description provided for @loadingAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading available orders...'**
  String get loadingAvailableOrders;

  /// No description provided for @loadingMerchantProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading merchant profile...'**
  String get loadingMerchantProfile;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationPermanentlyDeniedEnableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Location permanently denied. Enable in settings.'**
  String get locationPermanentlyDeniedEnableInSettings;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get loginWithGoogle;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @loyaltyRewards.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Rewards'**
  String get loyaltyRewards;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @manageYourDeliveryLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery locations'**
  String get manageYourDeliveryLocations;

  /// No description provided for @marMikhael.
  ///
  /// In en, this message translates to:
  /// **'Mar Mikhael'**
  String get marMikhael;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @marketplaceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Admin'**
  String get marketplaceAdmin;

  /// No description provided for @marketplaceListings.
  ///
  /// In en, this message translates to:
  /// **'Marketplace Listings'**
  String get marketplaceListings;

  /// No description provided for @maximumDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum Distance'**
  String get maximumDistance;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @merchantProfile.
  ///
  /// In en, this message translates to:
  /// **'Merchant Profile'**
  String get merchantProfile;

  /// No description provided for @messageSeller.
  ///
  /// In en, this message translates to:
  /// **'Message Seller'**
  String get messageSeller;

  /// No description provided for @minimum18YearsOld.
  ///
  /// In en, this message translates to:
  /// **'Minimum 18 years old'**
  String get minimum18YearsOld;

  /// No description provided for @minimumEarnings.
  ///
  /// In en, this message translates to:
  /// **'Minimum Earnings'**
  String get minimumEarnings;

  /// No description provided for @minimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order'**
  String get minimumOrder;

  /// No description provided for @monitorAndManageOrders.
  ///
  /// In en, this message translates to:
  /// **'Monitor and manage orders'**
  String get monitorAndManageOrders;

  /// No description provided for @myActivity.
  ///
  /// In en, this message translates to:
  /// **'My Activity'**
  String get myActivity;

  /// No description provided for @myBookings.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// No description provided for @nabatieh.
  ///
  /// In en, this message translates to:
  /// **'Nabatieh'**
  String get nabatieh;

  /// No description provided for @nego.
  ///
  /// In en, this message translates to:
  /// **'Nego'**
  String get nego;

  /// No description provided for @newProducts.
  ///
  /// In en, this message translates to:
  /// **'New Products'**
  String get newProducts;

  /// No description provided for @noAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'No Available Orders'**
  String get noAvailableOrders;

  /// No description provided for @noAdsYet.
  ///
  /// In en, this message translates to:
  /// **'No ads yet'**
  String get noAdsYet;

  /// No description provided for @noAnalyticsDataYet.
  ///
  /// In en, this message translates to:
  /// **'No analytics data yet'**
  String get noAnalyticsDataYet;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @noCategoriesInThisStoreYet.
  ///
  /// In en, this message translates to:
  /// **'No categories in this store yet. Product will be added without a category.'**
  String get noCategoriesInThisStoreYet;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @noDealsYetAddFeaturedProducts.
  ///
  /// In en, this message translates to:
  /// **'No deals yet. Add featured products.'**
  String get noDealsYetAddFeaturedProducts;

  /// No description provided for @noDriversOnline.
  ///
  /// In en, this message translates to:
  /// **'No drivers online'**
  String get noDriversOnline;

  /// No description provided for @noFaceToFaceInteraction.
  ///
  /// In en, this message translates to:
  /// **'No face-to-face interaction'**
  String get noFaceToFaceInteraction;

  /// No description provided for @noListingsNearThisLocation.
  ///
  /// In en, this message translates to:
  /// **'No listings near this location'**
  String get noListingsNearThisLocation;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'No pending orders'**
  String get noPendingOrders;

  /// No description provided for @noProductsFoundForThisSearch.
  ///
  /// In en, this message translates to:
  /// **'No products found for this search. Try browsing the categories or stores above.'**
  String get noProductsFoundForThisSearch;

  /// No description provided for @noProductsYet2.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYet2;

  /// No description provided for @noProvidersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No providers available'**
  String get noProvidersAvailable;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noStoresYet2.
  ///
  /// In en, this message translates to:
  /// **'No stores yet'**
  String get noStoresYet2;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @nowProceedingToReSeedDemo.
  ///
  /// In en, this message translates to:
  /// **'Now proceeding to re-seed demo data...'**
  String get nowProceedingToReSeedDemo;

  /// No description provided for @numberOfMeals.
  ///
  /// In en, this message translates to:
  /// **'Number of Meals'**
  String get numberOfMeals;

  /// No description provided for @onYourDevice.
  ///
  /// In en, this message translates to:
  /// **'On your device'**
  String get onYourDevice;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @orderPriority.
  ///
  /// In en, this message translates to:
  /// **'Order Priority'**
  String get orderPriority;

  /// No description provided for @orderSettings.
  ///
  /// In en, this message translates to:
  /// **'Order Settings'**
  String get orderSettings;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @orderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Order Updates'**
  String get orderUpdates;

  /// No description provided for @orderUpdatesPromotions.
  ///
  /// In en, this message translates to:
  /// **'Order updates, promotions'**
  String get orderUpdatesPromotions;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @outOfStock3.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock3;

  /// No description provided for @passwordAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password, account security'**
  String get passwordAccountSecurity;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Payment Options'**
  String get paymentOptions;

  /// No description provided for @perDelivery.
  ///
  /// In en, this message translates to:
  /// **'Per Delivery'**
  String get perDelivery;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'Per Hour'**
  String get perHour;

  /// No description provided for @perKilometer.
  ///
  /// In en, this message translates to:
  /// **'Per Kilometer'**
  String get perKilometer;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneVerifiedSuccessfullyYouCanNow.
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully! You can now access the app.'**
  String get phoneVerifiedSuccessfullyYouCanNow;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @planYourMeals.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Meals'**
  String get planYourMeals;

  /// No description provided for @planComparisonFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Plan comparison feature coming soon'**
  String get planComparisonFeatureComingSoon;

  /// No description provided for @plate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get plate;

  /// No description provided for @poweredByKjDelivery.
  ///
  /// In en, this message translates to:
  /// **'Powered by KJ Delivery'**
  String get poweredByKjDelivery;

  /// No description provided for @preferredStoreTypes.
  ///
  /// In en, this message translates to:
  /// **'Preferred Store Types'**
  String get preferredStoreTypes;

  /// No description provided for @premiumDairyProducts.
  ///
  /// In en, this message translates to:
  /// **'Premium Dairy Products'**
  String get premiumDairyProducts;

  /// No description provided for @preparationTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time'**
  String get preparationTime;

  /// No description provided for @priceDropAlerts.
  ///
  /// In en, this message translates to:
  /// **'Price Drop Alerts'**
  String get priceDropAlerts;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @price4.
  ///
  /// In en, this message translates to:
  /// **'Price ↑'**
  String get price4;

  /// No description provided for @price5.
  ///
  /// In en, this message translates to:
  /// **'Price ↓'**
  String get price5;

  /// No description provided for @pricingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Pricing updated'**
  String get pricingUpdated;

  /// No description provided for @productsWillAppearHereOnceCreated.
  ///
  /// In en, this message translates to:
  /// **'Products will appear here once created'**
  String get productsWillAppearHereOnceCreated;

  /// No description provided for @promoCode2.
  ///
  /// In en, this message translates to:
  /// **'Promo Code'**
  String get promoCode2;

  /// No description provided for @promotionsOffers.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Offers'**
  String get promotionsOffers;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @quickInquiries.
  ///
  /// In en, this message translates to:
  /// **'Quick Inquiries'**
  String get quickInquiries;

  /// No description provided for @quickSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Quick suggestions:'**
  String get quickSuggestions;

  /// No description provided for @rpcResetError.
  ///
  /// In en, this message translates to:
  /// **'RPC Reset Error'**
  String get rpcResetError;

  /// No description provided for @raouche.
  ///
  /// In en, this message translates to:
  /// **'Raouche'**
  String get raouche;

  /// No description provided for @rasBeirut.
  ///
  /// In en, this message translates to:
  /// **'Ras Beirut'**
  String get rasBeirut;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @recentOrdersWillAppearHereOnce.
  ///
  /// In en, this message translates to:
  /// **'Recent orders will appear here once customers start placing them.'**
  String get recentOrdersWillAppearHereOnce;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently Viewed'**
  String get recentlyViewed;

  /// No description provided for @regeneratePlan.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Plan'**
  String get regeneratePlan;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @relevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get relevance;

  /// No description provided for @reorderAll.
  ///
  /// In en, this message translates to:
  /// **'Reorder All'**
  String get reorderAll;

  /// No description provided for @reorderCategories.
  ///
  /// In en, this message translates to:
  /// **'Reorder Categories'**
  String get reorderCategories;

  /// No description provided for @reorderYourFavoritesWithOneTap.
  ///
  /// In en, this message translates to:
  /// **'Reorder your favorites with one tap'**
  String get reorderYourFavoritesWithOneTap;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// No description provided for @resetError.
  ///
  /// In en, this message translates to:
  /// **'Reset Error'**
  String get resetError;

  /// No description provided for @ringDoorbell.
  ///
  /// In en, this message translates to:
  /// **'Ring Doorbell'**
  String get ringDoorbell;

  /// No description provided for @roleUpgradeRequest.
  ///
  /// In en, this message translates to:
  /// **'Role Upgrade Request'**
  String get roleUpgradeRequest;

  /// No description provided for @roleUpgradeRequests.
  ///
  /// In en, this message translates to:
  /// **'Role Upgrade Requests'**
  String get roleUpgradeRequests;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotifications;

  /// No description provided for @saida.
  ///
  /// In en, this message translates to:
  /// **'Saida'**
  String get saida;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @salePriceMustBeLessThan.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be less than original price'**
  String get salePriceMustBeLessThan;

  /// No description provided for @salePriceMustBeLessThan2.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be less than regular price'**
  String get salePriceMustBeLessThan2;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @seasonalFruits.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Fruits'**
  String get seasonalFruits;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @seeAll2.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll2;

  /// No description provided for @seedingError.
  ///
  /// In en, this message translates to:
  /// **'Seeding Error'**
  String get seedingError;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// No description provided for @selectTheRoleYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Select the role you want to apply for and provide the required information'**
  String get selectTheRoleYouWantTo;

  /// No description provided for @sellerInformation.
  ///
  /// In en, this message translates to:
  /// **'Seller Information'**
  String get sellerInformation;

  /// No description provided for @selling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get selling;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @sendAQuickMessageToThe.
  ///
  /// In en, this message translates to:
  /// **'Send a quick message to the seller'**
  String get sendAQuickMessageToThe;

  /// No description provided for @sendingVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Sending verification code...'**
  String get sendingVerificationCode;

  /// No description provided for @shopNow.
  ///
  /// In en, this message translates to:
  /// **'Shop Now'**
  String get shopNow;

  /// No description provided for @shopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by Category'**
  String get shopByCategory;

  /// No description provided for @signInToYourAccountTo.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account to continue'**
  String get signInToYourAccountTo;

  /// No description provided for @sinElFil.
  ///
  /// In en, this message translates to:
  /// **'Sin el Fil'**
  String get sinElFil;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @smartSearchTips.
  ///
  /// In en, this message translates to:
  /// **'Smart Search Tips'**
  String get smartSearchTips;

  /// No description provided for @smartSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get smartSuggestions;

  /// No description provided for @smartSuggestionsBasedOnYourPreferences.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions based on your preferences and purchase history. Discover new products tailored just for you.'**
  String get smartSuggestionsBasedOnYourPreferences;

  /// No description provided for @smartphoneWithGps.
  ///
  /// In en, this message translates to:
  /// **'Smartphone with GPS'**
  String get smartphoneWithGps;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @startSellingToday.
  ///
  /// In en, this message translates to:
  /// **'Start Selling Today'**
  String get startSellingToday;

  /// No description provided for @startChattingWithSellersAboutItems.
  ///
  /// In en, this message translates to:
  /// **'Start chatting with sellers about items you are interested in'**
  String get startChattingWithSellersAboutItems;

  /// No description provided for @startShoppingToSeeYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Start shopping to see your order history here. Discover fresh groceries and everyday essentials.'**
  String get startShoppingToSeeYourOrder;

  /// No description provided for @startTheConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation!'**
  String get startTheConversation;

  /// No description provided for @statusChangesConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Status changes, confirmations'**
  String get statusChangesConfirmations;

  /// No description provided for @storeLogo.
  ///
  /// In en, this message translates to:
  /// **'Store Logo'**
  String get storeLogo;

  /// No description provided for @storeRated.
  ///
  /// In en, this message translates to:
  /// **'Store Rated ⭐'**
  String get storeRated;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @summaryOfActivity.
  ///
  /// In en, this message translates to:
  /// **'Summary of activity'**
  String get summaryOfActivity;

  /// No description provided for @sweetAndJuicyFruitsPickedAt.
  ///
  /// In en, this message translates to:
  /// **'Sweet and juicy fruits picked at perfect ripeness'**
  String get sweetAndJuicyFruitsPickedAt;

  /// No description provided for @tapToManageThisContent.
  ///
  /// In en, this message translates to:
  /// **'Tap to manage this content'**
  String get tapToManageThisContent;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @textMessages.
  ///
  /// In en, this message translates to:
  /// **'Text messages'**
  String get textMessages;

  /// No description provided for @theBarcodeWillBeScannedAutomatically.
  ///
  /// In en, this message translates to:
  /// **'The barcode will be scanned automatically'**
  String get theBarcodeWillBeScannedAutomatically;

  /// No description provided for @thisCategoryHasSubcategoriesDeleteSubcategories.
  ///
  /// In en, this message translates to:
  /// **'This category has subcategories. Delete subcategories first.'**
  String get thisCategoryHasSubcategoriesDeleteSubcategories;

  /// No description provided for @thisItemIsCurrentlyOutOf.
  ///
  /// In en, this message translates to:
  /// **'This item is currently out of stock'**
  String get thisItemIsCurrentlyOutOf;

  /// No description provided for @thisSubcategoryHasNestedChildrenDelete.
  ///
  /// In en, this message translates to:
  /// **'This subcategory has nested children. Delete them first.'**
  String get thisSubcategoryHasNestedChildrenDelete;

  /// No description provided for @thisWillCallResetDemoData.
  ///
  /// In en, this message translates to:
  /// **'This will call reset_demo_data() RPC to delete all demo rows, then re-seed the database. Continue?'**
  String get thisWillCallResetDemoData;

  /// No description provided for @thisWillCreateAPlatformWide.
  ///
  /// In en, this message translates to:
  /// **'This will create a platform-wide notification visible to all users.'**
  String get thisWillCreateAPlatformWide;

  /// No description provided for @thisWillDeleteTheDriverRecord.
  ///
  /// In en, this message translates to:
  /// **'This will delete the driver record and reset this user to a customer. They can re-apply as a driver later. Continue?'**
  String get thisWillDeleteTheDriverRecord;

  /// No description provided for @thisWillSearchForMatchingProducts.
  ///
  /// In en, this message translates to:
  /// **'This will search for matching products in available stores and add them to your cart. Items not found in any store will be skipped.'**
  String get thisWillSearchForMatchingProducts;

  /// No description provided for @timeSlotsSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Time slots, special instructions'**
  String get timeSlotsSpecialInstructions;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @toYourRegisteredEmail.
  ///
  /// In en, this message translates to:
  /// **'To your registered email'**
  String get toYourRegisteredEmail;

  /// No description provided for @topStores.
  ///
  /// In en, this message translates to:
  /// **'Top Stores'**
  String get topStores;

  /// No description provided for @totalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total Spent'**
  String get totalSpent;

  /// No description provided for @trendingProducts.
  ///
  /// In en, this message translates to:
  /// **'Trending Products'**
  String get trendingProducts;

  /// No description provided for @tripoli.
  ///
  /// In en, this message translates to:
  /// **'Tripoli'**
  String get tripoli;

  /// No description provided for @tryADifferentSearchTermOr.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or browse categories'**
  String get tryADifferentSearchTermOr;

  /// No description provided for @tryAdjustingYourSearchOrFilters2.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingYourSearchOrFilters2;

  /// No description provided for @tryAskingAiInNaturalLanguage.
  ///
  /// In en, this message translates to:
  /// **'Try asking AI in natural language:'**
  String get tryAskingAiInNaturalLanguage;

  /// No description provided for @tryExpandingYourSearchAreaOr2.
  ///
  /// In en, this message translates to:
  /// **'Try expanding your search area or browse all of Lebanon'**
  String get tryExpandingYourSearchAreaOr2;

  /// No description provided for @tryRephrasingYourSearchOrAdjusting.
  ///
  /// In en, this message translates to:
  /// **'Try rephrasing your search or adjusting filters'**
  String get tryRephrasingYourSearchOrAdjusting;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @tyre.
  ///
  /// In en, this message translates to:
  /// **'Tyre'**
  String get tyre;

  /// No description provided for @unableToInitializeTheAppPlease.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize the app. Please check your connection and try again.'**
  String get unableToInitializeTheAppPlease;

  /// No description provided for @upTo40Off.
  ///
  /// In en, this message translates to:
  /// **'Up to 40% OFF'**
  String get upTo40Off;

  /// No description provided for @useCode123456ToVerify.
  ///
  /// In en, this message translates to:
  /// **'Use code: 123456 to verify'**
  String get useCode123456ToVerify;

  /// No description provided for @useMyCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// No description provided for @useTheCreateButtonInAdmin.
  ///
  /// In en, this message translates to:
  /// **'Use the Create button in Admin bar to add stores'**
  String get useTheCreateButtonInAdmin;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @usersManagement.
  ///
  /// In en, this message translates to:
  /// **'Users Management'**
  String get usersManagement;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @vehicleLicense.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & License'**
  String get vehicleLicense;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type *'**
  String get vehicleType;

  /// No description provided for @vehicleInGoodWorkingCondition.
  ///
  /// In en, this message translates to:
  /// **'Vehicle in good working condition'**
  String get vehicleInGoodWorkingCondition;

  /// No description provided for @verdun.
  ///
  /// In en, this message translates to:
  /// **'Verdun'**
  String get verdun;

  /// No description provided for @verifiedSeller.
  ///
  /// In en, this message translates to:
  /// **'Verified Seller'**
  String get verifiedSeller;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewAllListings.
  ///
  /// In en, this message translates to:
  /// **'View All Listings'**
  String get viewAllListings;

  /// No description provided for @viewAndManageAllUsers.
  ///
  /// In en, this message translates to:
  /// **'View and manage all users'**
  String get viewAndManageAllUsers;

  /// No description provided for @viewPastOrdersAndReorder.
  ///
  /// In en, this message translates to:
  /// **'View past orders and reorder'**
  String get viewPastOrdersAndReorder;

  /// No description provided for @weEncounteredAnUnexpectedErrorWhile.
  ///
  /// In en, this message translates to:
  /// **'We encountered an unexpected error while processing your request.'**
  String get weEncounteredAnUnexpectedErrorWhile;

  /// No description provided for @weNeedYourLocationToDeliver.
  ///
  /// In en, this message translates to:
  /// **'We need your location to deliver fresh groceries to your doorstep and show nearby stores with the best deals.'**
  String get weNeedYourLocationToDeliver;

  /// No description provided for @weeklyDigest.
  ///
  /// In en, this message translates to:
  /// **'Weekly Digest'**
  String get weeklyDigest;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @whatAiMateCanDo.
  ///
  /// In en, this message translates to:
  /// **'What AI Mate can do'**
  String get whatAiMateCanDo;

  /// No description provided for @whatAreYouSelling.
  ///
  /// In en, this message translates to:
  /// **'What are you selling?'**
  String get whatAreYouSelling;

  /// No description provided for @whatCanIHelpWith.
  ///
  /// In en, this message translates to:
  /// **'What can I help with?'**
  String get whatCanIHelpWith;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get whatHappensNext;

  /// No description provided for @whatsappCallUnavailableSellerHasNo.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp & call unavailable — seller has no phone number on file.'**
  String get whatsappCallUnavailableSellerHasNo;

  /// No description provided for @whatsappSupport247.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Support 24/7'**
  String get whatsappSupport247;

  /// No description provided for @youDoNotHavePermissionTo2.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this page.'**
  String get youDoNotHavePermissionTo2;

  /// No description provided for @youMustBeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in'**
  String get youMustBeLoggedIn;

  /// No description provided for @yourDeliveryPartner.
  ///
  /// In en, this message translates to:
  /// **'Your Delivery Partner'**
  String get yourDeliveryPartner;

  /// No description provided for @yourMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Meal Plan'**
  String get yourMealPlan;

  /// No description provided for @yourDriverWillUseThisTo.
  ///
  /// In en, this message translates to:
  /// **'Your driver will use this to contact you via WhatsApp or phone call.'**
  String get yourDriverWillUseThisTo;

  /// No description provided for @yourFrequentlyPurchasedItems.
  ///
  /// In en, this message translates to:
  /// **'Your frequently purchased items'**
  String get yourFrequentlyPurchasedItems;

  /// No description provided for @yourProfileIsUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your profile is under review'**
  String get yourProfileIsUnderReview;

  /// No description provided for @yourSavedItems.
  ///
  /// In en, this message translates to:
  /// **'Your saved items'**
  String get yourSavedItems;

  /// No description provided for @yourWalletBalanceIsInsufficientPlease.
  ///
  /// In en, this message translates to:
  /// **'Your wallet balance is insufficient. Please top up or choose cash payment.'**
  String get yourWalletBalanceIsInsufficientPlease;

  /// No description provided for @zahle.
  ///
  /// In en, this message translates to:
  /// **'Zahle'**
  String get zahle;

  /// No description provided for @demoModePhoneVerifiedSuccessfullyYou.
  ///
  /// In en, this message translates to:
  /// **'[DEMO MODE] Phone verified successfully! You can now access the app.'**
  String get demoModePhoneVerifiedSuccessfullyYou;

  /// No description provided for @groceriesRestaurantsPharmacyRetailServicesNull.
  ///
  /// In en, this message translates to:
  /// **'groceries|restaurants|pharmacy|retail|services|null'**
  String get groceriesRestaurantsPharmacyRetailServicesNull;

  /// No description provided for @resetDemoDataRpcReturnedDeletion.
  ///
  /// In en, this message translates to:
  /// **'reset_demo_data() RPC returned deletion counts:'**
  String get resetDemoDataRpcReturnedDeletion;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
