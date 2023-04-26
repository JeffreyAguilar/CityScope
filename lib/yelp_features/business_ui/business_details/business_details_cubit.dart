import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:cityscope/yelp_features/domain/usecase/get_business_details_usecase.dart';
import 'package:cityscope/yelp_features/business_ui/business_details/business_details_mapper.dart';
import 'package:cityscope/yelp_features/business_ui/business_details/business_details_ui_model.dart';
import 'package:cityscope/yelp_features/business_ui/business_details/business_details_state.dart';


class BusinessDetailsCubit extends Cubit<BusinessDetailsState> {
  final GetBusinessDetailsUseCase _businessDetailsUseCase;

  BusinessDetailsCubit(this._businessDetailsUseCase)
      : super(BusinessDetailsLoading());

  Future<void> getBusinessDetails({
    required String businessId,
  }) async {
    try {
      emit(BusinessDetailsLoading());
      final business = await _businessDetailsUseCase.execute(businessId);
      emit(BusinessDetailsSuccess(business.toUiModel()));
    } on Exception catch (e) {
      emit(BusinessDetailsError(e.toString())); // TODO
    }
  }
}
