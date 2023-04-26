// ignore: depend_on_referenced_packages
import 'package:cityscope/yelp_features/domain/mod/business.dart';

abstract class BusinessRepository {
  Future<List<Business>> getBusinessList(String term, String location, String sortBy, int limit);
  Future<Business> getBusinessDetailsWithReviews(String businessId);
}