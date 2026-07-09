import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../widgets/animated_vehicle_preview.dart';

class UserVehiclesPage extends StatefulWidget {
  final String userId;
  const UserVehiclesPage({super.key, required this.userId});

  @override
  State<UserVehiclesPage> createState() => _UserVehiclesPageState();
}

class _UserVehiclesPageState extends State<UserVehiclesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
            'المركبات الملكية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('users')
              .doc(widget.userId)
              .collection('inventory')
              .where('type', isEqualTo: 'vehicle')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لا توجد مركبات ملكية مملوكة حالياً',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'قم بزيارة المتجر للحصول على مركبات فاخرة',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            final vehicles = snapshot.data!.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildVehicleCard(vehicle);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    final String name = vehicle['name'] ?? 'مركبة ملكية';
    final String imageUrl = vehicle['imageUrl'] ?? '';
    final String vehicleType = vehicle['vehicleType'] ?? 'gif';
    final bool isActive = vehicle['isActive'] ?? false;

    return GestureDetector(
      onTap: () => _showVehicleDetails(name, vehicle),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.royalGold.withValues(alpha: 0.5)
                : Colors.amber.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.royalGold.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(19),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: imageUrl.isNotEmpty
                          ? AnimatedVehiclePreview(
                              url: imageUrl,
                              type: vehicleType,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.directions_car,
                              size: 60,
                              color: Colors.white24,
                            ),
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.royalGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'نشط',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleType.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDetails(String name, Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  vehicle['imageUrl'] != null && vehicle['imageUrl'].isNotEmpty
                      ? AnimatedVehiclePreview(
                          url: vehicle['imageUrl'],
                          type: vehicle['vehicleType'] ?? 'gif',
                          fit: BoxFit.contain,
                        )
                      : const Icon(
                          Icons.directions_car,
                          size: 80,
                          color: Colors.white24,
                        ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'مركبة ملكية فاخرة تمنح صاحبها هيبة ومكانة عالية داخل المملكة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            if (widget.userId == FirebaseAuth.instance.currentUser?.uid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _activateVehicle(vehicle);
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: Text(
                    vehicle['isActive'] ?? false
                        ? 'إلغاء التفعيل'
                        : 'تفعيل المركبة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.royalGold,
                    minimumSize: const Size(double.infinity, 55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _activateVehicle(Map<String, dynamic> vehicle) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Deactivate all vehicles first
      final inventorySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .where('type', isEqualTo: 'vehicle')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in inventorySnap.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Activate the selected vehicle
      final vehicleRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('inventory')
          .doc(vehicle['id'] ?? vehicle['name']);

      batch.update(vehicleRef, {'isActive': !(vehicle['isActive'] ?? false)});

      // Also update user's active vehicle
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      if (!(vehicle['isActive'] ?? false)) {
        batch.update(userRef, {
          'activeVehicleUrl': vehicle['imageUrl'],
          'activeVehicleType': vehicle['vehicleType'],
        });
      } else {
        batch.update(userRef, {
          'activeVehicleUrl': FieldValue.delete(),
          'activeVehicleType': FieldValue.delete(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vehicle['isActive'] ?? false
                  ? 'تم إلغاء تفعيل المركبة'
                  : 'تم تفعيل المركبة بنجاح 🚗',
            ),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تفعيل المركبة: $e')),
        );
      }
    }
  }
}
