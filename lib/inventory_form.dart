import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryForm extends StatefulWidget {
  const InventoryForm({super.key});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  // Controllers to capture user input
  final _brandController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _purchaseController = TextEditingController(); // Purchase Price (Per Unit)
  final _shippingController = TextEditingController(); // Total Shipping Cost
  final _sellingController = TextEditingController(); // Selling Price (Per Unit)

  bool _isSubmitting = false;

  // Calculated variables
  double landingCostPerUnit = 0.0;
  double profitPerUnit = 0.0;
  double totalProfit = 0.0;

  // --- UPDATED LOGIC SECTION ---
  void _calculateValues() {
    final double qty = double.tryParse(_qtyController.text) ?? 0;
    final double purchasePerUnit = double.tryParse(_purchaseController.text) ?? 0;
    final double totalShipping = double.tryParse(_shippingController.text) ?? 0;
    final double sellingPerUnit = double.tryParse(_sellingController.text) ?? 0;

    setState(() {
      if (qty > 0) {
        // 1. Landing Cost per Unit = ((Purchase Price * Qty) + Total Shipping) / Qty
        landingCostPerUnit = ((purchasePerUnit * qty) + totalShipping) / qty;

        // 2. Profit per Unit = Selling Price - Landing Cost per Unit
        profitPerUnit = sellingPerUnit - landingCostPerUnit;

        // 3. Total Profit = Profit per Unit * Qty
        totalProfit = profitPerUnit * qty;
      } else {
        landingCostPerUnit = 0.0;
        profitPerUnit = 0.0;
        totalProfit = 0.0;
      }
    });
  }
  // --- END OF UPDATED LOGIC ---

  Future<void> _submitToSheet() async {
  setState(() => _isSubmitting = true);

  // Updated URL - Ensure you use the "New Version" deployment URL from Apps Script
  const String scriptUrl = "https://script.google.com/macros/s/AKfycbzKQmVGhZ0xlDp4tp4RN4rEA6dXoXo4HFzpsi_49rY2qD-z9_SV5jfoyn04-wmomtoi/exec";

  try {
    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "task": "add_inventory", // THIS IS NEW
        "brand": _brandController.text,
        "itemName": _itemNameController.text,
        "qty": double.tryParse(_qtyController.text) ?? 0,
        "purchasePrice": double.tryParse(_purchaseController.text) ?? 0,
        "shipping": double.tryParse(_shippingController.text) ?? 0,
        "sellingPrice": double.tryParse(_sellingController.text) ?? 0,
        }),
    ).timeout(const Duration(seconds: 15));

    // Apps Script redirects (302) are handled by the library, but we check for 200/302 for safety
    if (response.statusCode == 200 || response.statusCode == 302) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory Saved!")),
        );
        _clearForm();
      }
    } else {
      print("Status Code: ${response.statusCode}");
      throw Exception("Server returned ${response.statusCode}");
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  } finally {
    setState(() => _isSubmitting = false);
  }
}

  void _clearForm() {
    _brandController.clear();
    _itemNameController.clear();
    _qtyController.clear();
    _purchaseController.clear();
    _shippingController.clear();
    _sellingController.clear();
    setState(() {
      landingCostPerUnit = 0;
      profitPerUnit = 0;
      totalProfit = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Stock Entry", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionCard("Product Details", [
              _textField("Brand Name", Icons.branding_watermark, _brandController),
              _textField("Item/Perfume Name", Icons.label, _itemNameController),
            ]),
            const SizedBox(height: 15),
            _buildSectionCard("Sourcing & Costs", [
              _numberField("Quantity Purchased", Icons.numbers, _qtyController),
              _numberField("Purchase Price (Per Unit)", Icons.payments, _purchaseController),
              _numberField("Total Shipping Cost", Icons.local_shipping, _shippingController),
              _numberField("Selling Price per Unit", Icons.sell, _sellingController),
            ]),
            const SizedBox(height: 15),
            _buildSummaryCard(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitToSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("SUBMIT INVENTORY", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          _summaryRow("Landing Cost / Unit", landingCostPerUnit),
          _summaryRow("Profit / Unit", profitPerUnit),
          const Divider(),
          _summaryRow("Total Expected Profit", totalProfit, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text("৳${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 15, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
              color: value < 0 ? Colors.red : Colors.green
            )
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _numberField(String label, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        onChanged: (_) => _calculateValues(),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}