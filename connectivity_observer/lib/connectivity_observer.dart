import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_observer.g.dart'; // 生成されるファイルを指定

// Connectivityインスタンスを提供するプロバイダ
// これも keepAlive: true にするかどうかはユースケースによりますが、
// 通常は変更されないインスタンスなので true で良いでしょう。
@Riverpod(keepAlive: true)
Connectivity connectivityInstance(Ref ref) {
  return Connectivity();
}

// ネットワーク接続状態を提供するStreamプロバイダ
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivityResult(Ref ref) async* {
  // connectivityInstanceProvider を watch して Connectivity インスタンスを取得
  final connectivity = ref.watch(connectivityInstanceProvider);

  // 初期状態を取得してyield
  yield await connectivity.checkConnectivity();

  // 接続状態の変更を監視し、変更があるたびに新しい状態をyield
  await for (final result in connectivity.onConnectivityChanged) {
    yield result;
  }
}

// (補足) 単一の接続結果に関心がある場合の派生プロバイダ
@Riverpod(keepAlive: true)
ConnectivityResult primaryConnectivityResult(Ref ref) {
  // connectivityResultProvider を watch して非同期データを取得
  final connectivityResultsAsyncValue = ref.watch(connectivityResultProvider);

  return connectivityResultsAsyncValue.when(
    data: (results) {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        return ConnectivityResult.none;
      }
      if (results.contains(ConnectivityResult.wifi)) {
        return ConnectivityResult.wifi;
      }
      if (results.contains(ConnectivityResult.mobile)) {
        return ConnectivityResult.mobile;
      }
      if (results.contains(ConnectivityResult.ethernet)) {
        return ConnectivityResult.ethernet;
      }
      return results.first;
    },
    loading: () => ConnectivityResult.none, // ローディング中はnoneとして扱う例
    error: (err, stack) => ConnectivityResult.none, // エラー時もnoneとして扱う例
  );
}
