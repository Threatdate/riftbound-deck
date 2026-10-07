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
      backgroundColor: const Color(0xFF111318),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'RIFTBOUND',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'DECK MAKER',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '나만의 카드를 관리하고 덱을 만들어보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 40),

                // ① 보유 카드
                _buildMenuCard(
                  context: context,
                  screenWidth: screenWidth,
                  icon: Icons.style_outlined,
                  title: '보유 카드',
                  description: '보유하고 있는 카드를 관리합니다.',
                  accentColor: const Color(0xFF4FC3F7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CardScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ② 덱 리스트
                _buildMenuCard(
                  context: context,
                  screenWidth: screenWidth,
                  icon: Icons.layers_outlined,
                  title: '덱 리스트',
                  description: '내 덱을 만들고 관리합니다.',
                  accentColor: const Color(0xFFFFB74D),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeckScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ③ 부족 카드
                _buildMenuCard(
                  context: context,
                  screenWidth: screenWidth,
                  icon: Icons.inventory_2_outlined,
                  title: '부족 카드 목록',
                  description: '덱을 구성하기 위해 필요한 카드를 확인합니다.',
                  accentColor: const Color(0xFFEF5350),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const ShortageCardScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                Text(
                  'RIFTBOUND DECK',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required double screenWidth,
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: screenWidth * 0.88,
      child: Material(
        color: const Color(0xFF1B1F27),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: accentColor.withOpacity(0.12),
          highlightColor: accentColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF292E38),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade600,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}