import 'package:flutter/material.dart';
import 'payment_address_screen.dart';

class DepositAmountScreen extends StatefulWidget {
  final double initialAmount;
  final String network; // TRC-20 ёки BEP-20

  const DepositAmountScreen({
    Key? key,
    required this.initialAmount,
    this.network = 'TRC-20',
  }) : super(key: key);

  @override
  State<DepositAmountScreen> createState() => _DepositAmountScreenState();
}

class _DepositAmountScreenState extends State<DepositAmountScreen> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(0)
          : '50',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _proceedToAddress() {
    double enteredAmount = double.tryParse(_amountController.text) ?? 50.0;

    // =========================================================================
    // 🔴 БУ ЕРГА ЎЗИНГИЗНИНГ РЕАЛ КРИПТО АДРЕСЛАРИНГИЗНИ ЁЗИНГ:
    // =========================================================================
    String trc20Address =
        'TV9C1aB37bCL9Tea7qrKaFjRbf39sKhiBm'; // TRC-20 Address
    String bep20Address =
        '0xace5fe0bfc035281b18e5de2fe82967d030c875a'; // BEP-20 Address
    // =========================================================================

    // Танланган тармоққа қараб манзилни ажратиб олиш
    String walletAddress = widget.network.toUpperCase().contains('BEP')
        ? bep20Address
        : trc20Address;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentAddressScreen(
          amount: enteredAmount,
          network: widget.network,
          walletAddress: walletAddress,
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Сумма пополнения',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите сумму',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
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
              'Быстрый выбор',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['\$50', '\$100', '\$500', '\$1000'].map((amount) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _amountController.text = amount.replaceAll('\$', '');
                    });
                  },
                  child:
                      Text(amount, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _proceedToAddress,
                child: const Text(
                  'Продолжить',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
