import 'package:flutter/material.dart';
import '../app_theme.dart';

class LanguageSelectionPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const LanguageSelectionPage({
    super.key,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.currentLocale;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('اللغة / Language',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildLanguageCard(
                title: 'العربية',
                subTitle: 'Arabic',
                locale: const Locale('ar'),
                icon: '🇸🇦',
              ),
              const SizedBox(height: 12),
              _buildLanguageCard(
                title: 'English',
                subTitle: 'الإنجليزية',
                locale: const Locale('en'),
                icon: '🇺🇸',
              ),
              const Spacer(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: AppTheme.gradientButton(
                  text: _selectedLocale.languageCode == 'ar'
                      ? 'حفظ التغييرات'
                      : 'Save Changes',
                  onPressed: () {
                    widget.onLanguageChanged(_selectedLocale);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required String subTitle,
    required Locale locale,
    required String icon,
  }) {
    bool isSelected = _selectedLocale.languageCode == locale.languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: isSelected ? 0.1 : 0.03,
        borderGlow: isSelected,
        child: ListTile(
          onTap: () => setState(() => _selectedLocale = locale),
          leading: Text(icon, style: const TextStyle(fontSize: 24)),
          title: Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
          subtitle: Text(subTitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded,
                  color: AppTheme.royalGold, size: 26)
              : const Icon(Icons.radio_button_off_rounded,
                  color: Colors.white10, size: 26),
        ),
      ),
    );
  }
}
