import 'package:thi_massage/api/api_service.dart';

class Therapist {
  final int user;
  final String name;
  final String image;
  final String assignRole;
  final double rating;
  final int reviewCount;

  Therapist({
    required this.user,
    required this.name,
    required this.image,
    required this.assignRole,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    // Handle image URL
    final imagePath = json['therapist_image'] as String? ?? json['image'] as String? ?? '';
    final imageUrl = imagePath.isNotEmpty && (imagePath.startsWith('/media') || imagePath.startsWith('/client/media'))
        ? '${ApiService.baseUrl}$imagePath'
        : imagePath;

    return Therapist(
      user: json['therapist_user_id'] as int? ?? json['user'] as int? ?? 0,
      name: json['therapist_full_name'] as String? ?? json['name'] as String? ?? '',
      image: imageUrl,
      assignRole: json['therapist_assign_role'] as String? ?? json['role'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? json['sessions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user,
    'name': name,
    'image': image,
    'assignRole': assignRole,
    'rating': rating,
    'reviewCount': reviewCount,
  };
}