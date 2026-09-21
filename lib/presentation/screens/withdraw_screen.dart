import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawScreen extends StatefulWidget {
  final double currentBalance;
  final double activeDeposit; // Депозит суммасини билиш учун

  const WithdrawScreen({
    Key? key,
    required this.currentBalance,
    required this.activeDeposit,
  }) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String selectedNetwork = 'TRC-20';
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isAgreed = false; // Қоидага розилик белгиси
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submitWithdrawal() async {
    String wallet = _walletController.text.trim();
    String amountText = _amountController.text.trim();

    if (wallet.isEmpty || amountText.isEmpty) {
      _showErrorDialog("Барча майдонларни тўлдиринг!");
      return;
    }

    double? withdrawAmount = double.tryParse(amountText);
    if (withdrawAmount == null || withdrawAmount <= 0) {
      _showErrorDialog("Нотўғри сумма киритилди!");
      return;
    }

    if (withdrawAmount > widget.currentBalance) {
      _showErrorDialog("Балансингизда маблағ етарли эмас!");
      return;
    }

    // Агар выводдан кейинги қолдиқ депозитдан пастга тушиб кетса текшириш
    double remainingBalance = widget.currentBalance - withdrawAmount;
    if (widget.activeDeposit > 0 && remainingBalance < widget.activeDeposit) {
      bool confirm = await _showConfirmationDialog(
          "Диққат! Агар бу суммани ечсангиз, балансингиз депозит миқдоридан (\$${widget.activeDeposit}) пастга тушиб кетади ва фоизлар ишламай қолади. Давом этасизми?");
      if (!confirm) return;
    }

    if (!_isAgreed) {
      _showErrorDialog(
          "Илтимос, шартларга розилик белгисини (галичка) қўйинг!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 1. Реал балансни камайтириш
        double newBalance = widget.currentBalance - withdrawAmount;
        await _firestore.collection('users').doc(user.uid).update({
          'balance': newBalance,
        });

        // 2. МАРКАЗИЙ 'transactions' БАЗАСИГА САҚЛАШ (Бот учун)
        // Бу ерда фойдаланувчининг РЕАЛ Email'и ва кошелек манзили сақланади
        await _firestore.collection('transactions').add({
          'userId': user.uid,
          'userEmail': user.email ?? 'Емайл кўрсатилмаган',
          'amount': withdrawAmount,
          'type': 'withdraw', // Танлов тури: Вывод
          'network': selectedNetwork,
          'wallet': wallet,
          'status': 'pending', // Телеграм ботга 'ОК' тугмаси билан чиқади
          'notified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Фойдаланувчининг шахсий историясига ҳам қўшиш
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'type': 'Вывод',
          'amount': withdrawAmount,
          'network': selectedNetwork,
          'wallet': wallet,
          'status': 'В обработке',
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isLoading = false;
        });

        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog("Хатолик юз берди: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Огоҳлантириш',
            style: TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('ОК', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String message) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Огоҳлантириш',
                style: TextStyle(color: Colors.amber)),
            content:
                Text(message, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Йўқ',
                    style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ҳа, давом этиш',
                    style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF4CB050),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Заявка сформирована',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Заявка на перевод средств успешно сформирована и находится в процессе обработки.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Маблағ 3–7 дақиқада ўтади, кечикса 24 соат ичида ўтади.',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(context); // Ойнани ёпиш
                  Navigator.pop(context); // Асосий экранга қайтиш
                },
                child: const Text(
                  'Закрыть вкладку',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Вывод средств',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ажратилган баланс: \$${widget.currentBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'Выберите сеть',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedNetwork = 'TRC-20'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedNetwork == 'TRC-20'
                            ? const Color(0xFF4CB050)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Tether TRC-20',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedNetwork = 'BEP-20'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selectedNetwork == 'BEP-20'
                            ? const Color(0xFF4CB050)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Tether BEP-20',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              'Адрес кошелька',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _walletController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ҳамён манзилини киритинг...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Сумма вывода',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '0.00 \$',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Розилик галичкаси
            Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  activeColor: const Color(0xFF4CB050),
                  checkColor: Colors.white,
                  onChanged: (val) {
                    setState(() {
                      _isAgreed = val ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'Баланс 50/100/500/1000 дан пастга тушмаслигига ва камайса фоиз ишламаслигига розиман.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CB050),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isLoading ? null : _submitWithdrawal,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Вывести',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
