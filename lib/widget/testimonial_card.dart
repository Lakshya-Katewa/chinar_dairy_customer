import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TestimonialCard extends StatelessWidget {
  final String name;
  final String image;
  final String testimonial;
  final double rating;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.image,
    required this.testimonial,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(image),
                onBackgroundImageError: (_, __) {},
                child: const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          rating.floor(),
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        if (rating - rating.floor() > 0)
                          const Icon(
                            Icons.star_half,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ...List.generate(
                          5 - rating.ceil(),
                          (index) => const Icon(
                            Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            testimonial,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppTheme.textColor,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
