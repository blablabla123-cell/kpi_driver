import 'package:flutter_bloc/flutter_bloc.dart';

import '../card_density.dart';
import 'board_view_state.dart';

class BoardViewCubit extends Cubit<BoardViewState> {
  BoardViewCubit() : super(BoardViewState.initial());

  void setSearchQuery(String query) => emit(state.copyWith(searchQuery: query));

  void clearSearch() => emit(state.copyWith(searchQuery: ''));

  void setCardDensity(CardDensity density) =>
      emit(state.copyWith(cardDensity: density));
}
