import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class FamilyRolesManagementPage extends StatefulWidget {
  final String familyId;
  const FamilyRolesManagementPage({super.key, required this.familyId});

  @override
  State<FamilyRolesManagementPage> createState() =>
      _FamilyRolesManagementPageState();
}

class _FamilyRolesManagementPageState extends State<FamilyRolesManagementPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, String> _roleNames = {
    'leader': 'القائد',
    'co-leader': 'نائب القائد',
    'recruiter': 'المجند',
    'general': 'القائد العام',
    'member': 'عضو',
  };

  final Map<String, List<String>> _rolePermissions = {
    'leader': [
      'create_votes',
      'manage_archive',
      'manage_members',
      'manage_roles',
      'create_events',
      'manage_wars',
      'manage_alliances',
      'manage_settings',
    ],
    'co-leader': [
      'create_votes',
      'manage_archive',
      'manage_members',
      'create_events',
      'manage_wars',
    ],
    'recruiter': [
      'invite_members',
      'manage_requests',
    ],
    'general': [
      'create_votes',
      'manage_archive',
    ],
    'member': [],
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('إدارة الأدوار المتقدمة',
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
                _buildRolesOverview(),
                const SizedBox(height: 20),
                _buildPermissionsMatrix(),
                const SizedBox(height: 20),
                _buildMemberRolesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolesOverview() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نظرة عامة على الأدوار',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ..._roleNames.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getRoleIcon(entry.key),
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_rolePermissions[entry.key]?.length ?? 0} صلاحية',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPermissionsMatrix() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مصفوفة الصلاحيات',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildPermissionRow('إنشاء التصويتات', 'create_votes'),
          _buildPermissionRow('إدارة الأرشيف', 'manage_archive'),
          _buildPermissionRow('إدارة الأعضاء', 'manage_members'),
          _buildPermissionRow('إدارة الأدوار', 'manage_roles'),
          _buildPermissionRow('إنشاء الأحداث', 'create_events'),
          _buildPermissionRow('إدارة الحروب', 'manage_wars'),
          _buildPermissionRow('إدارة التحالفات', 'manage_alliances'),
          _buildPermissionRow('إدارة الإعدادات', 'manage_settings'),
          _buildPermissionRow('دعوة الأعضاء', 'invite_members'),
          _buildPermissionRow('إدارة الطلبات', 'manage_requests'),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(String permissionName, String permissionKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            permissionName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: _roleNames.entries.map((entry) {
              final hasPermission =
                  _rolePermissions[entry.key]?.contains(permissionKey) ?? false;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: hasPermission
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      hasPermission ? Icons.check : Icons.close,
                      color: hasPermission ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRolesList() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('أدوار الأعضاء',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('members')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final members = snapshot.data!.docs;
              if (members.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أعضاء',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  final role = member['role'] ?? 'member';
                  return _buildMemberRoleTile(member, members[index].id, role);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRoleTile(
      Map<String, dynamic> member, String memberId, String currentRole) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRoleIcon(currentRole),
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('users').doc(member['uid']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('جاري التحميل...',
                      style: TextStyle(color: Colors.white38));
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData?['name'] ?? 'بدون اسم',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _roleNames[currentRole] ?? currentRole,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          DropdownButton<String>(
            value: currentRole,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF3D0B16),
            items: _roleNames.entries.map((entry) {
              return DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) async {
              if (value == null) return;
              await _updateMemberRole(memberId, value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberRole(String memberId, String newRole) async {
    try {
      await _db
          .collection('families')
          .doc(widget.familyId)
          .collection('members')
          .doc(memberId)
          .update({'role': newRole});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الدور بنجاح ✅')),
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

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'leader':
        return Icons.emoji_events;
      case 'co-leader':
        return Icons.workspace_premium;
      case 'recruiter':
        return Icons.person_add;
      case 'general':
        return Icons.military_tech;
      default:
        return Icons.person;
    }
  }
}
