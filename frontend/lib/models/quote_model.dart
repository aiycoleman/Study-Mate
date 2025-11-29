class Quote {
  final String id;
  final String text;
  final String author;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
