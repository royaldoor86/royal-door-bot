import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/harvest_models.dart';
import '../services/harvest_service.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class RoyalHarvestMarketplacePage extends StatefulWidget {
  const RoyalHarvestMarketplacePage({super.key});

  @override
  State<RoyalHarvestMarketplacePage> createState() => _RoyalHarvestMarketplacePageState();
}

class _RoyalHarvestMarketplacePageState extends State<RoyalHarvestMarketplacePage> {
  final HarvestService _harvestService = HarvestService();
  final NumberFormat _formatter = NumberFormat.decimalPattern('ar');

  String _formatNumber(num number) {
    return _formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('سوق الحصاد الملكي',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _harvestService.getActiveListings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text('لا توجد عروض متاحة حالياً في السوق',
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                );
              }

              final listings = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final listing = HarvestListing.fromMap(listings[index]);
                  return _buildListingCard(listing);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(HarvestListing listing) {
    final investment = ActiveInvestment.fromMap(listing.investmentData, listing.investmentId);
    final bool isMyListing = listing.sellerId == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        borderGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.packageName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('البائع: ${listing.sellerId.substring(0, 8)}...',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${_formatNumber(listing.askingPrice)} د.ع',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('الأرباح المتبقية', '${_formatNumber(investment.remainingProfit)} د.ع'),
                _buildInfoColumn('الأيام المتبقية', '${investment.remainingDays} يوم'),
                _buildInfoColumn('الربح اليومي', '${_formatNumber(investment.dailyProfit)} د.ع'),
              ],
            ),
            if (listing.description != null && listing.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(listing.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppTheme.gradientButton(
                text: isMyListing ? 'عرضك الخاص' : 'شراء الحصاد الآن',
                onPressed: isMyListing ? null : () => _showPurchaseDialog(listing),
                isRoyal: !isMyListing,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _showPurchaseDialog(HarvestListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
        content: Text(
            'هل أنت متأكد من شراء حصاد "${listing.packageName}" مقابل ${_formatNumber(listing.askingPrice)} دينار؟\n\nستنتقل ملكية الحصاد وأرباحه المتبقية إليك فوراً.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _processPurchase(listing.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد الشراء'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(String listingId) async {
    try {
      await _harvestService.purchaseFromMarketplace(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت عملية الشراء بنجاح! 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الشراء: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
