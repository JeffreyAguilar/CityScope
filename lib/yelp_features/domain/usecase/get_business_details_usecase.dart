import 'package:cityscope/yelp_features/domain/mod/business.dart';

abstract class GetBusinessDetailsUseCase {
  Future<Business> execute(String businessId);
}