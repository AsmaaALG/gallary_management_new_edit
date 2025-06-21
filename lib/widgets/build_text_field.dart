 import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

Widget buildTextField(TextEditingController controller, String label,
      String errorMessage, bool required,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
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
      ),
      maxLines: maxLines,
      validator: (value) {
        if ((value == null || value.isEmpty) && required) {
          return errorMessage;
        }
        return null;
      },
    );
  }