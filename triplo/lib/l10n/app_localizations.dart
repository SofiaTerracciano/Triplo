import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @menu_title.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu_title;

  /// No description provided for @home_page_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_page_title;

  /// No description provided for @repositioning_button_label.
  ///
  /// In en, this message translates to:
  /// **'Move me'**
  String get repositioning_button_label;

  /// No description provided for @profile_page_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_page_title;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @password_label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_label;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_label;

  /// No description provided for @totals_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'My journeys'**
  String get totals_trekking_label;

  /// No description provided for @published_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published_trekking_label;

  /// No description provided for @private_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private_trekking_label;

  /// No description provided for @share_profile_button_label.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get share_profile_button_label;

  /// No description provided for @level_label.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level_label;

  /// No description provided for @begginer_level.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get begginer_level;

  /// No description provided for @intermediate_level.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate_level;

  /// No description provided for @advanced_level.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced_level;

  /// No description provided for @follow_label.
  ///
  /// In en, this message translates to:
  /// **'follow'**
  String get follow_label;

  /// No description provided for @followed_label.
  ///
  /// In en, this message translates to:
  /// **'followed'**
  String get followed_label;

  /// No description provided for @search_page_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_page_title;

  /// No description provided for @cancel_button_label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button_label;

  /// No description provided for @settings_page_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_page_title;

  /// No description provided for @edit_profile_photo_button_label.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Photo'**
  String get edit_profile_photo_button_label;

  /// No description provided for @name_field_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name_field_label;

  /// No description provided for @surname_field_label.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname_field_label;

  /// No description provided for @birthdate_field_label.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdate_field_label;

  /// No description provided for @language_field_label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language_field_label;

  /// No description provided for @language_selection_label.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get language_selection_label;

  /// No description provided for @starting_point_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Starting Point'**
  String get starting_point_trekking_label;

  /// No description provided for @distance_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance_trekking_label;

  /// No description provided for @estimated_time_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimated_time_trekking_label;

  /// No description provided for @elevaition_gain_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Elevation Gain'**
  String get elevaition_gain_trekking_label;

  /// No description provided for @ending_point_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Ending Point'**
  String get ending_point_trekking_label;

  /// No description provided for @info_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info_trekking_label;

  /// No description provided for @description_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description_trekking_label;

  /// No description provided for @refreshment_point_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Refreshments'**
  String get refreshment_point_trekking_label;

  /// No description provided for @refreshment_point_available_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'There are no refreshment points for this trekking'**
  String get refreshment_point_available_trekking_label;

  /// No description provided for @pic_nic_area_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Picnic Areas'**
  String get pic_nic_area_trekking_label;

  /// No description provided for @pic_nic_area_available_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'There are no picnic areas available'**
  String get pic_nic_area_available_trekking_label;

  /// No description provided for @family_friendly_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Family Friendly'**
  String get family_friendly_trekking_label;

  /// No description provided for @family_friendly_available_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'This trekking is not suitable for families with children'**
  String get family_friendly_available_trekking_label;

  /// No description provided for @start_trekking_button_label.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_trekking_button_label;

  /// No description provided for @save_trekking_button_label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save_trekking_button_label;

  /// No description provided for @challenges_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges_trekking_label;

  /// No description provided for @challenges_available_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'No challenges available for this trekking'**
  String get challenges_available_trekking_label;

  /// No description provided for @hours_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours_trekking_label;

  /// No description provided for @hour_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hour_trekking_label;

  /// No description provided for @minutes_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes_trekking_label;

  /// No description provided for @date_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date_trekking_label;

  /// No description provided for @day_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day_trekking_label;

  /// No description provided for @month_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month_trekking_label;

  /// No description provided for @year_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year_trekking_label;

  /// No description provided for @duration_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration_trekking_label;

  /// No description provided for @friends_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends_trekking_label;

  /// No description provided for @friends_selected_label.
  ///
  /// In en, this message translates to:
  /// **'No friends selected'**
  String get friends_selected_label;

  /// No description provided for @choose_friend_label.
  ///
  /// In en, this message translates to:
  /// **'Select friends'**
  String get choose_friend_label;

  /// No description provided for @photos_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos_trekking_label;

  /// No description provided for @refuge_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'“Did you eat there?”'**
  String get refuge_trekking_label;

  /// No description provided for @yes_botton_label.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes_botton_label;

  /// No description provided for @no_botton_label.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no_botton_label;

  /// No description provided for @mood_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood_trekking_label;

  /// No description provided for @mood_selected_label.
  ///
  /// In en, this message translates to:
  /// **'No mood selected'**
  String get mood_selected_label;

  /// No description provided for @choose_mood_label.
  ///
  /// In en, this message translates to:
  /// **'Select mood'**
  String get choose_mood_label;

  /// No description provided for @mood_love_label.
  ///
  /// In en, this message translates to:
  /// **'In love'**
  String get mood_love_label;

  /// No description provided for @mood_happy_label.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get mood_happy_label;

  /// No description provided for @mood_relaxed_label.
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get mood_relaxed_label;

  /// No description provided for @mood_tired_label.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get mood_tired_label;

  /// No description provided for @mood_proud_label.
  ///
  /// In en, this message translates to:
  /// **'Proud'**
  String get mood_proud_label;

  /// No description provided for @mood_sad_label.
  ///
  /// In en, this message translates to:
  /// **'Disappointed'**
  String get mood_sad_label;

  /// No description provided for @mood_excited_label.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get mood_excited_label;

  /// No description provided for @notes_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes_trekking_label;

  /// No description provided for @notes_placeholder_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Add your notes'**
  String get notes_placeholder_trekking_label;

  /// No description provided for @save_botton_label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save_botton_label;

  /// No description provided for @add_botton_label.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add_botton_label;

  /// No description provided for @public_botton_label.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public_botton_label;

  /// No description provided for @private_botton_label.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private_botton_label;

  /// No description provided for @public_private_label.
  ///
  /// In en, this message translates to:
  /// **'How do you want to set the diary visibility?'**
  String get public_private_label;

  /// No description provided for @challenge_selected_label.
  ///
  /// In en, this message translates to:
  /// **'No challenge selected'**
  String get challenge_selected_label;

  /// No description provided for @choose_challenge_label.
  ///
  /// In en, this message translates to:
  /// **'Select the challenges completed'**
  String get choose_challenge_label;

  /// No description provided for @challeng_title.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challeng_title;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
