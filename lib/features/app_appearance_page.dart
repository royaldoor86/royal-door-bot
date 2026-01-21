import 'package:flutter/material.dart';
import '../main.dart';

class AppAppearancePage extends StatefulWidget {
  const AppAppearancePage({super.key});

  @override
  State<AppAppearancePage> createState() => _AppAppearancePageState();
}

class _AppAppearancePageState extends State<AppAppearancePage> {
  @override
  Widget build(BuildContext context) {
    bool isRoyal = MyApp.isRoyal(context);
    bool isLargeFont = MyApp.isLargeFont(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مظهر التطبيق'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          _buildSectionTitle('السمات الخاصة'),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome, color: Colors.pink),
            title: const Text('الخلفية الملكية المتدرجة'),
            subtitle: const Text('تغيير لون التطبيق إلى البنفسجي الزهري الملكي'),
            value: isRoyal,
            onChanged: (val) {
              MyApp.updateConfig(context, useRoyalTheme: val);
            },
          ),
          
          const Divider(),
          
          _buildSectionTitle('إعدادات النص'),
          SwitchListTile(
            secondary: const Icon(Icons.format_size, color: Colors.blue),
            title: const Text('تكبير حجم الخط'),
            subtitle: const Text('عرض نصوص التطبيق بحجم أكبر لسهولة القراءة'),
            value: isLargeFont,
            onChanged: (val) {
              MyApp.updateConfig(context, useLargeFont: val);
            },
          ),
          
          const Divider(),
          
          _buildSectionTitle('الوضع العام'),
          _buildThemeOption('فاتح', Icons.light_mode_outlined, true),
          _buildThemeOption('داكن', Icons.dark_mode_outlined, false),
          
          const SizedBox(height: 40), // استبدال Spacer بمسافة ثابتة لحل الخطأ
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'سيتم تطبيق التغييرات فوراً لتجربة استخدام ملكية فريدة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.deepPurple : Colors.grey),
      title: Text(title),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Colors.deepPurple) 
          : const Icon(Icons.radio_button_off, color: Colors.grey),
    );
  }
}
