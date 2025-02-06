import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:staj_proje1/strings/strings.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final String langCode;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantData,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final name = restaurantData['name'] ?? 'Unknown';
    final imageUrl = restaurantData['image_url'] ?? '';
    final rating = restaurantData['rating']?.toString() ?? 'N/A';
    final reviewCount = restaurantData['review_count'] ?? 0;
    final address =
        (restaurantData['location']?['display_address'] as List?)?.join(', ') ??
            'No address';
    final phone = restaurantData['display_phone'] ?? 'No phone';
    final menuUrl = restaurantData['attributes']?['menu_url'];
    final categories = (restaurantData['categories'] as List?)
            ?.map((cat) => cat['title'])
            .join(', ') ??
        'N/A';

    final bool isOpen = _getIsOpen(restaurantData);
    final List<String> businessHours = _getBusinessHours(restaurantData);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restoran Kapak Resmi
            imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                    width: double.infinity, height: 250, fit: BoxFit.cover)
                : Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 80),
                  ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restoran İsmi & Puan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(rating),
                          Text(
                            " ($reviewCount ${AppStrings.getText(langCode, 'reviews')})",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Kategoriler
                  Text(
                    "${AppStrings.getText(langCode, 'categories')}: $categories",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Adres & Harita
                  _buildInfoRow(
                    icon: Icons.location_on,
                    text: address,
                    onTap: () => _openMap(address),
                  ),
                  const SizedBox(height: 8),
                  // Telefon & Arama
                  _buildInfoRow(
                    icon: Icons.phone,
                    text: phone,
                    onTap: () => _callNumber(phone),
                  ),
                  const SizedBox(height: 8),
                  // Açık mı Kapalı mı?
                  _buildOpenStatus(isOpen),
                  const SizedBox(height: 16),
                  // Çalışma Saatleri
                  _buildBusinessHoursSection(businessHours),
                  const SizedBox(height: 16),
                  // Menü Butonu
                  if (menuUrl != null)
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _openYelpPage(menuUrl),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_menu,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.getText(langCode, 'view_menu'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **İşletme Açık mı Kapalı mı?**
  Widget _buildOpenStatus(bool isOpen) {
    return Row(
      children: [
        Icon(
          isOpen ? Icons.check_circle : Icons.cancel,
          color: isOpen ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          isOpen
              ? AppStrings.getText(langCode, 'open_now')
              : AppStrings.getText(langCode, 'closed'),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// **Çalışma Saatlerini Gösterme**
  Widget _buildBusinessHoursSection(List<String> hours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getText(langCode, 'business_hours'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...hours
            .map((hour) => Text(hour, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  /// **Bilgi Satırı (Adres, Telefon vs.)**
  Widget _buildInfoRow(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  /// **Restoran Açık mı Kapalı mı?**
  bool _getIsOpen(Map<String, dynamic> restaurantData) {
    final List<dynamic>? businessHours = restaurantData['business_hours'];
    return (businessHours != null && businessHours.isNotEmpty)
        ? (businessHours[0]['is_open_now'] ?? false)
        : false;
  }

  /// **Çalışma Saatlerini Formatlı Çek**
  List<String> _getBusinessHours(Map<String, dynamic> restaurantData) {
    final List<dynamic>? businessHoursList = restaurantData['business_hours'];

    if (businessHoursList == null || businessHoursList.isEmpty) {
      return ['No business hours available'];
    }

    final List<dynamic>? openHours = businessHoursList[0]['open'];

    if (openHours == null || openHours.isEmpty) {
      return ['No business hours available'];
    }

    final List<String> days = [
      AppStrings.getText(langCode, 'monday'),
      AppStrings.getText(langCode, 'tuesday'),
      AppStrings.getText(langCode, 'wednesday'),
      AppStrings.getText(langCode, 'thursday'),
      AppStrings.getText(langCode, 'friday'),
      AppStrings.getText(langCode, 'saturday'),
      AppStrings.getText(langCode, 'sunday')
    ];

    return openHours.map((day) {
      final start = _formatTime(day['start']);
      final end = _formatTime(day['end']);
      return "${days[day['day']]}: $start - $end";
    }).toList();
  }

  /// **Saat Formatını Düzelt**
  String _formatTime(String? time) {
    if (time == null || time.length != 4) return 'N/A';
    final hours = time.substring(0, 2);
    final minutes = time.substring(2);
    return "$hours:$minutes";
  }

  /// **Google Haritalarda Aç**
  void _openMap(String address) async {
    final Uri url =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$address");
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      return;
    }
    debugPrint('Could not open map');
  }

  /// **Telefon Araması Yap**
  void _callNumber(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      return;
    }
    debugPrint('Could not call number');
  }

  /// **Menü Linkini Aç**
  /// **Menü Linkini Aç**
  void _openYelpPage(String? menuUrl) async {
    if (menuUrl == null || menuUrl.isEmpty) {
      debugPrint("No menu URL provided.");
      return;
    }

    final Uri url = Uri.parse(menuUrl);

    if (await canLaunchUrl(url)) {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Tarayıcıda açmayı zorunlu yap
      );
      if (!launched) {
        debugPrint('Could not launch Yelp menu page.');
      }
    } else {
      debugPrint('Could not open menu page: $menuUrl');
    }
  }
}
