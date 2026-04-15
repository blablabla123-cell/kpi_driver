import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/theme/app_theme.dart';
import 'app/theme/theme_cubit.dart';

void main() {
  runApp(BlocProvider(create: (_) => ThemeCubit(), child: const MainApp()));
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
          home: const _HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    final mode = context.select((ThemeCubit c) => c.state.themeMode);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPI Driver'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeCubit>().toggleLightDark(),
            icon: Icon(switch (mode) {
              ThemeMode.dark => Icons.dark_mode_outlined,
              _ => Icons.light_mode_outlined,
            }),
          ),
        ],
      ),
      body: const Center(child: Text('Hello World!')),
    );
  }
}
