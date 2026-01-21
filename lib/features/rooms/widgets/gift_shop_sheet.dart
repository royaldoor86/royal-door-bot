import 'package:flutter/material.dart';

class GiftShopSheet extends StatefulWidget {
  const GiftShopSheet({super.key});

  @override
  State<GiftShopSheet> createState() => _GiftShopSheetState();
}

class _GiftShopSheetState extends State<GiftShopSheet> {
  int _selectedGiftIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => _buildGiftItem(index),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.backpack, color: Colors.blue, size: 24),
          ),
          const Spacer(),
          _buildTab("روي", false),
          _buildTab("نادي الأعضاء", false),
          _buildTab("النشاط", false),
          _buildTab("كلاسيكي", true),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          if (isSelected) const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
        ],
      ),
    );
  }

  Widget _buildGiftItem(int index) {
    final gifts = [
      {'name': 'طوبة', 'price': '9', 'type': '💎', 'new': false},
      {'name': 'ملك الفهد', 'price': '8999', 'type': '💎', 'new': true},
      {'name': 'كاروسيل صغيرة', 'price': '99', 'type': '💎', 'new': true},
      {'name': 'بالون', 'price': '1000', 'type': '🟡', 'new': false},
      {'name': 'تهانينا!', 'price': '999', 'type': '💎', 'new': false},
      {'name': 'هدية مفاجئة', 'price': '399', 'type': '💎', 'new': false},
      {'name': 'شرب الشاي', 'price': '399', 'type': '💎', 'new': false},
      {'name': 'رحلة ليلية حض.', 'price': '5999', 'type': '💎', 'new': false},
    ];
    bool isSelected = index == _selectedGiftIndex;

    return GestureDetector(
      onTap: () => setState(() => _selectedGiftIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            if (gifts[index]['new'] as bool)
              Positioned(top: 5, right: 5, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 6)))),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.card_giftcard, color: Colors.amber, size: 35),
                const SizedBox(height: 5),
                Text(gifts[index]['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 10)),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(gifts[index]['price'] as String, style: TextStyle(color: isSelected ? Colors.amber : Colors.blue, fontSize: 10)), Text(gifts[index]['type'] as String, style: const TextStyle(fontSize: 8))]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFF0A121A),
      child: Row(
        children: [
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("إرسال")),
          const SizedBox(width: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Row(children: const [Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16), SizedBox(width: 8), Text("1", style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 16)]),
          ),
          const Spacer(),
          const Icon(Icons.more_horiz, color: Colors.white38),
        ],
      ),
    );
  }
}
