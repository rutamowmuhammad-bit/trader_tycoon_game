import 'package:flutter/material.dart';

class ProfileMenuScreen extends StatefulWidget {
  final String userEmail;

  const ProfileMenuScreen({Key? key, required this.userEmail})
      : super(key: key);

  @override
  _ProfileMenuScreenState createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  String selectedLanguage = 'UZ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E222D),
        title: const Text(
          'Меню ва Профил',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. ПРОФИЛЬ БЎЛИМИ (оддий, расмсиз)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userEmail.isNotEmpty
                            ? widget.userEmail
                            : "email@gmail.com",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "✅ Муваффақиятли рўйхатдан ўтган",
                        style:
                            TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. ТИЛНИ ТАНЛАШ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.language, color: Colors.greenAccent),
                    SizedBox(width: 12),
                    Text("Илова тили",
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedLanguage,
                  dropdownColor: const Color(0xFF1E222D),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: ['UZ', 'RU', 'EN'].map((String lang) {
                    return DropdownMenuItem<String>(
                      value: lang,
                      child: Text(lang,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedLanguage = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. ҚЎЛЛАБ-ҚУВВАТЛАШ ЧАТИ
          Card(
            color: const Color(0xFF1E222D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline,
                  color: Colors.greenAccent),
              title: const Text("Қўллаб-қувватлаш чати",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  "Саволларингизни админга тўғридан-тўғри ёзинг",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                // Чат саҳифасига ўтиш
              },
            ),
          ),
          const SizedBox(height: 10),

          // 4. ИЛОВА ҲАҚИДА ВА МАХФИЙЛИК ПОЛИСИ
          Card(
            color: const Color(0xFF1E222D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading:
                  const Icon(Icons.info_outline, color: Colors.greenAccent),
              title: const Text("Илова ҳақида ва Махфийлик сиёсати",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  "Версия: 1.0.0 | Ҳажми: ~25 MB\nИнвестиция платформаси қоидалари.",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 16),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Trader Tycoon Invest",
                  applicationVersion: "1.0.0 (Ҳажми: 25 MB)",
                  applicationLegalese:
                      "© 2026 Барча ҳуқуқлар ҳимояланган. Инвестициявий хавфсизлик қоидалари.",
                  children: [
                    const Text(
                        "Бу илова фойдаланувчиларга қулай шароитда инвестиция киритиш ва фоизларни ҳисоблаш имконини беради."),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
