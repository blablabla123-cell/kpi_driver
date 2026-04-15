import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../card_density.dart';
import '../cubit/board_view_cubit.dart';
import '../cubit/board_view_state.dart';

class BoardSearchField extends StatefulWidget {
  const BoardSearchField({super.key});

  @override
  State<BoardSearchField> createState() => _BoardSearchFieldState();
}

class _BoardSearchFieldState extends State<BoardSearchField> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BoardViewCubit, BoardViewState>(
      listenWhen: (p, c) =>
          p.searchQuery != c.searchQuery && c.searchQuery.isEmpty,
      listener: (context, state) {
        if (state.searchQuery.isEmpty) {
          _controller.clear();
        }
      },
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        return TextField(
          controller: _controller,
          onChanged: context.read<BoardViewCubit>().setSearchQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            hintText: 'Поиск по названию',
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: state.searchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Сбросить',
                    onPressed: () {
                      _controller.clear();
                      context.read<BoardViewCubit>().clearSearch();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}

class BoardDensityToggle extends StatelessWidget {
  const BoardDensityToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<BoardViewCubit, BoardViewState>(
      builder: (context, state) {
        return SegmentedButton<CardDensity>(
          segments: const [
            ButtonSegment<CardDensity>(
              value: CardDensity.comfortable,
              label: Text('Удобно'),
              icon: Icon(Icons.view_comfy_alt_outlined, size: 18),
            ),
            ButtonSegment<CardDensity>(
              value: CardDensity.compact,
              label: Text('Компакт'),
              icon: Icon(Icons.view_agenda_outlined, size: 18),
            ),
          ],
          selected: {state.cardDensity},
          onSelectionChanged: (s) {
            if (s.isEmpty) return;
            context.read<BoardViewCubit>().setCardDensity(s.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          ),
        );
      },
    );
  }
}
