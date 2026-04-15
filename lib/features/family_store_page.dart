import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/family_model.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyStorePage extends StatefulWidget {
  final FamilyModel family;
  const FamilyStorePage({super.key, required this.family});

  @override
  State<FamilyStorePage> createState() => _FamilyStorePageState();
}

class _FamilyStorePageState extends State<FamilyStorePage> {
  final FamilyService _familyService = FamilyService();

  final List<Map<String, dynamic>> _perks = [
    {
      'id': 'entrance_effect_1',
      'name': 'تأثير دخول ملكي',
      'desc': 'تأثير حركي مميز عند دخول أي عضو للغرف الصوتية',
      'cost': 5000,
      'currency': 'coins',
      'icon': Icons.auto_awesome,
    },
    {
      'id': 'extra_members_10',
      'name': 'توسيع العائلة (+10)',
      'desc': 'زيادة الحد الأقصى للأعضاء بـ 10 مقاعد إضافية',
      'cost': 200,
      'currency': 'gems',
      'icon': Icons.group_add,
    },
    {
      'id': 'family_badge_gold',
      'name': 'شارة العائلة الذهبية',
      'desc': 'تظهر شارة ذهبية بجانب اسم العائلة في القوائم',
      'cost': 1000,
      'currency': 'gems',
      'icon': Icons.verified,
    },
  ];

  void _buyPerk(Map<String, dynamic> perk) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد شراء "${perk['name']}" مقابل ${perk['cost']} ${perk['currency'] == 'gems' ? 'جوهرة' : 'عملة'} من خزينة العائلة؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _familyService.buyFamilyPerk(widget.family.id, perk['id'], perk['cost'], perk['currency']);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الشراء بنجاح! 🎉'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('شراء'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متجر العائلة الملكي'),
          backgroundColor: const Color(0xFF1A050E),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('families').doc(widget.family.id).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final family = FamilyModel.fromFirestore(snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
              
              return Column(
                children: [
                  _buildWealthHeader(family),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _perks.length,
                      itemBuilder: (context, index) {
                        final perk = _perks[index];
                        final bool isUnlocked = family.perks.containsKey(perk['id']);
                        
                        return AppTheme.glassContainer(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          opacity: 0.05,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white10,
                              child: Icon(perk['icon'], color: Colors.amber),
                            ),
                            title: Text(perk['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(perk['desc'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: isUnlocked 
                              ? const Text('مفعل ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                  onPressed: () => _buyPerk(perk),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${perk['cost']}', style: const TextStyle(color: Colors.black)),
                                      const SizedBox(width: 4),
                                      Icon(perk['currency'] == 'gems' ? Icons.diamond : Icons.monetization_on, size: 14, color: Colors.black),
                                    ],
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildWealthHeader(FamilyModel family) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _wealthItem(family.familyGems, Icons.diamond, Colors.cyanAccent, 'جواهر الخزينة'),
          _wealthItem(family.familyCoins, Icons.monetization_on, Colors.amber, 'عملات الخزينة'),
        ],
      ),
    );
  }

  Widget _wealthItem(int value, IconData icon, Color color, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
