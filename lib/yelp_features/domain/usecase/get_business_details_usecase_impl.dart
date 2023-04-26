import 'package:cityscope/yelp_features/domain/mod/business.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_details_usecase.dart';
import 'package:cityscope/yelp_features/domain/repository/business_repository.dart';

class GetBusinessDetailsUseCaseImpl implements GetBusinessDetailsUseCase {
  final BusinessRepository repository;

  GetBusinessDetailsUseCaseImpl(this.repository);

  @override
  Future<Business> execute(String businessId) async {
    return await repository.getBusinessDetailsWithReviews(businessId);
  }
}