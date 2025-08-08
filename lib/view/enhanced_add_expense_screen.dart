import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../model/expense.dart';
import '../view_model/expense_view_model.dart';
import '../services/voice_service.dart';
import '../services/ocr_service.dart';

class EnhancedAddExpenseScreen extends StatefulWidget {
  const EnhancedAddExpenseScreen({super.key});

  @override
  State<EnhancedAddExpenseScreen> createState() =>
      _EnhancedAddExpenseScreenState();
}

class _EnhancedAddExpenseScreenState extends State<EnhancedAddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _category = 'General';
  DateTime _selectedDate = DateTime.now();

  // Services
  late VoiceService _voiceService;
  late OCRService _ocrService;

  bool _isVoiceInitialized = false;
  bool _showVoiceUI = false;
  bool _showOCRUI = false;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _ocrService = OCRService();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    _isVoiceInitialized = await _voiceService.initialize();
    setState(() {});
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) return;

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _category,
    );

    Provider.of<ExpenseViewModel>(context, listen: false)
        .addExpense(newExpense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Expense "${title}" added successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _startVoiceInput() async {
    setState(() {
      _showVoiceUI = true;
    });

    await _voiceService.startListening();
  }

  void _stopVoiceInput() async {
    await _voiceService.stopListening();

    if (_voiceService.text.isNotEmpty) {
      final voiceData = _voiceService.parseExpenseFromVoice(_voiceService.text);
      if (voiceData != null) {
        _titleController.text = voiceData.title;
        _amountController.text = voiceData.amount.toString();
        setState(() {
          _category = voiceData.category;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input processed: ${voiceData.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }

    setState(() {
      _showVoiceUI = false;
    });
  }

  void _showOCROptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan Bill/Receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture a new photo of your receipt'),
              onTap: () async {
                Navigator.pop(context);
                await _scanFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select an existing photo'),
              onTap: () async {
                Navigator.pop(context);
                await _scanFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    setState(() {
      _showOCRUI = true;
    });

    final billData = await _ocrService.scanBillFromCamera();
    _processBillData(billData);

    setState(() {
      _showOCRUI = false;
    });
  }

  Future<void> _scanFromGallery() async {
    setState(() {
      _showOCRUI = true;
    });

    final billData = await _ocrService.scanBillFromGallery();
    _processBillData(billData);

    setState(() {
      _showOCRUI = false;
    });
  }

  void _processBillData(BillData? billData) {
    if (billData != null) {
      _titleController.text = billData.suggestedTitle;
      _amountController.text = billData.totalAmount.toString();
      setState(() {
        _category = billData.suggestedCategory;
        _selectedDate = billData.date;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill scanned: ${billData.suggestedTitle}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Details',
            onPressed: () => _showBillDetails(billData),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not extract data from the image'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showBillDetails(BillData billData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bill Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Merchant: ${billData.merchantName}'),
              Text('Total: ${billData.totalAmount}'),
              Text('Date: ${billData.date.toString().split(' ')[0]}'),
              if (billData.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Items:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ...billData.items
                    .map((item) => Text('• ${item.name}: ${item.price}')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRawText(billData.rawText);
            },
            child: const Text('View Raw Text'),
          ),
        ],
      ),
    );
  }

  void _showRawText(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extracted Text'),
        content: SingleChildScrollView(
          child: Text(text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      case 'shopping':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          // Voice Input Button
          if (_isVoiceInitialized)
            IconButton(
              onPressed: _showVoiceUI ? _stopVoiceInput : _startVoiceInput,
              icon: Icon(
                _showVoiceUI ? Icons.mic_off : Icons.mic,
                color: _showVoiceUI ? Colors.red : Colors.blue,
              ),
              tooltip: 'Voice Input',
            ),
          // OCR Button
          IconButton(
            onPressed: _showOCRUI ? null : _showOCROptions,
            icon: Icon(
              Icons.camera_alt,
              color: _showOCRUI ? Colors.grey : Colors.green,
            ),
            tooltip: 'Scan Receipt',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Voice Input UI
                  if (_showVoiceUI)
                    Consumer<VoiceService>(
                      builder: (context, voiceService, child) => Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.mic,
                                  size: 48, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text(
                                voiceService.isListening
                                    ? 'Listening...'
                                    : 'Voice Input Ready',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (voiceService.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(voiceService.text),
                                const SizedBox(height: 8),
                                Text(
                                    'Confidence: ${(voiceService.confidence * 100).toStringAsFixed(1)}%'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                  // OCR Processing UI
                  if (_showOCRUI)
                    Card(
                      color: Colors.green.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 8),
                            Text(
                              'Processing image...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Expense Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expense Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              hintText: 'Enter expense title',
                              prefixIcon: Icon(Icons.edit),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Consumer<ExpenseViewModel>(
                            builder: (context, viewModel, child) =>
                                TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                hintText: 'Enter amount',
                                prefixIcon: Icon(Icons.currency_rupee),
                                suffixText:
                                    viewModel.currencyService.selectedCurrency,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              prefixIcon: Icon(
                                _getCategoryIcon(_category),
                                color: _getCategoryColor(_category),
                              ),
                            ),
                            items: [
                              'General',
                              'Food',
                              'Transport',
                              'Bills',
                              'Shopping'
                            ]
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(category),
                                            color: _getCategoryColor(category),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            category,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _category = value!),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
