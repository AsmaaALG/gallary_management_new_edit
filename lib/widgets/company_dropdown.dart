import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompanyDropdown extends StatefulWidget {
  final String? selectedCompanyId;
  final Function(String? companyId)? onChanged;

  const CompanyDropdown({
    Key? key,
    this.selectedCompanyId,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CompanyDropdown> createState() => _CompanyDropdownState();
}

class _CompanyDropdownState extends State<CompanyDropdown> {
  String? _selectedId;
  Map<String, String> _companyMap = {};

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCompanyId;
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('company').get();
    final map = {
      for (var doc in snapshot.docs)
        doc.id: (doc['name'] ?? 'بدون اسم').toString(),
    };

    setState(() {
      _companyMap = map;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'الشركة المنظمة',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      items: _companyMap.entries
          .map((entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Align(
                    alignment: Alignment.topRight, child: Text(entry.value)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedId = value;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
    );
  }
}
