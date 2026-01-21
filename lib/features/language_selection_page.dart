import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('اللغة / Language'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildLanguageOption(
            title: 'العربية',
            subTitle: 'Arabic',
            locale: const Locale('ar'),
          ),
          const Divider(),
          _buildLanguageOption(
            title: 'English',
            subTitle: 'الإنجليزية',
            locale: const Locale('en'),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: () {
                widget.onLanguageChanged(_selectedLocale);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حفظ / Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subTitle,
    required Locale locale,
  }) {
    bool isSelected = _selectedLocale.languageCode == locale.languageCode;
    return ListTile(
      onTap: () {
        setState(() {
          _selectedLocale = locale;
        });
      },
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subTitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.deepPurple)
          : const Icon(Icons.radio_button_off, color: Colors.grey),
    );
  }
}
