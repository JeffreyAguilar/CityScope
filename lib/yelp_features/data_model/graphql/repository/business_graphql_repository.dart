import 'package:cityscope/yelp_features/data_model/graphql/datasource/remote/business_graphql_datasource.dart';
import 'package:cityscope/yelp_features/data_model/graphql/mapper/business_graphql_mapper.dart';
import 'package:cityscope/yelp_features/data_model/graphql/mod/business_graphql_model.dart';
import 'package:cityscope/yelp_features/domain/mod/business.dart';
import 'package:cityscope/yelp_features/domain/repository/business_repository.dart';

class BusinessGraphQLRepository implements BusinessRepository {
  final BusinessGraphQLDataSource remoteDataSource;

  BusinessGraphQLRepository(this.remoteDataSource);

  @override
  Future<List<Business>> getBusinessList(String term, String location, String sortBy, int limit) async {
    // TODO add try/catch - return Resource<List<Business>>
    BusinessListGraphQLModel response = await remoteDataSource.getBusinessList(
      term,
      location,
      sortBy,
      limit,
    );
    return response.businesses.toDomainModel();
  }

  @override
  Future<Business> getBusinessDetailsWithReviews(String businessId) async {
    // TODO add try/catch - return Resource<Business>
    BusinessDetailsGraphQLModel response = await remoteDataSource.getBusinessDetailsWithReviews(businessId);
    return response.business.toDomainModel();
  }
}