import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cityscope/core/const.dart' as Const;
import 'package:cityscope/core/network.dart' as Network;
import 'package:cityscope/yelp_features/data_model/graphql/datasource/remote/business_graphql_datasource.dart';
import 'package:cityscope/yelp_features/data_model/graphql/repository/business_graphql_repository.dart';
import 'package:cityscope/yelp_features/data_model/rest/datasource/business_rest_datasource.dart';
import 'package:cityscope/yelp_features/data_model/rest/repository/business_rest_repository.dart';
import 'package:cityscope/yelp_features/data_model/stub/datasource/local/business_stub_datasource.dart';
import 'package:cityscope/yelp_features/data_model/stub/datasource/repository/business_stub_repository.dart';
import 'package:cityscope/yelp_features/domain/repository/business_repository.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_details_usecase.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_details_usecase_impl.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_list_usecase.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_list_usecase_impl.dart';
import 'package:cityscope/yelp_features/business_ui/business_details/business_details_cubit.dart';
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_bloc.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  await _setupAppConfig();

  switch (Const.DATA_LAYER) {
    case Const.DataLayer.rest:
      _setupRest();
      break;
    case Const.DataLayer.graphql:
      _setupGraphQL();
      break;
    case Const.DataLayer.stub:
      _setupStub();
      break;
  }
}

Future<void> _setupAppConfig() async {
  // API Key
  final String json = await rootBundle.loadString("config/app_config.json");
  final String apiKey = jsonDecode(json)["api_key"];
  getIt.registerSingleton<String>(apiKey, instanceName: Const.NAMED_API_KEY);

  // BLoC/Cubit
  getIt.registerFactory<BusinessListBloc>(() {
    GetBusinessListUseCase getBusinessListUseCase =
        getIt<GetBusinessListUseCase>();
    return BusinessListBloc(getBusinessListUseCase);
  });
  getIt.registerFactory<BusinessDetailsCubit>(() {
    GetBusinessDetailsUseCase getBusinessDetailsUseCase =
        getIt<GetBusinessDetailsUseCase>();
    return BusinessDetailsCubit(getBusinessDetailsUseCase);
  });

  // Use Cases
  getIt.registerLazySingleton<GetBusinessListUseCase>(
      () => GetBusinessListUseCaseImpl(getIt()));
  getIt.registerLazySingleton<GetBusinessDetailsUseCase>(
      () => GetBusinessDetailsUseCaseImpl(getIt()));

  // HTTP Client - used by both REST/GraphQL
  getIt.registerLazySingleton<Network.YelpHttpClient>(
      () => Network.YelpHttpClient());
}

void _setupGraphQL() {
  // GraphQL Client
  getIt.registerLazySingleton<GraphQLClient>(
      () => Network.getGraphQLClient(getIt()));

  // Repository
  getIt.registerLazySingleton<BusinessRepository>(
      () => BusinessGraphQLRepository(getIt()));

  // Data Sources
  getIt.registerLazySingleton<BusinessGraphQLDataSource>(
      () => BusinessGraphQLDataSource(getIt()));
}

void _setupRest() {
  // Repository
  getIt.registerLazySingleton<BusinessRepository>(
      () => BusinessRestRepository(getIt()));

  // Data Source
  getIt.registerLazySingleton<BusinessRestDataSource>(
      () => BusinessRestDataSource(getIt()));
}

void _setupStub() {
  // Repository
  getIt.registerLazySingleton<BusinessRepository>(
      () => BusinessStubRepository(getIt()));

  // Data Source
  getIt.registerLazySingleton<BusinessStubDataSource>(
      () => BusinessStubDataSource());
}
