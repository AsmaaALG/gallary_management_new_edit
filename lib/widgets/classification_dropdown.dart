import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/models/classification.dart';
import 'package:gallery_management/services/classification_service.dart';
import 'package:gallery_management/constants.dart';

class ClassificationDropdown extends StatefulWidget {
  final String? selectedClassification;
  final void Function(Classification?) onChanged;

  const ClassificationDropdown({
    super.key,
    required this.selectedClassification,
    required this.onChanged,
  });

  @override
  State<ClassificationDropdown> createState() => _ClassificationDropdownState();
}

class _ClassificationDropdownState extends State<ClassificationDropdown> {
  final ClassificationService _classificationService = ClassificationService();
  Map<String, String> _classificationMap = {};
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedClassification;
    _fetchClassifications();
  }

  Future<bool> isClassificationUsed(String classificationId) async {
    final galleries = await FirebaseFirestore.instance
        .collection('2')
        .where('classification id', isEqualTo: classificationId)
        .limit(1)
        .get();

    final ads = await FirebaseFirestore.instance
        .collection('ads')
        .where('classification id', isEqualTo: classificationId)
        .limit(1)
        .get();

    return galleries.docs.isNotEmpty || ads.docs.isNotEmpty;
  }

  Future<void> _fetchClassifications() async {
    try {
      final list = await _classificationService.fetchClassifications();
      final map = {
        for (var item in list) item.id: item.name,
      };
      setState(() {
        _classificationMap = map;
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

  Future<void> _addNewClassification() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة تصنيف جديد'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'اسم التصنيف'),
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
        await _classificationService.addClassification(result.trim());
        await _fetchClassifications();
        _showSnackBar('تمت إضافة التصنيف بنجاح');
      } catch (e) {
        _showSnackBar(e.toString());
      }
    }
  }

  Future<void> _deleteClassification(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text('هل تريد حذف هذا التصنيف؟'),
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
        final used = await isClassificationUsed(id);
        if (used) {
          _showSnackBar('لا يمكنك حذف التصنيفات المستخدمة مسبقا!');
          return;
        }

        await _classificationService.deleteClassification(id);
        await _fetchClassifications();
        if (_selectedId == id) {
          setState(() => _selectedId = null);
          widget.onChanged(null);
        }
        _showSnackBar('تم حذف التصنيف');
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
              labelText: 'التصنيف',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
            items: _classificationMap.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _deleteClassification(entry.key),
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
                final name = _classificationMap[value]!;
                widget.onChanged(Classification(id: value, name: name));
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _addNewClassification,
          child: const Text('+'),
        ),
      ],
    );
  }
}
