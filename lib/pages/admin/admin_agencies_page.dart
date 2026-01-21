import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/agency_model.dart';
import '../../services/agency_service.dart';
import '../../services/storage_service.dart';

class AdminAgenciesPage extends StatefulWidget {
  const AdminAgenciesPage({super.key});

  @override
  State<AdminAgenciesPage> createState() => _AdminAgenciesPageState();
}

class _AdminAgenciesPageState extends State<AdminAgenciesPage> {
  final AgencyService _agencyService = AgencyService();

  void _showCreateAgencyDialog({AgencyModel? agency}) {
    final targetIdCtrl = TextEditingController(); // لا يتم استخدامه في التعديل
    final nameCtrl = TextEditingController(text: agency?.name);
    File? selectedLogo;
    AgencyType selectedType = agency?.type ?? AgencyType.reseller;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setST) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A0A10),
            title: Text(
                agency == null ? "تأسيس وكالة جديدة" : "تعديل بيانات الوكالة",
                style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setST(() => selectedLogo = File(picked.path));
                      }
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: (0.5 * 255))),
                        image: selectedLogo != null
                            ? DecorationImage(
                                image: FileImage(selectedLogo!),
                                fit: BoxFit.cover)
                            : (agency != null
                                ? DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        agency.logoUrl),
                                    fit: BoxFit.cover)
                                : null),
                      ),
                      child: selectedLogo == null && agency == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.camera_alt, color: Colors.amber),
                                  Text("شعار الوكالة",
                                      style: TextStyle(
                                          color: Colors.white24, fontSize: 10))
                                ])
                          : (selectedLogo == null
                              ? const Icon(Icons.camera_alt,
                                  color: Colors.white70)
                              : null),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (agency == null) ...[
                    _inputField(targetIdCtrl, "ID المستخدم (الصغير)"),
                    const SizedBox(height: 10),
                  ],
                  _inputField(nameCtrl, "اسم الوكالة"),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButton<AgencyType>(
                      value: selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF1A0A10),
                      items: const [
                        DropdownMenuItem(
                            value: AgencyType.reseller,
                            child: Text("وكالة شحن",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14))),
                        DropdownMenuItem(
                            value: AgencyType.hosting,
                            child: Text("وكالة استضافة",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14))),
                      ],
                      onChanged: (v) => setST(() => selectedType = v!),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("إلغاء")),
              if (isSaving)
                const CircularProgressIndicator(color: Colors.amber)
              else
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty ||
                        (agency == null &&
                            (targetIdCtrl.text.isEmpty ||
                                selectedLogo == null))) {
                      return;
                    }
                    setST(() => isSaving = true);
                    try {
                      String finalLogoUrl = agency?.logoUrl ?? "";

                      if (selectedLogo != null) {
                        final tempId =
                            DateTime.now().millisecondsSinceEpoch.toString();
                        finalLogoUrl = await StorageService.uploadFamilyLogo(
                            "agency_$tempId", selectedLogo!);
                      }

                      if (agency == null) {
                        await _agencyService.createAgencyByShortId(
                          targetShortId: targetIdCtrl.text.trim(),
                          agencyName: nameCtrl.text.trim(),
                          logoUrl: finalLogoUrl,
                          type: selectedType,
                        );
                      } else {
                        await _agencyService.updateAgency(agency.id, {
                          'name': nameCtrl.text.trim(),
                          'logoUrl': finalLogoUrl,
                          'type': selectedType == AgencyType.reseller
                              ? 'reseller'
                              : 'hosting',
                        });
                      }

                      if (mounted) {
                        Navigator.pop(ctx);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
                      }
                    } finally {
                      setST(() => isSaving = false);
                    }
                  },
                  child:
                      Text(agency == null ? "تأكيد التأسيس" : "حفظ التعديلات"),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _confirmDeleteAgency(AgencyModel agency) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A10),
        title: const Text("حذف الوكالة", style: TextStyle(color: Colors.red)),
        content: Text(
            "هل أنت متأكد من حذف وكالة '${agency.name}'؟ سيتم سحب صلاحية الوكيل من صاحبها نهائياً."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              await _agencyService.deleteAgency(agency.id, agency.ownerId);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف الوكالة بنجاح")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف نهائي"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAgencyDialog(),
        icon: const Icon(Icons.add),
        label: const Text("تعيين وكيل جديد"),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('agencies').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final agencies = snapshot.data!.docs
              .map((d) => AgencyModel.fromFirestore(
                  d as DocumentSnapshot<Map<String, dynamic>>))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agencies.length,
            itemBuilder: (context, index) => _agencyAdminTile(agencies[index]),
          );
        },
      ),
    );
  }

  Widget _agencyAdminTile(AgencyModel agency) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
              radius: 25,
              backgroundImage: CachedNetworkImageProvider(agency.logoUrl)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agency.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(agency.ownerName,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Row(
                  children: [
                    Text(agency.type == AgencyType.reseller ? "شحن" : "استضافة",
                        style:
                            const TextStyle(color: Colors.amber, fontSize: 10)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showCreateAgencyDialog(agency: agency),
                      child:
                          const Icon(Icons.edit, color: Colors.blue, size: 14),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _confirmDeleteAgency(agency),
                      child: const Icon(Icons.delete_forever,
                          color: Colors.redAccent, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text("${agency.balance} 💎",
                  style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showChargeDialog(agency, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(50, 25),
                        padding: EdgeInsets.zero),
                    child: const Text("جواهر", style: TextStyle(fontSize: 9)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _showChargeDialog(agency, false),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(50, 25),
                        padding: EdgeInsets.zero),
                    child: const Text("كوينز", style: TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChargeDialog(AgencyModel agency, bool isGems) {
    final chargeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A10),
        title: Text("شحن ${isGems ? 'جواهر' : 'كوينز'} لـ ${agency.name}"),
        content: _inputField(chargeCtrl, "الكمية", isNumber: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(chargeCtrl.text) ?? 0;
              if (isGems) {
                await _agencyService.chargeAgentBalance(agency.id, amount);
              } else {
                await _agencyService.chargeAgentCoins(agency.id, amount);
              }
              if (mounted) {
                Navigator.pop(ctx);
              }
            },
            child: const Text("شحن الآن"),
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none)),
    );
  }
}
