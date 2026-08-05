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

class _FamilyAlliancesPageState extends State<FamilyAlliancesPage>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedFamilyId;
  String? _selectedFamilyName;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
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
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
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
                      ),
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
      // الحصول على اسم العائلة
      final familySnap =
          await _db.collection('families').doc(widget.familyId).get();
      final familyName = familySnap.data()?['name'] ?? 'Unknown';

      // إنشاء تحالف جديد
      await _familyService.createAlliance(
        familyId: widget.familyId,
        familyName: familyName,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        allianceType: 'social',
      );

      // إرسال دعوة للعائلة المستهدفة
      final allianceId = await _getLatestAllianceId(widget.familyId);
      if (allianceId != null) {
        await _familyService.sendAllianceInvitation(
          allianceId: allianceId,
          targetFamilyId: _selectedFamilyId!,
          targetFamilyName: _selectedFamilyName ?? 'Unknown',
        );
      }

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إنشاء التحالف وإرسال الدعوة بنجاح ✅'),
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

  Future<String?> _getLatestAllianceId(String familyId) async {
    final snapshot = await _db
        .collection('family_alliances')
        .where('creatorFamilyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
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
      await _familyService.acceptAllianceInvitation(allianceId);
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
      await _familyService.dissolveAlliance(allianceId, widget.familyId);
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
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'التحالفات'),
              Tab(text: 'المهام المشتركة'),
              Tab(text: 'الدعم المتبادل'),
              Tab(text: 'الاتصال المباشر'),
            ],
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAlliancesTab(),
              _buildCollaborativeTasksTab(),
              _buildMutualSupportTab(),
              _buildDirectCommunicationTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlliancesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Propose Alliance Form
          AppTheme.glassContainer(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
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
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_alliances')
                .where('familyId1', isEqualTo: widget.familyId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot1) {
              if (!snapshot1.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
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
                        child: CircularProgressIndicator(color: Colors.amber));
                  }

                  final alliances2 = snapshot2.data!.docs;
                  final allAlliances = [...alliances1, ...alliances2];

                  if (allAlliances.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('لا توجد تحالفات حالياً',
                            style: TextStyle(color: Colors.white38)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
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
                                          ? NetworkImage(alliance.familyLogo1)
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
                                              fontWeight: FontWeight.bold)),
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
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      child: const Text('قبول',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                if (alliance.status == 'active')
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _dissolveAlliance(alliance.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                      ),
                                      child: const Text('فك التحالف',
                                          style:
                                              TextStyle(color: Colors.white)),
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
        ],
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

  // --- تبويب المهام المشتركة ---
  Widget _buildCollaborativeTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.gradientButton(
            text: 'إنشاء مهمة مشتركة جديدة',
            onPressed: () => _showCreateCollaborativeTaskDialog(),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List>(
            stream: _familyService.getFamilyCollaborativeTasks(widget.familyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final tasks = snapshot.data!;
              if (tasks.isEmpty) {
                return const Center(
                  child: Text('لا توجد مهام مشتركة حالياً',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildCollaborativeTaskCard(task);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeTaskCard(dynamic task) {
    final progress = task.currentValue / task.targetValue;
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.status == 'completed'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.status == 'completed' ? 'مكتمل' : 'قيد التنفيذ',
                  style: TextStyle(
                    color: task.status == 'completed'
                        ? Colors.green
                        : Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              color: task.status == 'completed' ? Colors.green : Colors.amber,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% مكتمل',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showCreateCollaborativeTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('إنشاء مهمة مشتركة',
            style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'عنوان المهمة',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'وصف المهمة',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.createCollaborativeTask(
                  familyId: widget.familyId,
                  familyName: '',
                  title: titleController.text,
                  description: descriptionController.text,
                  type: 'points',
                  duration: const Duration(days: 7),
                  requiredParticipants: 5,
                  createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إنشاء المهمة المشتركة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  // --- تبويب الدعم المتبادل ---
  Widget _buildMutualSupportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.gradientButton(
            text: 'طلب دعم من التحالف',
            onPressed: () => _showRequestSupportDialog(),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('alliance_support_requests')
                .where('familyId', isEqualTo: widget.familyId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final requests = snapshot.data!.docs;
              if (requests.isEmpty) {
                return const Center(
                  child: Text('لا توجد طلبات دعم حالياً',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index].data() as Map<String, dynamic>;
                  final reqId = requests[index].id;
                  return _buildSupportRequestCard(req, reqId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportRequestCard(Map<String, dynamic> req, String reqId) {
    final status = req['status'] ?? 'pending';
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req['supportType'] ?? 'بدون نوع',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'pending' ? 'قيد الانتظار' : 'تم القبول',
                  style: TextStyle(
                    color: status == 'pending' ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req['description'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showRequestSupportDialog() {
    final typeController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedAllianceId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('طلب دعم من التحالف',
            style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<QuerySnapshot>(
              future: _db
                  .collection('family_alliances')
                  .where('memberFamilyIds', arrayContains: widget.familyId)
                  .where('status', isEqualTo: 'active')
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(color: Colors.amber);
                }
                final alliances = snapshot.data!.docs;
                if (alliances.isEmpty) {
                  return const Text('لا توجد تحالفات نشطة',
                      style: TextStyle(color: Colors.white38));
                }
                return DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1A050E),
                  initialValue: selectedAllianceId,
                  hint: const Text('اختر التحالف',
                      style: TextStyle(color: Colors.white70)),
                  items: alliances.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? 'بدون اسم',
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedAllianceId = value;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'نوع الدعم',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'وصف الطلب',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedAllianceId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى اختيار التحالف')),
                );
                return;
              }
              try {
                await _familyService.requestAllianceSupport(
                  allianceId: selectedAllianceId!,
                  familyId: widget.familyId,
                  supportType: typeController.text,
                  description: descriptionController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلب الدعم'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  // --- تبويب الاتصال المباشر ---
  Widget _buildDirectCommunicationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.gradientButton(
            text: 'إرسال رسالة للتحالف',
            onPressed: () => _showSendMessageDialog(),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_chat')
                .where('familyId', isEqualTo: widget.familyId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final messages = snapshot.data!.docs;
              if (messages.isEmpty) {
                return const Center(
                  child: Text('لا توجد رسائل حالياً',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index].data() as Map<String, dynamic>;
                  return _buildMessageCard(msg);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> msg) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                msg['senderName'] ?? 'مجهول',
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (msg['timestamp'] != null)
                Text(
                  _formatTimestamp(msg['timestamp']),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            msg['message'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showSendMessageDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('إرسال رسالة للتحالف',
            style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'الرسالة',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.sendEnhancedChatMessage(
                  familyId: widget.familyId,
                  senderId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  senderName: 'أنت',
                  message: messageController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال الرسالة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }
}
