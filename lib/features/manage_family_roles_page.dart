import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class ManageFamilyRolesPage extends StatefulWidget {
  final String familyId;
  const ManageFamilyRolesPage({super.key, required this.familyId});

  @override
  State<ManageFamilyRolesPage> createState() => _ManageFamilyRolesPageState();
}

class _ManageFamilyRolesPageState extends State<ManageFamilyRolesPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Map roles to their Arabic names
  final Map<String, String> _roleNames = {
    'leader': 'رئيس العائلة',
    'co-leader': 'قائد مشارك',
    'organizer': 'نائب',
    'recruiter': 'مسؤول توظيف',
    'member': 'عضو ملكي',
  };
  
  // Define the roles that can be assigned by the leader
  final List<String> _assignableRoles = ['co-leader', 'organizer', 'recruiter', 'member'];

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الأدوار'),
          backgroundColor: const Color(0xFF1A050E),
          elevation: 0,
        ),
        body: Container(
           decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('families').doc(widget.familyId).collection('members').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!.docs;
              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  final String userId = member['uid'];
                  final String currentRole = member['role'];
                  
                  // The leader's role cannot be changed
                  if (currentRole == 'leader') {
                    return _buildMemberTile(userId, currentRole, false);
                  }

                  return _buildMemberTile(userId, currentRole, true);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile(String userId, String role, bool canChangeRole) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(userId).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final userData = userSnap.data!.data() as Map<String, dynamic>;

        return AppTheme.glassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          padding: const EdgeInsets.all(10),
          opacity: 0.05,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: (userData['profilePic'] != null && userData['profilePic']!.isNotEmpty) 
                  ? NetworkImage(userData['profilePic']) 
                  : null,
              child: (userData['profilePic'] == null || userData['profilePic']!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(userData['name'] ?? '', style: const TextStyle(color: Colors.white)),
            trailing: canChangeRole
                ? DropdownButton<String>(
                    value: role,
                    dropdownColor: const Color(0xFF1A050E),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    underline: Container(height: 0),
                    items: _assignableRoles.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(_roleNames[value] ?? value),
                      );
                    }).toList(),
                    onChanged: (newRole) async {
                      if (newRole != null && newRole != role) {
                        try {
                          await _familyService.updateMemberRole(widget.familyId, userId, newRole);
                          _showSuccessSnack('تم تحديث دور ${userData['name']}');
                        } catch (e) {
                          _showErrorSnack(e.toString());
                        }
                      }
                    },
                  )
                : Text(
                    _roleNames[role] ?? role,
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
    );
  }
}
