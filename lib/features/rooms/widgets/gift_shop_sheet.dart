import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../app_theme.dart';
import '../../../services/challenges_service.dart';
import '../../../models/family_model.dart';

class GiftShopSheet extends StatefulWidget {
  final String roomId;
  const GiftShopSheet({super.key, required this.roomId});

  @override
  State<GiftShopSheet> createState() => _GiftShopSheetState();
}

class _GiftShopSheetState extends State<GiftShopSheet> {
  int _selectedGiftIndex = -1;
  List<DocumentSnapshot>? _gifts;
  final TextEditingController _countController =
      TextEditingController(text: "1");
  int _giftCount = 1;
  String? _selectedReceiverId;
  String? _selectedReceiverName;
  Map<String, int> _userSeats = {};
  StreamSubscription? _seatsSub;

  final List<String> _tabs = ['رويال', 'نادي الأعضاء', 'النشاط', 'كلاسيكي'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenToSeats();
    _countController.addListener(() {
      final val = int.tryParse(_countController.text) ?? 1;
      if (val != _giftCount) {
        setState(() => _giftCount = val > 0 ? val : 1);
      }
    });
  }

  @override
  void dispose() {
    _seatsSub?.cancel();
    _countController.dispose();
    super.dispose();
  }

  void _listenToSeats() {
    _seatsSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .snapshots()
        .listen((snap) {
      Map<String, int> seats = {};
      for (var doc in snap.docs) {
        final data = doc.data();
        seats[data['userId']] = int.tryParse(doc.id) ?? 0;
      }
      if (mounted) setState(() => _userSeats = seats);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final int stars =
                    (data?['stars'] ?? data?['coins'] ?? 0).toInt();
                final int gems = (data?['gems'] ?? 0).toInt();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("إرسال هدية ملكية 🎁",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Row(
                        children: [
                          _buildBalanceItem(
                              '$gems', Icons.diamond, Colors.cyan),
                          const SizedBox(width: 12),
                          _buildBalanceItem(
                              '$stars', Icons.stars_rounded, Colors.amber),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          _buildTabsHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gifts')
                  .where('showInStore', isEqualTo: true)
                  .where('category', isEqualTo: _tabs[_selectedTabIndex])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.royalGold));
                }

                final gifts = snapshot.data?.docs ?? [];
                _gifts = gifts;

                if (gifts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard,
                            color: Colors.white10, size: 60),
                        const SizedBox(height: 10),
                        Text(
                            'لا توجد هدايا في قسم ${_tabs[_selectedTabIndex]} حالياً',
                            style: const TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: gifts.length,
                  itemBuilder: (context, index) =>
                      _buildGiftItemFirestore(index, gifts[index]),
                );
              },
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildTabsHeader() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedTabIndex = index;
              _selectedGiftIndex = -1;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.royalGold.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? AppTheme.royalGold : Colors.white10),
              ),
              child: Center(
                child: Text(_tabs[index],
                    style: TextStyle(
                        color: isSelected ? AppTheme.royalGold : Colors.white38,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceItem(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(width: 5),
          Icon(icon, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _buildGiftItemFirestore(int index, DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final String name = d['name'] ?? '';
    final String imageUrl = d['imageUrl'] ?? '';
    final int price = d['price'] ?? 0;
    final String currencyType = d['currencyType'] ?? 'gems';
    bool isSelected = index == _selectedGiftIndex;

    return GestureDetector(
      onTap: () => setState(() => _selectedGiftIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isSelected ? AppTheme.royalGold : Colors.transparent,
              width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.royalGold.withValues(alpha: 0.1),
                      blurRadius: 10)
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (c, u) => const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1))),
                    errorWidget: (c, u, e) => const Icon(Icons.card_giftcard,
                        color: Colors.amber, size: 30)),
              ),
            ),
            const SizedBox(height: 4),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('$price',
                  style: TextStyle(
                      color: isSelected ? AppTheme.royalGold : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 3),
              Text(currencyType == 'gems' ? '💎' : '⭐',
                  style: const TextStyle(fontSize: 9)),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF0A121A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('online_users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final members = snapshot.data?.docs ?? [];
                    if (members.isNotEmpty && _selectedReceiverId == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedReceiverId == null) {
                          setState(() {
                            _selectedReceiverId = members.first.id;
                            _selectedReceiverName = (members.first.data()
                                    as Map<String, dynamic>?)?['name'] ??
                                'مستخدم';
                          });
                        }
                      });
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15)),
                      child: DropdownButton<String>(
                        value: _selectedReceiverId,
                        dropdownColor: const Color(0xFF0A121A),
                        isExpanded: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                        icon: const Icon(Icons.keyboard_arrow_up,
                            color: AppTheme.royalGold, size: 20),
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem<String>(
                              value: 'all',
                              child: Text('الكل في الروم',
                                  style: TextStyle(
                                      color: AppTheme.royalGold,
                                      fontWeight: FontWeight.bold))),
                          ...members.map((doc) => DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text((doc.data()
                                      as Map<String, dynamic>?)?['name'] ??
                                  'مستخدم')))
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedReceiverId = val;
                              _selectedReceiverName = (val == 'all')
                                  ? 'الكل'
                                  : (members
                                              .firstWhere((m) => m.id == val)
                                              .data()
                                          as Map<String, dynamic>?)?['name'] ??
                                      'مستخدم';
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            color: Colors.white54, size: 16),
                        onPressed: () {
                          if (_giftCount > 1) {
                            setState(() {
                              _giftCount--;
                              _countController.text = _giftCount.toString();
                            });
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.royalGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white54, size: 16),
                        onPressed: () {
                          setState(() {
                            _giftCount++;
                            _countController.text = _giftCount.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: (_gifts == null ||
                    _selectedGiftIndex == -1 ||
                    _selectedReceiverId == null)
                ? null
                : () => _sendGift(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: (_selectedGiftIndex != -1)
                    ? AppTheme.royalGold
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: (_selectedGiftIndex != -1)
                    ? [
                        BoxShadow(
                            color: AppTheme.royalGold.withValues(alpha: 0.3),
                            blurRadius: 10)
                      ]
                    : [],
              ),
              child: Center(
                child: Text("إرسال الهدايا (x$_giftCount)",
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGift(BuildContext context) async {
    if (_gifts == null ||
        _selectedGiftIndex == -1 ||
        _selectedReceiverId == null) {
      return;
    }

    // التحقق من قفل صندوق الهدايا
    final systemDoc = await FirebaseFirestore.instance
        .collection('system_settings')
        .doc('global')
        .get();
    if (systemDoc.exists) {
      final data = systemDoc.data()!;
      if (data['isGiftBoxLocked'] == true) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final userData = userDoc.data() ?? {};
          final String role = userData['role'] ?? 'user';
          final bool isAdmin = userData['isAdmin'] ?? false;
          if (!isAdmin &&
              !['admin', 'owner', 'developer', 'staff'].contains(role)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('عذراً، نظام الهدايا قيد الصيانة الملكية حالياً 👑'),
                backgroundColor: Colors.orange,
              ));
            }
            return;
          }
        }
      }
    }

    final selectedGift = _gifts![_selectedGiftIndex];
    final giftData = selectedGift.data() as Map<String, dynamic>;
    final String currencyType = giftData['currencyType'] ?? 'gems';
    final int price = (giftData['price'] ?? 0).toInt();
    final int totalCost = price * _giftCount;
    final String? soundUrl = giftData['soundUrl'];

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
        final roomRef =
            FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

        // 1. All Reads First
        final userSnap = await transaction.get(userRef);
        final roomSnap = await transaction.get(roomRef);

        if (!userSnap.exists) throw "User doc not found";
        if (!roomSnap.exists) throw "Room doc not found";

        final userData = userSnap.data() as Map<String, dynamic>;
        final String? familyId = userData['familyId'];

        DocumentSnapshot? familySnap;
        if (familyId != null && familyId.isNotEmpty) {
          familySnap = await transaction.get(
              FirebaseFirestore.instance.collection('families').doc(familyId));
        }

        DocumentSnapshot? warSnap;
        if (familySnap != null && familySnap.exists) {
          final familyData = familySnap.data() as Map<String, dynamic>?;
          final String? currentWarId = familyData?['currentWarId'];
          if (currentWarId != null && currentWarId.isNotEmpty) {
            warSnap = await transaction.get(FirebaseFirestore.instance
                .collection('family_wars')
                .doc(currentWarId));
          }
        }

        // 2. Logic
        final int userGems = (userData['gems'] ?? 0).toInt();
        final int userStars =
            (userData['stars'] ?? userData['coins'] ?? 0).toInt();
        final String senderName = userData['name'] ?? 'مستخدم ملكي';

        if (currencyType == 'gems') {
          if (userGems < totalCost) throw "رصيد الجواهر غير كافٍ";
          transaction.update(userRef, {
            'gems': FieldValue.increment(-totalCost),
          });
        } else {
          if (userStars < totalCost) throw "رصيد النجوم غير كافٍ";
          transaction.update(userRef, {
            'stars': FieldValue.increment(-totalCost),
            'coins': FieldValue.increment(-totalCost), // Keep in sync
          });
        }

        // 3. Writes
        transaction
            .set(FirebaseFirestore.instance.collection('sent_gifts').doc(), {
          'giftId': selectedGift.id,
          'giftName': giftData['name'],
          'giftImage': giftData['imageUrl'],
          'receiverId': _selectedReceiverId,
          'receiverName': _selectedReceiverName,
          'count': _giftCount,
          'sentAt': FieldValue.serverTimestamp(),
          'senderId': currentUser.uid,
          'senderName': senderName,
          'currencyType': currencyType,
          'totalCost': totalCost,
          'roomId': widget.roomId,
        });

        final giftImageUrl = (giftData['imageUrl'] as String?) ?? '';
        final giftVideoUrl = (giftData['videoUrl'] as String?) ??
            (giftData['giftVideoUrl'] as String?) ??
            '';
        final giftType = (giftData['giftType'] as String?) ??
            (giftVideoUrl.isNotEmpty
                ? 'video'
                : (giftImageUrl.toLowerCase().endsWith('.gif')
                    ? 'gif'
                    : 'image'));

        transaction.set(roomRef.collection('gift_events').doc(), {
          'giftName': giftData['name'],
          'giftImageUrl': giftImageUrl,
          'giftVideoUrl': giftVideoUrl,
          'senderName': senderName,
          'receiverName': _selectedReceiverName,
          'count': _giftCount,
          'timestamp': FieldValue.serverTimestamp(),
          'giftType': giftType,
          'soundUrl': soundUrl,
        });

        // --- تحديث خبرة العائلة وحروب العائلات ---
        if (familySnap != null && familySnap.exists) {
          final familyData = familySnap.data() as Map<String, dynamic>;
          int currentTotalExp =
              (familyData['totalExp'] ?? familyData['totalPoints'] ?? 0);
          int newTotalExp = currentTotalExp + totalCost;
          int currentLevel = (familyData['level'] ?? 1);
          int nextLevelExp = currentLevel * currentLevel * 10000;

          Map<String, dynamic> familyUpdates = {
            'totalExp': newTotalExp,
            'totalPoints': newTotalExp
          };
          if (newTotalExp >= nextLevelExp) {
            currentLevel++;
            familyUpdates['level'] = currentLevel;
            familyUpdates['maxMembers'] =
                FamilyModel.calculateMaxMembers(currentLevel);
          }
          transaction.update(familySnap.reference, familyUpdates);

          final memberRef =
              familySnap.reference.collection('members').doc(currentUser.uid);
          // استخدم set مع merge لتفادي خطأ not-found في حال عدم وجود وثيقة العضو
          transaction.set(
              memberRef,
              {'totalContribution': FieldValue.increment(totalCost)},
              SetOptions(merge: true));

          if (warSnap != null && warSnap.exists) {
            final warData = warSnap.data() as Map<String, dynamic>?;
            if (warData?['status'] == 'active') {
              String field = (warData?['challengerId'] == familyId)
                  ? 'challengerExp'
                  : 'targetExp';
              transaction.update(warSnap.reference, {
                field: FieldValue.increment(totalCost),
                field.replaceAll('Exp', 'Points'):
                    FieldValue.increment(totalCost)
              });
            }
          }
        }

        // --- تحديث نقاط المعركة (PK) ---
        if (roomSnap.exists) {
          final roomData = roomSnap.data() as Map<String, dynamic>;
          final battle = roomData['battle'] as Map<String, dynamic>?;

          if (battle != null && battle['active'] == true) {
            String mode = battle['mode'] ?? 'team';
            String? team;

            if (mode == 'individual') {
              if (_selectedReceiverId == battle['redId']) {
                team = 'red';
              } else if (_selectedReceiverId == battle['blueId']) {
                team = 'blue';
              }
            } else {
              if (_selectedReceiverId == 'all') {
                int redOnMic = 0;
                int blueOnMic = 0;
                _userSeats.forEach((uid, seat) {
                  if (seat % 2 != 0) {
                    redOnMic++;
                  } else {
                    blueOnMic++;
                  }
                });

                if (redOnMic > 0) {
                  transaction.update(roomRef, {
                    'battle.redPoints': FieldValue.increment(totalCost),
                    'battle.redStars':
                        FieldValue.increment(totalCost), // Modern sync
                    'battle.redPool': FieldValue.increment(totalCost)
                  });
                }
                if (blueOnMic > 0) {
                  transaction.update(roomRef, {
                    'battle.bluePoints': FieldValue.increment(totalCost),
                    'battle.blueStars':
                        FieldValue.increment(totalCost), // Modern sync
                    'battle.bluePool': FieldValue.increment(totalCost)
                  });
                }
              } else {
                int? receiverSeat = _userSeats[_selectedReceiverId];
                if (receiverSeat != null) {
                  team = (receiverSeat % 2 != 0) ? 'red' : 'blue';
                }
              }
            }

            if (team != null) {
              transaction.update(roomRef, {
                'battle.${team}Points': FieldValue.increment(totalCost),
                'battle.${team}Stars':
                    FieldValue.increment(totalCost), // Modern sync
                'battle.${team}Pool': FieldValue.increment(totalCost),
              });
            }
          }

          // --- تحديث خبرة الغرفة ---
          int currentExp = roomData['exp'] ?? roomData['points'] ?? 0;
          int currentLevel = roomData['level'] ?? 1;
          int pointsToAdd = (_giftCount >= 5) ? 30 : (5 * _giftCount);
          int newExp = currentExp + pointsToAdd;
          int nextLevelThreshold = currentLevel * 10000;

          if (newExp >= nextLevelThreshold) {
            transaction.update(roomRef, {
              'exp': newExp - nextLevelThreshold,
              'points': newExp - nextLevelThreshold,
              'level': currentLevel + 1,
            });
          } else {
            transaction.update(roomRef, {
              'exp': newExp,
              'points': newExp,
            });
          }
        }

        // تحديث الإعلان العالمي
        transaction.set(
            FirebaseFirestore.instance.collection('global_announcements').doc(),
            {
              'senderName': senderName,
              'giftName': giftData['name'],
              'receiverName': _selectedReceiverName ?? 'الجميع',
              'roomId': widget.roomId,
              'roomName': (roomSnap.data())?['name'] ?? 'غرفة ملكية',
              'timestamp': FieldValue.serverTimestamp(),
            });
      });

      // ربط التحديات اليومية (تحديث تقدم تحدي إرسال الهدايا)
      await ChallengesService.updateProgress(ChallengesService.typeGift,
          increment: _giftCount);

      HapticFeedback.heavyImpact(); // اهتزاز قوي ملكي عند نجاح إرسال الهدية

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('فشل الإرسال: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }
}
