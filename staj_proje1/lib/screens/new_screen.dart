// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/strings/strings.dart';
import '../services/news_service.dart';
import '../services/translation_service.dart';
import '../model_view/news_model.dart';
import 'news_detail_screen.dart';

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

class NewsScreen extends StatefulWidget {
  final String langCode;
  const NewsScreen({super.key, required this.langCode});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();

  List<NewsItem> _newsList = [];
  int _page = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant NewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.langCode != widget.langCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _newsList.clear();
          _page = 1;
          _isLoading = true;
          print(
              "NewsScreen: Dil değiştirildi, veriler yeniden yükleniyor."); // Debug çıktısı
        });
        _fetchInitialData();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final fetchedNews = await NewsService.fetchNews('tr', _page);
      print(
          "Fetched ${fetchedNews.length} news items for page $_page"); // Debug çıktısı

      // Çeviri işlemi
      List<NewsItem> translatedNews =
          await Future.wait(fetchedNews.map((item) async {
        String translatedName = item.name;
        String translatedDescription = item.description;

        if (widget.langCode != 'tr') {
          translatedName = await TranslationService.translateText(
            item.name,
            widget.langCode, // Hedef dil kodu
          );
          translatedDescription = await TranslationService.translateText(
            item.description,
            widget.langCode, // Hedef dil kodu
          );
          print("Translated: $translatedName"); // Debug çıktısı
          print(
              "Translated Description: $translatedDescription"); // Debug çıktısı
        }

        print(
            "Translated NewsItem: $translatedName - $translatedDescription"); // Debug çıktısı

        return NewsItem(
          key: item.key,
          url: item.url,
          description: translatedDescription,
          image: item.image,
          name: translatedName,
          source: item.source, // Source Türkçe kalacak
        );
      }).toList());

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _newsList = translatedNews;
          _isLoading = false;
          print("Haberler başarıyla güncellendi."); // Debug çıktısı
        });
      });
    } catch (e) {
      print("Hata: $e"); // Debug çıktısı
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppStrings.getText(widget.langCode, 'error_fetching_news')),
            action: SnackBarAction(
              label: AppStrings.getText(widget.langCode, 'retry'),
              onPressed: () {
                _fetchInitialData();
              },
            ),
          ),
        );
      });
    }
  }

  Future<void> _fetchMoreData() async {
    if (_isLoadingMore || _isLoading) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        print("Fetching more data..."); // Debug çıktısı
      });
    });

    final nextPage = _page + 1;
    try {
      final fetchedNews = await NewsService.fetchNews('tr', nextPage);
      print(
          "Fetched ${fetchedNews.length} news items for page $nextPage"); // Debug çıktısı

      // Çeviri işlemi
      List<NewsItem> translatedNews =
          await Future.wait(fetchedNews.map((item) async {
        String translatedName = item.name;
        String translatedDescription = item.description;

        if (widget.langCode != 'tr') {
          translatedName = await TranslationService.translateText(
            item.name,
            widget.langCode, // Hedef dil kodu
          );
          translatedDescription = await TranslationService.translateText(
            item.description,
            widget.langCode, // Hedef dil kodu
          );
          print("Translated (More): $translatedName"); // Debug çıktısı
          print(
              "Translated Description (More): $translatedDescription"); // Debug çıktısı
        }

        return NewsItem(
          key: item.key,
          url: item.url,
          description: translatedDescription,
          image: item.image,
          name: translatedName,
          source: item.source, // Source Türkçe kalacak
        );
      }).toList());

      if (translatedNews.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _page = nextPage;
            for (var news in translatedNews) {
              if (!_newsList.any((element) => element.key == news.key)) {
                _newsList.add(news);
                print("Yeni haber eklendi: ${news.name}"); // Debug çıktısı
              }
            }
            print("Yeni haberler eklendi."); // Debug çıktısı
          });
        });
      }
    } catch (e) {
      print("Hata fetchMoreData: $e"); // Debug çıktısı
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppStrings.getText(widget.langCode, 'error_fetching_news')),
            action: SnackBarAction(
              label: AppStrings.getText(widget.langCode, 'retry'),
              onPressed: () {
                _fetchMoreData();
              },
            ),
          ),
        );
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isLoadingMore = false;
          print("Fetch more data tamamlandı."); // Debug çıktısı
        });
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreData();
    }
  }

  Future<void> _refreshNews() async {
    if (_isLoading) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _newsList.clear();
        _page = 1;
        _isLoading = true;
        print("Haberler yenileniyor..."); // Debug çıktısı
      });
    });
    await _fetchInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getText(widget.langCode, 'news')),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshNews,
            child: _isLoading
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  )
                : _newsList.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Center(
                              child: Text(
                                AppStrings.getText(
                                    widget.langCode, 'no_news_found'),
                                style:
                                    TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _newsList.length,
                        itemBuilder: (context, index) {
                          final item = _newsList[index];
                          return _buildNewsCard(context, item);
                        },
                      ),
          ),

          // Alt tarafta "Loading..." göstermek
          if (_isLoadingMore)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white70,
                padding: const EdgeInsets.all(8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsItem item) {
    final logoUrl = getSourceLogo(item.source);
    final sourceNameTr = AppStrings.getSourceNameTr(item.source);

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewsDetailScreen(newsItem: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üstte resim ve source bandı
            Stack(
              children: [
                item.image.isNotEmpty
                    ? Image.network(
                        item.image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Icon(Icons.image, size: 60),
                          );
                        },
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, size: 60),
                      ),

                // Kaynak etiketi (logo + source adı)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (logoUrl != null)
                          Image.network(
                            logoUrl,
                            height: 44,
                            width: 44,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 44,
                                width: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.newspaper,
                                color: Colors.white,
                                size: 24,
                              );
                            },
                          )
                        else
                          const Icon(
                            Icons.newspaper,
                            color: Colors.white,
                            size: 24,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          sourceNameTr, // Kaynak Türkçe olarak gösterilecek
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Başlık
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name, // 'name' alanı doğru dilde olacak
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Açıklama
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.description, // 'description' alanı doğru dilde olacak
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
