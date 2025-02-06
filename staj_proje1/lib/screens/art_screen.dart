import 'package:flutter/material.dart';
import 'package:staj_proje1/screens/movie_screen.dart';
import 'package:staj_proje1/screens/series_screen.dart';
import 'package:staj_proje1/screens/theater_screen.dart';
import 'package:staj_proje1/strings/strings.dart';

class ArtsScreen extends StatelessWidget {
  final String langCode;

  const ArtsScreen({super.key, required this.langCode});

  @override
  Widget build(BuildContext context) {
    // Strings.dart üzerinden dil ayarlı metinler
    final movieLabel = AppStrings.getText(langCode, 'movies');
    final seriesLabel = AppStrings.getText(langCode, 'series');
    final theaterLabel = AppStrings.getText(langCode, 'theater');
    // Alt başlıklar (strings.dart içinde tanımlı olması gerekiyor)
    final movieSubtitle = AppStrings.getText(langCode, 'movie_subtitle');
    final seriesSubtitle = AppStrings.getText(langCode, 'series_subtitle');
    final theaterSubtitle = AppStrings.getText(langCode, 'theater_subtitle');

    return Scaffold(
      // İsterseniz AppBar ekleyebilirsiniz
      // appBar: AppBar(title: Text(AppStrings.getText(langCode, 'art'))),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1) Film Kartı
              _buildArtsCard(
                context,
                icon: Icons.movie,
                title: movieLabel,
                subtitle: movieSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieScreen(langCode: langCode),
                    ),
                  );
                },
              ),
              // 2) Dizi Kartı
              _buildArtsCard(
                context,
                icon: Icons.tv,
                title: seriesLabel,
                subtitle: seriesSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TvScreen(langCode: langCode),
                    ),
                  );
                },
              ),
              // 3) Tiyatro Kartı
              _buildArtsCard(
                context,
                icon: Icons.theaters,
                title: theaterLabel,
                subtitle: theaterSubtitle,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TiyatroScreen(langCode: langCode),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ortak kart widget'ı
  Widget _buildArtsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 130,
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Sol taraftaki ikon (tema renklerine uyumlu)
                Icon(
                  icon,
                  size: 40,
                  color: Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 16),
                // Başlık ve Alt Başlık
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Sağ tarafta küçük bir ok ikonu
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
