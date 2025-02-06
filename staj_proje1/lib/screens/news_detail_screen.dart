import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // LaunchMode için
import '../model_view/news_model.dart'; // Haber modelinizin import'u

const Map<String, String> sourceLogos = {
  "sabah":
      "https://upload.wikimedia.org/wikipedia/tr/c/c6/Sabah_logosu_%281993-2003%29.png",
  "cumhuriyet":
      "https://logowik.com/content/uploads/images/cumhuriyet-gazetesi9127.logowik.com.webp",
  "hurriyet":
      "https://e7.pngegg.com/pngimages/752/455/png-clipart-hurriyet-newspaper-logo-brand-do%C4%9Fan-holding-check-logo-text-rectangle-thumbnail.png",
  "karar":
      "https://upload.wikimedia.org/wikipedia/commons/5/55/Karar_gazetesi_logo.png",
  "habertürk":
      "https://upload.wikimedia.org/wikipedia/commons/7/78/Haberturk_logo.png",
};

String? getSourceLogo(String sourceName) {
  final key = sourceName.toLowerCase();
  return sourceLogos[key];
}

class NewsDetailScreen extends StatelessWidget {
  final NewsItem newsItem;

  const NewsDetailScreen({super.key, required this.newsItem});

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    try {
      final bool launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open URL'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error launching $url: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open URL'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String sourceName = newsItem.source;
    final String? logoUrl = getSourceLogo(sourceName);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (logoUrl != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network(
                  logoUrl,
                  height: 30,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
              ),
            Text(sourceName),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newsItem.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  newsItem.image,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 60),
                ),
              ),
            const SizedBox(height: 16),

            // Başlık
            Text(
              newsItem.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Açıklama
            Text(
              newsItem.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // URL Link (tıklanabilir)
            if (newsItem.url.isNotEmpty)
              GestureDetector(
                onTap: () => _launchURL(context, newsItem.url),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        newsItem.url,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
