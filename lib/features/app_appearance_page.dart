import 'package:flutter/material.dart';
import '../main.dart';
import '../app_theme.dart';

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
    bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('مظهر التطبيق'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: AppTheme.background(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _buildSectionTitle('السمات الملكية الخاصة'),
              _buildCardWrapper(
                child: SwitchListTile(
                  secondary:
                      const Icon(Icons.auto_awesome, color: AppTheme.royalPink),
                  title: const Text('الخلفية الملكية المتدرجة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      'تفعيل اللون البنفسجي الزهري في كافة أنحاء التطبيق',
                      style: TextStyle(fontSize: 12)),
                  value: isRoyal,
                  activeThumbColor: AppTheme.royalPink,
                  onChanged: (val) =>
                      MyApp.updateConfig(context, useRoyalTheme: val),
                ),
              ),
              _buildSectionTitle('إعدادات الخط'),
              _buildCardWrapper(
                child: SwitchListTile(
                  secondary:
                      const Icon(Icons.format_size, color: Colors.blueAccent),
                  title: const Text('تكبير حجم الخط',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('عرض نصوص التطبيق بحجم أكبر ومريح للعين',
                      style: TextStyle(fontSize: 12)),
                  value: isLargeFont,
                  onChanged: (val) =>
                      MyApp.updateConfig(context, useLargeFont: val),
                ),
              ),
              _buildSectionTitle('الوضع العام'),
              _buildCardWrapper(
                child: Column(
                  children: [
                    _buildThemeOption(
                        'الوضع الفاتح (صباحي)',
                        Icons.light_mode_rounded,
                        isLightMode,
                        Colors.orangeAccent, () {
                      MyApp.updateConfig(context, themeMode: ThemeMode.light);
                    }),
                    const Divider(color: Colors.white10, height: 1, indent: 50),
                    _buildThemeOption(
                        'الوضع الداكن (ليلي)',
                        Icons.dark_mode_rounded,
                        !isLightMode,
                        Colors.indigoAccent, () {
                      MyApp.updateConfig(context, themeMode: ThemeMode.dark);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'سيتم تطبيق التغييرات فوراً لتجربة استخدام ملكية فريدة تتناسب مع ذوقك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isLightMode ? Colors.black38 : Colors.white38,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Text(
        title,
        style: TextStyle(
            color: isLight ? Colors.deepPurple : AppTheme.royalGold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: child,
      ),
    );
  }

  Widget _buildThemeOption(String title, IconData icon, bool isSelected,
      Color iconColor, VoidCallback onTap) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: Colors.greenAccent, size: 22)
          : Icon(Icons.radio_button_off_rounded,
              color: isLight ? Colors.black12 : Colors.white10, size: 22),
    );
  }
}
