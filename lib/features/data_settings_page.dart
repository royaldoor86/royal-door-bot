import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../app_theme.dart';
import '../theme/reusable_widgets.dart';

class DataSettingsPage extends StatefulWidget {
  const DataSettingsPage({super.key});

  @override
  State<DataSettingsPage> createState() => _DataSettingsPageState();
}

class _DataSettingsPageState extends State<DataSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إعدادات البيانات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // تصدير البيانات
              _buildSectionHeader('تصدير البيانات'),
              _buildActionCard(
                icon: Icons.download,
                title: 'تصدير بياناتي',
                subtitle: 'تحميل نسخة من جميع بياناتك بتنسيق JSON',
                color: Colors.blue,
                onTap: _exportData,
              ),
              const SizedBox(height: 30),

              // حذف البيانات
              _buildSectionHeader('حذف البيانات'),
              _buildActionCard(
                icon: Icons.delete_forever,
                title: 'حذف جميع البيانات',
                subtitle: 'حذف جميع بياناتك من التطبيق (GDPR)',
                color: Colors.red,
                onTap: _deleteAllData,
              ),
              const SizedBox(height: 30),

              // النسخ الاحتياطي
              _buildSectionHeader('النسخ الاحتياطي'),
              _buildActionCard(
                icon: Icons.cloud_upload,
                title: 'إنشاء نسخة احتياطية',
                subtitle: 'حفظ نسخة احتياطية من بياناتك على السحابة',
                color: Colors.green,
                onTap: _createBackup,
              ),
              _buildActionCard(
                icon: Icons.cloud_download,
                title: 'استعادة النسخة الاحتياطية',
                subtitle: 'استعادة بياناتك من النسخة الاحتياطية',
                color: Colors.orange,
                onTap: _restoreBackup,
              ),
              const SizedBox(height: 30),

              // معلومات إضافية
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'معلومات مهمة',
                content:
                    'تصدير البيانات لا يحذفها من السيرفر. حذف البيانات نهائي ولا يمكن التراجع عنه.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.royalGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await _db.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) throw Exception('بيانات المستخدم غير موجودة');

      final userData = userDoc.data() as Map<String, dynamic>;

      // معالجة البيانات لتحويل الـ Timestamps إلى نصوص قابلة للتحويل لـ JSON
      final Map<String, dynamic> exportedData = _prepareDataForExport(userData);
      exportedData['exportTimestamp'] = DateTime.now().toIso8601String();

      final jsonData = const JsonEncoder.withIndent('  ').convert(exportedData);

      // حفظ في ملف مؤقت ومشاركته
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/royaldoor_user_data.json');
      await file.writeAsString(jsonData);

      if (mounted) {
        HapticFeedback.mediumImpact();
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'نسخة من بياناتي الشخصية من تطبيق رويال دور 👑',
          subject: 'تصدير بيانات رويال دور',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تصدير البيانات بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير البيانات: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _prepareDataForExport(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _prepareDataForExport(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map<String, dynamic>) return _prepareDataForExport(item);
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _deleteAllData() async {
    showDialog(
      context: context,
      builder: (context) => RoyalConfirmDialog(
        title: 'حذف جميع البيانات',
        message:
            'هل أنت متأكد من حذف جميع بياناتك؟\n\nهذا الإجراء لا يمكن التراجع عنه وسيتم حذف:\n- بروفايلك\n- إشعاراتك\n- جميع بياناتك الأخرى',
        confirmLabel: 'حذف الكل',
        cancelLabel: 'إلغاء',
        icon: Icons.warning_rounded,
        iconColor: Colors.red,
        onConfirm: () async {
          setState(() => _isLoading = true);
          try {
            // حذف بيانات المستخدم من Firestore
            await _db.collection('users').doc(_currentUserId).delete();

            // حذف الإشعارات
            final notifications = await _db
                .collection('users')
                .doc(_currentUserId)
                .collection('notifications')
                .get();
            for (var doc in notifications.docs) {
              await doc.reference.delete();
            }

            if (mounted) {
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف جميع البيانات بنجاح'),
                  backgroundColor: AppTheme.royalGold,
                ),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('فشل حذف البيانات: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await _db.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = userDoc.data() as Map<String, dynamic>;

      // إضافة timestamp للنسخة الاحتياطية
      userData['backupTimestamp'] = DateTime.now().toIso8601String();

      await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .add(userData);

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء النسخة الاحتياطية بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    setState(() => _isLoading = true);
    try {
      final backups = await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('backups')
          .orderBy('backupTimestamp', descending: true)
          .limit(1)
          .get();

      if (backups.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد نسخ احتياطية')),
          );
        }
        return;
      }

      final backupData = backups.docs.first.data();
      backupData.remove('backupTimestamp');

      await _db.collection('users').doc(_currentUserId).set(backupData);

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استعادة النسخة الاحتياطية بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل استعادة النسخة الاحتياطية: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
