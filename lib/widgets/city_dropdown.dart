import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/models/city.dart';
import 'package:gallery_management/services/citys_service.dart';
import 'package:gallery_management/constants.dart';

class CityDropdown extends StatefulWidget {
  final String? selectedCity;
  final void Function(City?) onChanged;

  const CityDropdown({
    super.key,
    required this.selectedCity,
    required this.onChanged,
  });

  @override
  State<CityDropdown> createState() => _CityDropdownState();
}

Future<bool> isCityUsed(String cityId) async {
  final galleries = await FirebaseFirestore.instance
      .collection('2')
      .where('city', isEqualTo: cityId)
      .limit(1)
      .get();

  final ads = await FirebaseFirestore.instance
      .collection('ads')
      .where('city', isEqualTo: cityId)
      .limit(1)
      .get();

  return galleries.docs.isNotEmpty || ads.docs.isNotEmpty;
}

class _CityDropdownState extends State<CityDropdown> {
  final CitysService _citysService = CitysService();
  Map<String, String> _cityMap = {};
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedCity;
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    try {
      final list = await _citysService.fetchCitys();
      final map = {
        for (var city in list) city.id: city.name,
      };

      setState(() {
        _cityMap = map;
      });
    } catch (e) {
      _showSnackBar(e.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addNewCity() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة مدينة جديدة'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'اسم المدينة'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('إضافة'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        await _citysService.addCity(result.trim());
        await _fetchCities();
        _showSnackBar('تمت إضافة المدينة بنجاح');
      } catch (e) {
        _showSnackBar(e.toString());
      }
    }
  }

  Future<void> _deleteCity(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد حذف هذه المدينة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      try {
        final used = await isCityUsed(id);
        if (used) {
          _showSnackBar('لا يمكنك حذف المدن المستخدمة!');
          return;
        }

        await _citysService.deleteCity(id);
        await _fetchCities();

        if (_selectedId == id) {
          setState(() => _selectedId = null);
          widget.onChanged(null);
        }

        _showSnackBar('تم حذف المدينة');
      } catch (e) {
        _showSnackBar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'المدينة',
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
            items: _cityMap.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _deleteCity(entry.key),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedId = value;
              });

              if (value == null) {
                widget.onChanged(null);
              } else {
                final cityName = _cityMap[value]!;
                widget.onChanged(City(id: value, name: cityName));
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _addNewCity,
          child: const Text('+'),
        ),
      ],
    );
  }
}
