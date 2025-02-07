import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:staj_proje1/strings/strings.dart';

/// Google Translate (opsiyonel)
Future<String> googleTranslate(String text, String targetLang) async {
  if (text.trim().isEmpty) return text;

  const String apiKey = ''; // Kendi Google API Key'inizi girin
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
  return text; // hata durumunda orijinali döndür
}

/// Menü Seçenekleri
enum TvMenuOption {
  onAir,
  topRated,
  favorites,
}

class TvScreen extends StatefulWidget {
  final String langCode;

  const TvScreen({super.key, required this.langCode});

  @override
  State<TvScreen> createState() => _TvScreenState();
}

class _TvScreenState extends State<TvScreen> {
  /// Grid ↔ List görünüm
  bool _isGrid = true;

  /// Sekmeler: OnAir / TopRated / Favorites
  TvMenuOption _selectedMenu = TvMenuOption.onAir;

  /// Favoriler
  List<Map<String, dynamic>> _favoriteTvShows = [];

  // On Air
  bool _isLoadingOA = false;
  bool _isLoadingMoreOA = false;
  List<dynamic> _onAirTvShows = [];
  int _currentPageOA = 1;
  int _totalPagesOA = 1;
  final ScrollController _scrollControllerOA = ScrollController();

  // Top Rated
  bool _isLoadingTR = false;
  bool _isLoadingMoreTR = false;
  List<dynamic> _topRatedTvShows = [];
  int _currentPageTR = 1;
  int _totalPagesTR = 1;
  final ScrollController _scrollControllerTR = ScrollController();

  /// Arama (local)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    // Varsayılan: OnAir
    _fetchOnAir(page: _currentPageOA);

    // Scroll Listeners
    _scrollControllerOA.addListener(() {
      final pos = _scrollControllerOA.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.9) {
        _loadNextPageOnAir();
      }
    });
    _scrollControllerTR.addListener(() {
      final pos = _scrollControllerTR.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.9) {
        _loadNextPageTopRated();
      }
    });

    // Arama listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollControllerOA.dispose();
    _scrollControllerTR.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Favori yükle/kaydet
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('favoriteTvShows');
    if (savedData != null) {
      final List<dynamic> dataList = jsonDecode(savedData);
      _favoriteTvShows =
          dataList.map((e) => e as Map<String, dynamic>).toList();
    }
    // TR dilindeyse favori listeyi de çevir
    if (widget.langCode == 'tr') {
      await _translateTvShowsIfNeeded(_favoriteTvShows);
    }
    setState(() {});
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(_favoriteTvShows);
    await prefs.setString('favoriteTvShows', jsonData);
  }

  void _toggleFavorite(Map<String, dynamic> show) {
    final showId = show['id'];
    final existingIndex =
        _favoriteTvShows.indexWhere((element) => element['id'] == showId);

    setState(() {
      if (existingIndex >= 0) {
        _favoriteTvShows.removeAt(existingIndex);
      } else {
        _favoriteTvShows.add(show);
      }
    });
    _saveFavorites();
  }

  bool _isInFavorites(Map<String, dynamic> show) {
    final showId = show['id'];
    return _favoriteTvShows.any((element) => element['id'] == showId);
  }

  /// ON AIR
  Future<void> _fetchOnAir({int page = 1}) async {
    if (page == 1) {
      setState(() => _isLoadingOA = true);
    } else {
      setState(() => _isLoadingMoreOA = true);
    }

    try {
      final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/on_the_air?language=en-US&page=$page',
      );
      final resp = await http.get(
        url,
        headers: {
          'Authorization': '',
          'accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = data['results'] ?? [];
        _totalPagesOA = data['total_pages'] ?? 1;

        // TR çevir
        await _translateTvShowsIfNeeded(results);

        setState(() {
          if (page == 1) {
            _onAirTvShows = results;
          } else {
            _onAirTvShows.addAll(results);
          }
        });
      }
    } catch (e) {
      debugPrint("Exception onAir: $e");
    } finally {
      if (page == 1) {
        setState(() => _isLoadingOA = false);
      } else {
        setState(() => _isLoadingMoreOA = false);
      }
    }
  }

  void _loadNextPageOnAir() {
    if (_isLoadingMoreOA) return;
    if (_currentPageOA >= _totalPagesOA) return;

    _currentPageOA++;
    _fetchOnAir(page: _currentPageOA);
  }

  /// TOP RATED
  Future<void> _fetchTopRated({int page = 1}) async {
    if (page == 1) {
      setState(() => _isLoadingTR = true);
    } else {
      setState(() => _isLoadingMoreTR = true);
    }

    try {
      final url = Uri.parse(
        'https://api.themoviedb.org/3/tv/top_rated?language=en-US&page=$page',
      );
      final resp = await http.get(
        url,
        headers: {
          'Authorization': '',
          'accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = data['results'] ?? [];
        _totalPagesTR = data['total_pages'] ?? 1;

        // TR çevir
        await _translateTvShowsIfNeeded(results);

        setState(() {
          if (page == 1) {
            _topRatedTvShows = results;
          } else {
            _topRatedTvShows.addAll(results);
          }
        });
      }
    } catch (e) {
      debugPrint("Exception topRated: $e");
    } finally {
      if (page == 1) {
        setState(() => _isLoadingTR = false);
      } else {
        setState(() => _isLoadingMoreTR = false);
      }
    }
  }

  void _loadNextPageTopRated() {
    if (_isLoadingMoreTR) return;
    if (_currentPageTR >= _totalPagesTR) return;

    _currentPageTR++;
    _fetchTopRated(page: _currentPageTR);
  }

  /// TR çeviri
  Future<void> _translateTvShowsIfNeeded(List<dynamic> tvList) async {
    if (widget.langCode == 'tr') {
      for (final item in tvList) {
        final name = item['name'] ?? '';
        final overview = item['overview'] ?? '';

        final tName = await googleTranslate(name, 'tr');
        final tOverview = await googleTranslate(overview, 'tr');

        item['name'] = tName;
        item['overview'] = tOverview;
      }
    }
  }

  /// Tarih formatı (TR)
  String _formatTurkishDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Lokal arama (Card üzerindeki "name" içinde)

  Widget _buildFilterRow() {
    final nowPlayingLabel = AppStrings.getText(widget.langCode, 'on_air');
    final topRatedLabel = AppStrings.getText(widget.langCode, 'top_rated');
    final favoritesLabel = AppStrings.getText(widget.langCode, 'favorites');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
            child: _buildGradientFilterButton(
                TvMenuOption.onAir, nowPlayingLabel)),
        Expanded(
            child: _buildGradientFilterButton(
                TvMenuOption.topRated, topRatedLabel)),
        Expanded(
            child: _buildGradientFilterButton(
                TvMenuOption.favorites, favoritesLabel)),
      ],
    );
  }

  Widget _buildGradientFilterButton(TvMenuOption option, String label) {
    final isSelected = (_selectedMenu == option);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMenu = option;
          });
          if (option == TvMenuOption.topRated && _topRatedTvShows.isEmpty) {
            _fetchTopRated(page: _currentPageTR);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Colors.deepPurple, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final searchHint = AppStrings.getText(widget.langCode, 'search_hint');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDarkMode ? Colors.black : Colors.black, // Metin rengi
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.black54 : Colors.grey,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.black : Colors.grey,
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.white : Colors.grey.shade200,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// List/Grid Toggle

  void _toggleLayoutMode() {
    setState(() {
      _isGrid = !_isGrid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tvLabel = AppStrings.getText(widget.langCode, 'series');

    return Scaffold(
      appBar: AppBar(
        title: Text(tvLabel),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleLayoutMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama alanı
          _buildSearchField(),
          // Üç buton
          _buildFilterRow(),
          // İçerik
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                if (_selectedMenu == TvMenuOption.onAir && _isLoadingMoreOA)
                  _buildBottomLoading(),
                if (_selectedMenu == TvMenuOption.topRated && _isLoadingMoreTR)
                  _buildBottomLoading(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLoading() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(8),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Ekran Gövdesi
  Widget _buildContent() {
    switch (_selectedMenu) {
      case TvMenuOption.onAir:
        if (_isLoadingOA) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_onAirTvShows.isEmpty) {
          return _buildNoData();
        }
        return _buildOnAirView();

      case TvMenuOption.topRated:
        if (_isLoadingTR) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_topRatedTvShows.isEmpty) {
          return _buildNoData();
        }
        return _buildTopRatedView();

      case TvMenuOption.favorites:
        if (_favoriteTvShows.isEmpty) {
          return _buildNoData();
        }
        return _buildFavoritesView();
    }
  }

  Widget _buildNoData() {
    final noDataLabel = AppStrings.getText(widget.langCode, 'no_data_found');
    return Center(child: Text(noDataLabel));
  }

  /// On Air
  Widget _buildOnAirView() {
    return _isGrid
        ? _buildTvGrid(_onAirTvShows, _scrollControllerOA)
        : _buildTvList(_onAirTvShows, _scrollControllerOA);
  }

  /// Top Rated
  Widget _buildTopRatedView() {
    return _isGrid
        ? _buildTvGrid(_topRatedTvShows, _scrollControllerTR)
        : _buildTvList(_topRatedTvShows, _scrollControllerTR);
  }

  /// Favorites
  Widget _buildFavoritesView() {
    return _isGrid
        ? _buildTvGrid(_favoriteTvShows, null)
        : _buildTvList(_favoriteTvShows, null);
  }

  /// Filtreleme (Arama)
  List<dynamic> _filterBySearch(List<dynamic> tvShows) {
    if (_searchQuery.isEmpty) {
      return tvShows;
    }
    return tvShows.where((element) {
      final name = (element['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  /// Grid
  Widget _buildTvGrid(List<dynamic> tvShows, ScrollController? controller) {
    final filtered = _filterBySearch(tvShows);

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.6,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final show = filtered[index];
        return _buildTvCard(show);
      },
    );
  }

  /// Liste
  Widget _buildTvList(List<dynamic> tvShows, ScrollController? controller) {
    final filtered = _filterBySearch(tvShows);

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final show = filtered[index];
        return _buildTvListItem(show);
      },
    );
  }

  /// Kart (Grid)
  Widget _buildTvCard(Map<String, dynamic> show) {
    final name = show['name'] ?? '';
    final posterPath = show['poster_path'] ?? '';
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;

    final firstAirDate = show['first_air_date'] ?? '';
    final dateTr = _formatTurkishDate(firstAirDate);
    final isFav = _isInFavorites(show);
    final showId = show['id'] ?? '0';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TvDetailScreen(
              showData: show,
              dateTr: dateTr,
              initialIsFavorite: isFav,
              onToggleFavorite: () => _toggleFavorite(show),
              langCode: widget.langCode,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Arka plan: Poster görüntüsü, Hero animasyonu ile
            Positioned.fill(
              child: posterUrl != null
                  ? Hero(
                      tag: 'tvPoster_$showId',
                      child: Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.live_tv, size: 50),
                    ),
            ),
            // Üstte koyu mavi-siyah gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Alt kısımda film adı, yayın tarihi ve favori butonu
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                        if (dateTr.isNotEmpty)
                          Text(
                            '${AppStrings.getText(widget.langCode, 'release_date')}: $dateTr',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(show),
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : Colors.white,
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

  /// Liste Elemanı
  Widget _buildTvListItem(Map<String, dynamic> show) {
    final name = show['name'] ?? '';
    final posterPath = show['poster_path'] ?? '';
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;

    final firstAirDate = show['first_air_date'] ?? '';
    final dateTr = _formatTurkishDate(firstAirDate);
    final isFav = _isInFavorites(show);
    final showId = show['id'] ?? '0';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TvDetailScreen(
                showData: show,
                dateTr: dateTr,
                initialIsFavorite: isFav,
                onToggleFavorite: () => _toggleFavorite(show),
                langCode: widget.langCode,
              ),
            ),
          );
        },
        leading: (posterUrl != null)
            ? Hero(
                tag: 'tvPoster_$showId',
                child: Image.network(posterUrl, width: 50, fit: BoxFit.cover),
              )
            : const Icon(Icons.live_tv, size: 50),
        title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: dateTr.isNotEmpty
            ? Text(
                '${AppStrings.getText(widget.langCode, 'release_date')}: $dateTr',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: IconButton(
          onPressed: () => _toggleFavorite(show),
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : null,
          ),
        ),
      ),
    );
  }
}

class TvDetailScreen extends StatefulWidget {
  final Map<String, dynamic> showData;
  final String dateTr;
  final bool initialIsFavorite;
  final VoidCallback onToggleFavorite;
  final String langCode;

  const TvDetailScreen({
    super.key,
    required this.showData,
    required this.dateTr,
    required this.initialIsFavorite,
    required this.onToggleFavorite,
    required this.langCode,
  });

  @override
  State<TvDetailScreen> createState() => _TvDetailScreenState();
}

class _TvDetailScreenState extends State<TvDetailScreen> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    _isFav = widget.initialIsFavorite;
  }

  void _handleToggleFavorite() {
    widget.onToggleFavorite();
    setState(() {
      _isFav = !_isFav;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.showData['name'] ?? '';
    final overview = widget.showData['overview'] ?? '';
    final backdropPath = widget.showData['backdrop_path'] ?? '';
    final posterPath = widget.showData['poster_path'] ?? '';
    final voteAverage = widget.showData['vote_average']?.toString() ?? '';

    final backdropUrl = backdropPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$backdropPath'
        : null;
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;

    // strings
    final releaseLabel = AppStrings.getText(widget.langCode, 'release_date');
    final ratingLabel = AppStrings.getText(widget.langCode, 'rating_label');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final infoColor = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            onPressed: _handleToggleFavorite,
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Arka plan
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  if (backdropUrl != null)
                    Positioned.fill(
                      child: Hero(
                        tag: 'tvPoster_${widget.showData['id'] ?? '0'}',
                        child: Image.network(backdropUrl, fit: BoxFit.cover),
                      ),
                    )
                  else if (posterUrl != null)
                    Positioned.fill(
                      child: Hero(
                        tag: 'tvPoster_${widget.showData['id'] ?? '0'}',
                        child: Image.network(posterUrl, fit: BoxFit.cover),
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Center(child: Icon(Icons.live_tv, size: 50)),
                      ),
                    ),
                  // Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Dizi adı
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tarih + Puan
            if (widget.dateTr.isNotEmpty || voteAverage.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    if (widget.dateTr.isNotEmpty)
                      Text(
                        "$releaseLabel: ${widget.dateTr}",
                        style: TextStyle(color: infoColor),
                      ),
                    const Spacer(),
                    if (voteAverage.isNotEmpty)
                      Text(
                        "$ratingLabel: $voteAverage",
                        style: TextStyle(color: infoColor),
                      ),
                  ],
                ),
              ),
            // Açıklama
            if (overview.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  overview,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
