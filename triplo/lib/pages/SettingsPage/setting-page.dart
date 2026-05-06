import 'package:flutter/material.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/GeowatchPage/Navigation.dart';
import 'package:triplo/pages/SettingsPage/paired_watches_page.dart';
import 'package:triplo/pages/SettingsPage/watch_pair_page.dart';
import 'package:triplo/pages/SettingsPage/weather_notification_page.dart';
import 'package:triplo/pages/trekkingPage/challenges-page.dart';
import '../../exception/change_email_exception.dart';
import '../HomePage/home-page.dart';
import '../UserProfilePage/user-page.dart';
import '../SearchPage/search-page.dart';
import '../../controller/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';


class SettingPage extends StatefulWidget {
  SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<UserController>().refreshEmailFromAuth();
      } catch (_) {

      }
    });
  }
  bool _emailChangeRequested = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextStyle titleStyle = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  final TextStyle infoStyle = const TextStyle(
    fontSize: 14,
    color: Color.fromARGB(255, 72, 72, 72),
  );


  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final userController = context.watch<UserController>();
    final user = userController.currentUser;

    final languageController = context.watch<Language>();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(local.settings_page_title),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                local.not_logged_title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                local.not_logged_subtitle,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(local.please_login_label),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(local.settings_page_title),
        centerTitle: true,
      ),

      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: ListView(
          padding: const EdgeInsets.all(25.0),
          children: [
            // Profile info + avatar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              user.photoProfile != null &&
                                  user.photoProfile!.isNotEmpty
                              ? NetworkImage(user.photoProfile!)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child:
                              user.photoProfile == null ||
                                  user.photoProfile!.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickProfileImage,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(
                                Icons.edit,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(local.username_label, style: titleStyle),
                                    const SizedBox(height: 2),
                                    Text(user.username, style: infoStyle),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 17),
                                onPressed: () => _editField(
                                  title: local.username_label,
                                  initialValue: user.username,
                                  onSave: userController.updateUsername,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            ListTile(
              title: Text(local.name_field_label, style: titleStyle),
              subtitle: Text(
                user.name.isNotEmpty ? user.name : "-",
                style: infoStyle,
              ),
              trailing: const Icon(Icons.edit, size: 17),
              dense: true,
              onTap: () => _editField(
                title: local.name_field_label,
                initialValue: user.name,
                onSave: userController.updateName,
              ),
            ),

            const Divider(height: 1),
            ListTile(
              title: Text(local.surname_field_label, style: titleStyle),
              subtitle: Text(
                user.surname.isNotEmpty ? user.surname : "-",
                style: infoStyle,
              ),
              trailing: const Icon(Icons.edit, size: 17),
              dense: true,
              onTap: () => _editField(
                title: local.surname_field_label,
                initialValue: user.surname,
                onSave: userController.updateSurname,
              ),
            ),

            const Divider(height: 1),
            ListTile(
              title: Text(local.birthdate_field_label, style: titleStyle),
              subtitle: Text(
                "${user.birthdate.day.toString().padLeft(2, '0')}/"
                "${user.birthdate.month.toString().padLeft(2, '0')}/"
                "${user.birthdate.year}",
                style: infoStyle,
              ),
              trailing: const Icon(Icons.calendar_today, size: 17),
              dense: true,
              onTap: () => _pickBirthdate(user.birthdate),
            ),

            const Divider(height: 1),
            ListTile(
              title: Text(local.email_label, style: titleStyle),
              subtitle: Text(user.email, style: infoStyle),
              trailing: const Icon(Icons.edit, size: 17),
              dense: true,
              onTap: () async {
                if (context.read<UserController>().isGoogleUser) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(local.provider_google),
                    ),
                  );
                  return;
                }

                await _showChangeEmailDialog();
              },
            ),

            if (context.watch<UserController>().isPasswordUser && _emailChangeRequested)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.login),
                  label: Text(local.sign_in_again_label),
                  onPressed: () async {
                    await context.read<UserController>().logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                ),
              ),

            const Divider(height: 1),
            ListTile(
              title: Text(local.language_field_label, style: titleStyle),
              subtitle: Text(
                _getLanguageName(languageController.locale.languageCode),
                style: infoStyle,
              ),
              trailing: const Icon(Icons.language, size: 17),
              dense: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => LanguageDialog(
                    onLocaleSelected: languageController.setLocale,
                  ),
                );
              },
            ),

            if (context.read<UserController>().isPasswordUser) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                local.password_message_label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await userController.requestPasswordReset();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(local.password_reset_label)),
                    );
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: Text(local.password_send_label),
                ),
              ),
            ],

            if (context.read<UserController>().isGoogleUser) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(local.restore_google_photo_label),
                onPressed: userController.restoreGoogleProfilePhoto,
              ),
            ],

            const SizedBox(height: 12),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PairedWatchesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.watch),
                label: Text(local.paired_watches_label),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const WatchPairScannerPage()),
                );

                if (ok == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(local.watch_paired_label)),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(local.watch_pair_label),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WeatherAlertSubscriptionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: Text(local.weather_alerts_label),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),

      drawer: Drawer(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const SizedBox.shrink(),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
                title: Text(local.home_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                title: Text(local.profile_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => UserPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                title: Text(local.search_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SearchPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                title: Text(local.settings_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                title: Text(local.challeng_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ChallengesPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.explore, color: Theme.of(context).colorScheme.primary),
                title: Text(local.navigation_page_title, style: optionStyle),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => CompassAltitudePage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final userController = context.read<UserController>();
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await userController.updateProfilePhoto(File(picked.path));
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final local = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(local.cancel_button_label),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await onSave(value);
              }
              Navigator.pop(context);
            },
            child: Text(local.save_trekking_button_label),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBirthdate(DateTime initial) async {
    final userController = context.read<UserController>();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    await userController.updateBirthdate(picked);
  }

  Future<void> _showChangeEmailDialog() async {
    final local = AppLocalizations.of(context)!;
    final userController = context.read<UserController>();

    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    bool obscure = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(local.email_label),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Nuova email",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Password attuale",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          dialogSetState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(local.cancel_button_label),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newEmail = emailController.text.trim();
                    final currentPassword = passwordController.text.trim();

                    if (newEmail.isEmpty || currentPassword.isEmpty) {
                      return;
                    }

                    try {
                      await userController.changeEmail(
                        newEmail: newEmail,
                        currentPassword: currentPassword,
                      );

                      if (!mounted) return;
                      setState(() {
                        _emailChangeRequested = true;
                      });

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            local.email_change_success_label,
                          ),
                        ),
                      );
                    } on ChangeEmailException catch (e) {
                      String msg = local.email_change_error;

                      if (e.code == "wrong-password") {
                        msg = local.wrong_password;
                      } else if (e.code == "email-already-in-use") {
                        msg = local.email_already_in_use;
                      } else if (e.code == "invalid-email") {
                        msg = local.invalid_email;
                      } else if (e.code == "requires-recent-login") {
                        msg = local.requires_recent_login;
                      } else if (e.code == "not-authenticated") {
                        msg = local.not_authenticated;
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    }
                  },
                  child: Text(local.save_trekking_button_label),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Popup dialog to select the language
class LanguageDialog extends StatelessWidget {
  final Future<void> Function(Locale) onLocaleSelected;

  const LanguageDialog({super.key, required this.onLocaleSelected});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(local.language_selection_label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTile(context, "🇬🇧", "English", const Locale('en')),
          _langTile(context, "🇮🇹", "Italiano", const Locale('it')),
          _langTile(context, "🇪🇸", "Español", const Locale('es')),
          _langTile(context, "🇩🇪", "Deutsch", const Locale('de')),
          _langTile(context, "🇫🇷", "Français", const Locale('fr')),
        ],
      ),
    );
  }

  Widget _langTile(
    BuildContext context,
    String flag,
    String name,
    Locale locale,
  ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(name),
      onTap: () async {
        await onLocaleSelected(locale);
        Navigator.pop(context);
      },
    );
  }
}

String _getLanguageName(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'it':
      return 'Italiano';
    case 'es':
      return 'Español';
    case 'de':
      return 'Deutsch';
    case 'fr':
      return 'Français';
    default:
      return 'Unknown';
  }
}
