// lib/model_view/news_response.dart
import 'package:staj_proje1/model_view/news_model.dart';

class NewsResponse {
  final bool success;
  final List<NewsItem> result;

  NewsResponse({
    required this.success,
    required this.result,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      success: json['success'] as bool,
      result: (json['result'] as List<dynamic>)
          .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
