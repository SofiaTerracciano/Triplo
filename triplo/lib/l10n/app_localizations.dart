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

  /// No description provided for @watch_profile_dialog_level.
  ///
  /// In en, this message translates to:
  /// **'Watch my profile on Triplo!'**
  String get watch_profile_dialog_level;

  /// No description provided for @my_profile_dialog_level.
  ///
  /// In en, this message translates to:
  /// **'My Triplo Profile'**
  String get my_profile_dialog_level;

  /// No description provided for @level_label.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level_label;

  /// No description provided for @beginner_level.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner_level;

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

  /// No description provided for @no_public_diary_label.
  ///
  /// In en, this message translates to:
  /// **'No public diary'**
  String get no_public_diary_label;

  /// No description provided for @no_private_diary_label.
  ///
  /// In en, this message translates to:
  /// **'No private diary'**
  String get no_private_diary_label;

  /// No description provided for @no_saved_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'No saved trekking'**
  String get no_saved_trekking_label;

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

  /// No description provided for @user_label.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get user_label;

  /// No description provided for @trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Trekking'**
  String get trekking_label;

  /// No description provided for @no_user_found_label.
  ///
  /// In en, this message translates to:
  /// **'No user found'**
  String get no_user_found_label;

  /// No description provided for @no_trekking_found_label.
  ///
  /// In en, this message translates to:
  /// **'No trekking found'**
  String get no_trekking_found_label;

  /// No description provided for @no_diary_found_label.
  ///
  /// In en, this message translates to:
  /// **'No public diary'**
  String get no_diary_found_label;

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

  /// No description provided for @weather_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather_trekking_label;

  /// No description provided for @weather_trekking_botton.
  ///
  /// In en, this message translates to:
  /// **'Click here to check the weather'**
  String get weather_trekking_botton;

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
  /// **'Did you eat there?'**
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

  /// No description provided for @no_challenge.
  ///
  /// In en, this message translates to:
  /// **'No challenges available'**
  String get no_challenge;

  /// No description provided for @start_trekking_label.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start_trekking_label;

  /// No description provided for @before_start.
  ///
  /// In en, this message translates to:
  /// **'Before starting'**
  String get before_start;

  /// No description provided for @back_label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back_label;

  /// No description provided for @trekking_in_progress_label.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get trekking_in_progress_label;

  /// No description provided for @trekking_completed_label.
  ///
  /// In en, this message translates to:
  /// **'Trekking Completed'**
  String get trekking_completed_label;

  /// No description provided for @stop_trekking.
  ///
  /// In en, this message translates to:
  /// **'Stop trekking'**
  String get stop_trekking;

  /// No description provided for @add_to_diary_question_label.
  ///
  /// In en, this message translates to:
  /// **'Do you want to add a thought to your diary?'**
  String get add_to_diary_question_label;

  /// No description provided for @add_to_diary_label.
  ///
  /// In en, this message translates to:
  /// **'Add to diary'**
  String get add_to_diary_label;

  /// No description provided for @not_now.
  ///
  /// In en, this message translates to:
  /// **'Not now, return to home'**
  String get not_now;

  /// No description provided for @no_users_found_label.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get no_users_found_label;

  /// No description provided for @weather_near_trail_label.
  ///
  /// In en, this message translates to:
  /// **'Weather near trail'**
  String get weather_near_trail_label;

  /// No description provided for @weather_error_label.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get weather_error_label;

  /// No description provided for @no_weather_available_label.
  ///
  /// In en, this message translates to:
  /// **'No weather data available'**
  String get no_weather_available_label;

  /// No description provided for @trail_area_label.
  ///
  /// In en, this message translates to:
  /// **'Trail area'**
  String get trail_area_label;

  /// No description provided for @current_position_label.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get current_position_label;

  /// No description provided for @your_position_label.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get your_position_label;

  /// No description provided for @based_on_nearest_station_label.
  ///
  /// In en, this message translates to:
  /// **'Based on nearest weather station'**
  String get based_on_nearest_station_label;

  /// No description provided for @forecast_label.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast_label;

  /// No description provided for @no_forecast_available_label.
  ///
  /// In en, this message translates to:
  /// **'No forecast available'**
  String get no_forecast_available_label;

  /// No description provided for @open_satellite_weather_layers_label.
  ///
  /// In en, this message translates to:
  /// **'Open satellite view & weather layers'**
  String get open_satellite_weather_layers_label;

  /// No description provided for @no_active_weather_alerts_label.
  ///
  /// In en, this message translates to:
  /// **'No active weather alerts for this area'**
  String get no_active_weather_alerts_label;

  /// No description provided for @weather_alerts_label.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get weather_alerts_label;

  /// No description provided for @trail_weather_label.
  ///
  /// In en, this message translates to:
  /// **'Trail weather'**
  String get trail_weather_label;

  /// No description provided for @my_gps_label.
  ///
  /// In en, this message translates to:
  /// **'My GPS'**
  String get my_gps_label;

  /// No description provided for @error_loading_weather_label.
  ///
  /// In en, this message translates to:
  /// **'Error loading weather'**
  String get error_loading_weather_label;

  /// No description provided for @weather_alert_title.
  ///
  /// In en, this message translates to:
  /// **'Weather Alert'**
  String get weather_alert_title;

  /// No description provided for @navigation_page_title.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation_page_title;

  /// No description provided for @weather_title.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather_title;

  /// No description provided for @password_message_label.
  ///
  /// In en, this message translates to:
  /// **'If you want to change your password or if you forgot it, we can send you a password reset link to the email associated with your account.'**
  String get password_message_label;

  /// No description provided for @password_send_label.
  ///
  /// In en, this message translates to:
  /// **'Send password reset link'**
  String get password_send_label;

  /// No description provided for @password_reset_label.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get password_reset_label;

  /// No description provided for @watch_pair_label.
  ///
  /// In en, this message translates to:
  /// **'Pair watch'**
  String get watch_pair_label;

  /// No description provided for @watch_paired_label.
  ///
  /// In en, this message translates to:
  /// **'Watch paired!'**
  String get watch_paired_label;

  /// No description provided for @fill_fields_label.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields'**
  String get fill_fields_label;

  /// No description provided for @welcome_label.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Triplo App'**
  String get welcome_label;

  /// No description provided for @title_notification_arrival.
  ///
  /// In en, this message translates to:
  /// **'📍 Almost there!'**
  String get title_notification_arrival;

  /// No description provided for @body_notification_arrival.
  ///
  /// In en, this message translates to:
  /// **'Tap to complete the trek.'**
  String get body_notification_arrival;

  /// No description provided for @alert_notification_arrival.
  ///
  /// In en, this message translates to:
  /// **'You are close to the arrival point; remember to stop the timer and complete your diary.'**
  String get alert_notification_arrival;

  /// No description provided for @title_challenge_balance.
  ///
  /// In en, this message translates to:
  /// **'🪨 Challenge: Balance'**
  String get title_challenge_balance;

  /// No description provided for @body_challenge_balance.
  ///
  /// In en, this message translates to:
  /// **'Test your balance!'**
  String get body_challenge_balance;

  /// No description provided for @alert_challenge_balance.
  ///
  /// In en, this message translates to:
  /// **'Find a rock or root and try to keep your balance for a few seconds!'**
  String get alert_challenge_balance;

  /// No description provided for @title_challenge_hi.
  ///
  /// In en, this message translates to:
  /// **'👋🏻 Challenge: Say hello'**
  String get title_challenge_hi;

  /// No description provided for @body_challenge_hi.
  ///
  /// In en, this message translates to:
  /// **'Say hello on the trail!'**
  String get body_challenge_hi;

  /// No description provided for @alert_challenge_hi.
  ///
  /// In en, this message translates to:
  /// **'Say hello to at least 4 people you meet along the trail and make the hike more social.'**
  String get alert_challenge_hi;

  /// No description provided for @title_challenge_mini_orientiring.
  ///
  /// In en, this message translates to:
  /// **'🧭 Challenge: Navigation'**
  String get title_challenge_mini_orientiring;

  /// No description provided for @body_challenge_mini_orientiring.
  ///
  /// In en, this message translates to:
  /// **'Do you know which way you\'re heading?'**
  String get body_challenge_mini_orientiring;

  /// No description provided for @alert_challenge_mini_orientiring.
  ///
  /// In en, this message translates to:
  /// **'Look at the sun and the trail and try to understand which direction you\'re heading (North, South, East or West). No need to answer in the app, just orient yourself.'**
  String get alert_challenge_mini_orientiring;

  /// No description provided for @title_challenge_photo.
  ///
  /// In en, this message translates to:
  /// **'📷 Challenge: Photo'**
  String get title_challenge_photo;

  /// No description provided for @body_challenge_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the landscape!'**
  String get body_challenge_photo;

  /// No description provided for @alert_challenge_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of something special along the trail: an animal, a waterfall or an interesting detail in nature.'**
  String get alert_challenge_photo;

  /// No description provided for @title_challenge_silent_walking.
  ///
  /// In en, this message translates to:
  /// **'🧘🏻 Challenge: Silent walk'**
  String get title_challenge_silent_walking;

  /// No description provided for @body_challenge_silent_walking.
  ///
  /// In en, this message translates to:
  /// **'Try walking in silence.'**
  String get body_challenge_silent_walking;

  /// No description provided for @alert_challenge_silent_walking.
  ///
  /// In en, this message translates to:
  /// **'Walk in silence for a few minutes and listen to the sounds of nature around you.'**
  String get alert_challenge_silent_walking;

  /// No description provided for @title_challenge_time.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Challenge: Beat the clock'**
  String get title_challenge_time;

  /// No description provided for @body_challenge_time.
  ///
  /// In en, this message translates to:
  /// **'Can you beat the time?'**
  String get body_challenge_time;

  /// No description provided for @alert_challenge_time.
  ///
  /// In en, this message translates to:
  /// **'Try to complete the route within the estimated time. Can you beat the clock?'**
  String get alert_challenge_time;

  /// No description provided for @please_login_label.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get please_login_label;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @google_signin_button.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get google_signin_button;

  /// No description provided for @no_account_label.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get no_account_label;

  /// No description provided for @signup_label.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signup_label;

  /// No description provided for @forgot_password_label.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password_label;

  /// No description provided for @fill_fields_login_label.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fill_fields_login_label;

  /// No description provided for @login_success.
  ///
  /// In en, this message translates to:
  /// **'Logged in'**
  String get login_success;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get login_failed;

  /// No description provided for @google_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Google login failed'**
  String get google_login_failed;

  /// No description provided for @follower.
  ///
  /// In en, this message translates to:
  /// **'Follower'**
  String get follower;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @registration_title.
  ///
  /// In en, this message translates to:
  /// **'Register on Triplo'**
  String get registration_title;

  /// No description provided for @confirm_password_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirm_password_label;

  /// No description provided for @register_button.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register_button;

  /// No description provided for @back_to_login.
  ///
  /// In en, this message translates to:
  /// **'Go back to login page'**
  String get back_to_login;

  /// No description provided for @fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in every field'**
  String get fill_all_fields;

  /// No description provided for @passwords_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_not_match;

  /// No description provided for @registration_success.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registration_success;

  /// No description provided for @registration_failed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registration_failed;

  /// No description provided for @not_logged_title.
  ///
  /// In en, this message translates to:
  /// **'You are not logged in'**
  String get not_logged_title;

  /// No description provided for @not_logged_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please login to access your profile'**
  String get not_logged_subtitle;

  /// No description provided for @go_to_login_button.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get go_to_login_button;

  /// No description provided for @user_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get user_not_found;

  /// No description provided for @save_route_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save route'**
  String get save_route_error;

  /// No description provided for @no_title.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get no_title;

  /// No description provided for @no_description.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get no_description;

  /// No description provided for @restore_google_photo_label.
  ///
  /// In en, this message translates to:
  /// **'Restore Google profile photo'**
  String get restore_google_photo_label;

  /// No description provided for @scan_qr_label.
  ///
  /// In en, this message translates to:
  /// **'Scan watch QR'**
  String get scan_qr_label;

  /// No description provided for @not_valid_qr_label.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get not_valid_qr_label;

  /// No description provided for @connect_watch_label.
  ///
  /// In en, this message translates to:
  /// **'Connect the watch?'**
  String get connect_watch_label;

  /// No description provided for @cancel_label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_label;

  /// No description provided for @confirm_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm_label;

  /// No description provided for @diary_not_found.
  ///
  /// In en, this message translates to:
  /// **'Diary not found'**
  String get diary_not_found;

  /// No description provided for @offline_mode_label.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offline_mode_label;

  /// No description provided for @no_internet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get no_internet;

  /// No description provided for @forgot_password_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgot_password_title;

  /// No description provided for @forgot_password_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email below'**
  String get forgot_password_subtitle;

  /// No description provided for @enter_email_prompt.
  ///
  /// In en, this message translates to:
  /// **'We’ll send you a link to reset your password'**
  String get enter_email_prompt;

  /// No description provided for @send_reset_link_button.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get send_reset_link_button;

  /// No description provided for @email_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get email_required;

  /// No description provided for @reset_link_sent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent! Check your email.'**
  String get reset_link_sent;

  /// No description provided for @generic_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get generic_error;

  /// No description provided for @satellite_weather_layers_title.
  ///
  /// In en, this message translates to:
  /// **'Satellite map with weather layers'**
  String get satellite_weather_layers_title;

  /// No description provided for @weather_layers_label.
  ///
  /// In en, this message translates to:
  /// **'Weather Layers'**
  String get weather_layers_label;

  /// No description provided for @layer_precipitation.
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get layer_precipitation;

  /// No description provided for @layer_snow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get layer_snow;

  /// No description provided for @layer_wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get layer_wind;

  /// No description provided for @layer_clouds.
  ///
  /// In en, this message translates to:
  /// **'Clouds'**
  String get layer_clouds;

  /// No description provided for @layer_temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get layer_temperature;

  /// No description provided for @layer_pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get layer_pressure;

  /// No description provided for @gps_disabled.
  ///
  /// In en, this message translates to:
  /// **'GPS Disabled'**
  String get gps_disabled;

  /// No description provided for @permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permission_denied;

  /// No description provided for @gps_disabled_message.
  ///
  /// In en, this message translates to:
  /// **'GPS is turned off'**
  String get gps_disabled_message;

  /// No description provided for @permission_denied_message.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have the required permissions to provide the information'**
  String get permission_denied_message;

  /// No description provided for @open_settings_button.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get open_settings_button;

  /// No description provided for @loading_coordinates.
  ///
  /// In en, this message translates to:
  /// **'Loading coordinates...'**
  String get loading_coordinates;

  /// No description provided for @no_friends.
  ///
  /// In en, this message translates to:
  /// **'Your feed is waiting for some adventure! Follow fellow trekkers to see their latest journeys here.'**
  String get no_friends;

  /// No description provided for @error_loading_trekkings.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscribed routes'**
  String get error_loading_trekkings;

  /// No description provided for @no_weather_alerts.
  ///
  /// In en, this message translates to:
  /// **'No routes with weather alerts enabled'**
  String get no_weather_alerts;

  /// No description provided for @weather_alert_removed.
  ///
  /// In en, this message translates to:
  /// **'Weather alert removed'**
  String get weather_alert_removed;

  /// No description provided for @open_button.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open_button;

  /// No description provided for @remove_button.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove_button;
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
