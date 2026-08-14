import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Edit donation — accepts Map<String,dynamic>, saves to Firestore.
class EditDonationScreen extends StatefulWidget {
  final Map<String, dynamic> donation;
  const EditDonationScreen({super.key, required this.donation});

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _foodTypeCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedUnit;
  late String _selectedCategory;

  static const _units = ['kg', 'g', 'liters', 'ml', 'pieces', 'packets', 'boxes'];
  static const _categories = ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Meat', 'Bakery', 'Processed', 'Other'];

  @override
  void initState() {
    super.initState();
    _foodTypeCtrl = TextEditingController(
        text: widget.donation['foodType'] as String? ?? '');
    _quantityCtrl = TextEditingController(
        text: (widget.donation['quantity'] as int? ?? 1).toString());
    _locationCtrl = TextEditingController(
        text: widget.donation['pickupLocation'] as String? ?? '');
    _notesCtrl = TextEditingController(
        text: widget.donation['description'] as String? ?? '');

    final savedUnit = widget.donation['unit'] as String? ?? 'kg';
    _selectedUnit = _units.contains(savedUnit) ? savedUnit : 'kg';

    final savedCat = widget.donation['category'] as String? ?? 'Other';
    _selectedCategory = _categories.contains(savedCat)
        ? savedCat
        : 'Other';
  }

  @override
  void dispose() {
    _foodTypeCtrl.dispose();
    _quantityCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final donId = widget.donation['id'] as String?;
    if (donId == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donId)
          .update({
        'foodType': _foodTypeCtrl.text.trim(),
        'quantity': int.tryParse(_quantityCtrl.text.trim()) ?? 1,
        'unit': _selectedUnit,
        'category': _selectedCategory,
        'pickupLocation': _locationCtrl.text.trim(),
        'description': _notesCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Donation updated!'),
              backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Donation'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _foodTypeCtrl,
              label: 'Food Type',
              icon: Icons.fastfood_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _field(
                    controller: _quantityCtrl,
                    label: 'Quantity',
                    icon: Icons.scale,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                    ),
                    items: _units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedUnit = v ?? _selectedUnit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? _selectedCategory),
            ),
            const SizedBox(height: 16),
            _field(
              controller: _locationCtrl,
              label: 'Pickup Address',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _notesCtrl,
              label: 'Notes / Instructions',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}