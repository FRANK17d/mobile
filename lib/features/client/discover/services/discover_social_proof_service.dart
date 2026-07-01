import '../../explore/services/explore_service.dart';
import '../../reviews/services/review_service.dart';

class SocialProofItem {
  const SocialProofItem({
    required this.provider,
    required this.review,
    required this.reviewCount,
  });

  final CategoryProvider provider;
  final TechnicianReview review;
  final int reviewCount;

  String get providerName {
    final name = provider.fullName.trim();
    return name.isEmpty ? 'Prestador verificado' : name;
  }

  String get clientName {
    final name = review.clientFirstName?.trim();
    return name == null || name.isEmpty ? 'Cliente verificado' : name;
  }

  String get location {
    final district = provider.districtName?.trim();
    return district == null || district.isEmpty ? 'Zona verificada' : district;
  }

  String get categoryName {
    final category = review.categoryName?.trim();
    return category == null || category.isEmpty
        ? 'Servicio completado'
        : category;
  }

  String get description {
    final bio = provider.bio?.trim();
    if (bio != null && bio.isNotEmpty) return bio;
    final request = review.requestTitle?.trim();
    if (request != null && request.isNotEmpty) return request;
    return 'Prestador verificado por TOKE+ con reseñas de clientes reales.';
  }

  String get quote => review.comment?.trim() ?? '';

  num get rating => provider.avgRating ?? review.rating;

  Map<String, dynamic> toPublicProfileData() {
    return provider.toPublicProfileData(
      serviceName: categoryName,
      serviceDescription: review.requestTitle,
    );
  }
}

class DiscoverSocialProofService {
  DiscoverSocialProofService({ExploreService? explore, ReviewService? reviews})
    : _explore = explore ?? ExploreService(),
      _reviews = reviews ?? ReviewService();

  final ExploreService _explore;
  final ReviewService _reviews;

  Future<List<SocialProofItem>> getReviewBackedItems({
    int maxProviders = 12,
    int maxItems = 6,
  }) async {
    final providers = await _explore.getAllProviders();
    final featuredProviders = providers
        .where((provider) => provider.isVerified)
        .take(maxProviders)
        .toList(growable: false);

    final batches = await Future.wait(
      featuredProviders.map((provider) async {
        final reviews = await _reviews.getTechnicianReviews(provider.id);
        final commentedReviews = reviews.where((review) {
          final comment = review.comment?.trim();
          return comment != null && comment.isNotEmpty;
        });

        return commentedReviews
            .map(
              (review) => SocialProofItem(
                provider: provider,
                review: review,
                reviewCount: reviews.length,
              ),
            )
            .toList(growable: false);
      }),
    );

    final items = batches.expand((batch) => batch).toList(growable: false)
      ..sort((a, b) {
        final aTime =
            a.review.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            b.review.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return items.take(maxItems).toList(growable: false);
  }
}
