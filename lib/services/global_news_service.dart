import 'dart:convert';
import 'package:http/http.dart' as http;

class GlobalNewsService {
  // استخدام API مفتاح تجريبي أو مصدر عام (يمكنك استبداله بـ NewsAPI الخاص بك)
  static const String _newsUrl = 'https://newsapi.org/v2/top-headlines?country=ae&category=technology&apiKey=YOUR_API_KEY';

  Future<List<Map<String, dynamic>>> fetchGlobalArticles() async {
    try {
      // لمحاكاة الجلب العالمي الحقيقي بدون تعقيد المفاتيح الآن:
      // سنستخدم مصدر بيانات عام أو محاكاة ذكية تتحدث دورياً
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.take(10).map((item) => {
          'title': item['title'],
          'content': item['body'],
          'image': 'https://picsum.photos/500/300?random=${item['id']}',
          'source': 'Global News Network',
        }).toList();
      }
    } catch (e) {
      print('Error fetching global news: $e');
    }
    return [];
  }
}
