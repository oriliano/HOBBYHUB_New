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
  return text;
}

/// Menü Seçenekleri
enum MovieMenuOption { nowPlaying, topRated, favorites }

class MovieScreen extends StatefulWidget {
  final String langCode;
  const MovieScreen({super.key, required this.langCode});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  bool _isGrid = true;
  MovieMenuOption _selectedMenu = MovieMenuOption.nowPlaying;
  List<Map<String, dynamic>> _favoriteMovies = [];

  // Featured movies (slider için)
  List<dynamic> _featuredMovies = [];
  bool _isLoadingFeatured = false;

  // Now Playing
  bool _isLoadingNP = false;
  bool _isLoadingMoreNP = false;
  List<dynamic> _nowPlayingMovies = [];
  int _currentPageNP = 1;
  int _totalPagesNP = 1;
  final ScrollController _scrollControllerNP = ScrollController();

  // Top Rated
  bool _isLoadingTR = false;
  bool _isLoadingMoreTR = false;
  List<dynamic> _topRatedMovies = [];
  int _currentPageTR = 1;
  int _totalPagesTR = 1;
  final ScrollController _scrollControllerTR = ScrollController();

  /// Local search (filtreleme)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchFeaturedMovies();
    _fetchNowPlaying(page: _currentPageNP);
    _fetchTopRated(page: _currentPageTR);

    _scrollControllerNP.addListener(() {
      if (_scrollControllerNP.position.pixels >=
          _scrollControllerNP.position.maxScrollExtent * 0.9) {
        _loadNextPageNowPlaying();
      }
    });
    _scrollControllerTR.addListener(() {
      if (_scrollControllerTR.position.pixels >=
          _scrollControllerTR.position.maxScrollExtent * 0.9) {
        _loadNextPageTopRated();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollControllerNP.dispose();
    _scrollControllerTR.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('favoriteMovies');
    if (savedData != null) {
      final List<dynamic> dataList = jsonDecode(savedData);
      _favoriteMovies = dataList.map((e) => e as Map<String, dynamic>).toList();
    }
    if (widget.langCode == 'tr') {
      await _translateMoviesIfNeeded(_favoriteMovies);
    }
    setState(() {});
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(_favoriteMovies);
    await prefs.setString('favoriteMovies', jsonData);
  }

  void _toggleFavorite(Map<String, dynamic> movie) {
    final movieId = movie['id'];
    final existingIndex =
        _favoriteMovies.indexWhere((element) => element['id'] == movieId);
    setState(() {
      if (existingIndex >= 0) {
        _favoriteMovies.removeAt(existingIndex);
      } else {
        _favoriteMovies.add(movie);
      }
    });
    _saveFavorites();
  }

  bool _isInFavorites(Map<String, dynamic> movie) {
    final movieId = movie['id'];
    return _favoriteMovies.any((element) => element['id'] == movieId);
  }

  /// Featured Movies: Üstte carousel için
  Future<void> _fetchFeaturedMovies() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final url = Uri.parse(
          'https://api.themoviedb.org/3/movie/now_playing?language=en-US&page=1');
      final resp = await http.get(url, headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5ZTAwNDZmNjQzOTJjNDBmMTRiZWI5OWE4NWUxZmFlZCIsIm5iZiI6MTczODY2NTM1OS44ODksInN1YiI6IjY3YTFlZDhmMzgwYjg2YWNkOTAyZmJmZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.Xo_Wp1Soy7TGZx9YAb5XGHg7krqyrPZ8ohhCukAMcP8',
        'accept': 'application/json',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = data['results'] ?? [];
        // İlk 5 filmi "featured" olarak alalım
        List<dynamic> firstFive = results.take(5).toList();
        await _translateMoviesIfNeeded(firstFive);
        setState(() {
          _featuredMovies = firstFive;
        });
      }
    } catch (e) {
      debugPrint('Exception fetching featured movies: $e');
    } finally {
      setState(() => _isLoadingFeatured = false);
    }
  }

  /// Now Playing API
  Future<void> _fetchNowPlaying({int page = 1}) async {
    if (page == 1) {
      setState(() => _isLoadingNP = true);
    } else {
      setState(() => _isLoadingMoreNP = true);
    }
    try {
      final url = Uri.parse(
          'https://api.themoviedb.org/3/movie/now_playing?language=en-US&page=$page');
      final resp = await http.get(url, headers: {
        'Authorization':
            '',
        'accept': 'application/json',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = data['results'] ?? [];
        _totalPagesNP = data['total_pages'] ?? 1;
        await _translateMoviesIfNeeded(results);
        setState(() {
          if (page == 1) {
            _nowPlayingMovies = results;
          } else {
            _nowPlayingMovies.addAll(results);
          }
        });
      }
    } catch (e) {
      debugPrint('Exception now playing: $e');
    } finally {
      if (page == 1) {
        setState(() => _isLoadingNP = false);
      } else {
        setState(() => _isLoadingMoreNP = false);
      }
    }
  }

  void _loadNextPageNowPlaying() {
    if (_isLoadingMoreNP) return;
    if (_currentPageNP >= _totalPagesNP) return;
    _currentPageNP++;
    _fetchNowPlaying(page: _currentPageNP);
  }

  /// Top Rated API
  Future<void> _fetchTopRated({int page = 1}) async {
    if (page == 1) {
      setState(() => _isLoadingTR = true);
    } else {
      setState(() => _isLoadingMoreTR = true);
    }
    try {
      final url = Uri.parse(
          'https://api.themoviedb.org/3/movie/top_rated?language=en-US&page=$page');
      final resp = await http.get(url, headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5ZTAwNDZmNjQzOTJjNDBmMTRiZWI5OWE4NWUxZmFlZCIsIm5iZiI6MTczODY2NTM1OS44ODksInN1YiI6IjY3YTFlZDhmMzgwYjg2YWNkOTAyZmJmZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.Xo_Wp1Soy7TGZx9YAb5XGHg7krqyrPZ8ohhCukAMcP8',
        'accept': 'application/json',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final results = data['results'] ?? [];
        _totalPagesTR = data['total_pages'] ?? 1;
        await _translateMoviesIfNeeded(results);
        setState(() {
          if (page == 1) {
            _topRatedMovies = results;
          } else {
            _topRatedMovies.addAll(results);
          }
        });
      }
    } catch (e) {
      debugPrint('Exception top rated: $e');
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

  /// TR Çevirisi
  Future<void> _translateMoviesIfNeeded(List<dynamic> movieList) async {
    if (widget.langCode == 'tr') {
      for (final item in movieList) {
        final title = item['title'] ?? '';
        final overview = item['overview'] ?? '';
        final tTitle = await googleTranslate(title, 'tr');
        final tOverview = await googleTranslate(overview, 'tr');
        item['title'] = tTitle;
        item['overview'] = tOverview;
      }
    }
  }

  /// Tarih Formatı
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    if (widget.langCode == 'tr') {
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd.MM.yyyy', 'tr_TR').format(date);
      } catch (_) {
        return dateStr;
      }
    } else {
      return dateStr;
    }
  }

  /// Local Search Filtreleme (Title üzerinden)
  List<dynamic> _filterBySearch(List<dynamic> list) {
    if (_searchQuery.isEmpty) return list;
    return list.where((element) {
      final title = (element['title'] ?? '').toLowerCase();
      return title.contains(_searchQuery);
    }).toList();
  }

  Widget _buildFilterRow() {
    final nowPlayingLabel = AppStrings.getText(widget.langCode, 'now_playing');
    final topRatedLabel = AppStrings.getText(widget.langCode, 'top_rated');
    final favoritesLabel = AppStrings.getText(widget.langCode, 'favorites');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
            child: _buildGradientFilterButton(
                MovieMenuOption.nowPlaying, nowPlayingLabel)),
        Expanded(
            child: _buildGradientFilterButton(
                MovieMenuOption.topRated, topRatedLabel)),
        Expanded(
            child: _buildGradientFilterButton(
                MovieMenuOption.favorites, favoritesLabel)),
      ],
    );
  }

  Widget _buildGradientFilterButton(MovieMenuOption option, String label) {
    final isSelected = (_selectedMenu == option);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMenu = option;
          });
          if (option == MovieMenuOption.topRated && _topRatedMovies.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final movieLabel = AppStrings.getText(widget.langCode, 'movies');
    return Scaffold(
      appBar: AppBar(
        title: Text(movieLabel),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildFilterRow(),
          Expanded(
            child: Stack(
              children: [
                _buildContent(),
                if (_selectedMenu == MovieMenuOption.nowPlaying &&
                    _isLoadingMoreNP)
                  _buildBottomLoading(),
                if (_selectedMenu == MovieMenuOption.topRated &&
                    _isLoadingMoreTR)
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

  Widget _buildContent() {
    switch (_selectedMenu) {
      case MovieMenuOption.nowPlaying:
        if (_isLoadingNP) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_nowPlayingMovies.isEmpty) return _buildNoData();
        return _buildNowPlayingView();
      case MovieMenuOption.topRated:
        if (_isLoadingTR) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_topRatedMovies.isEmpty) return _buildNoData();
        return _buildTopRatedView();
      case MovieMenuOption.favorites:
        if (_favoriteMovies.isEmpty) return _buildNoData();
        return _buildFavoritesView();
    }
  }

  Widget _buildNoData() {
    final noDataLabel = AppStrings.getText(widget.langCode, 'no_data_found');
    return Center(child: Text(noDataLabel));
  }

  Widget _buildNowPlayingView() {
    final data = _nowPlayingMovies;
    return _isGrid
        ? _buildMovieGrid(data, _scrollControllerNP)
        : _buildMovieList(data, _scrollControllerNP);
  }

  Widget _buildTopRatedView() {
    final data = _topRatedMovies;
    return _isGrid
        ? _buildMovieGrid(data, _scrollControllerTR)
        : _buildMovieList(data, _scrollControllerTR);
  }

  Widget _buildFavoritesView() {
    final data = _favoriteMovies;
    return _isGrid ? _buildMovieGrid(data, null) : _buildMovieList(data, null);
  }

  /// Grid Görünümü
  Widget _buildMovieGrid(List<dynamic> movies, ScrollController? controller) {
    final filtered = _filterBySearch(movies);
    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.6,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final movie = filtered[index];
        return _buildMovieCard(movie);
      },
    );
  }

  /// List Görünümü
  Widget _buildMovieList(List<dynamic> movies, ScrollController? controller) {
    final filtered = _filterBySearch(movies);
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(8.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final movie = filtered[index];
        return _buildMovieListItem(movie);
      },
    );
  }

  /// Grid Kartı
  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final title = movie['title'] ?? '';
    final posterPath = movie['poster_path'] ?? '';
    final imageUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;
    final bool isFav = _isInFavorites(movie);
    final movieId = movie['id'] ?? '0';
    return InkWell(
      onTap: () {
        final releaseDate = movie['release_date'] ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(
              movieData: movie,
              formattedDate: _formatDate(releaseDate),
              isFavorite: isFav,
              onToggleFavorite: () => _toggleFavorite(movie),
              langCode: widget.langCode,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned.fill(
              child: (imageUrl != null)
                  ? Hero(
                      tag: 'poster_$movieId',
                      child: Image.network(imageUrl, fit: BoxFit.cover),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, size: 50),
                    ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(movie),
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
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

  /// List Elemanı
  Widget _buildMovieListItem(Map<String, dynamic> movie) {
    final title = movie['title'] ?? '';
    final posterPath = movie['poster_path'] ?? '';
    final imageUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;
    final bool isFav = _isInFavorites(movie);
    final movieId = movie['id'] ?? '0';
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () {
          final releaseDate = movie['release_date'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(
                movieData: movie,
                formattedDate: _formatDate(releaseDate),
                isFavorite: isFav,
                onToggleFavorite: () => _toggleFavorite(movie),
                langCode: widget.langCode,
              ),
            ),
          );
        },
        leading: (imageUrl != null)
            ? Hero(
                tag: 'poster_$movieId',
                child: Image.network(imageUrl, width: 50, fit: BoxFit.cover),
              )
            : const Icon(Icons.movie, size: 50),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          onPressed: () => _toggleFavorite(movie),
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.red : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Detay Ekranı (global tema kullanılıyor)
class MovieDetailScreen extends StatefulWidget {
  final Map<String, dynamic> movieData;
  final String formattedDate;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String langCode;
  const MovieDetailScreen({
    super.key,
    required this.movieData,
    required this.formattedDate,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.langCode,
  });
  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late bool _isFav;
  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
  }

  void _handleToggleFavorite() {
    widget.onToggleFavorite();
    setState(() {
      _isFav = !_isFav;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.movieData['title'] ?? '';
    final overview = widget.movieData['overview'] ?? '';
    final backdropPath = widget.movieData['backdrop_path'] ?? '';
    final posterPath = widget.movieData['poster_path'] ?? '';
    final voteAverage = widget.movieData['vote_average']?.toString() ?? '';
    final releaseLabel = AppStrings.getText(widget.langCode, 'release_date');
    final ratingLabel = AppStrings.getText(widget.langCode, 'rating_label');
    final movieId = widget.movieData['id'] ?? '0';
    final backdropUrl = backdropPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$backdropPath'
        : null;
    final posterUrl = posterPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w500$posterPath'
        : null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final infoColor = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  if (backdropUrl != null)
                    Positioned.fill(
                      child: Hero(
                        tag: 'poster_$movieId',
                        child: Image.network(backdropUrl, fit: BoxFit.cover),
                      ),
                    )
                  else if (posterUrl != null)
                    Positioned.fill(
                      child: Hero(
                        tag: 'poster_$movieId',
                        child: Image.network(posterUrl, fit: BoxFit.cover),
                      ),
                    )
                  else
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Center(child: Icon(Icons.movie, size: 50)),
                      ),
                    ),
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
                  Positioned(
                    left: 16,
                    bottom: 16,
                    right: 16,
                    child: Text(
                      title,
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
                              color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.formattedDate.isNotEmpty || voteAverage.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    if (widget.formattedDate.isNotEmpty)
                      Text(
                        "$releaseLabel: ${widget.formattedDate}",
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
