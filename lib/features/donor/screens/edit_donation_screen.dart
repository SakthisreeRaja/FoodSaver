import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/donation.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';

class EditDonationScreen extends StatefulWidget {
  final Donation donation;

  const EditDonationScreen({super.key, required this.donation});

  @override
  State<EditDonationScreen> createState() => _EditDonationScreenState();
}

class _EditDonationScreenState extends State<EditDonationScreen> {
  late final TextEditingController _foodNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController(text: widget.donation.foodName);
    _descriptionController = TextEditingController(text: widget.donation.description);
    _locationController = TextEditingController(text: widget.donation.location);
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation updated successfully!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Donation'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CustomTextField(
                controller: _foodNameController,
                label: 'Food Name',
                validator: (value) => value == null || value.isEmpty ? 'Please enter a food name' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _locationController,
                label: 'Pickup Location',
                validator: (value) => value == null || value.isEmpty ? 'Please enter a location' : null,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}