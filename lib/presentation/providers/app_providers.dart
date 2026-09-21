import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/user_model.dart';

class AppProvider extends ChangeNotifier {
  UserModel? _currentUser;
  var _balanceSubscription;

  UserModel? get currentUser => _currentUser;

  // Фойдаланувчи тизимга кирганда маълумотларни ва БАЗАДАГИ БАЛАНСНИ тинглаш
  void setUser(String uid, String email) {
    // Аввалги эски тингловчини тўхтатамиз (агар бўлса)
    _balanceSubscription?.cancel();

    // Firestore'даги фойдаланувчи ҳужжатини реал вақтда кузатиб борамиз
    _balanceSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final serverBalance = (data?['balance'] ?? 0.0).toDouble();

        // Моделни яратиш ёки янгилаш
        _currentUser = UserModel(
          uid: uid,
          email: email,
          balance: serverBalance, // <-- Базадан келаётган реал баланс!
        );
        notifyListeners(); // Баланс ўзгариши билан экранни янгилайди
      } else {
        _currentUser = UserModel(
          uid: uid,
          email: email,
          balance: 0.0,
        );
        notifyListeners();
      }
    });
  }

  // Тизимдан чиққанда тинглашни тўхтатиш ва маълумотларни тозалаш
  void clearUser() {
    _balanceSubscription?.cancel();
    _currentUser = null;
    notifyListeners();
  }

  // Балансни қўлда янгилаш учун
  void updateBalance(double newBalance) {
    if (_currentUser != null) {
      _currentUser!.balance = newBalance;
      notifyListeners();
    }
  }
}
