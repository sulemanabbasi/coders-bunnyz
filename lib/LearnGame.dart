import 'package:flutter/material.dart';

class LearnGame extends StatefulWidget {
  const LearnGame({super.key});

  @override
  State<LearnGame> createState() => _LearnGameState();
}

class _LearnGameState extends State<LearnGame> {
  final PageController pageController = PageController();

  int currentIndex = 0;

  // IMAGES
  final List<String> images = [
    'assets/learngame/pausedgame.png',
    'assets/learngame/gameboard.png',
    'assets/learngame/options.png',
    'assets/learngame/cards.png',
    'assets/learngame/selectcard.png',
    'assets/learngame/previousmoves.png',
  ];

  // NEXT
  void goNext() {
    if (currentIndex < images.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),

        curve: Curves.easeInOut,
      );
    }
  }

  // PREVIOUS
  void goPrev() {
    if (currentIndex > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),

        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B3C),

      body: SafeArea(
        child: Stack(
          children: [
            // BACK BUTTON
            Positioned(
              top: 20,
              left: 20,

              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),

            // MAIN CONTENT
            Column(
              children: [
                const SizedBox(height: 80),

                // TITLE
                const Text(
                  "Learn Game Screen",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // SLIDER
                Expanded(
                  child: Stack(
                    children: [
                      // PAGE VIEW
                      PageView.builder(
                        controller: pageController,

                        itemCount: images.length,

                        onPageChanged: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },

                        itemBuilder: (context, index) {
                          return Center(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,

                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),

                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),

                                borderRadius: BorderRadius.circular(20),

                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),

                                child: Image.asset(
                                  images[index],

                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // LEFT ARROW
                      if (currentIndex > 0)
                        Positioned(
                          left: 10,
                          top: MediaQuery.of(context).size.height * 0.3,

                          child: GestureDetector(
                            onTap: goPrev,

                            child: Container(
                              padding: const EdgeInsets.all(6),

                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),

                      // RIGHT ARROW
                      if (currentIndex < images.length - 1)
                        Positioned(
                          right: 10,
                          top: MediaQuery.of(context).size.height * 0.3,

                          child: GestureDetector(
                            onTap: goNext,

                            child: Container(
                              padding: const EdgeInsets.all(6),

                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // DOTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: List.generate(images.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      margin: const EdgeInsets.symmetric(horizontal: 5),

                      width: currentIndex == index ? 12 : 8,
                      height: currentIndex == index ? 12 : 8,

                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.grey,

                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
