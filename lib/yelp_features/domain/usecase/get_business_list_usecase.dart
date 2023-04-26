import 'package:cityscope/yelp_features/domain/mod/business.dart';

abstract class GetBusinessListUseCase {
  Future<List<Business>> execute(
    String term,
    String location,
    String sortBy,
    int limit,
  );
}