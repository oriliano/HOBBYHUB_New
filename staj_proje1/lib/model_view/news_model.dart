// lib/model_view/news_model.dart
import 'package:flutter/material.dart';

class NewsItem {
  final String key; // Benzersiz tanımlayıcı
  final String url;
  final String description;
  final String image;
  final String name;
  final String source;

  NewsItem({
    required this.key,
    required this.url,
    required this.description,
    required this.image,
    required this.name,
    required this.source,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      key: json['key'] ?? UniqueKey().toString(), // Benzersiz bir key
      url: json['url'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      name: json['name'] ?? '',
      source: json['source'] ?? '',
    );
  }
}
