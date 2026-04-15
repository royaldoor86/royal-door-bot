import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'battle_setup_sheet.dart';
import 'room_theme_shop_sheet.dart';

class RoomMoreMenuSheet extends StatefulWidget {
  final String roomId;
  final bool hasPower;
  final bool isBattleActive;
  final String micMode;
  final bool noiseReduction;
  final bool eyeComfort;
  final Function(bool) onNoiseReductionChanged;
  final Function(bool) onEyeComfortChanged;
  final VoidCallback onEndBattle;

  const RoomMoreMenuSheet({
    super.key,
    required this.roomId,
    required this.hasPower,
    required this.isBattleActive,
    required this.micMode,
    required this.noiseReduction,
    required this.eyeComfort,
    required this.onNoiseReductionChanged,
    required this.onEyeComfortChanged,
    required this.onEndBattle,
  });

  @override
  State<RoomMoreMenuSheet> createState() => _RoomMoreMenuSheetState();
}

class _RoomMoreMenuSheetState extends State<RoomMoreMenuSheet> {
  late bool _localNoise;
  late bool _localEye;

  @override
  void initState() {
    super.initState();
    _localNoise = widget.noiseReduction;
    _localEye = widget.eyeComfort;
  }

  void _showMicModesMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F26),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text('اختر نمط المايكات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _micModeItem('النمط العادي (5-5)', 'normal'),
            _micModeItem('نمط 2-4-4', '2-4-4'),
            _micModeItem('نمط 1-4-5', '1-4-5'),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _micModeItem(String title, String mode) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: widget.micMode == mode ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({'micMode': mode});
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B25),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickActionItem(Icons.card_giftcard, 'إعدادات الهدايا', Colors.cyan),
                        _quickActionItem(Icons.graphic_eq, 'تقليل الضوضاء', Colors.teal,
                            hasSwitch: true,
                            switchVal: _localNoise,
                            onChanged: (v) {
                              setState(() => _localNoise = v);
                              widget.onNoiseReductionChanged(v);
                            }),
                        _quickActionItem(Icons.mic_none, 'مشكلات الصوت', Colors.cyan),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(left: 10),
                        child: _quickActionItem(Icons.nightlight_round, 'راحة العين', Colors.blue,
                            hasSwitch: true,
                            switchVal: _localEye,
                            onChanged: (v) {
                              setState(() => _localEye = v);
                              widget.onEyeComfortChanged(v);
                            }),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _sectionHeader('إعدادات الغرفة'),
                    const SizedBox(height: 15),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                      children: [
                        _moreMenuItem(Icons.mic, 'نمط المايكات', [Colors.orange, Colors.amber], onTap: () {
                          Navigator.pop(context);
                          _showMicModesMenu();
                        }),
                        _moreMenuItem(
                          widget.isBattleActive ? Icons.flash_off : Icons.flash_on,
                          widget.isBattleActive ? 'إنهاء المعركة' : 'معركة الفريق',
                          widget.isBattleActive ? [Colors.red, Colors.orange] : [Colors.blue, Colors.red],
                          onTap: () {
                            Navigator.pop(context);
                            if (widget.isBattleActive) {
                              widget.onEndBattle();
                            } else {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => BattleSetupSheet(roomId: widget.roomId),
                              );
                            }
                          }
                        ),
                        _moreMenuItem(Icons.brush, 'موضوع', [Colors.brown, Colors.orange], onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => RoomThemeShopSheet(roomId: widget.roomId),
                          );
                        }),
                        _moreMenuItem(Icons.settings, 'الإعدادات', [Colors.purple, Colors.deepPurple]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader('أخرى'),
                    const SizedBox(height: 15),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                      children: [
                        _moreMenuItem(Icons.campaign, 'استدعاء الأعضاء', [Colors.orange, Colors.red]),
                        _moreMenuItem(Icons.thumb_up, 'توصية للأصدقاء', [Colors.purple, Colors.pink]),
                        _moreMenuItem(Icons.shopping_cart, 'المتجر', [Colors.blue, Colors.cyan]),
                        _moreMenuItem(Icons.inventory_2, 'أرباحي', [Colors.red, Colors.orange]),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3B4F).withOpacity(0.8),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
        ),
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
      );

  Widget _quickActionItem(IconData icon, String label, Color color, {bool hasSwitch = false, bool switchVal = false, Function(bool)? onChanged}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5), width: 1)), child: Icon(icon, color: color, size: 28)),
            if (hasSwitch) Positioned(bottom: -15, child: Transform.scale(scale: 0.6, child: Switch(value: switchVal, onChanged: onChanged, activeColor: Colors.green))),
          ]),
          const SizedBox(height: 15),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
        ],
      );

  Widget _moreMenuItem(IconData icon, String label, List<Color> colors, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors), boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 8)]), child: Icon(icon, color: Colors.white, size: 28)),
            const SizedBox(height: 8),
            Flexible(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ],
        ),
      );
}
