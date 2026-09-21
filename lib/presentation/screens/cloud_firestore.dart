import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createTransaction({
  required double amount,
  required String type, // <-- Бот учун муҳим: 'deposit' ёки 'withdraw'
  required String network, // <-- Масалан: 'TRC-20' ёки 'BEP-20'
  required String walletAddress, // <-- Фойдаланувчининг ҳамён манзили
}) async {
  try {
    // 1. Ҳозирги тизимга кирган фойдаланувчини аниқлаймиз
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Фойдаланувчи тизимга кирмаган!");
      return;
    }

    // 2. Firestore'да янги транзакция яратиш
    final docRef = FirebaseFirestore.instance.collection('transactions').doc();

    // 3. Марказий базага транзакцияни ёзиш (Бот шуни ўқийди)
    await docRef.set({
      'transactionId': docRef.id,
      'userId': user.uid, // Бот шу орқали одамни адашмай топади
      'userEmail': user.email ?? 'Кўрсатилмаган',
      'amount': amount,
      'type': type, // Бот шунга қараб + ёки - қилади
      'network': network, // Телеграмда кўрсатилади
      'wallet': walletAddress, // Телеграмда кўрсатилади
      'status': 'pending', // Ҳолати: кутилмоқда
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 4. Фойдаланувчининг ўзи учун "История" га ҳам ёзиб қўямиз (Иловада кўриниши учун)
    String displayTitle = (type == 'deposit') ? 'Пополнение' : 'Вывод';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc(docRef.id) // Бот билан бир хил ID бўлиши шарт!
        .set({
      'type': displayTitle,
      'amount': amount,
      'network': network,
      'status': 'В обработке', // Иловада шундай кўриниб туради
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("Транзакция ва ҳамён манзиллари базага муваффақиятли сақланди!");
  } catch (e) {
    print("Хатолик юз берди: $e");
  }
}
