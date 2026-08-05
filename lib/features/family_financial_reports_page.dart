import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class FamilyFinancialReportsPage extends StatefulWidget {
  final String familyId;
  const FamilyFinancialReportsPage({super.key, required this.familyId});

  @override
  State<FamilyFinancialReportsPage> createState() =>
      _FamilyFinancialReportsPageState();
}

class _FamilyFinancialReportsPageState
    extends State<FamilyFinancialReportsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedPeriod = 'all';

  final Map<String, String> _periodNames = {
    'all': 'الكل',
    'today': 'اليوم',
    'week': 'الأسبوع',
    'month': 'الشهر',
    'year': 'السنة',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('التقارير المالية',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPeriodFilter(),
                const SizedBox(height: 20),
                _buildFinancialSummary(),
                const SizedBox(height: 20),
                _buildTransactionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periodNames.entries.map((entry) {
            final isSelected = _selectedPeriod == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedPeriod = entry.key);
                },
                selectedColor: Colors.amber.withValues(alpha: 0.3),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('families').doc(widget.familyId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        final family = snapshot.data!.data() as Map<String, dynamic>?;

        final familyGems = family?['familyGems'] ?? 0;
        final familyStars = family?['familyCoins'] ?? 0;
        final totalExp = family?['totalExp'] ?? 0;

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الملخص المالي',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildSummaryItem(
                  'جواهر العائلة', familyGems, Icons.diamond, Colors.cyan),
              const SizedBox(height: 10),
              _buildSummaryItem('كوينز العائلة', familyStars,
                  Icons.monetization_on, Colors.amber),
              const SizedBox(height: 10),
              _buildSummaryItem(
                  'إجمالي الخبرة', totalExp, Icons.explore, Colors.purple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
      String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    Query query = _db
        .collection('families')
        .doc(widget.familyId)
        .collection('financial_transactions')
        .orderBy('timestamp', descending: true);

    if (_selectedPeriod != 'all') {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(2000);
      }

      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سجل المعاملات',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: query.limit(50).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final transactions = snapshot.data!.docs;
              if (transactions.isEmpty) {
                return const Center(
                  child: Text('لا توجد معاملات',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction =
                      transactions[index].data() as Map<String, dynamic>;
                  return _buildTransactionTile(transaction);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] ?? 0;
    final description = transaction['description'] ?? '';
    final timestamp = transaction['timestamp'] as Timestamp?;
    final isIncoming = transaction['isIncoming'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isIncoming
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncoming ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncoming ? '+' : '-'}$amount',
            style: TextStyle(
                color: isIncoming ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
