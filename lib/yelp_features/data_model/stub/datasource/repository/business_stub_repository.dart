import 'package:cityscope/yelp_features/data_model/graphql/mapper/business_graphql_mapper.dart';
import 'package:cityscope/yelp_features/data_model/graphql/mod/business_graphql_model.dart';
import 'package:cityscope/yelp_features/data_model/stub/datasource/local/business_stub_datasource.dart';
import 'package:cityscope/yelp_features/domain/mod/business.dart';
import 'package:cityscope/yelp_features/domain/repository/business_repository.dart';

// For simplicity, the BusinessStubDataSource uses the GraphQL data and models
class BusinessStubRepository implements BusinessRepository {
  final BusinessStubDataSource localDataSource;

  BusinessStubRepository(this.localDataSource);

  @override
  Future<List<Business>> getBusinessList(String term, String location, String sortBy, int limit) async {
    BusinessListGraphQLModel response = await localDataSource.getBusinessList();
    return response.businesses.toDomainModel();
  }

  @override
  Future<Business> getBusinessDetailsWithReviews(String businessId) async {
    BusinessDetailsGraphQLModel response = await localDataSource.getBusinessDetails();
    return response.business.toDomainModel();
  }
}