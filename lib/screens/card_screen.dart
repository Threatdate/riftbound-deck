import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  // DB에서 불러온 카드 목록
  List<Map<String, dynamic>> cards = [];

  String selectedSeries = '전체';
  String selectedType = '전체';
  String selectedColor = '전체';
  String searchText = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  // ============================================================
  // 카드 불러오기
  // ============================================================

  Future<void> loadCards() async {
    try {
      final db = await dbHelper.database;

      final savedCards = await db.query(
        'cards',
        orderBy: 'number ASC',
      );

      if (!mounted) return;

      setState(() {
        cards = savedCards.map((card) {
          return {
            'id': card['id'],
            'name': card['name'],
            'number': card['number'],
            'series': card['series'],
            'type': card['type'],
            'color': card['color'],
            'count': card['owned_count'],
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카드 불러오기 오류: $e'),
        ),
      );
    }
  }

  // ============================================================
  // 보유 카드 저장
  // ============================================================

  Future<void> saveCards() async {
    try {
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        for (final card in cards) {
          final String number = card['number'].toString();
          final int count = card['count'] as int;

          await txn.update(
            'cards',
            {
              'owned_count': count,
            },
            where: 'number = ?',
            whereArgs: [number],
          );
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보유 카드가 저장되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
        ),
      );
    }
  }

  // ============================================================
  // 검색 + 필터
  // ============================================================

  List<Map<String, dynamic>> get filteredCards {
    return cards.where((card) {
      final name = card['name'].toString();
      final number = card['number'].toString();
      final series = card['series'].toString();
      final type = card['type'].toString();
      final color = card['color'].toString();

      final matchesSearch =
          searchText.isEmpty ||
              name.toLowerCase().contains(
                searchText.toLowerCase(),
              ) ||
              number.toLowerCase().contains(
                searchText.toLowerCase(),
              );

      final matchesSeries =
          selectedSeries == '전체' ||
              series == selectedSeries;

      final matchesType =
          selectedType == '전체' ||
              type == selectedType;

      final matchesColor =
          selectedColor == '전체' ||
              (selectedColor == '전장' &&
                  color == '무색') ||
              color.split(',').contains(selectedColor);

      return matchesSearch &&
          matchesSeries &&
          matchesType &&
          matchesColor;
    }).toList();
  }

  // ============================================================
  // 속성 색상
  // ============================================================

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

  // ============================================================
  // 드롭다운
  // ============================================================

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
    bool showColors = false,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 55),
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 180,
      ),
      onSelected: onSelected,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showColors && value != '전체') ...[
                    if (value == '전장')
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      ..._getColors(value).map(
                            (color) => Padding(
                          padding:
                          const EdgeInsets.only(
                            right: 3,
                          ),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) {
        return items.map((item) {
          if (showColors && item != '전체') {
            if (item == '전장') {
              return PopupMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              );
            }

            final colors = _getColors(item);

            return PopupMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  ...colors.map(
                        (color) => Padding(
                      padding:
                      const EdgeInsets.only(right: 3),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(item),
                ],
              ),
            );
          }

          return PopupMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList();
      },
    );
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보유 카드 입력'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          // ==================================================
          // 검색 + 필터
          // ==================================================

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: '카드 이름 또는 번호 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    // 세트
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '세트',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDropdown(
                            value: selectedSeries,
                            items: const [
                              '전체',
                              '오리진',
                            ],
                            onSelected: (value) {
                              setState(() {
                                selectedSeries = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 종류
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '종류',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDropdown(
                            value: selectedType,
                            items: const [
                              '전체',
                              '전설',
                              '유닛',
                              '주문',
                              '도구',
                              '룬',
                            ],
                            onSelected: (value) {
                              setState(() {
                                selectedType = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 속성
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '속성',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDropdown(
                            value: selectedColor,
                            items: const [
                              '전체',
                              '분노',
                              '평정',
                              '정신',
                              '신체',
                              '혼돈',
                              '질서',
                              '전장',
                            ],
                            showColors: true,
                            onSelected: (value) {
                              setState(() {
                                selectedColor = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================================================
          // 카드 목록
          // DeckCreateScreen과 동일한 UI
          // ==================================================

          Expanded(
            child: filteredCards.isEmpty
                ? const Center(
              child: Text(
                '조건에 맞는 카드가 없습니다.',
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 16,
              ),
              itemCount: filteredCards.length,
              itemBuilder: (context, index) {
                final card =
                filteredCards[index];

                final count =
                card['count'] as int;

                final type =
                card['type'].toString();

                final cardColor =
                card['color'].toString();

                final colors =
                _getColors(cardColor);

                final isBattlefield =
                    cardColor == '무색';

                final isLegend =
                    type == '전설';

                final isRune =
                    type == '룬';

                return Card(
                  margin:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    // ==================================================
                    // 카드 이름
                    // ==================================================

                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            card['name']
                                .toString(),
                          ),
                        ),

                        if (isLegend)
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              '전설',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),

                        if (isRune)
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              '룬',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),

                        if (isBattlefield)
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              '전장',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // ==================================================
                    // 카드 번호 + 속성
                    // ==================================================

                    subtitle: Row(
                      children: [
                        Text(
                          card['number']
                              .toString(),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        ...colors.map(
                              (color) => Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              right: 3,
                            ),
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration:
                              BoxDecoration(
                                color: color,
                                shape:
                                BoxShape
                                    .circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // 수량 조절
                    // ==================================================

                    trailing: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                          ),
                          onPressed: count > 0
                              ? () {
                            setState(() {
                              card['count']--;
                            });
                          }
                              : null,
                        ),

                        SizedBox(
                          width: 30,
                          child: Center(
                            child: Text(
                              '$count',
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.add,
                          ),
                          onPressed: () {
                            setState(() {
                              card['count']++;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ==================================================
          // 저장 버튼
          // ==================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: saveCards,
                child: const Text(
                  '보유 카드 저장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}