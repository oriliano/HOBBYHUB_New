import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:staj_proje1/strings/strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opsiyonel: Google Translate fonksiyonu
Future<String> googleTranslate(String text, String targetLang) async {
  if (text.trim().isEmpty) return text;
  const String apiKey = ''; // Google Translate API Key'inizi buraya yazın
  final url = Uri.parse(
      'https://translation.googleapis.com/language/translate/v2?key=$apiKey');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'q': text,
        'target': targetLang,
        'format': 'text',
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final translations = data['data']?['translations'];
      if (translations != null && translations.isNotEmpty) {
        return translations[0]['translatedText'] ?? text;
      }
    } else {
      debugPrint('Google Translate API Error: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Google Translate Exception: $e');
  }
  return text;
}

class TiyatroScreen extends StatefulWidget {
  final String langCode;
  const TiyatroScreen({super.key, required this.langCode});

  @override
  State<TiyatroScreen> createState() => _TiyatroScreenState();
}

class _TiyatroScreenState extends State<TiyatroScreen> {
  /// Grid/List toggle
  bool _isGrid = true;
  bool _isLoading = false;
  List<dynamic> _tiyatrolar = [];

  @override
  void initState() {
    super.initState();
    _fetchTiyatrolar();
  }

  Future<void> _fetchTiyatrolar() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
          'https://api.collectapi.com/watching/tiyatro?data.city=ankara');
      final response = await http.get(
        url,
        headers: {
          'authorization':
              ' ',
          'content-type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['result'] ?? [];
        // Eğer dil İngilizce ise (örneğin) çeviri yapılabilir
        if (widget.langCode == 'en') {
          for (int i = 0; i < results.length; i++) {
            final Map<String, dynamic> item = results[i];
            final title = item['title'] ?? '';
            final tTitle = await googleTranslate(title, 'en');
            item['title'] = tTitle;
          }
        }
        setState(() {
          _tiyatrolar = results;
        });
      } else {
        debugPrint('Error (Tiyatro): ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception (Tiyatro): $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle Grid / List
  void _toggleLayoutMode() {
    setState(() {
      _isGrid = !_isGrid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theaterLabel = AppStrings.getText(widget.langCode, 'theater');
    return Scaffold(
      appBar: AppBar(
        title: Text(theaterLabel),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleLayoutMode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tiyatrolar.isEmpty
              ? Center(
                  child: Text(
                      AppStrings.getText(widget.langCode, 'no_data_found')))
              : _isGrid
                  ? _buildTiyatroGrid()
                  : _buildTiyatroList(),
    );
  }

  /// Grid Görünümü
  Widget _buildTiyatroGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _tiyatrolar.length,
      itemBuilder: (context, index) {
        final item = _tiyatrolar[index];
        return _buildTiyatroCard(item);
      },
    );
  }

  /// Liste Görünümü
  Widget _buildTiyatroList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _tiyatrolar.length,
      itemBuilder: (context, index) {
        final item = _tiyatrolar[index];
        return _buildTiyatroListItem(item);
      },
    );
  }

  /// Grid Kartı Tasarımı
  Widget _buildTiyatroCard(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final imageUrl = item['image'] ?? '';
    return InkWell(
      onTap: () => _showTiyatroDetails(item),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: Stack(
          children: [
            // Görsel alanı
            Positioned.fill(
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.theater_comedy, size: 50),
                    ),
            ),
            // Üstte gradient overlay
            // Positioned.fill(
            //   child: Container(
            //     decoration: BoxDecoration(
            //       gradient: LinearGradient(
            //         colors: [
            //           Colors.deepPurple.withOpacity(0.3),
            //           Colors.black.withOpacity(0.8)
            //         ],
            //         begin: Alignment.topCenter,
            //         end: Alignment.bottomCenter,
            //       ),
            //     ),
            //   ),
            // ),
            // Alt kısımda başlık
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black87),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Liste Elemanı Tasarımı
  Widget _buildTiyatroListItem(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final imageUrl = item['image'] ?? '';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showTiyatroDetails(item),
        leading: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl,
                    width: 60, height: 80, fit: BoxFit.cover),
              )
            : const Icon(Icons.theater_comedy, size: 50),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Detay Dialog veya Ekranı
  void _showTiyatroDetails(Map<String, dynamic> item) {
    final image = item['image'] ?? '';
    final title = item['title'] ?? '';
    final sahne = item['sahne'] ?? '';
    final url = item['url'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (image.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(image, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                if (sahne.isNotEmpty)
                  Text(
                    "${AppStrings.getText(widget.langCode, 'sahne')}: $sahne",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.getText(widget.langCode, 'more_info'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _launchURL(url),
                    child: Text(
                      url,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.getText(widget.langCode, 'close')),
            ),
          ],
        );
      },
    );
  }

  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Exception launching $url : $e');
    }
  }
}
