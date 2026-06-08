import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  int selectedAvatar = 0;
  String username = "Coder Bunny";

  final int gamesWon = 18;
  final int totalGames = 30;

  final TextEditingController usernameController = TextEditingController();

  final List<String> avatars = [
    'assets/players/player1.png',
    'assets/players/player2.png',
    'assets/players/player3.png',
    'assets/players/player4.png',
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedAvatar = prefs.getInt("selectedAvatar") ?? 0;
      username = prefs.getString("username") ?? "Coder Bunny";
      usernameController.text = username;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("selectedAvatar", selectedAvatar);
    await prefs.setString("username", usernameController.text.trim());
    await prefs.setString("selectedDestination", "assets/destinations/zoo.png");
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Settings saved")));

    Navigator.pop(context);
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = gamesWon / totalGames;

    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222A94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF50C9F4)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Choose Character",
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 15),

                      CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage(avatars[selectedAvatar]),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(avatars.length, (index) {
                          final bool isSelected = selectedAvatar == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedAvatar = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: isSelected
                                  ? const EdgeInsets.all(2)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                border: isSelected
                                    ? Border.all(color: Colors.blue, width: 2)
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Opacity(
                                opacity: isSelected ? 1 : 0.6,
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundImage: AssetImage(avatars[index]),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 25),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Username",
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextField(
                        controller: usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter username",
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF222222),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Games Won: $gamesWon/$totalGames",
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF4DA6FF),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F6DFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
