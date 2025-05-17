import 'dart:async'; // StreamControllerのため
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';

// テスト対象のプロバイダが定義されているファイルをインポート
import 'package:connectivity_observer/connectivity_observer.dart';

// Mock クラスの定義
class MockConnectivity extends Mock implements Connectivity {}
// AppLifecycleObserverのテストでWidgetsBinding.instanceにアクセスするため
// WidgetsBindingのモックは複雑になるため、ここでは実際のTestWidgetsFlutterBindingを利用
// class MockWidgetsBinding extends Mock implements WidgetsBinding {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConnectivityResult.none);
    registerFallbackValue(<ConnectivityResult>[]);
  });

  group('Connectivity Providers', () {
    late MockConnectivity mockConnectivity;
    late ProviderContainer container;

    setUp(() {
      mockConnectivity = MockConnectivity();
      container = ProviderContainer(
        overrides: [
          connectivityInstanceProvider.overrideWithValue(mockConnectivity),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('connectivityResultProvider', () {
      test(
        'initial state from checkConnectivity, then updates from onConnectivityChanged',
        () async {
          // checkConnectivity の初期値を設定
          when(
            () => mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.wifi]);

          // onConnectivityChanged のストリームを設定
          final streamController = StreamController<List<ConnectivityResult>>();
          when(
            () => mockConnectivity.onConnectivityChanged,
          ).thenAnswer((_) => streamController.stream);

          final emittedValues = <AsyncValue<List<ConnectivityResult>>>[];
          // fireImmediately: true を設定すると、購読開始時の値もコールバックで受け取れる
          final sub = container.listen<AsyncValue<List<ConnectivityResult>>>(
            connectivityResultProvider,
            (previous, next) {
              emittedValues.add(next);
            },
            fireImmediately: true,
          );

          // 初期値 (AsyncLoading -> AsyncData) がemitされるのを待つ
          // `fireImmediately: true` の場合、最初の `AsyncLoading` がすぐに `emittedValues` に入る。
          // その後 `checkConnectivity` の結果が `AsyncData` として入る。
          await container.read(
            connectivityResultProvider.future,
          ); // 初期化が完了するのを待つ

          expect(
            emittedValues,
            isNotEmpty,
            reason:
                "Listener should have received at least one value (loading or initial data)",
          );
          expect(
            emittedValues.last,
            const AsyncData<List<ConnectivityResult>>([
              ConnectivityResult.wifi,
            ]),
            reason: "Initial data should be wifi",
          );

          // ストリームから新しい値をemit
          streamController.add([ConnectivityResult.mobile]);
          await Future.delayed(Duration.zero); // イベントループを1サイクル進めてStreamの値を処理させる
          expect(
            emittedValues.last,
            const AsyncData<List<ConnectivityResult>>([
              ConnectivityResult.mobile,
            ]),
            reason: "Updated data should be mobile",
          );

          streamController.add([ConnectivityResult.none]);
          await Future.delayed(Duration.zero);
          expect(
            emittedValues.last,
            const AsyncData<List<ConnectivityResult>>([
              ConnectivityResult.none,
            ]),
            reason: "Updated data should be none",
          );

          streamController.add([
            ConnectivityResult.wifi,
            ConnectivityResult.mobile,
          ]);
          await Future.delayed(Duration.zero);
          expect(
            emittedValues.last,
            const AsyncData<List<ConnectivityResult>>([
              ConnectivityResult.wifi,
              ConnectivityResult.mobile,
            ]),
            reason: "Updated data should be wifi and mobile",
          );

          await streamController.close();
          sub.close(); // リスナーをクローズ
        },
      );

      test('handles empty initial state from checkConnectivity', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => []);
        // onConnectivityChanged はここでは影響しないが、設定はしておく
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => Stream.value([]));

        // 初期値が解決されるのを待つ
        final result = await container.read(connectivityResultProvider.future);
        expect(
          result,
          <ConnectivityResult>[],
        ); // `List<ConnectivityResult>`が空であることを期待

        // プロバイダの現在の状態も確認
        expect(
          container.read(connectivityResultProvider),
          const AsyncData<List<ConnectivityResult>>([]),
        );
      });

      test('handles error from checkConnectivity', () async {
        final exception = Exception('Failed to check connectivity');
        when(() => mockConnectivity.checkConnectivity()).thenThrow(exception);
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => Stream.empty()); // onConnectivityChangedはエラーに影響しない

        // プロバイダのfutureがエラーで完了することを期待
        await expectLater(
          container.read(connectivityResultProvider.future),
          throwsA(
            predicate(
              (e) =>
                  e is Exception &&
                  e.toString().contains('Failed to check connectivity'),
            ),
          ),
        );

        // プロバイダの現在の状態がAsyncErrorであることを確認
        final currentState = container.read(connectivityResultProvider);
        expect(currentState, isA<AsyncError>());
        expect(currentState.error, exception);
      });

      test('handles error from onConnectivityChanged stream', () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        final streamController = StreamController<List<ConnectivityResult>>();
        when(
          () => mockConnectivity.onConnectivityChanged,
        ).thenAnswer((_) => streamController.stream);

        final emittedValues = <AsyncValue<List<ConnectivityResult>>>[];
        final sub = container.listen<AsyncValue<List<ConnectivityResult>>>(
          connectivityResultProvider,
          (previous, next) {
            emittedValues.add(next);
          },
          fireImmediately: true,
        );

        // 初期値が解決されるのを待つ
        await container.read(connectivityResultProvider.future);
        expect(
          emittedValues.last,
          const AsyncData<List<ConnectivityResult>>([ConnectivityResult.wifi]),
        );

        final streamError = Exception('Stream error');
        streamController.addError(streamError);
        await Future.delayed(Duration.zero); // エラーイベントが処理されるのを待つ

        final lastValue = emittedValues.last;
        expect(
          lastValue,
          isA<AsyncError>(),
          reason: "Last emitted value should be an AsyncError",
        );
        expect(
          lastValue.error,
          streamError,
          reason: "Error in AsyncError should match the streamError",
        );

        await streamController.close();
        sub.close();
      });
    });

    // providers_test.dart の続き

    group('primaryConnectivityResultProvider', () {
      // Helper to setup ProviderContainer with connectivityResultProvider overridden
      // to provide a stream that will result in a specific AsyncValue.
      ProviderContainer setupContainerForPrimaryTest({
        List<ConnectivityResult>? data, // For AsyncData
        Object? error, // For AsyncError
        StackTrace? stackTrace, // For AsyncError
        bool simulateLoading = false, // For AsyncLoading
      }) {
        return ProviderContainer(
          overrides: [
            connectivityResultProvider.overrideWith((ref) {
              if (simulateLoading) {
                // To simulate AsyncLoading, provide a stream that never emits.
                // Or a stream that emits very late, but for testing a non-emitting one is simpler.
                return StreamController<List<ConnectivityResult>>().stream;
              }
              if (error != null) {
                // To simulate AsyncError, provide a stream that emits an error.
                return Stream.error(error, stackTrace ?? StackTrace.current);
              }
              if (data != null) {
                // To simulate AsyncData, provide a stream that emits the data.
                return Stream.value(data);
              }
              // Default case or if no specific simulation is requested,
              // provide an empty stream which will result in AsyncData([]) after loading.
              return Stream.value([]);
            }),
          ],
        );
      }

      test('returns none when connectivityResultProvider is loading', () async {
        // simulateLoading: true で connectivityResultProvider が AsyncLoading 状態を維持するようにする
        final container = setupContainerForPrimaryTest(simulateLoading: true);

        // primaryConnectivityResultProvider は connectivityResultProvider を watch しており、
        // connectivityResultProvider が AsyncLoading の場合、その when句で ConnectivityResult.none を返す
        final result = container.read(primaryConnectivityResultProvider);
        expect(result, ConnectivityResult.none);

        container.dispose();
      });

      test('returns none when connectivityResultProvider has error', () async {
        final testError = Exception('test error');
        final container = setupContainerForPrimaryTest(error: testError);

        // Stream.error を提供した場合、connectivityResultProvider は AsyncError 状態になる。
        // primaryConnectivityResultProvider はその AsyncError を処理し、ConnectivityResult.none を返す。
        // pumpEventQueue を使ってStreamのエラーが処理されるのを待つ
        await pumpEventQueue(); // flutter_test からインポート

        final result = container.read(primaryConnectivityResultProvider);
        expect(result, ConnectivityResult.none);

        container.dispose();
      });

      test(
        'returns correct primary result when connectivityResultProvider has data',
        () async {
          final testCases = <List<ConnectivityResult>, ConnectivityResult>{
            []: ConnectivityResult.none,
            [ConnectivityResult.none]: ConnectivityResult.none,
            [ConnectivityResult.wifi]: ConnectivityResult.wifi,
            [ConnectivityResult.mobile]: ConnectivityResult.mobile,
            [ConnectivityResult.ethernet]: ConnectivityResult.ethernet,
            [ConnectivityResult.bluetooth]: ConnectivityResult.bluetooth,
            [ConnectivityResult.wifi, ConnectivityResult.mobile]:
                ConnectivityResult.wifi,
            [ConnectivityResult.mobile, ConnectivityResult.wifi]:
                ConnectivityResult.wifi,
            [ConnectivityResult.ethernet, ConnectivityResult.mobile]:
                ConnectivityResult.ethernet,
            [ConnectivityResult.bluetooth, ConnectivityResult.mobile]:
                ConnectivityResult.mobile,
          };

          for (final entry in testCases.entries) {
            final container = setupContainerForPrimaryTest(data: entry.key);

            // Stream.value を提供した場合、connectivityResultProvider は AsyncData 状態になる。
            // primaryConnectivityResultProvider はその AsyncData を処理する。
            // pumpEventQueue を使ってStreamの値が処理されるのを待つ
            await pumpEventQueue();

            final actualResult = container.read(
              primaryConnectivityResultProvider,
            );
            expect(actualResult, entry.value, reason: 'For input ${entry.key}');
            container.dispose();
          }
        },
      );

      test(
        'returns first if no specific priority matches but not empty/none (data test)',
        () async {
          final container = setupContainerForPrimaryTest(
            data: [ConnectivityResult.vpn, ConnectivityResult.other],
          );
          await pumpEventQueue();

          final result = container.read(primaryConnectivityResultProvider);
          expect(result, ConnectivityResult.vpn);
          container.dispose();
        },
      );
    });
  });
}
