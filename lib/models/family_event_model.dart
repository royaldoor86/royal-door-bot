import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyEventModel {
  final String id;
  final String familyId;
  final String title;
  final String description;
  final Timestamp startTime;
  final Timestamp endTime;
  final Map<String, dynamic> rewards;
  final List<String> participants;

  FamilyEventModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.rewards = const {},
    this.participants = const [],
  });

  factory FamilyEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyEventModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      rewards: data['rewards'] ?? {},
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'rewards': rewards,
      'participants': participants,
    };
  }
}
