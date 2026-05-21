import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_challenge_model.dart';

class FamilyChallengesPage extends StatefulWidget {
  final String familyId;
  const FamilyChallengesPage({super.key, required this.familyId});

  @override
  State<FamilyChallengesPage> createState() => _FamilyChallengesPageState();
}

class _FamilyChallengesPageState extends State<FamilyChallengesPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _rewardGemsController = TextEditingController();
  final _rewardStarsController = TextEditingController();
  String _selectedType = 'contribution';
  String _selectedMetric = 'gems';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createChallenge() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final targetValue = int.tryParse(_targetValueController.text) ?? 0;
      final rewardGems = int.tryParse(_rewardGemsController.text) ?? 0;
      final rewardStars = int.tryParse(_rewardStarsController.text) ?? 0;

      await _familyService.createFamilyChallenge(
        familyId: widget.familyId,
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        targetValue: targetValue,
        metric: _selectedMetric,
        startDate: Timestamp.fromDate(_startDate!),
        endDate: Timestamp.fromDate(_endDate!),
        rewardGems: rewardGems,
        rewardStars: rewardStars,
      );

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إنشاء التحدي بنجاح ✅'),
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
    _targetValueController.clear();
    _rewardGemsController.clear();
    _rewardStarsController.clear();
    setState(() {
      _selectedType = 'contribution';
      _selectedMetric = 'gems';
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('التحديات الداخلية',
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
              // Create Challenge Form
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إنشاء تحدي جديد',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم التحدي',
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
                        labelText: 'وصف التحدي',
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
                        labelText: 'نوع التحدي',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'contribution', child: Text('مساهمة')),
                        DropdownMenuItem(
                            value: 'activity', child: Text('نشاط')),
                        DropdownMenuItem(value: 'custom', child: Text('مخصص')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedMetric,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'المقياس',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'gems', child: Text('جواهر 💎')),
                        DropdownMenuItem(value: 'stars', child: Text('نجوم ⭐')),
                        DropdownMenuItem(
                            value: 'activity_minutes',
                            child: Text('دقائق نشاط 🕐')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedMetric = value!),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _targetValueController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الهدف',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rewardGemsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'مكافأة الجواهر',
                              labelStyle:
                                  const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _rewardStarsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'مكافأة النجوم',
                              labelStyle:
                                  const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: AppTheme.glassContainer(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.amber),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _startDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                          : 'تاريخ البدء',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: AppTheme.glassContainer(
                            padding: const EdgeInsets.all(12),
                            child: GestureDetector(
                              onTap: () => _selectDate(context, false),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.amber),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _endDate != null
                                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'تاريخ الانتهاء',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createChallenge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('إنشاء التحدي',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Challenges List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_challenges')
                      .where('familyId', isEqualTo: widget.familyId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final challenges = snapshot.data!.docs;

                    if (challenges.isEmpty) {
                      return const Center(
                        child: Text('لا توجد تحديات حالياً',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: challenges.length,
                      itemBuilder: (context, index) {
                        final challenge = FamilyChallengeModel.fromFirestore(
                            challenges[index]);
                        return _buildChallengeCard(challenge);
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

  Widget _buildChallengeCard(FamilyChallengeModel challenge) {
    final isCompleted = challenge.status == 'completed';
    final isExpired = challenge.endDate.toDate().isBefore(DateTime.now());

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
                      ? Icons.emoji_events
                      : (isExpired ? Icons.close : Icons.flag),
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
                    Text(challenge.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(challenge.description,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _getTypeBadge(challenge.type),
              const SizedBox(width: 10),
              _getMetricBadge(challenge.metric),
              const SizedBox(width: 10),
              Text('الهدف: ${challenge.targetValue}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 10),
              if (challenge.rewardGems > 0)
                Text('${challenge.rewardGems} 💎',
                    style: const TextStyle(color: Colors.cyan, fontSize: 12)),
              if (challenge.rewardStars > 0)
                Text('${challenge.rewardStars} ⭐',
                    style: const TextStyle(color: Colors.amber, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text(
                'ينتهي: ${challenge.endDate.toDate().day}/${challenge.endDate.toDate().month}/${challenge.endDate.toDate().year}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          if (challenge.winnerId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.green),
                  const SizedBox(width: 5),
                  Text('الفائز: ${challenge.winnerName ?? 'غير معروف'}',
                      style:
                          const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    switch (type) {
      case 'contribution':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('مساهمة',
              style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'activity':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('نشاط',
              style: TextStyle(color: Colors.orange, fontSize: 10)),
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

  Widget _getMetricBadge(String metric) {
    switch (metric) {
      case 'gems':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('جواهر',
              style: TextStyle(color: Colors.cyan, fontSize: 10)),
        );
      case 'stars':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('نجوم',
              style: TextStyle(color: Colors.amber, fontSize: 10)),
        );
      case 'activity_minutes':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('دقائق',
              style: TextStyle(color: Colors.green, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }
}
