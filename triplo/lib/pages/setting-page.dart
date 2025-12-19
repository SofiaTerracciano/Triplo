import 'package:flutter/material.dart';
import 'package:triplo/controller/language.dart';
import 'package:triplo/l10n/app_localizations.dart';
import 'package:triplo/pages/challenges-page.dart';
import 'home-page.dart';
import 'user-page.dart';
import 'search-page.dart';
import '../controller/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';



class SettingPage extends StatefulWidget {

  SettingPage({
    super.key,
  });

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  //TextStyle for texts
  static const TextStyle optionStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.italic,
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  //late Users userAccount;

  //late String name;


  //late String surname;
  //late String username;
  //late DateTime birthdate;
  //late String photoProfile;
  //late String email;
  //late String password; //da chiedere a Giulio per l'impkementazione


  //void initState() {
  //  super.initState();
    //userAccount = widget.userController.currentUser!;
    //name = userAccount.name;
    //surname = userAccount.surname;
    //username = userAccount.username;
    //birthdate = userAccount.birthdate;
    //photoProfile = userAccount.photoProfile!;
    //email = userAccount.email;
  //}



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
              const Text(
                "You are not logged in",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please login to access your settings",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(local.settings_page_title),
        centerTitle: true, // Forced center the title
      ),

      body: ListView(
        padding: const EdgeInsets.all(25.0),
        children: [
          // Profile info + avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column: username + password
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username + edit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          local.username_label,
                          style: TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          onPressed: () {
                            _editField(
                              title: local.username_label,
                              initialValue: user.username,
                              onSave: userController.updateUsername,
                            );
                          },
                          icon: const Icon(Icons.edit, size: 16),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 8.0),
                      child: Text(
                        user.username,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    // Password + edit
                    /*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          local.password_label,
                          style: TextStyle(fontSize: 14),
                        ),
                        IconButton(
                          onPressed: () async {
                            await widget.userController.requestPasswordReset();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password reset email sent"),
                              ),
                            );

                          },
                          icon: const Icon(Icons.edit, size: 16),
                        ),
                      ],
                    ),

                     */
                    /*
                    const Padding(
                      padding: EdgeInsets.only(left: 0, bottom: 8.0),
                      child: Text(
                        '***********', // numero di * uguale alla lunghezza della password
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                     */
                    const SizedBox(height: 8),
                    /*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(local.password_label, style: const TextStyle(fontSize: 14)),
                        TextButton.icon(
                          onPressed: () async {
                            await widget.userController.requestPasswordReset();

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password reset email sent")),
                            );
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text("Send reset password link"),
                        ),
                      ],
                    ),

                     */

                    const SizedBox(height: 6),

                  ],
                ),
              ),

              // Right column: avatar + edit photo
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      //backgroundImage: AssetImage('images/prova.jpeg'),
                      backgroundImage: (user.photoProfile != null && user.photoProfile!.isNotEmpty)
                          ? NetworkImage(user.photoProfile!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: (user.photoProfile == null || user.photoProfile!.isEmpty)
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(

                            onPressed: _pickProfileImage,

                          child: Text(
                            local.edit_profile_photo_button_label,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Altri campi come nome, cognome, email, nascita, lingua .
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(local.name_field_label, style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () {

                  _editField(
                    title: local.name_field_label,
                    initialValue: user.name,
                    onSave: userController.updateName,
                  );

                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                user.name.isNotEmpty ? user.name : "-",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(local.surname_field_label, style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () {
                  _editField(
                    title: local.surname_field_label,
                    initialValue: user.surname,
                    onSave: userController.updateSurname,
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                user.surname.isNotEmpty ? user.surname : "-",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(local.birthdate_field_label, style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () => _pickBirthdate(user.birthdate),
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                //'birthdate_placeholder',
                "${user.birthdate.day.toString().padLeft(2, '0')}/"
                    "${user.birthdate.month.toString().padLeft(2, '0')}/"
                    "${user.birthdate.year}",

                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(local.email_label, style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () {
                  // to do modifica email
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                user.email,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(local.language_field_label, style: TextStyle(fontSize: 14)),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => LanguageDialog(
                      onLocaleSelected: (locale) {
                        languageController.setLocale(locale); // <-- cambia lingua(locale);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
              ),
              const Spacer(),
              Text(
                _getLanguageName(languageController.locale.languageCode),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          /*
          Divider(),

          const SizedBox(height: 16),

          Text(
            "Password",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "If you want to change your password or if you forgot it, "
                "we can send you a password reset link to the email associated "
                "with your account.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await widget.userController.requestPasswordReset();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password reset email sent"),
                  ),
                );
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text("Send password reset email"),
            ),
          ),
        if (context.read<UserController>().isGoogleUser)
              TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Restore Google photo"),
                  onPressed: widget.userController.restoreGoogleProfilePhoto,
              ),
        ],





           */
        if (context.read<UserController>().isPasswordUser) ...[
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            "Password",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),



          Text(
            "If you want to change your password or if you forgot it, "
            "we can send you a password reset link to the email associated "
            "with your account.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
            onPressed: () async {
            await userController.requestPasswordReset();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
              content: Text("Password reset email sent"),
              ),
            );
            },
            icon: const Icon(Icons.email_outlined),
            label: const Text("Send password reset email"),
            ),
          ),

        ],

          if (context.read<UserController>().isGoogleUser) ...[
                const SizedBox(height: 24),

                TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Restore Google profile photo"),
                    onPressed: userController.restoreGoogleProfilePhoto,
                ),
          ]
        ],
      ),

      //Drawer to control the navigation among pages
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.greenAccent),
              child: Text(
                local.menu_title,
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(local.home_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyHomePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(local.profile_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(local.search_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(local.settings_page_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: Text(local.challeng_title, style: optionStyle),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChallengesPage(),
                  ),
                );
              },
            ),
          ],
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

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                await onSave(value);
              }
              Navigator.pop(context);
            },
            child: const Text("Save"),
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

}

// Popup dialog to select the language
class LanguageDialog extends StatelessWidget {
  final void Function(Locale) onLocaleSelected;

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
      onTap: () {
        onLocaleSelected(locale);
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
