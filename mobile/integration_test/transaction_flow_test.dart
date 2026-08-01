import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nala/config/api_config.dart';
import 'package:nala/screens/add_transaction_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/wallet_service.dart';
import 'package:nala/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  Map<String, dynamic>? submittedTransaction;
  String? authorization;
  String? idempotencyKey;

  setUpAll(() async {
    expect(
      ApiConfig.baseUrl,
      'http://127.0.0.1:39091/api',
      reason: 'Run with the API_BASE_URL dart-define documented in CI.',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 39091);
    server.listen((request) async {
      if (request.method == 'GET' && request.uri.path == '/api/wallets') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {
              'id': 'wallet-test-1',
              'name': 'Dompet Utama',
              'type': 'EWALLET',
              'balance': 4550000,
            },
          ]));
      } else if (request.method == 'POST' &&
          request.uri.path == '/api/transactions') {
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        idempotencyKey = request.headers.value('Idempotency-Key');
        submittedTransaction =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'transaction': {
              'id': 'transaction-test-1',
              ...submittedTransaction!,
              'date': '2026-08-02T00:00:00.000Z',
            },
            'warning': null,
            'replayed': false,
          }));
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
  });

  setUp(() async {
    submittedTransaction = null;
    authorization = null;
    idempotencyKey = null;
    WalletService.clearCache();
    await TokenStorage.write('integration-access-token');
  });

  tearDownAll(() async {
    await TokenStorage.clear();
    await server.close(force: true);
  });

  testWidgets('user records an expense through the transaction form',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const _TransactionFlowHost(),
      ),
    );

    await tester.tap(find.text('Buka form transaksi'));
    await tester.pumpAndSettle();
    expect(find.text('Dompet Utama'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '125000');
    expect(find.text('125.000'), findsOneWidget);

    await tester.tap(find.text('Pilih Kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Simpan Transaksi'));
    await tester.tap(find.text('Simpan Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Transaksi tersimpan'), findsOneWidget);
    expect(submittedTransaction, {
      'walletId': 'wallet-test-1',
      'type': 'EXPENSE',
      'amount': 125000,
      'categoryId': 'Food',
    });
    expect(authorization, 'Bearer integration-access-token');
    expect(idempotencyKey, startsWith('nala-'));
  });
}

class _TransactionFlowHost extends StatefulWidget {
  const _TransactionFlowHost();

  @override
  State<_TransactionFlowHost> createState() => _TransactionFlowHostState();
}

class _TransactionFlowHostState extends State<_TransactionFlowHost> {
  bool _saved = false;

  Future<void> _openForm() async {
    final saved = await Navigator.of(context).push<bool>(addTransactionRoute());
    if (saved == true && mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _saved
            ? const Text('Transaksi tersimpan')
            : ElevatedButton(
                onPressed: _openForm,
                child: const Text('Buka form transaksi'),
              ),
      ),
    );
  }
}
