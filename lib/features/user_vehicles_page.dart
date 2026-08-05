import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../widgets/animated_vehicle_preview.dart';
import '../../services/custom_car_service.dart';
import '../../services/privilege_service.dart';

class UserVehiclesPage extends StatefulWidget {
  final String userId;
  const UserVehiclesPage({super.key, required this.userId});

  @override
  State<UserVehiclesPage> createState() => _UserVehiclesPageState();
}

class _UserVehiclesPageState extends State<UserVehiclesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _availableCustomCars = [];
  List<Map<String, dynamic>> _purchasedCars = [];
  Map<String, dynamic>? _activeCustomCar;
  bool _hasCustomCarPrivilege = false;

  @override
  void initState() {
    super.initState();
    _loadCustomCarData();
  }

  Future<void> _loadCustomCarData() async {
    try {
      final userId = widget.userId;
      final hasPrivilege =
          await PrivilegeService.hasPrivilege(userId, 'custom_car');
      final availableVipCars =
          await CustomCarService.getAvailableVipCars(userId);
      final purchasedCars = await CustomCarService.getPurchasedCars(userId);
      final activeCar = await CustomCarService.getActiveCar(userId);

      if (mounted) {
        setState(() {
          _hasCustomCarPrivilege = hasPrivilege;
          _availableCustomCars = availableVipCars;
          _purchasedCars = purchasedCars;
          _activeCustomCar = activeCar;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom car data: $e');
    }
  }

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
        body: Column(
          children: [
            // قسم المركبات المخصصة VIP
            if (_hasCustomCarPrivilege) _buildCustomCarsSection(),
            // قسم المركبات المشتراة من المتجر
            if (_purchasedCars.isNotEmpty) _buildPurchasedCarsSection(),
            // قسم المركبات من المخزون
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('users')
                    .doc(widget.userId)
                    .collection('inventory')
                    .where('type', isEqualTo: 'vehicle')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.royalGold),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCarsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.royalGold.withValues(alpha: 0.1),
            AppTheme.royalGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.royalGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.royalGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المركبات المخصصة VIP',
                      style: TextStyle(
                        color: AppTheme.royalGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ميزة حصرية للمستوى 19+',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_availableCustomCars.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد مركبات متاحة لمستواك حالياً',
                  style: TextStyle(color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _availableCustomCars.length,
                itemBuilder: (context, index) {
                  final car = _availableCustomCars[index];
                  final isActive = _activeCustomCar?['type'] == car['type'];
                  return GestureDetector(
                    onTap: () => _showCustomCarDetails(car),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.royalGold.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.royalGold
                              : Colors.white.withValues(alpha: 0.1),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: isActive
                                ? AppTheme.royalGold
                                : Colors.white.withValues(alpha: 0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            car['name'] ?? '',
                            style: TextStyle(
                              color:
                                  isActive ? AppTheme.royalGold : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isActive)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'نشط',
                                style: TextStyle(
                                  color: AppTheme.royalGold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showCustomCarDetails(Map<String, dynamic> car) {
    final isActive = _activeCustomCar?['type'] == car['type'];
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
            const Icon(
              Icons.directions_car,
              size: 80,
              color: AppTheme.royalGold,
            ),
            const SizedBox(height: 20),
            Text(
              car['name'] ?? 'مركبة مخصصة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'مركبة ملكية مخصصة حصرية للمستويات الملكية العالية. تمنحك هيبة ومكانة استثنائية.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  if (isActive) {
                    await CustomCarService.removeCustomCar(widget.userId);
                  } else {
                    await CustomCarService.setCustomCar(
                      widget.userId,
                      car['type']!,
                      car['url']!,
                    );
                  }
                  await _loadCustomCarData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isActive
                              ? 'تم إلغاء تفعيل المركبة'
                              : 'تم تفعيل المركبة بنجاح 🚗',
                        ),
                        backgroundColor: AppTheme.royalGold,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isActive ? Icons.close : Icons.check_circle,
                  color: Colors.white,
                ),
                label: Text(
                  isActive ? 'إلغاء التفعيل' : 'تفعيل المركبة',
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

  Widget _buildPurchasedCarsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المركبات المشتراة',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'من المتجر الملكي',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _purchasedCars.length,
              itemBuilder: (context, index) {
                final car = _purchasedCars[index];
                final isActive =
                    _activeCustomCar?['activeVehicleId'] == car['id'];
                return GestureDetector(
                  onTap: () => _showPurchasedCarDetails(car),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.blue
                            : Colors.white.withValues(alpha: 0.1),
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: isActive
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.5),
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          car['name'] ?? 'مركبة',
                          style: TextStyle(
                            color: isActive ? Colors.blue : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'نشط',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchasedCarDetails(Map<String, dynamic> car) {
    final isActive = _activeCustomCar?['activeVehicleId'] == car['id'];
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
            const Icon(
              Icons.directions_car,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              car['name'] ?? 'مركبة مشتراة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'مركبة ملكية مشتراة من المتجر. تمنحك هيبة ومكانة استثنائية.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  if (isActive) {
                    await CustomCarService.removeCustomCar(widget.userId);
                  } else {
                    await CustomCarService.setPurchasedCar(
                      widget.userId,
                      car['id']!,
                      car['imageUrl'] ?? '',
                      car['vehicleType'] ?? 'gif',
                    );
                  }
                  await _loadCustomCarData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isActive
                              ? 'تم إلغاء تفعيل المركبة'
                              : 'تم تفعيل المركبة بنجاح 🚗',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                },
                icon: Icon(
                  isActive ? Icons.close : Icons.check_circle,
                  color: Colors.white,
                ),
                label: Text(
                  isActive ? 'إلغاء التفعيل' : 'تفعيل المركبة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
