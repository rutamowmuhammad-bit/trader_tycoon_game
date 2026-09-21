import 'dart:convert';
import 'package:http/http.dart' as http;

class TransactionModel {
  final String id;
  final String type; // 'deposit' ёки 'withdraw'
  final double amount;
  final String network;
  final String date;
  final String time;
  String status; // 'В обработке', 'Выполнена', 'Отклонена'

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.network,
    required this.date,
    required this.time,
    required this.status,
  });
}

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // Real tranzaksiyalar ro'yxati
  final List<TransactionModel> transactions = [];

  void addTransaction(TransactionModel tx) {
    transactions.insert(0, tx);
  }

  // Telegram bot orqali tugma bosilganda statusni yangilash
  Future<void> checkTelegramUpdates(
      String botToken, Function() onUpdated) async {
    try {
      final url = Uri.parse('https://api.telegram.org/bot$botToken/getUpdates');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          List updates = data['result'];
          for (var update in updates) {
            if (update.containsKey('callback_query')) {
              String callbackData = update['callback_query']['data'];

              if (callbackData.startsWith('dep_ok_')) {
                for (var tx in transactions) {
                  if (tx.status == 'В обработке' && tx.type == 'deposit') {
                    tx.status = 'Выполнена';
                  }
                }
                onUpdated();
              } else if (callbackData.startsWith('dep_no_')) {
                for (var tx in transactions) {
                  if (tx.status == 'В обработке' && tx.type == 'deposit') {
                    tx.status = 'Отклонена';
                  }
                }
                onUpdated();
              }
            }
          }
        }
      }
    } catch (e) {
      print("Telegram polling error: $e");
    }
  }
}
