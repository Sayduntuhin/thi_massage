// In models/therapist_model.dart
class Therapist {
  final int user; // Maps to user (main identifier)
  final String name; // Maps to full_name
  final String image; // Fallback for missing image
  final double rating;
  final int reviewCount; // Fallback for total_booked
  final String assignRole; // Maps to assign_role

  Therapist({
    required this.user,
    required this.name,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.assignRole,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      user: json['user'] as int? ?? 0, // Use user as main ID, fallback to 0
      name: json['full_name'] as String? ?? 'Unknown Therapist', // Fallback for null full_name
      image: json['image'] ?? 'https://randomuser.me/api/portraits/men/${json['user'] ?? 0}.jpg', // Fallback image using user ID
      rating: double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0, // Handle null rating
      reviewCount: json['total_booked'] as int? ?? 0, // Fallback for total_booked
      assignRole: json['assign_role'] as String? ?? '', // Fallback to empty string
    );
  }
}