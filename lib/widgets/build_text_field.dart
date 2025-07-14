import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

Widget buildTextField(
  TextEditingController controller,
  String label,
  String errorMessage,
  bool required, {
  int maxLines = 1,
  bool readOnly = false,
  bool enabled = true,
  bool isPassword = false,
  bool obscureText = false,
  VoidCallback? toggleObscure,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    readOnly: readOnly,
    enabled: enabled,
    obscureText: isPassword ? obscureText : false,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide(color: primaryColor),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: toggleObscure,
            )
          : null,
    ),
    maxLines: maxLines,
    validator: validator ??
        (value) {
          if ((value == null || value.isEmpty) && required) {
            return errorMessage;
          }
          return null;
        },
  );
}
