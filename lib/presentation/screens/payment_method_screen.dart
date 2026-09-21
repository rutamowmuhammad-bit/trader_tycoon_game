import 'package:flutter/material.dart';
import 'deposit_amount_screen.dart';

class PaymentMethodScreen extends StatelessWidget {
  final double planAmount;

  const PaymentMethodScreen({Key? key, required this.planAmount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. TRC-20 карточкаси
            _buildCryptoCard(
              context: context,
              title: 'Tether (USDT) TRC-20',
              network: 'TRC-20',
              minAmount: '\$30',
              time: 'моментально',
              iconColor: Colors.red,
            ),

            const SizedBox(height: 16),

            // 2. BEP-20 (BEP20) карточкаси
            _buildCryptoCard(
              context: context,
              title: 'Tether (USDT) BEP-20',
              network: 'BEP-20',
              minAmount: '\$10',
              time: 'моментально',
              iconColor: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoCard({
    required BuildContext context,
    required String title,
    required String network,
    required String minAmount,
    required String time,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () {
        // Танланган тармоқ (TRC-20 ёки BEP-20) DepositAmountScreen га узатилади
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepositAmountScreen(
              initialAmount: planAmount,
              network: network, // <-- ТАНЛАНГАН ТАРМОҚ УЗАТИЛАДИ
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const Icon(Icons.diamond,
                          color: Colors.tealAccent, size: 40),
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: iconColor,
                        child: const Icon(Icons.currency_bitcoin,
                            size: 10, color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text('Мин.: $minAmount',
                          style: const TextStyle(color: Colors.white70)),
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.white24),
                  Expanded(
                    child: Center(
                      child: Text(time,
                          style: const TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
