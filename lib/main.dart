import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/theme/app_theme.dart';
import 'app/theme/theme_cubit.dart';
import 'core/api/api_client.dart';
import 'core/api/api_config.dart';
import 'features/board/data/repository/indicators_repository_impl.dart';
import 'features/board/domain/usecases/fetch_tasks.dart';
import 'features/board/domain/usecases/save_task_field.dart';
import 'features/board/presentation/cubit/board_cubit.dart';
import 'features/board/presentation/cubit/board_view_cubit.dart';
import 'features/board/presentation/kanban_board_screen.dart';

void main() {
  final apiClient = ApiClient(config: ApiConfig.dev);
  final repo = IndicatorsRepositoryImpl(apiClient);
  final fetchTasks = FetchTasks(repo);
  final saveTaskField = SaveTaskField(repo);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => BoardViewCubit()),
        BlocProvider(
          create: (_) => BoardCubit(fetchTasks, saveTaskField)..load(),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          home: const KanbanBoardScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
