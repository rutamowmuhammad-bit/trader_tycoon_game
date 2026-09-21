import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'history_screen.dart';

class PaymentAddressScreen extends StatefulWidget {
  final double amount;
  final String network; // TRC-20 ёки BEP-20
  final String walletAddress;

  const PaymentAddressScreen({
    Key? key,
    required this.amount,
    required this.network,
    required this.walletAddress,
  }) : super(key: key);

  @override
  State<PaymentAddressScreen> createState() => _PaymentAddressScreenState();
}

class _PaymentAddressScreenState extends State<PaymentAddressScreen> {
  final String botToken = '8923425875:AAFxFb57_CmvjKiFVLzdZwOtXMWukqHRMMM';
  final String chatId = '-1004421392472';

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // 1. Firebase базасига ва Историяга сақлаш
  Future<void> _processPayment() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String userEmail = user?.email ?? 'Кўрсатилмаган';

      if (user != null) {
        // А) Марказий базага қўшиш ва docId олиш
        DocumentReference docRef =
            await FirebaseFirestore.instance.collection('transactions').add({
          'userId': user.uid,
          'userEmail': userEmail,
          'amount': widget.amount,
          'type': 'deposit',
          'network': widget.network,
          'wallet': widget.walletAddress,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Б) История бўлими учун фойдаланувчи папкасига ёзиш
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .doc(docRef.id) // Бир хил ID ишлатилади
            .set({
          'type': 'Пополнение',
          'amount': widget.amount,
          'network': widget.network,
          'wallet': widget.walletAddress,
          'status': 'В обработке',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // В) Телеграмга ID билан бирга хабар юбориш
        await _sendToTelegram(userEmail, docRef.id);
      }
    } catch (e) {
      print("Firebase хатолиги: $e");
    }
  }

  // 2. Телеграмга хабар юбориш
  Future<void> _sendToTelegram(String userEmail, String docId) async {
    final url = Uri.parse('https://api.telegram.org/bot$botToken/sendMessage');

    DateTime now = DateTime.now();
    String date =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
    String time =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    String message = "📥 *ЯНГИ ДЕПОЗИТ ТАЛАБИ*\n\n"
        "👤 *Фойдаланувчи:* $userEmail\n"
        "💰 *Сумма:* \$${widget.amount}\n"
        "🌐 *Тармоқ:* ${widget.network}\n"
        "💳 *Адрес (боссанг нусхаланади):*\n${widget.walletAddress}\n\n"
        "📅 *Сана:* $date | $time\n"
        "Холат: Кутилмоқда (В обработке)";

    var keyboard = {
      "inline_keyboard": [
        [
          {"text": "✅ ТАСДИҚЛАШ (ОК)", "callback_data": "dep_ok_$docId"},
          {"text": "❌ РАД ЭТИШ (НЕТ)", "callback_data": "dep_no_$docId"}
        ]
      ]
    };

    try {
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chat_id": chatId,
          "text": message,
          "parse_mode": "Markdown",
          "reply_markup": keyboard
        }),
      );
    } catch (e) {
      print("Telegram хатоси: $e");
    }
  }

  void _showAgreementDialog() {
    bool isAgreed = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("⚠️ Шартнома ва Огоҳлантириш",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Сиз \$${widget.amount} миқдорида депозит қилмоқчисиз.\n\nДиққат: Қилинган депозит суммасидан ҳатто 1\$ ҳам камайса, фоиз ишлаши тўхтатилади.",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: isAgreed,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setStateModal(() {
                            isAgreed = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text("Мен шартларга розиман",
                            style:
                                TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Бекор қилиш",
                      style: TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isAgreed ? Colors.green : Colors.grey),
                  onPressed: isAgreed
                      ? () {
                          Navigator.pop(context);
                          _onPaymentCompleted();
                        }
                      : null,
                  child: const Text("Давом этиш",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onPaymentCompleted() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Выполнение",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 12),
              Text("Идет процесс отправки данных, ожидайте завершения операции",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)),
              SizedBox(height: 24),
              LinearProgressIndicator(
                  color: Colors.greenAccent, backgroundColor: Colors.white10),
            ],
          ),
        ),
      ),
    );

    await _processPayment();

    if (mounted) Navigator.pop(context);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Заявка сформирована",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  "Қилинган депозит 3-7 минут ичида ўтади. Агар тармоқда кечикиш бўлса, 24 соат ичида ҳисобингизга автоматик ўтказилади.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 20),
              CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 40)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HistoryScreen()));
                },
                child: const Text("Закрыть вкладку",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.currency_bitcoin,
                      color: Colors.amber, size: 50),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text('\$${widget.amount}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const Text('Сумма пополнения',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('|',
                            style:
                                TextStyle(color: Colors.white24, fontSize: 30)),
                      ),
                      const Column(
                        children: [
                          Text('моментально',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Время обработки',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Чтобы ваш платеж Tether (USDT) ${widget.network} был обработан автоматически:\n\n– Используйте для передачи данных только сеть ${widget.network.contains('TRC') ? 'Tron' : 'BSC'}\n\nНевыполнение одного из требований приведет к потере средств.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Для совершения платежа, отправьте',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${widget.amount} USDT',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16))),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  InkWell(
                    onTap: () => _copyToClipboard(
                        widget.amount.toString(), 'Сумма нусха олинди'),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text('Копировать',
                                style: TextStyle(color: Colors.white70))
                          ]),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
                'на адрес через сеть ${widget.network.contains('TRC') ? 'Tron' : 'BSC'}',
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(widget.walletAddress,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  InkWell(
                    onTap: () => _copyToClipboard(
                        widget.walletAddress, 'Манзил нусха олинди'),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text('Копировать',
                                style: TextStyle(color: Colors.white70))
                          ]),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _showAgreementDialog,
                child: const Text('Тўловни амалга оширдим',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
