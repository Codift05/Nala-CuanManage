import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nala/config/api_config.dart';
import 'package:nala/screens/scan_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/wallet_service.dart';
import 'package:nala/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  Map<String, dynamic>? submittedTransaction;

  setUpAll(() async {
    expect(ApiConfig.baseUrl, 'http://127.0.0.1:39092/api');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 39092);
    server.listen((request) async {
      if (request.method == 'GET' && request.uri.path == '/api/wallets') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {
              'id': 'wallet-receipt-1',
              'name': 'Dompet Receipt',
              'type': 'EWALLET',
              'balance': 500000,
            },
          ]));
      } else if (request.method == 'POST' &&
          request.uri.path == '/api/transactions') {
        submittedTransaction = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'transaction': {
              'id': 'receipt-transaction-1',
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
    WalletService.clearCache();
    await TokenStorage.write('receipt-integration-token');
  });

  tearDownAll(() async {
    await TokenStorage.clear();
    await server.close(force: true);
  });

  testWidgets('user reviews, corrects, and saves a receipt draft',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const _ReceiptFlowHost(),
      ),
    );

    await tester.tap(find.text('Tinjau draft struk'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('AI kurang yakin pada merchant'), findsOneWidget);
    expect(find.text('Estimasi keyakinan AI 55%'), findsOneWidget);
    expect(find.text('Dompet Receipt'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '135000');
    await tester.enterText(find.byType(TextField).at(1), 'Toko Nala Manado');
    await tester.ensureVisible(find.text('Simpan'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt tersimpan'), findsOneWidget);
    expect(submittedTransaction, {
      'walletId': 'wallet-receipt-1',
      'type': 'EXPENSE',
      'amount': 135000,
      'categoryId': 'Shopping',
      'merchant': 'Toko Nala Manado',
      'notes': 'Belanja kebutuhan',
    });
  });
}

class _ReceiptFlowHost extends StatefulWidget {
  const _ReceiptFlowHost();

  @override
  State<_ReceiptFlowHost> createState() => _ReceiptFlowHostState();
}

class _ReceiptFlowHostState extends State<_ReceiptFlowHost> {
  bool _saved = false;

  Future<void> _openReview() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ScanScreen(
          initialDraft: {
            'amount': 125000,
            'merchant': 'Toko Nala',
            'categoryId': 'Shopping',
            'notes': 'Belanja kebutuhan',
            'confidence': {
              'amount': 0.95,
              'merchant': 0.55,
              'categoryId': 0.9,
            },
            'reviewRequired': ['merchant'],
          },
        ),
      ),
    );
    if (saved == true && mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _saved
            ? const Text('Receipt tersimpan')
            : ElevatedButton(
                onPressed: _openReview,
                child: const Text('Tinjau draft struk'),
              ),
      ),
    );
  }
}
