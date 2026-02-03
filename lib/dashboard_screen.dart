import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import 'invoice_form.dart';   
import 'inventory_form.dart'; 

class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  // --- VARIABLES FOR DYNAMIC DATA ---
  String _lifetimeRevenue = "0.00";
  String _lifetimeProfit = "0.00";
  String _monthlyOrders = "0"; 
  String _monthlyRevenue = "0.00";
  String _prevMonthlyRevenue = "0.00";
  String _growthPercentage = "0.0";
  String _totalStock = "0";
  List<dynamic> _topProducts = [];
  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
];
    String _getMonthName(int offset) {
    // DateTime.now().month is 1-based (Jan = 1)
    // We subtract 1 to make it 0-based for our list
    int targetMonth = DateTime.now().month - 1 + offset;
    
    // Handle year wrap-around (e.g., January - 1 = December)
    if (targetMonth < 0) targetMonth = 12 + targetMonth;
    if (targetMonth > 11) targetMonth = targetMonth % 12;
    
    return _months[targetMonth];
}
  bool _isLoading = true;
  
  final String _scriptUrl = "https://script.google.com/macros/s/AKfycbzKQmVGhZ0xlDp4tp4RN4rEA6dXoXo4HFzpsi_49rY2qD-z9_SV5jfoyn04-wmomtoi/exec";

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats(); 
  }

  Future<void> _fetchDashboardStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$_scriptUrl?task=get_dashboard_stats"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _lifetimeRevenue = data['revenue'].toString();
          _lifetimeProfit = data['profit'].toString();
          _monthlyOrders = data['monthlyQty'].toString();
          _monthlyRevenue = data['monthlyRevenue'].toString();
          _prevMonthlyRevenue = data['prevMonthlyRevenue'].toString();
          _growthPercentage = data['growth'].toString();
          _totalStock = data['totalStock'].toString();
          _topProducts = data['topProducts'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Dashboard Stats Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        color: Colors.black,
        child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverAppBar(
                    expandedHeight: 200, 
                    pinned: true,
                    backgroundColor: Colors.black,
                    flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black,
                            gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.black, Color(0xFF1A1A1A)],
                            ),
                        ),
                        padding: const EdgeInsets.only(top: 60, left: 25, right: 25),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                const Text(
                                    "AREEJA",
                                    style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: 8,
                                    ),
                                ),
                                Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 16),
                                ),
                                ],
                            ),
                            const SizedBox(height: 20),
                            
                            const Text(
                                "LIFETIME PROFIT",
                                style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2),
                            ),
                            const SizedBox(height: 5),
                            Text(
                                _isLoading ? "..." : "৳ $_lifetimeProfit",
                                style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier', 
                                ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                                children: [
                                const Text("Total Revenue: ", style: TextStyle(color: Colors.white38, fontSize: 11)),
                                Text(
                                    _isLoading ? "..." : "৳ $_lifetimeRevenue",
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                ],
                            ),
                            ],
                        ),
                        ),
                    ),
                ),
            
            SliverToBoxAdapter(
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    _buildSectionTitle("Monthly Performance"),
                    const SizedBox(height: 15),
                    
                    _buildComparisonCard(),
                    
                    const SizedBox(height: 25),
                    
                    Row(
                            children: [
                                _buildMiniStat(_getMonthName(0), _isLoading ? "..." : "$_monthlyOrders Items", Icons.local_mall_outlined, Colors.black),
                                const SizedBox(width: 15),
                                _buildMiniStat("Active Stock", _isLoading ? "..." : "$_totalStock Units", Icons.inventory_2_outlined, Colors.black),
                            ],
                        ),

                    const SizedBox(height: 35),

                    _buildSectionTitle("Top Selling Products"),
                    const SizedBox(height: 15),

                    Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : Column(
                            children: _topProducts.isEmpty 
                            ? [const Text("No sales data yet")]
                            // PRECISE UPDATE: Using asMap().entries to get the index for ranking
                            : _topProducts.asMap().entries.map((entry) {
                                int index = entry.key; // 0 for 1st, 1 for 2nd, etc.
                                var item = entry.value;

                                return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                    children: [
                                        Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                            // Color Logic: Gold, Silver, then Bronze/Grey
                                            color: index == 0 ? const Color(0xFFD4AF37) : 
                                                index == 1 ? const Color(0xFFC0C0C0) : 
                                                const Color(0xFFCD7F32),
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                            child: Text(
                                            "${index + 1}", // Shows 1, 2, or 3
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                            ),
                                            ),
                                        ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                        child: Text(
                                            item['name'].toString(),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        ),
                                        Text(
                                        "${item['qty']} Sold",
                                        style: TextStyle(
                                            color: Colors.grey.shade600, 
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w600
                                        ),
                                        ),
                                    ],
                                    ),
                                );
                                }).toList(),
                        ),
                    ),
                    const SizedBox(height: 35),

                    _buildSectionTitle("Operations"),
                    const SizedBox(height: 15),
                    
                    _buildWideActionBtn(context, "NEW INVOICE", Icons.add_rounded, Colors.black, () async {
                        // Added 'await' and refresh logic
                        await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InvoiceForm()),
                        );
                        _fetchDashboardStats();
                    }),

                        const SizedBox(height: 12),

                        _buildWideActionBtn(context, "STOCK ENTRY", Icons.edit_note_rounded, Colors.grey.shade800, () async {
                        // Added 'await' and refresh logic
                        await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InventoryForm()),
                        );
                        _fetchDashboardStats();
                        }),
                    ],
                ),
                ),
            ),
            ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
      return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text("${_getMonthName(0).toUpperCase()} SALES", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(_isLoading ? "..." : "৳ $_monthlyRevenue", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                // FIX: Added "৳72,100" as the missing 2nd argument
                _buildComparisonMetric("${_getMonthName(-1)} Sales", _isLoading ? "..." : "৳ $_prevMonthlyRevenue", false),
                _buildComparisonMetric("Growth", _isLoading ? "..." : "$_growthPercentage%", true),
            ],
            ),
          ],
      ),
      );
  }

  Widget _buildComparisonMetric(String label, String value, bool isHighlight) {
      return Column(
      crossAxisAlignment: isHighlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: isHighlight ? Colors.green.shade700 : Colors.black
          )),
      ],
      );
  }

  Widget _buildMiniStat(String title, String value, IconData icon, Color color) {
      return Expanded(
      child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
          ),
      ),
      );
  }

  Widget _buildWideActionBtn(BuildContext context, String label, IconData icon, Color bg, VoidCallback onTap) {
    return Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap, 
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
                children: [
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 15),
                Text(
                    label,
                    style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                ],
            ),
            ),
        ),
        ),
    );
  }

  Widget _buildSectionTitle(String title) {
      return Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.5));
  }
}