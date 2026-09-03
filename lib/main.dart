import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/firebase/firebase_service.dart';
import 'package:safarsure/core/providers/cloud_sync_provider.dart';
import 'package:safarsure/core/router/app_router.dart';
import 'package:safarsure/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const ProviderScope(child: SafarSureApp()));
}

class SafarSureApp extends ConsumerWidget {
  const SafarSureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return CloudSyncHost(
      child: MaterialApp.router(
        title: 'SafarSure',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
  }
}
