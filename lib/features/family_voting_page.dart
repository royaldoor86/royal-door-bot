import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_vote_model.dart';

class FamilyVotingPage extends StatefulWidget {
  final String familyId;
  const FamilyVotingPage({super.key, required this.familyId});

  @override
  State<FamilyVotingPage> createState() => _FamilyVotingPageState();
}

class _FamilyVotingPageState extends State<FamilyVotingPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'name_change';
  DateTime? _deadline;
  bool _isLoading = false;

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _createVote() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _familyService.createVote(
        familyId: widget.familyId,
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        deadline: Timestamp.fromDate(_deadline!),
      );

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء التصويت بنجاح ✅')),
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

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedType = 'name_change';
      _deadline = null;
    });
  }

  Future<void> _castVote(String voteId, String vote) async {
    try {
      await _familyService.castVote(voteId, vote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل صوتك ✅')),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('التصويت الديمقراطي',
              style: TextStyle(color: Colors.white)),
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
              // Create Vote Form
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إنشاء تصويت جديد',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'عنوان التصويت',
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
                        labelText: 'وصف التصويت',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'نوع التصويت',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'name_change',
                            child: Text('تغيير اسم العائلة')),
                        DropdownMenuItem(
                            value: 'member_remove', child: Text('طرد عضو')),
                        DropdownMenuItem(
                            value: 'leader_election',
                            child: Text('انتخابات القائد')),
                        DropdownMenuItem(value: 'custom', child: Text('مخصص')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 15),
                    AppTheme.glassContainer(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: () => _selectDeadline(context),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.amber),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _deadline != null
                                    ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                    : 'اختر موعد انتهاء التصويت',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createVote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إنشاء التصويت',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Votes List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_votes')
                      .where('familyId', isEqualTo: widget.familyId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final votes = snapshot.data!.docs;

                    if (votes.isEmpty) {
                      return const Center(
                        child: Text('لا توجد تصويتات حالياً',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: votes.length,
                      itemBuilder: (context, index) {
                        final vote =
                            FamilyVoteModel.fromFirestore(votes[index]);
                        return _buildVoteCard(vote);
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

  Widget _buildVoteCard(FamilyVoteModel vote) {
    final user = FirebaseAuth.instance.currentUser;
    final hasVoted = vote.votes.containsKey(user?.uid);
    final isExpired = vote.deadline.toDate().isBefore(DateTime.now());
    final isCompleted = vote.status == 'completed';

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
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : (isExpired
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.how_to_vote
                      : (isExpired ? Icons.close : Icons.poll),
                  color: isCompleted
                      ? Colors.green
                      : (isExpired ? Colors.red : Colors.amber),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vote.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(vote.description,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _getTypeBadge(vote.type),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text(
                'ينتهي: ${vote.deadline.toDate().day}/${vote.deadline.toDate().month}/${vote.deadline.toDate().year}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 15),
              Icon(Icons.people, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text(
                'الأصوات: ${vote.votes.length}/${vote.requiredVotes}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (!isCompleted && !isExpired && !hasVoted)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _castVote(vote.id, 'yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('موافق',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _castVote(vote.id, 'no'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('معارض',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          if (hasVoted)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  const SizedBox(width: 5),
                  Text('لقد صوتت بالفعل',
                      style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ),
          if (isCompleted && vote.result != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, size: 16, color: Colors.green),
                  const SizedBox(width: 5),
                  Text('النتيجة: ${vote.result}',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    switch (type) {
      case 'name_change':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('تغيير الاسم',
              style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'member_remove':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('طرد عضو',
              style: TextStyle(color: Colors.red, fontSize: 10)),
        );
      case 'leader_election':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('انتخابات',
              style: TextStyle(color: Colors.amber, fontSize: 10)),
        );
      case 'custom':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('مخصص',
              style: TextStyle(color: Colors.purple, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }
}
