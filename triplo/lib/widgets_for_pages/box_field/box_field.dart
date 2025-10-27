import 'package:flutter/material.dart';

/// A reusable text input field used for login and forms (optional password hiding)
class BoxField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final bool isEmail;
  //bridge between widget and ui
  final TextEditingController? controller;

  const BoxField({
    Key? key,
    required this.label,
    this.isPassword = false,
    this.isEmail = false,
    this.controller,
  }) : super(key: key);

  @override
  State<BoxField> createState() => _BoxFieldState();
}

///The state of the box_field, handling basic email validation and visibility for passwords
class _BoxFieldState extends State<BoxField> {
  //if true the text is hidden, false otherwise
  bool hide = true; //password visibility
  String? _errorMessage; //error message for invalid email

  ///Email validation with a regular expression
  bool _emailValid(String value){
    //[\w-\.]+ means \w word, - allows dashes, \. dot allowed, + same meaning as plus in regular expressions
    //@ separates the user name from the domain of the email
    //([\w-]+\.)+ domain made of one or more groups of alphanumeric-dash-underscore strings
    //[\w-]{2,4} 2,4 is the string length allowed for the top level domain
    const pattern = r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$';

    return RegExp(pattern).hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      //horizontal and vertical padding for distance
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8.0),
        child: TextField(
          //the controller is passed from box_field to box_field_state
            controller: widget.controller,
            //if it is a password, hide/show based on hide bool
            obscureText: widget.isPassword ? hide : false,

            //setting the keyboard to email keyboard if email field, generic keyboard otherwise
            keyboardType:
            widget.isEmail ? TextInputType.emailAddress : TextInputType.text,
            //decoration and styling
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),


              //if ErrorMessage != null, show the message
              errorText: _errorMessage,

              //if password, add the icon in order to allow the user to show/hide the password
              suffixIcon: widget.isPassword
                  ? IconButton(
                //icon changes based on the hide bool
                icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  //on pressed updated the state and forces the widget to rebuild
                  setState(() {

                    hide = !hide;

                  });
                },
              ): null,
            ),
            onChanged: (value){
              //if email, validation
              if(widget.isEmail) {
                setState(() {
                  _errorMessage =
                  value.isEmpty || _emailValid(value) ? null : 'Please provide a valid email (e.g. name@mail.com)';
                });
              } else {
                //for non email no error message
                setState(() {
                  _errorMessage = null;
                });
              }

            }
        )
    );
  }
}