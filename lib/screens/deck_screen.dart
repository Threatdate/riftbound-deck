import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'deck_create_screen.dart';
import 'deck_detail_screen.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> decks = [];

  bool isLoading = true;

  static const Color backgroundColor = Color(0xFF111318);
  static const Color panelColor = Color(0xFF1B1F27);
  static const Color borderColor = Color(0xFF292E38);
  static const Color secondaryTextColor = Color(0xFF9298A5);

  @override
  void initState() {
    super.initState();

    loadDecks();
  }

  Future<void> loadDecks() async {
    try {
      final db = await dbHelper.database;

      final savedDecks = await db.query(
        'decks',
        orderBy: 'id ASC',
      );

      final List<Map<String, dynamic>> loadedDecks = [];

      for (final deck in savedDecks) {
        final int deckId = deck['id'] as int;

        final deckCards = await db.rawQuery(
          '''
          SELECT
            cards.name,
            cards.number,
            cards.series,
            cards.type,
            cards.color,
            cards.owned_count,
            deck_cards.count
          FROM deck_cards
          INNER JOIN cards
            ON deck_cards.card_id = cards.id
          WHERE deck_cards.deck_id = ?
          ORDER BY cards.number ASC
          ''',
          [deckId],
        );

        int totalCount = 0;
        int shortageCount = 0;

        // 전설 속성
        String legendColor = '';

        for (final card in deckCards) {
          final int need =
              int.tryParse(
                card['count'].toString(),
              ) ??
                  0;

          final int owned =
              int.tryParse(
                card['owned_count'].toString(),
              ) ??
                  0;

          totalCount += need;

          if (need > owned) {
            shortageCount += need - owned;
          }

          if (card['type'].toString() == '전설' &&
              need > 0) {
            legendColor =
                card['color'].toString();
          }
        }

        loadedDecks.add({
          'id': deckId,
          'name': deck['name'],
          'cards': deckCards,
          'totalCount': totalCount,
          'shortageCount': shortageCount,
          'legendColor': legendColor,
        });
      }

      if (!mounted) return;

      setState(() {
        decks = loadedDecks;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '덱 불러오기 오류: $e',
          ),
        ),
      );
    }
  }

  // 덱 만들기
  Future<void> createDeck() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeckCreateScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadDecks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('덱이 저장되었습니다.'),
        ),
      );
    }
  }

  // 덱 상세 화면
  Future<void> openDeckDetail(
      int deckId,
      String deckName,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailScreen(
          deckId: deckId,
          deckName: deckName,
        ),
      ),
    );

    if (!mounted) return;

    await loadDecks();
  }

  Color _getAttributeColor(String attribute) {
    switch (attribute.trim()) {
      case '분노':
        return Colors.red;

      case '평정':
        return Colors.green;

      case '정신':
        return Colors.blue;

      case '신체':
        return Colors.orange;

      case '혼돈':
        return Colors.purple;

      case '질서':
        return Colors.amber;

      case '무색':
        return Colors.grey;

      default:
        return const Color(0xFF555B66);
    }
  }

  List<Color> _getLegendColors(String legendColor) {
    if (legendColor.isEmpty) {
      return [
        const Color(0xFF555B66),
        const Color(0xFF3A3F49),
      ];
    }

    final colors = legendColor
        .split(',')
        .map(
          (value) => value.trim(),
    )
        .where(
          (value) => value.isNotEmpty,
    )
        .map(_getAttributeColor)
        .toList();

    if (colors.isEmpty) {
      return [
        const Color(0xFF555B66),
        const Color(0xFF3A3F49),
      ];
    }

    if (colors.length == 1) {
      return [
        colors[0],
        colors[0],
      ];
    }

    return [
      colors[0],
      colors[1],
    ];
  }

  Widget _buildLegendIcon(String legendColor) {
    final colors = _getLegendColors(legendColor);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF252A33),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 첫 번째 속성
          Positioned(
            left: 7,
            top: 9,
            child: Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: colors[0],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // 두 번째 속성
          Positioned(
            right: 7,
            bottom: 9,
            child: Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: colors[1],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors[1].withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // 가운데 장식
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF171A20),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '덱 리스트',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20,
        ),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        )
            : decks.isEmpty
            ? _buildEmptyState()
            : _buildDeckList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.layers_outlined,
              size: 40,
              color: Color(0xFF7E8795),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '저장된 덱이 없습니다.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '덱을 만들어 보유 카드와 비교해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: createDeck,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2A2F39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.add,
                size: 21,
              ),
              label: const Text(
                '덱 만들기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 2,
            bottom: 14,
          ),
          child: Text(
            '내 덱',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 4,
            ),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];

              final int deckId =
              deck['id'] as int;

              final String deckName =
              deck['name'].toString();

              final int totalCount =
              deck['totalCount'] as int;

              final int shortageCount =
              deck['shortageCount'] as int;

              final String legendColor =
              deck['legendColor'].toString();

              final bool isComplete =
                  shortageCount == 0;

              return _buildDeckCard(
                deckId: deckId,
                deckName: deckName,
                totalCount: totalCount,
                shortageCount: shortageCount,
                isComplete: isComplete,
                legendColor: legendColor,
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: createDeck,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF252A33),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 23,
            ),
            label: const Text(
              '새 덱 만들기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard({
    required int deckId,
    required String deckName,
    required int totalCount,
    required int shortageCount,
    required bool isComplete,
    required String legendColor,
  }) {
    final Color statusColor = isComplete
        ? const Color(0xFF66BB6A)
        : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            openDeckDetail(
              deckId,
              deckName,
            );
          },
          splashColor:
          Colors.white.withOpacity(0.04),
          highlightColor:
          Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // 전설 속성 아이콘
                _buildLegendIcon(legendColor),

                const SizedBox(width: 16),

                // 덱 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        deckName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '총 $totalCount장',
                            style: TextStyle(
                              color:
                              Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 보유 카드 상태
                      Row(
                        children: [
                          Icon(
                            isComplete
                                ? Icons
                                .check_circle_rounded
                                : Icons
                                .warning_amber_rounded,
                            size: 17,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isComplete
                                ? '모든 카드 보유'
                                : '$shortageCount장 부족',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade600,
                  size: 27,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}