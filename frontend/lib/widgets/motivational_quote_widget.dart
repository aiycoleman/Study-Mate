// filepath: lib/widgets/motivational_quote_widget.dart
import 'package:flutter/material.dart';
import '../services/quotes_service.dart';

class MotivationalQuoteWidget extends StatefulWidget {
  const MotivationalQuoteWidget({Key? key}) : super(key: key);

  @override
  State<MotivationalQuoteWidget> createState() => _MotivationalQuoteWidgetState();
}

class _MotivationalQuoteWidgetState extends State<MotivationalQuoteWidget> with TickerProviderStateMixin {
  final QuotesService _quotesService = QuotesService();
  Map<String, dynamic>? _quoteData;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _loadQuote();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadQuote() async {
    setState(() => _isLoading = true);

    final quote = await _quotesService.getTimeBasedQuote();

    if (mounted) {
      setState(() {
        _quoteData = quote;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _refreshQuote() async {
    _fadeController.reset();
    setState(() => _isLoading = true);

    final quote = await _quotesService.getDailyMotivationalQuote();

    if (mounted) {
      setState(() {
        _quoteData = quote;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_quoteData == null) {
      return _buildErrorWidget();
    }

    return _buildQuoteCard();
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[300]!, Colors.purple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading inspiration...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_quote, color: Colors.grey[600], size: 32),
            const SizedBox(height: 8),
            Text(
              'Quote unavailable',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            TextButton(
              onPressed: _loadQuote,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    final content = _quoteData!['content'] as String;
    final author = _quoteData!['author'] as String;
    final tags = _quoteData!['tags'] as List<dynamic>?;
    final icon = _quotesService.getQuoteIcon(tags);

    // Choose gradient based on time of day
    final hour = DateTime.now().hour;
    Color gradientStart, gradientEnd;

    if (hour < 12) {
      // Morning - warm orange/yellow
      gradientStart = Colors.orange[300]!;
      gradientEnd = Colors.deepOrange[400]!;
    } else if (hour < 17) {
      // Afternoon - blue/teal
      gradientStart = Colors.teal[300]!;
      gradientEnd = Colors.teal[500]!;
    } else {
      // Evening - purple/indigo
      gradientStart = Colors.purple[300]!;
      gradientEnd = Colors.purple[500]!;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientEnd.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and refresh button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  IconButton(
                    onPressed: _refreshQuote,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'New Quote',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quote content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opening quote mark
                    Icon(
                      Icons.format_quote,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(height: 8),

                    // Quote text
                    Text(
                      content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Author
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '— $author',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Inspiration label
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Daily Inspiration',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
