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
  List<Classification> _classifications = [];

  @override
  void initState() {
    super.initState();
    _fetchClassifications();
  }

  Future<void> _fetchClassifications() async {
    try {
      final list = await _classificationService.fetchClassifications();
      setState(() {
        _classifications = list;
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
        await _classificationService.deleteClassification(id);
        await _fetchClassifications();
        if (widget.selectedClassification == id) {
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
          child: DropdownButtonFormField<Classification>(
            value: _classifications.isNotEmpty
                ? _classifications.firstWhere(
                    (c) => c.id == widget.selectedClassification,
                    orElse: () => _classifications[
                        0], // إرجاع أول تصنيف إذا لم يتم العثور على تصنيف مطابق
                  )
                : null,
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
            items: _classifications.map((classification) {
              return DropdownMenuItem<Classification>(
                value: classification,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _deleteClassification(classification.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classification.name,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: widget.onChanged,
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
