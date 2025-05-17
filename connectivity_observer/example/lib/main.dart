import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_observer/connectivity_observer.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
    // ネットワーク接続状態の監視 (List<ConnectivityResult>)
    final connectivityResults = ref.watch(connectivityResultProvider);

    // 主要なネットワーク接続状態の監視 (単一のConnectivityResult)
    final primaryConnectivity = ref.watch(primaryConnectivityResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App & Network Status')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Network Status (connectivity_plus):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            connectivityResults.when(
              data: (results) {
                if (results.isEmpty ||
                    results.contains(ConnectivityResult.none)) {
                  return const Text('Not connected');
                }
                // List<ConnectivityResult> を表示
                return Text(
                  'Connected via: ${results.map((r) => r.name).join(', ')}',
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 20),
            Text(
              'Primary Network Status:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Current primary connection: ${primaryConnectivity.name}'),
            // 例: 接続状態に基づいて何かを行う
            if (primaryConnectivity == ConnectivityResult.none)
              const Text('No network connection. Please check your settings.'),
          ],
        ),
      ),
    );
  }
}
