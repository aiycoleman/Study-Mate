import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_events.dart';
import 'add_quote_screen.dart';
import 'dart:async';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({Key? key}) : super(key: key);

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final ApiService _api = ApiService();
  final AppEvents _events = AppEvents();
  List<dynamic> _quotes = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<String> _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadQuotes();

    // Listen for app events
    _eventSubscription = _events.events.listen((event) {
      if (event == AppEventTypes.quoteAdded ||
          event == AppEventTypes.quoteDeleted) {
        print('Quotes screen received event: $event, reloading...');
        _loadQuotes();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.fetchQuotes();
      if (mounted) {
        setState(() {
          _quotes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addQuote() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddQuoteScreen()),
    );

    if (result != null) {
      try {
        print('Creating quote with data: $result');
        final response = await _api.createQuote(result);
        print('API response for createQuote: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote added successfully')),
          );

          // Extract the created quote from the response
          Map<String, dynamic>? createdQuote;
          if (response.containsKey('quote')) {
            createdQuote = response['quote'] as Map<String, dynamic>;
          } else if (response.containsKey('data')) {
            createdQuote = response['data'] as Map<String, dynamic>;
          } else {
            createdQuote = response;
          }

          if (createdQuote != null) {
            // Optimistically add to the local list
            setState(() {
              _quotes.insert(0, createdQuote);
            });
            // Emit event to notify other screens
            _events.emit(AppEventTypes.quoteAdded);
          } else {
            // Fallback to reload if we can't extract the quote
            await _loadQuotes();
          }
        }
      } catch (e) {
        print('Error creating quote: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add quote: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteQuote(dynamic quote) async {
    final quoteId = quote['id']?.toString() ?? quote['quote_id']?.toString();
    if (quoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete quote: missing ID')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text('Are you sure you want to delete this quote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Optimistic update: remove from local list immediately
    final originalIndex = _quotes.indexWhere((q) =>
      (q['id']?.toString() ?? q['quote_id']?.toString()) == quoteId);

    if (originalIndex != -1) {
      final removedQuote = _quotes[originalIndex];
      setState(() {
        _quotes.removeAt(originalIndex);
      });

      try {
        await _api.deleteQuote(quoteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote deleted successfully')),
          );
          // Emit event to notify other screens
          _events.emit(AppEventTypes.quoteDeleted);
        }
      } catch (e) {
        // Rollback on error: add the quote back to its original position
        if (mounted) {
          setState(() {
            _quotes.insert(originalIndex, removedQuote);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete quote: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote not found in local list')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motivational Quotes'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load quotes'),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuotes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _quotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_quote,
                              size: 64, color: Colors.purple[200]),
                          const SizedBox(height: 16),
                          const Text(
                            'No quotes yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text('Add your first motivational quote!'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _addQuote,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Quote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadQuotes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          // Backend returns 'content' field for the quote text
                          final quoteText = quote['content'] ??
                              quote['quote_text'] ??
                              quote['text'] ??
                              'No quote text';
                          // Backend returns 'username' as the author (person who created it)
                          final author = quote['username'] ??
                              quote['author'] ??
                              'Unknown';
                          final createdAt = quote['created_at']?.toString() ??
                              quote['date']?.toString() ??
                              '';
                          final formattedDate =
                              createdAt.isNotEmpty ? createdAt.split('T').first : '';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.format_quote,
                                          color: Colors.purple[300], size: 32),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              quoteText,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '— $author',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (formattedDate.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteQuote(quote),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuote,
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

