import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; 
import 'package:dropdown_search/dropdown_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceForm extends StatefulWidget {
  const InvoiceForm({super.key});

  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  // 1. Change to late initialization
  late TextEditingController _invoiceNoController;
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _perfumeController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _discountController = TextEditingController();

  double _subtotal = 0.0;
  double _totalAmount = 0.0;
  bool _isSubmitting = false;

  List<Map<String, String>> _products = []; 
  bool _isLoadingProducts = true;
  final String _scriptUrl = "https://script.google.com/macros/s/AKfycbzKQmVGhZ0xlDp4tp4RN4rEA6dXoXo4HFzpsi_49rY2qD-z9_SV5jfoyn04-wmomtoi/exec";

  @override
  void initState() {
    super.initState();
    // 2. Initialize with a placeholder, then load the real one
    _invoiceNoController = TextEditingController(text: "INV-2026-001");
    _loadInitialData(); 
  }

  // --- NEW: LOAD LAST INVOICE + STOCK ---
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Last Invoice Number
    final String? lastInvoice = prefs.getString('last_invoice_no');
    if (lastInvoice != null) {
      setState(() {
        _invoiceNoController.text = lastInvoice;
      });
    }

    // Load Offline Stock
    final String? cachedData = prefs.getString('cached_products');
    if (cachedData != null) {
      var decoded = jsonDecode(cachedData) as List;
      setState(() {
        _products = decoded.map((item) => Map<String, String>.from(item)).toList();
      });
    }
    _fetchProducts();
  }

  // --- UPDATED: INCREMENT & SAVE ---
  void _incrementInvoiceNumber() async {
    String current = _invoiceNoController.text;
    try {
      List<String> parts = current.split('-');
      if (parts.length == 3) {
        int lastNum = int.parse(parts[2]);
        int nextNum = lastNum + 1;
        String nextInvoice = "${parts[0]}-${parts[1]}-${nextNum.toString().padLeft(3, '0')}";
        
        setState(() {
          _invoiceNoController.text = nextInvoice;
        });

        // SAVE TO MEMORY IMMEDIATELY
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_invoice_no', nextInvoice);
      }
    } catch (e) {
      debugPrint("Could not increment invoice: $e");
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);

    try {
      final response = await http.get(Uri.parse(_scriptUrl)).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body) as List;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_products', response.body);

        if (mounted) {
          setState(() {
            _products = decoded.map((item) => Map<String, String>.from(item)).toList();
            _isLoadingProducts = false;
          });
        }
      }
    } on SocketException {
      if (mounted) setState(() => _isLoadingProducts = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _handleFullRefresh() async {
    _customerNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _perfumeController.clear();
    _qtyController.clear();
    _priceController.clear();
    _deliveryController.clear();
    _discountController.clear();
    
    setState(() {
      _subtotal = 0.0;
      _totalAmount = 0.0;
    });

    await _fetchProducts();
  }

  void _calculateTotal() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final delivery = double.tryParse(_deliveryController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;

    setState(() {
      _subtotal = qty * price;
      _totalAmount = (_subtotal + delivery) - discount;
    });
  }

  Future<void> _handleSyncAndPdf() async {
    if (_perfumeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a perfume")));
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "task": "create_invoice",
          "invoiceNo": _invoiceNoController.text,
          "customerName": _customerNameController.text,
          "phone": _phoneController.text,
          "address": _addressController.text,
          "itemName": _perfumeController.text,
          "qty": double.tryParse(_qtyController.text) ?? 0,
          "sellingPrice": double.tryParse(_priceController.text) ?? 0,
          "totalAmount": _totalAmount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        await _generatePdf();
        _incrementInvoiceNumber(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inventory Deducted & Invoice Saved!")));
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Failed: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("AREEJA", style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.Text("Fine Fragrances", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("INVOICE", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                      pw.Text("# ${_invoiceNoController.text}"), 
                      pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("BILL TO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700)),
                        pw.SizedBox(height: 5),
                        pw.Text(_customerNameController.text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(_phoneController.text),
                        pw.Container(width: 200, child: pw.Text(_addressController.text)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
                headers: ['Description', 'Qty', 'Unit Price', 'Total'],
                data: [
                  [_perfumeController.text, _qtyController.text, "${_priceController.text} TK", "${_subtotal.toStringAsFixed(2)} TK"],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _pdfRow("Subtotal:", "${_subtotal.toStringAsFixed(2)} TK"),
                        _pdfRow("Delivery:", "${_deliveryController.text.isEmpty ? "0.0" : _deliveryController.text} TK"),
                        _pdfRow("Discount:", "- ${_discountController.text.isEmpty ? "0.0" : _discountController.text} TK"),
                        pw.Divider(thickness: 1, color: PdfColors.black),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                            pw.Text("${_totalAmount.toStringAsFixed(2)} TK", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.Center(
                child: pw.Text("Thank you for choosing AREEJA. Your signature scent awaits.", 
                  style: const pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    final fileName = "${_customerNameController.text.replaceAll(' ', '_')}_${_invoiceNoController.text}";
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: '$fileName.pdf');
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Invoice", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _isLoadingProducts ? null : _handleFullRefresh, 
            tooltip: "Reset Form & Refresh Stock",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceHeader(),
            const SizedBox(height: 25),
            _buildSectionTitle("Customer Details"),
            _classicField("Customer Name", Icons.person_outline, controller: _customerNameController),
            _classicField("Phone Number", Icons.phone_android_outlined, isNumber: true, controller: _phoneController),
            _classicField("Full Shipping Address", Icons.location_on_outlined, maxLines: 2, controller: _addressController),
            const SizedBox(height: 20),
            _buildSectionTitle("Product Details"),
            
            // --- UPDATED LOADING LOGIC ---
            if (_isLoadingProducts) 
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(color: Colors.black, backgroundColor: Colors.white),
              ),

            // Dropdown shows regardless of loading if products exist in cache
            if (_products.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: DropdownSearch<Map<String, String>>(
                  items: (filter, loadProps) => _products
                      .where((item) => item['name']!.toLowerCase().contains(filter.toLowerCase()))
                      .toList(),
                  itemAsString: (Map<String, String>? u) => u?['name'] ?? "Unknown Item",
                  compareFn: (item1, item2) => item1['name'] == item2['name'],
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      labelText: "Select Perfume",
                      prefixIcon: const Icon(Icons.local_mall_outlined, size: 20),
                      labelStyle: const TextStyle(color: Colors.black54),
                      border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      decoration: InputDecoration(hintText: "Search name...", prefixIcon: Icon(Icons.search)),
                    ),
                  ),
                  onChanged: (Map<String, String>? selectedData) {
                    if (selectedData != null) {
                      setState(() {
                        _perfumeController.text = selectedData['name']!;
                        _priceController.text = selectedData['price']!; 
                        _calculateTotal();
                      });
                    }
                  },
                ),
              )
            else if (!_isLoadingProducts && _products.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No products available. Sync required.", style: TextStyle(color: Colors.red))),
              ),

            Row(
              children: [
                Expanded(child: _classicField("Quantity", Icons.numbers, isNumber: true, controller: _qtyController)),
                const SizedBox(width: 15),
                Expanded(child: _classicField("Unit Price", Icons.payments_outlined, isNumber: true, controller: _priceController)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _classicField("Delivery Cost", Icons.local_shipping_outlined, isNumber: true, controller: _deliveryController)),
                const SizedBox(width: 15),
                Expanded(child: _classicField("Discount (TK)", Icons.discount_outlined, isNumber: true, controller: _discountController)),
              ],
            ),
            const SizedBox(height: 30),
            _buildTotalPreview(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("INVOICE NO", style: TextStyle(color: Colors.grey[600], letterSpacing: 1.2, fontSize: 12)),
            SizedBox(
              width: 150,
              child: TextField(
                controller: _invoiceNoController,
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("DATE", style: TextStyle(color: Colors.grey[600], letterSpacing: 1.2, fontSize: 12)),
            Text(DateTime.now().toString().split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Grand Total", style: TextStyle(color: Colors.white70, fontSize: 16)),
          Text("৳${_totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleSyncAndPdf,
          icon: _isSubmitting 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isSubmitting ? "SYNCING DATA..." : "GENERATE PDF & SAVE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel Entry", style: TextStyle(color: Colors.redAccent))),
      ],
    );
  }

  Widget _classicField(String label, IconData icon, {bool isNumber = false, int maxLines = 1, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => _calculateTotal(),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.black54),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
    );
  }
}