import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_invitation_model.dart';

class FamilyInvitationPage extends StatefulWidget {
  final String familyId;
  const FamilyInvitationPage({super.key, required this.familyId});

  @override
  State<FamilyInvitationPage> createState() => _FamilyInvitationPageState();
}

class _FamilyInvitationPageState extends State<FamilyInvitationPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _invitationCode;
  String? _invitationLink;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingInvitation();
  }

  Future<void> _loadExistingInvitation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('family_invitations')
        .where('familyId', isEqualTo: widget.familyId)
        .where('createdBy', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _invitationCode = snapshot.docs.first.id;
        _invitationLink = snapshot.docs.first.data()['link'];
      });
    }
  }

  Future<void> _createInvitation() async {
    setState(() => _isLoading = true);

    try {
      final code = await _familyService.createFamilyInvitation(widget.familyId);
      final link = 'https://royaldoor.app/invite/$code';
      setState(() {
        _invitationCode = code;
        _invitationLink = link;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الدعوة بنجاح ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyCode() async {
    if (_invitationCode == null) return;

    await Clipboard.setData(ClipboardData(text: _invitationCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الكود 📋')),
      );
    }
  }

  Future<void> _copyLink() async {
    if (_invitationLink == null) return;

    await Clipboard.setData(ClipboardData(text: _invitationLink!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ الرابط 🔗')),
      );
    }
  }

  Future<void> _shareInvitation() async {
    if (_invitationLink == null) return;

    try {
      await Share.share(
        'انضم إلى عائلتي الملكية! 🏰\n\nاستخدم كود الدعوة: $_invitationCode\n\nأو انقر على الرابط: $_invitationLink',
        subject: 'دعوة للانضمام إلى عائلة ملكية',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في المشاركة: $e')),
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
          title: const Text('دعوات العائلة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                // Create Invitation Section
                AppTheme.glassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إنشاء دعوة جديدة',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      if (_invitationCode != null) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            children: [
                              const Text('كود الدعوة الخاص بك:',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(
                                _invitationCode!,
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _copyCode,
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: const Text('نسخ الكود'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _shareInvitation,
                                      icon: const Icon(Icons.share, size: 18),
                                      label: const Text('مشاركة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 10),
                              const Text('رابط الدعوة:',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(
                                _invitationLink!,
                                style: const TextStyle(
                                    color: Colors.cyanAccent, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _copyLink,
                                      icon: const Icon(Icons.link, size: 18),
                                      label: const Text('نسخ الرابط'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _createInvitation,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text('إنشاء جديد'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.amber),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    'مكافأة: 2 جوهرة 💎 لكل دعوة ناجحة تضاف لخزينة العائلة',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createInvitation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : const Text('إنشاء دعوة',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Invitations History
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_invitations')
                      .where('familyId', isEqualTo: widget.familyId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final invitations = snapshot.data!.docs;

                    if (invitations.isEmpty) {
                      return const Center(
                        child: Text('لا توجد دعوات حالياً',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return Column(
                      children: [
                        const Text('سجل الدعوات',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invitations.length,
                          itemBuilder: (context, index) {
                            final invitation =
                                FamilyInvitationModel.fromFirestore(
                                    invitations[index]);
                            return _buildInvitationCard(invitation);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(FamilyInvitationModel invitation) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: invitation.isActive
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              invitation.isActive ? Icons.mail : Icons.close,
              color: invitation.isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كود: ${invitation.inviteCode.substring(0, 8)}...',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text('الدعوات المقبولة: ${invitation.acceptedInvites}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                Text('تم الإنشاء: ${_formatDate(invitation.createdAt)}',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _getStatusBadge(invitation.isActive),
        ],
      ),
    );
  }

  Widget _getStatusBadge(bool isActive) {
    if (isActive) {
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
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: const Text('منتهي',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
