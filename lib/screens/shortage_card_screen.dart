import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ShortageCardScreen extends StatefulWidget {
  const ShortageCardScreen({super.key});

  @override
  State<ShortageCardScreen> createState() =>
      _ShortageCardScreenState();
}

class _ShortageCardScreenState
    extends State<ShortageCardScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> shortageCards = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadShortageCards();
  }

  Future<void> loadShortageCards() async {
    try {
      final db = await dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT
          cards.id,
          cards.name,
          cards.number,
          cards.series,
          cards.type,
          cards.color,
          cards.owned_count,
          SUM(deck_cards.count) AS required_count
        FROM deck_cards
        INNER JOIN cards
          ON deck_cards.card_id = cards.id
        GROUP BY cards.id
        HAVING SUM(deck_cards.count) > cards.owned_count
        ORDER BY cards.number ASC
        ''',
      );

      if (!mounted) return;

      setState(() {
        shortageCards = result;
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
            '부족 카드 불러오기 오류: $e',
          ),
        ),
      );
    }
  }

  Color _getColor(String color) {
    switch (color) {
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
        return Colors.grey;
    }
  }

  List<Color> _getColors(String color) {
    return color
        .split(',')
        .map(
          (value) => _getColor(value.trim()),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부족 카드 목록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : shortageCards.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 70,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                '부족한 카드가 없습니다.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '현재 저장된 덱을 만들기에 충분한 카드를 보유하고 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '현재 부족한 카드가 ${shortageCards.length}종 있습니다.',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: shortageCards.length,
                itemBuilder:
                    (context, index) {
                  final card =
                  shortageCards[index];

                  final int requiredCount =
                      int.tryParse(
                        card[
                        'required_count']
                            .toString(),
                      ) ??
                          0;

                  final int ownedCount =
                      int.tryParse(
                        card[
                        'owned_count']
                            .toString(),
                      ) ??
                          0;

                  final int shortageCount =
                      requiredCount -
                          ownedCount;

                  return Card(
                    margin:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      child: Row(
                        children: [
                          Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children:
                            _getColors(
                              card['color']
                                  .toString(),
                            ).map(
                                  (color) {
                                return Container(
                                  width: 20,
                                  height: 20,
                                  margin:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color: color,
                                    shape:
                                    BoxShape
                                        .circle,
                                  ),
                                );
                              },
                            ).toList(),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  card['name']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  card['number']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  card['series']
                                      .toString(),
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .end,
                            children: [
                              Text(
                                '필요 $requiredCount장',
                                style:
                                const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                '보유 $ownedCount장',
                                style:
                                const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                '$shortageCount장 부족',
                                style:
                                const TextStyle(
                                  color:
                                  Colors.red,
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}