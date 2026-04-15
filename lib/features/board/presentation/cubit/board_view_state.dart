import 'package:equatable/equatable.dart';

import '../card_density.dart';

class BoardViewState extends Equatable {
  const BoardViewState({
    required this.searchQuery,
    required this.cardDensity,
  });

  factory BoardViewState.initial() => const BoardViewState(
        searchQuery: '',
        cardDensity: CardDensity.comfortable,
      );

  final String searchQuery;
  final CardDensity cardDensity;

  bool get isSearchActive => searchQuery.trim().isNotEmpty;

  BoardViewState copyWith({
    String? searchQuery,
    CardDensity? cardDensity,
  }) {
    return BoardViewState(
      searchQuery: searchQuery ?? this.searchQuery,
      cardDensity: cardDensity ?? this.cardDensity,
    );
  }

  @override
  List<Object?> get props => [searchQuery, cardDensity];
}
