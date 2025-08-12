import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/customer.dart';
import '../models/debt.dart';
import '../providers/app_state.dart';
import '../services/notification_service.dart';

class AddDebtScreen extends StatefulWidget {
  final Customer? customer;

  const AddDebtScreen({super.key, this.customer});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    
    // Add listener to description controller for real-time validation
    _descriptionController.addListener(() {
      setState(() {}); // Rebuild to show/hide warning icon
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }





  Future<void> _saveDebt() async {
    if (_formKey.currentState?.validate() == true && _selectedCustomer != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final amount = double.parse(_amountController.text.replaceAll(',', ''));
        
        final debt = Debt(
          id: appState.generateDebtId(),
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          description: _descriptionController.text.trim(),
          amount: amount,
          type: DebtType.credit,
          status: DebtStatus.pending,
          createdAt: DateTime.now(),
        );

        await appState.addDebt(debt);

        setState(() {
          _isLoading = false;
        });
        
        // Navigate back with result
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error notification
        final notificationService = NotificationService();
        await notificationService.showErrorNotification(
          title: 'Error',
          body: 'Failed to add debt: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Debt for ${_selectedCustomer?.name ?? "Customer"}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                helperText: 'Enter a description for the debt item',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final cleanValue = value.replaceAll(',', '');
                if (double.tryParse(cleanValue) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(cleanValue) <= 0) {
                  return 'Amount must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDebt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Add Debt',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 