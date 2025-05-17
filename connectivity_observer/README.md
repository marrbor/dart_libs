# ネットワーク接続状態プロバイダ
StreamProvider に相当するものは、@riverpod アノテーションを付けた async* (ジェネレータ) 関数で簡単に実現できます。これもアプリ全体で利用されることが多いため keepAlive: true を設定します。

- @Riverpod(keepAlive: true) Connectivity connectivityInstance(ConnectivityInstanceRef ref):
    - Connectivity クラスのインスタンスを提供するシンプルなプロバイダです。
    - keepAlive: true を設定しています。
    - 関数名 (connectivityInstance) の末尾に Provider が自動的に付与された名前 (connectivityInstanceProvider) でプロバイダが生成されます。
- @Riverpod(keepAlive: true) Stream<List<ConnectivityResult>> connectivityResult(ConnectivityResultRef ref) async*:
  - async* を使うことで、ストリームを返すプロバイダ (StreamProvider相当) を定義できます。
  - ref.watch(connectivityInstanceProvider) で上で定義した Connectivity インスタンスを取得します。
  - ロジックは以前の StreamProvider の実装と同じです。
  - プロバイダ名は connectivityResultProvider となります。
- @Riverpod(keepAlive: true) ConnectivityResult primaryConnectivityResult(PrimaryConnectivityResultRef ref):
  - connectivityResultProvider の状態を監視し、それを加工して単一の ConnectivityResult を返す同期プロバイダです。
  - 非同期プロバイダ (connectivityResultProvider) の結果を when で処理しています。ローディング中やエラー時のデフォルト値を適切に設定します。
  - プロバイダ名は primaryConnectivityResultProvider となります。
