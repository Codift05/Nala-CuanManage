import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nala/config/api_config.dart';
import 'package:nala/screens/nala_chat_screen.dart';
import 'package:nala/services/token_storage.dart';
import 'package:nala/services/wallet_service.dart';
import 'package:nala/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  Map<String, dynamic>? submittedTransaction;
  final chatMessages = <String>[];
  String? chatAuthorization;
  String? transactionAuthorization;
  String? idempotencyKey;

  setUpAll(() async {
    expect(ApiConfig.baseUrl, 'http://127.0.0.1:39093/api');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 39093);
    server.listen((request) async {
      if (request.method == 'POST' && request.uri.path == '/api/chat') {
        chatAuthorization =
            request.headers.value(HttpHeaders.authorizationHeader);
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        chatMessages.add(body['message'] as String);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'reply': 'Aku menyiapkan draft pengeluaran untuk kamu periksa.',
            'fallback': false,
            'transactionDraft': {
              'type': 'EXPENSE',
              'amount': 35000,
              'categoryId': 'Food',
              'walletId': 'wallet-chat-1',
              'merchant': 'Kantin Teknik',
              'notes': 'Makan siang',
            },
          }));
      } else if (request.method == 'GET' &&
          request.uri.path == '/api/wallets') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {
              'id': 'wallet-chat-1',
              'name': 'Dompet Utama',
              'type': 'EWALLET',
              'balance': 500000,
            },
          ]));
      } else if (request.method == 'POST' &&
          request.uri.path == '/api/transactions') {
        transactionAuthorization =
            request.headers.value(HttpHeaders.authorizationHeader);
        idempotencyKey = request.headers.value('Idempotency-Key');
        submittedTransaction = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        request.response
          ..statusCode = HttpStatus.created
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'transaction': {
              'id': 'chat-transaction-1',
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
    chatMessages.clear();
    chatAuthorization = null;
    transactionAuthorization = null;
    idempotencyKey = null;
    WalletService.clearCache();
    await TokenStorage.write('chat-integration-token');
  });

  tearDownAll(() async {
    await TokenStorage.clear();
    await server.close(force: true);
  });

  testWidgets('user can cancel then confirm an AI transaction draft',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const NalaChatScreen(),
      ),
    );

    Future<void> askNala() async {
      await tester.enterText(
          find.byType(TextField), 'Catat makan siang 35 ribu');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Tinjau Draft Nala'), findsOneWidget);
      expect(find.text('35.000'), findsOneWidget);
      expect(find.text('Dompet Utama'), findsOneWidget);
    }

    await askNala();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(submittedTransaction, isNull);
    expect(
      find.text('Draft belum disimpan. Kamu tetap memegang kendali.'),
      findsOneWidget,
    );

    await askNala();
    await tester.ensureVisible(find.text('Konfirmasi & Simpan'));
    await tester.tap(find.text('Konfirmasi & Simpan'));
    await tester.pumpAndSettle();

    expect(chatMessages, [
      'Catat makan siang 35 ribu',
      'Catat makan siang 35 ribu',
    ]);
    expect(submittedTransaction, {
      'walletId': 'wallet-chat-1',
      'type': 'EXPENSE',
      'amount': 35000,
      'categoryId': 'Food',
      'merchant': 'Kantin Teknik',
      'notes': 'Makan siang',
    });
    expect(chatAuthorization, 'Bearer chat-integration-token');
    expect(transactionAuthorization, 'Bearer chat-integration-token');
    expect(idempotencyKey, startsWith('nala-'));
    expect(
      find.text('Transaksinya sudah tersimpan setelah kamu konfirmasi.'),
      findsOneWidget,
    );
  });
}
