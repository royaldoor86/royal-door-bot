import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyVoteModel {
  final String id;
  final String familyId;
  final String type; // 'name_change', 'member_remove', 'leader_election'
  final String title;
  final String description;
  final Map<String, dynamic>? data;
  final String proposedBy;
  final String? proposedByName;
  final Timestamp createdAt;
  final Timestamp deadline;
  final Map<String, String> votes; // userId: vote ('yes', 'no')
  final String status; // 'active', 'passed', 'rejected', 'cancelled'
  final int requiredVotes;
  final String? result;

  FamilyVoteModel({
    required this.id,
    required this.familyId,
    required this.type,
    required this.title,
    required this.description,
    this.data,
    required this.proposedBy,
    this.proposedByName,
    required this.createdAt,
    required this.deadline,
    required this.votes,
    required this.status,
    required this.requiredVotes,
    this.result,
  });

  factory FamilyVoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyVoteModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: data['data'],
      proposedBy: data['proposedBy'] ?? '',
      proposedByName: data['proposedByName'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      deadline: data['deadline'] ?? Timestamp.now(),
      votes: Map<String, String>.from(data['votes'] ?? {}),
      status: data['status'] ?? 'active',
      requiredVotes: data['requiredVotes'] ?? 0,
      result: data['result'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'proposedBy': proposedBy,
      'proposedByName': proposedByName,
      'createdAt': createdAt,
      'deadline': deadline,
      'votes': votes,
      'status': status,
      'requiredVotes': requiredVotes,
      'result': result,
    };
  }

  int get yesVotes => votes.values.where((v) => v == 'yes').length;
  int get noVotes => votes.values.where((v) => v == 'no').length;
}
