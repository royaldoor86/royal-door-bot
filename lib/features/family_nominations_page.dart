import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/family_service.dart';

class FamilyNominationsPage extends StatefulWidget {
  final String familyId;
  const FamilyNominationsPage({super.key, required this.familyId});

  @override
  State<FamilyNominationsPage> createState() => _FamilyNominationsPageState();
}

class _FamilyNominationsPageState extends State<FamilyNominationsPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final memberSnap = await _db
        .collection('families')
        .doc(widget.familyId)
        .collection('members')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        _userRole = memberSnap.data()?['role'] ?? 'member';
      });
    }
  }

  bool _canCreateNomination() {
    return _userRole == 'leader' || _userRole == 'co-leader';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('الترشيحات والمقترحات',
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
                _buildCreateNominationButton(),
                const SizedBox(height: 20),
                _buildActiveNominations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNominationButton() {
    if (!_canCreateNomination()) {
      return const SizedBox.shrink();
    }
    return AppTheme.gradientButton(
      text: 'إنشاء ترشيح جديد 🗳️',
      onPressed: _showCreateNominationDialog,
    );
  }

  Widget _buildActiveNominations() {
    return StreamBuilder<QuerySnapshot>(
      stream: _familyService.streamFamilyNominations(widget.familyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        final nominations = snapshot.data!.docs;
        if (nominations.isEmpty) {
          return const Center(
            child: Text('لا توجد ترشيحات نشطة',
                style: TextStyle(color: Colors.white38)),
          );
        }
        return Column(
          children: [
            const Text('الترشيحات النشطة',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nominations.length,
              itemBuilder: (context, index) {
                final nomination =
                    nominations[index].data() as Map<String, dynamic>;
                return _buildNominationCard(nomination, nominations[index].id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNominationCard(
      Map<String, dynamic> nomination, String nominationId) {
    final type = nomination['type'] ?? 'member';
    final title = nomination['title'] ?? '';
    final description = nomination['description'] ?? '';
    final votes = nomination['votes'] as Map<String, dynamic>? ?? {};
    final voteCount = votes.length;

    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type == 'member' ? Icons.person : Icons.star,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      type == 'member' ? 'ترشيح عضو' : 'اقتراح',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$voteCount صوت',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _voteForNomination(nominationId),
                  icon: const Icon(Icons.thumb_up, size: 18),
                  label: const Text('موافقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _voteAgainstNomination(nominationId),
                  icon: const Icon(Icons.thumb_down, size: 18),
                  label: const Text('رفض'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateNominationDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          title: const Text('إنشاء ترشيح جديد',
              style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      labelStyle: TextStyle(color: Colors.white38),
                    )),
                TextField(
                    controller: descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      labelStyle: TextStyle(color: Colors.white38),
                    )),
                const SizedBox(height: 15),
                const Text('نوع الترشيح:',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF3D0B16),
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    labelStyle: TextStyle(color: Colors.white38),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('ترشيح عضو')),
                    DropdownMenuItem(
                        value: 'suggestion', child: Text('اقتراح')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedType = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال العنوان')),
                  );
                  return;
                }

                try {
                  final currentUser = _auth.currentUser;
                  if (currentUser == null) return;

                  await _familyService.createNomination(
                    familyId: widget.familyId,
                    userId: currentUser.uid,
                    type: selectedType,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إنشاء الترشيح بنجاح ✅')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: $e')),
                    );
                  }
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _voteForNomination(String nominationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _familyService.voteOnNomination(
        nominationId: nominationId,
        userId: currentUser.uid,
        approve: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التصويت بالموافقة 👍')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _voteAgainstNomination(String nominationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _familyService.voteOnNomination(
        nominationId: nominationId,
        userId: currentUser.uid,
        approve: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التصويت بالرفض 👎')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
