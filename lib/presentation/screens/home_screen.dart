import 'profile_menu_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_method_screen.dart';
import 'history_screen.dart';
import 'withdraw_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double balance = 0.0;
  double activeDeposit = 0.0;
  double currentProfit = 0.0;
  String depositStatus = 'none';

  String _timeLeft = "00:00:00";
  String _currentDate = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    _listenToUserDepositStatus();
  }

  void _listenToUserDepositStatus() {
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          double dbBalance = (data['balance'] ?? 0.0).toDouble();
          String status = data['status'] ?? 'none';
          double savedDeposit =
              (data['activeInvestmentAmount'] ?? data['activeDeposit'] ?? 0.0)
                  .toDouble();
          Timestamp? depositTime = data['depositStartTime'];

          // ==========================================
          // ДАГОВОР БУЗИЛИШИНИ ТЕКШИРАМИЗ (АСОСИЙ ХИМОЯ)
          // ==========================================
          // Агар баланс даговор қилинган тариф суммасидан 1 центга бўлса ҳам камайса:
          if (savedDeposit > 0 && dbBalance < savedDeposit) {
            savedDeposit = 0.0; // Тариф нолга тушади
            status = 'none'; // Статус ўчади

            // Буни дарҳол серверга ҳам ёзиб қўямиз, шунда ҳамма нарса соатдек тўхтайди
            _firestore.collection('users').doc(user.uid).update({
              'activeInvestmentAmount': 0,
              'status': 'none',
            });
          }

          setState(() {
            depositStatus = status;
            balance = dbBalance;
          });

          // Таймерни ишлатиш мантиғи
          if (status == 'active' && savedDeposit > 0 && depositTime != null) {
            DateTime startTime = depositTime.toDate();
            DateTime now = DateTime.now();

            int differenceInSeconds = now.difference(startTime).inSeconds;
            int totalDuration = 24 * 3600;

            int currentCycleSeconds = differenceInSeconds % totalDuration;
            int remainingSeconds = totalDuration - currentCycleSeconds;

            activeDeposit = savedDeposit;

            double targetProfitPercent = 0.03;
            currentProfit =
                (savedDeposit * targetProfitPercent / totalDuration) *
                    currentCycleSeconds;

            setState(() {
              balance = dbBalance + currentProfit;
            });

            _startTimerWithSeconds(remainingSeconds, dbBalance);
          } else {
            setState(() {
              activeDeposit = 0.0;
              currentProfit = 0.0;
              _timeLeft = "00:00:00";
            });
            _timer?.cancel();
          }
        }
      });
    }
  }

  void _startTimerWithSeconds(int remainingSeconds, double dbBalance) {
    _timer?.cancel();
    int totalSeconds = remainingSeconds;
    double targetProfitPercent = 0.03;

    double incrementPerSecond =
        (activeDeposit * targetProfitPercent) / (24 * 3600);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (totalSeconds > 0) {
        totalSeconds--;
      } else {
        totalSeconds = 24 * 3600;
      }
      int hours = totalSeconds ~/ 3600;
      int minutes = (totalSeconds % 3600) ~/ 60;
      int seconds = totalSeconds % 60;
      if (mounted) {
        setState(() {
          currentProfit += incrementPerSecond;
          balance = dbBalance + currentProfit;
          _timeLeft =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Инвестициялар',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Профиль ва Менюни очиш тугмаси (Қўшилди)
          IconButton(
            icon:
                const Icon(Icons.person_outline, color: Colors.white, size: 28),
            onPressed: () {
              String currentEmail =
                  _auth.currentUser?.email ?? "email@gmail.com";
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileMenuScreen(userEmail: currentEmail),
                ),
              );
            },
          ),
          // Чиқиш (Logout) тугмаси
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CB050),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currentDate,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.timer,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 5),
                            Text(_timeLeft,
                                style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Умумий баланс',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${balance.toStringAsFixed(6)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('3% / 24с',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  if (depositStatus == 'pending') ...[
                    const SizedBox(height: 10),
                    const Text(
                      '⏳ Депозит тасдиқланиши кутилмоқда...',
                      style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HistoryScreen()));
                          },
                          icon: const Icon(Icons.history, size: 20),
                          label: const Text('История'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WithdrawScreen(
                                    currentBalance: balance,
                                    activeDeposit: activeDeposit),
                              ),
                            );
                          },
                          icon: const Icon(Icons.north_east, size: 18),
                          label: const Text('Вывести'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Инвестиция тарифлари',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTariffCard(
                context: context,
                icon: '⚡️',
                title: 'Бошланғич Қадам',
                dailyPercent: '3.0%',
                dailyProfit: '1.5\$',
                monthlyProfit: '45\$',
                price: 50.0),
            const SizedBox(height: 12),
            _buildTariffCard(
                context: context,
                icon: '🚀',
                title: 'Стандарт Профит',
                dailyPercent: '3.0%',
                dailyProfit: '3.0\$',
                monthlyProfit: '90\$',
                price: 100.0),
            const SizedBox(height: 12),
            _buildTariffCard(
                context: context,
                icon: '💎',
                title: 'Премиум Инвестор',
                dailyPercent: '3.0%',
                dailyProfit: '15.0\$',
                monthlyProfit: '450\$',
                price: 500.0),
            const SizedBox(height: 12),
            _buildTariffCard(
                context: context,
                icon: '👑',
                title: 'VIP Магнат',
                dailyPercent: '3.0%',
                dailyProfit: '30.0\$',
                monthlyProfit: '900\$',
                price: 1000.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTariffCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String dailyPercent,
    required String dailyProfit,
    required String monthlyProfit,
    required double price,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Кунлик $dailyPercent фойда',
                      style: const TextStyle(
                          color: Colors.greenAccent, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Кунлик: $dailyProfit | Ойлик: $monthlyProfit',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CB050),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PaymentMethodScreen(planAmount: price)));
              },
              child: Text('\$$price',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
