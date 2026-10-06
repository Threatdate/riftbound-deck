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
        }

        loadedDecks.add({
          'id': deckId,
          'name': deck['name'],
          'cards': deckCards,
          'totalCount': totalCount,
          'shortageCount': shortageCount,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('덱 리스트 비교'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : decks.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 70,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                '저장된 덱이 없습니다.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '덱을 만들어 보유 카드와 비교해보세요.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: createDeck,
                icon: const Icon(Icons.add),
                label: const Text('덱 만들기'),
              ),
            ],
          ),
        )
            : Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              '내 덱',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
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

                  final bool isComplete =
                      shortageCount == 0;

                  return Card(
                    margin:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: InkWell(
                      borderRadius:
                      BorderRadius.circular(12),
                      onTap: () {
                        openDeckDetail(
                          deckId,
                          deckName,
                        );
                      },
                      child: Padding(
                        padding:
                        const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 덱 아이콘
                            Container(
                              width: 50,
                              height: 50,
                              decoration:
                              BoxDecoration(
                                color: Colors
                                    .grey.shade100,
                                borderRadius:
                                BorderRadius
                                    .circular(12),
                              ),
                              child: const Icon(
                                Icons.style_outlined,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 14),

                            // 덱 정보
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Text(
                                    deckName,
                                    style:
                                    const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Text(
                                    '총 $totalCount장',
                                    style:
                                    const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Row(
                                    children: [
                                      Icon(
                                        isComplete
                                            ? Icons
                                            .check_circle
                                            : Icons
                                            .warning_amber_rounded,
                                        size: 18,
                                        color: isComplete
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        isComplete
                                            ? '모든 카드 보유'
                                            : '$shortageCount장 부족',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                          FontWeight.bold,
                                          color: isComplete
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: createDeck,
                icon: const Icon(Icons.add),
                label: const Text(
                  '덱 만들기',
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