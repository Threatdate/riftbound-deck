import 'package:flutter/material.dart';
import 'card_screen.dart';
import 'deck_screen.dart';
import 'shortage_card_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riftbound Deck'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ① 보유 카드 입력
            SizedBox(
              width: screenWidth * 0.6,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const CardScreen(),
                    ),
                  );
                },
                child: const Text(
                  '① 보유 카드 입력',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ② 덱 리스트 비교
            SizedBox(
              width: screenWidth * 0.6,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const DeckScreen(),
                    ),
                  );
                },
                child: const Text(
                  '② 덱 리스트 비교',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ③ 부족 카드 목록
            SizedBox(
              width: screenWidth * 0.6,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const ShortageCardScreen(),
                    ),
                  );
                },
                child: const Text(
                  '③ 부족 카드 목록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}