import 'package:cityscope/yelp_features/data_model/rest/datasource/business_rest_datasource.dart';
import 'package:cityscope/yelp_features/data_model/rest/mapper/business_rest_mapper';
import 'package:cityscope/yelp_features/data_model/rest/mapper/review_rest_mapper';
import 'package:cityscope/yelp_features/data_model/rest/mod/business_rest_model.dart';
import 'package:cityscope/yelp_features/data_model/rest/mod/review_rest_model.dart';
import 'package:cityscope/yelp_features/domain/mod/business.dart';
import 'package:cityscope/yelp_features/domain/mod/review.dart';
import 'package:cityscope/yelp_features/domain/repository/business_repository.dart';

class BusinessRestRepository implements BusinessRepository {
  final BusinessRestDataSource remoteDataSource;

  BusinessRestRepository(this.remoteDataSource);
  
  @override
  Future<List<Business>> getBusinessList(String term, String location, String sortBy, int limit) async {
    // TODO add try/catch - return Resource<List<Business>>
    BusinessListRestModel response = await remoteDataSource.getBusinessList(
      term,
      location,
      sortBy,
      limit,
    );
    return response.businesses.toDomainModel();
  }

  @override
  Future<Business> getBusinessDetailsWithReviews(String businessId) async {
    // TODO add try/catch - return Resource<List<Review>>
    Future<BusinessRestModel> futureBusinessRestModel = remoteDataSource.getBusinessDetails(businessId);
    Future<ReviewListRestModel> futureReviewListRestModel = remoteDataSource.getBusinessReviews(businessId);
    BusinessRestModel businessRestModel = await futureBusinessRestModel;
    ReviewListRestModel reviewListRestModel = await futureReviewListRestModel;

    Business business = businessRestModel.toDomainModel();
    List<Review> reviews = reviewListRestModel.reviews.toDomainModels();

    return business.copyWith(reviews: reviews);
  }
}