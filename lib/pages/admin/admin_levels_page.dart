import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key});

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  final _db = FirebaseFirestore.instance;
  final _levelController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AppTheme.background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const HeadingText("إدارة مستويات المتجر",
                fontSize: DesignTokens.fontSizeLg),
            backgroundColor: Colors.transparent,
            elevation: 0),
        body: Column(
          children: [
            _buildAddForm(),
            const RoyalDivider(),
            Expanded(child: _buildLevelsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return RoyalCard(
      child: Column(
        children: [
          const HeadingText("صنع مستوى جديد للمتجر",
              fontSize: DesignTokens.fontSizeBase,
              color: DesignTokens.primaryGold),
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(
                  child: RoyalTextField(
                controller: _levelController,
                hintText: "رقم المستوى",
                prefixIcon: Icons.trending_up,
                keyboardType: TextInputType.number,
              )),
              const SizedBox(width: DesignTokens.spacingMd),
              Expanded(
                  child: RoyalTextField(
                controller: _priceController,
                hintText: "السعر بالجواهر",
                prefixIcon: Icons.diamond,
                keyboardType: TextInputType.number,
              )),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          RoyalButton(
            label: _isSaving ? "جاري الحفظ..." : "إضافة المستوى للمتجر 🚀",
            onPressed: _isSaving ? () {} : () => _saveLevel(),
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Future<void> _saveLevel() async {
    final lvl = int.tryParse(_levelController.text);
    final prc = int.tryParse(_priceController.text);

    if (lvl == null || prc == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("يرجى إدخال قيم صحيحة")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // حفظ المستوى في مجموعة خاصة بمتجر المستويات
      await _db.collection('store_levels').doc('lvl_$lvl').set({
        'levelValue': lvl,
        'price': prc,
        'name': "ترقية للمستوى $lvl",
        'category': 'levels',
        'currencyType': 'gems',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _levelController.clear();
      _priceController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تمت إضافة المستوى بنجاح ✅")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("خطأ: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLevelsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('store_levels').orderBy('levelValue').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const RoyalLoadingIndicator();
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return RoyalCard(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
              padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spacingSm,
                  horizontal: DesignTokens.spacingMd),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    backgroundColor: DesignTokens.primaryGold,
                    child: Text("${data['levelValue']}",
                        style: const TextStyle(
                            color: DesignTokens.neutralBlack,
                            fontWeight: DesignTokens.fontWeightBold))),
                title: BodyText(data['name'],
                    fontWeight: DesignTokens.fontWeightBold),
                subtitle: CaptionText("السعر: ${data['price']} جوهرة",
                    textAlign: TextAlign.right),
                trailing: IconButton(
                  icon: const Icon(Icons.delete,
                      color: DesignTokens.semanticError),
                  onPressed: () => docs[i].reference.delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
