// filepath: lib/services/quotes_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class QuotesService {
  static const String _quotableBaseUrl = 'https://api.quotable.io';

  Future<Map<String, dynamic>?> getDailyMotivationalQuote() async {
    try {
      // Get random motivational quote
      final uri = Uri.parse('$_quotableBaseUrl/random?tags=motivational|inspirational|success|wisdom');

      print('Fetching motivational quote...');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('Quote received: ${data['content']}');
        return {
          'content': data['content'],
          'author': data['author'],
          'tags': data['tags'],
        };
      } else {
        print('Quotes API error: ${response.statusCode}');
        return _getRandomStudyQuote();
      }
    } catch (e) {
      print('Quotes service error: $e');
      return _getRandomStudyQuote();
    }
  }

  Future<Map<String, dynamic>?> getStudyQuote() async {
    try {
      // Try to get education-related quote
      final uri = Uri.parse('$_quotableBaseUrl/random?tags=wisdom|success');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'content': data['content'],
          'author': data['author'],
          'tags': data['tags'],
        };
      } else {
        return _getRandomStudyQuote();
      }
    } catch (e) {
      print('Study quotes error: $e');
      return _getRandomStudyQuote();
    }
  }

  // Fallback study quotes for when API is unavailable
  Map<String, dynamic> _getRandomStudyQuote() {
    final List<Map<String, dynamic>> studyQuotes = [
      {
        'content': 'Success is the sum of small efforts repeated day in and day out.',
        'author': 'Robert Collier',
        'tags': ['success', 'persistence']
      },
      {
        'content': 'The expert in anything was once a beginner.',
        'author': 'Helen Hayes',
        'tags': ['learning', 'growth']
      },
      {
        'content': 'Education is the most powerful weapon which you can use to change the world.',
        'author': 'Nelson Mandela',
        'tags': ['education', 'empowerment']
      },
      {
        'content': 'The beautiful thing about learning is that nobody can take it away from you.',
        'author': 'B.B. King',
        'tags': ['learning', 'knowledge']
      },
      {
        'content': 'Study while others are sleeping; work while others are loafing.',
        'author': 'William A. Ward',
        'tags': ['dedication', 'hard work']
      },
      {
        'content': 'The more that you read, the more things you will know. The more that you learn, the more places you\'ll go.',
        'author': 'Dr. Seuss',
        'tags': ['reading', 'knowledge']
      },
      {
        'content': 'Learning never exhausts the mind.',
        'author': 'Leonardo da Vinci',
        'tags': ['learning', 'curiosity']
      },
      {
        'content': 'The capacity to learn is a gift; the ability to learn is a skill; the willingness to learn is a choice.',
        'author': 'Brian Herbert',
        'tags': ['learning', 'choice']
      },
      {
        'content': 'Don\'t let what you cannot do interfere with what you can do.',
        'author': 'John Wooden',
        'tags': ['motivation', 'focus']
      },
      {
        'content': 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        'author': 'Winston Churchill',
        'tags': ['perseverance', 'courage']
      }
    ];

    final random = Random();
    return studyQuotes[random.nextInt(studyQuotes.length)];
  }

  // Get quote based on time of day
  Future<Map<String, dynamic>?> getTimeBasedQuote() async {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      // Morning motivational quotes
      return _getRandomStudyQuote();
    } else if (hour < 17) {
      // Afternoon focus quotes
      return getStudyQuote();
    } else {
      // Evening reflection quotes
      return getDailyMotivationalQuote();
    }
  }

  String getQuoteIcon(List<dynamic>? tags) {
    if (tags == null) return '💡';

    final tagString = tags.join(' ').toLowerCase();

    if (tagString.contains('success')) return '🎯';
    if (tagString.contains('wisdom')) return '🧠';
    if (tagString.contains('learning')) return '📚';
    if (tagString.contains('motivation')) return '💪';
    if (tagString.contains('perseverance')) return '🔥';
    if (tagString.contains('education')) return '🎓';
    if (tagString.contains('knowledge')) return '💡';

    return '✨';
  }

  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 6) return 'Late night study session? 🌙';
    if (hour < 12) return 'Good morning, scholar! ☀️';
    if (hour < 17) return 'Good afternoon, learner! 📚';
    if (hour < 21) return 'Good evening, student! 🌅';
    return 'Night study session! 🌟';
  }
}
