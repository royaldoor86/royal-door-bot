import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_alliance_model.dart';

class FamilyAlliancesPage extends StatefulWidget {
  final String familyId;
  const FamilyAlliancesPage({super.key, required this.familyId});

  @override
  State<FamilyAlliancesPage> createState() => _FamilyAlliancesPageState();
}

class _FamilyAlliancesPageState extends State<FamilyAlliancesPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedFamilyId;
  String? _selectedFamilyName;
  bool _isLoading = false;

  Future<void> _showFamilyPicker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A050E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('families')
            .where(FieldPath.documentId, isNotEqualTo: widget.familyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          final families = snapshot.data!.docs;

          if (families.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: Text('لا توجد عائلات أخرى حالياً',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('اختر عائلة للتحالف',
                    style: TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: families.length,
                  itemBuilder: (context, index) {
                    final family =
                        families[index].data() as Map<String, dynamic>;
                    final familyId = families[index].id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: family['logoUrl'] != null &&
                                family['logoUrl'].isNotEmpty
                            ? NetworkImage(family['logoUrl'])
                            : null,
                        child: (family['logoUrl'] == null ||
                                family['logoUrl'].isEmpty)
                            ? const Icon(Icons.family_restroom)
                            : null,
                      ),
                      title: Text(family['name'] ?? '',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('المستوى: ${family['level'] ?? 1}',
                          style: const TextStyle(color: Colors.white38)),
                      onTap: () {
                        setState(() {
                          _selectedFamilyId = familyId;
                          _selectedFamilyName = family['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _proposeAlliance() async {
    if (_selectedFamilyId == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار عائلة وإدخال اسم التحالف')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _familyService.proposeAlliance(
        familyId1: widget.familyId,
        familyId2: _selectedFamilyId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إرسال طلب التحالف بنجاح ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedFamilyId = null;
      _selectedFamilyName = null;
    });
  }

  Future<void> _acceptAlliance(String allianceId) async {
    try {
      await _familyService.acceptAlliance(allianceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم قبول التحالف بنجاح ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dissolveAlliance(String allianceId) async {
    try {
      await _familyService.dissolveAlliance(allianceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم فك التحالف'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('التحالفات', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // Propose Alliance Form
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إنشاء تحالف جديد',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showFamilyPicker,
                      child: AppTheme.glassContainer(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            const Icon(Icons.group_add, color: Colors.amber),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _selectedFamilyName ?? 'اضغط لاختيار عائلة',
                                style: TextStyle(
                                  color: _selectedFamilyName != null
                                      ? Colors.white
                                      : Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم التحالف',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'وصف التحالف',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _proposeAlliance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إرسال طلب التحالف',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Alliances List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_alliances')
                      .where('familyId1', isEqualTo: widget.familyId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot1) {
                    if (!snapshot1.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final alliances1 = snapshot1.data!.docs;

                    return StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('family_alliances')
                          .where('familyId2', isEqualTo: widget.familyId)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot2) {
                        if (!snapshot2.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber));
                        }

                        final alliances2 = snapshot2.data!.docs;
                        final allAlliances = [...alliances1, ...alliances2];

                        if (allAlliances.isEmpty) {
                          return const Center(
                            child: Text('لا توجد تحالفات حالياً',
                                style: TextStyle(color: Colors.white38)),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: allAlliances.length,
                          itemBuilder: (context, index) {
                            final alliance = FamilyAllianceModel.fromFirestore(
                                allAlliances[index]);

                            return AppTheme.glassContainer(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: alliance.familyId1 ==
                                                    widget.familyId &&
                                                alliance.familyLogo2.isNotEmpty
                                            ? NetworkImage(alliance.familyLogo2)
                                            : (alliance.familyLogo1.isNotEmpty
                                                ? NetworkImage(
                                                    alliance.familyLogo1)
                                                : null),
                                        child: (alliance.familyLogo1.isEmpty &&
                                                alliance.familyLogo2.isEmpty)
                                            ? const Icon(Icons.group,
                                                color: Colors.amber)
                                            : null,
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(alliance.name,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(alliance.description,
                                                style: const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    children: [
                                      _getStatusBadge(alliance.status),
                                      const SizedBox(width: 10),
                                      if (alliance.status == 'pending' &&
                                          alliance.familyId2 == widget.familyId)
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _acceptAlliance(alliance.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                            ),
                                            child: const Text('قبول',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                      if (alliance.status == 'active')
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _dissolveAlliance(alliance.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                            ),
                                            child: const Text('فك التحالف',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    switch (status) {
      case 'pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange),
          ),
          child: const Text('قيد الانتظار',
              style: TextStyle(color: Colors.orange, fontSize: 12)),
        );
      case 'active':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: const Text('نشط',
              style: TextStyle(color: Colors.green, fontSize: 12)),
        );
      case 'dissolved':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red),
          ),
          child: const Text('منحل',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        );
      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey),
          ),
          child: const Text('مرفوض',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        );
      default:
        return const SizedBox();
    }
  }
}
