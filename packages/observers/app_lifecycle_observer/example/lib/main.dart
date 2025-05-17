import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_lifecycle_observer/app_lifecycle_observer.dart'; // 生成されたプロバイダを含むファイルをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyAppStatusScreenGenerated(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyAppStatusScreenGenerated extends ConsumerWidget {
  const MyAppStatusScreenGenerated({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AppLifecycleStateの監視
    final appLifecycleState = ref.watch(appLifecycleObserverProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'App Lifecycle State: ${appLifecycleState.name}',
              // appLifecycleObserverProviderは直接AppLifecycleStateを返す
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Network Status (connectivity_plus):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 20),
            Text(
              'Primary Network Status:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // 例: ライフサイクル状態に基づいて何かを行う
            if (appLifecycleState == AppLifecycleState.paused)
              const Text('App is paused. Background tasks might be limited.'),
          ],
        ),
      ),
    );
  }
}
