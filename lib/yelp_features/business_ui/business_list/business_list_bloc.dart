import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_list_usecase.dart';
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_mapper.dart';
import 'package:cityscope/yelp_features/business_ui/business_list/business_list_ui_model.dart';

part 'business_list_event.dart';
part 'business_list_state.dart';

class BusinessListBloc extends Bloc<BusinessListEvent, BusinessListState> {
  final GetBusinessListUseCase _businessListUseCase;

  BusinessListBloc(this._businessListUseCase) : super(BusinessListLoading());

  @override
  Stream<BusinessListState> mapEventToState(BusinessListEvent event) async* {
    if (event is GetBusinessList) {
      try {
        yield (BusinessListLoading());
        final businesses = await _businessListUseCase.execute(
          event.term,
          event.location,
          event.sortBy,
          event.limit,
        );
        yield (BusinessListSuccess(businesses.toUiModels()));
      } on Exception catch (e) {
        yield (BusinessListError(e.toString())); // TODO
      }
    }
  }
}