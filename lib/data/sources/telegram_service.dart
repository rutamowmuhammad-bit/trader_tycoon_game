// lib/Telegram_service.dart

class TelegramService {
  // Илова энди Телеграмга хабар жўнатмайди (буни сервердаги Node.js бот қилади).

  static Future<bool> sendDepositRequest({
    required String userEmail,
    required String amount,
    required String network,
    required String requestId,
  }) async {
    print("ℹ️ Депозит сўрови базага сақланди. Бот буни ўзи админга етказади.");
    return true;
  }
}
