import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle_observer.g.dart'; // 生成されるファイルを指定

@Riverpod(keepAlive: true)
class AppLifecycleObserver extends _$AppLifecycleObserver with WidgetsBindingObserver {
  @override
  AppLifecycleState build() {
    // 初期状態を設定
    // WidgetsBinding.instanceが利用可能であることを確認
    // 通常、buildメソッドが呼ばれる時点では利用可能
    final initialState = WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

    WidgetsBinding.instance.addObserver(this);

    // Notifierが破棄されるときにObserverを解除
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    return initialState;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 状態が変更されたら、新しい状態をセット
    this.state = state;
    super.didChangeAppLifecycleState(state);
  }
}
