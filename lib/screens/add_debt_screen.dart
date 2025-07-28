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



  Future<void> _selectCustomer() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final customers = appState.customers;
    
    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No customers available. Please add a customer first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final Customer? selected = await showDialog<Customer>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      customer.name.split(' ').map((e) => e[0]).join(''),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.phone),
                  onTap: () => Navigator.of(context).pop(customer),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedCustomer = selected;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        final amount = double.parse(_amountController.text);
        
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
        Navigator.pop(context, true);
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
        title: const Text('Add Debt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer selection
            Consumer<AppState>(
              builder: (context, appState, child) {
                return InkWell(
                  onTap: _selectCustomer,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Customer *',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedCustomer?.name ?? 'Select a customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedCustomer != null 
                                      ? AppColors.textPrimary 
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
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
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
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
                onPressed: _isLoading || _selectedCustomer == null ? null : _saveDebt,
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