import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staj_proje1/screens/restaurant_detail_screen.dart';

const String yelpApiKey =
    'ZQ_Rx1misHRgHM8zil0b6_zdNil0B5OoN8UMBGP_L6EMEXBHysm08arOEgfo9pa4ae5TbH3cKTkZLgUQXQXL5027gJtBHje0khTtiQRmhpRmpNMuMu0wXfbcVEajZ3Yx';

class YelpRestaurantsScreen extends StatefulWidget {
  final String langCode;

  const YelpRestaurantsScreen({super.key, required this.langCode});

  @override
  _YelpRestaurantsScreenState createState() => _YelpRestaurantsScreenState();
}

class _YelpRestaurantsScreenState extends State<YelpRestaurantsScreen> {
  final TextEditingController _locationController = TextEditingController();
  List<dynamic> _restaurants = [];
  bool _isLoading = false;
  Set<String> _favoriteRestaurants = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _fetchRestaurants(String location) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://api.yelp.com/v3/businesses/search?term=restaurants&location=$location&limit=20');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $yelpApiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> businesses = data['businesses'] ?? [];

      // Boş görselleri filtrele
      businesses = businesses.where((restaurant) {
        return restaurant['image_url'] != null && restaurant['image_url'] != '';
      }).toList();

      setState(() {
        _restaurants = businesses;
      });
    } else {
      print('Error: ${response.statusCode}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteRestaurants = prefs.getStringList('favorites')?.toSet() ?? {};
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favoriteRestaurants.toList());
  }

  void _toggleFavorite(String restaurantId) {
    setState(() {
      if (_favoriteRestaurants.contains(restaurantId)) {
        _favoriteRestaurants.remove(restaurantId);
      } else {
        _favoriteRestaurants.add(restaurantId);
      }
    });
    _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final searchHint = widget.langCode == 'tr' ? 'Şehir girin' : 'Enter city';
    final searchButton = widget.langCode == 'tr' ? 'Ara' : 'Search';
    final title = widget.langCode == 'tr' ? 'Restoranlar' : 'Restaurants';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final location = _locationController.text.trim();
                if (location.isNotEmpty) {
                  _fetchRestaurants(location);
                }
              },
              child: Text(searchButton),
            ),
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _restaurants[index];
                        final id = restaurant['id'];
                        final name = restaurant['name'] ?? '';
                        final imageUrl = restaurant['image_url'] ?? '';
                        final rating =
                            restaurant['rating']?.toString() ?? 'N/A';
                        final isFav = _favoriteRestaurants.contains(id);
                        return ListTile(
                          leading: Image.network(imageUrl,
                              width: 60, height: 60, fit: BoxFit.cover),
                          title: Text(name),
                          subtitle: Text("⭐ $rating"),
                          trailing: IconButton(
                            icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : null),
                            onPressed: () => _toggleFavorite(id),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailScreen(
                                  restaurantData: restaurant,
                                  langCode: widget.langCode,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
