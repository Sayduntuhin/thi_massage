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
    return Therapist(
      user: json['therapist_user_id'] as int,
      name: json['therapist_full_name'] as String,
      image: json['therapist_image'].startsWith('/media')
          ? '${ApiService.baseUrl}${json['therapist_image']}'
          : json['therapist_image'] as String,
      assignRole: json['therapist_assign_role'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}