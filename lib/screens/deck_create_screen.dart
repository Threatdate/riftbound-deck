import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class DeckCreateScreen extends StatefulWidget {
  const DeckCreateScreen({super.key});

  @override
  State<DeckCreateScreen> createState() => _DeckCreateScreenState();
}

class _DeckCreateScreenState extends State<DeckCreateScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  final TextEditingController deckNameController =
  TextEditingController();

  List<Map<String, dynamic>> cards = [];

  String selectedSeries = '전체';
  String selectedType = '전체';
  String selectedColor = '전체';
  String searchText = '';

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  @override
  void dispose() {
    deckNameController.dispose();
    super.dispose();
  }

  Future<void> loadCards() async {
    final db = await dbHelper.database;

    final result = await db.query(
      'cards',
      orderBy: 'number ASC',
    );

    if (!mounted) return;

    setState(() {
      cards = result.map((card) {
        return {
          'id': card['id'],
          'name': card['name'],
          'number': card['number'],
          'series': card['series'],
          'type': card['type'],
          'color': card['color'],
          'deckCount': 0,
        };
      }).toList();

      isLoading = false;
    });
  }

  int get totalDeckCount {
    return cards.fold<int>(
      0,
          (sum, card) {
        final type = card['type'].toString();
        final color = card['color'].toString();

        if (type == '전설' ||
            type == '룬' ||
            color == '무색') {
          return sum;
        }

        return sum + (card['deckCount'] as int);
      },
    );
  }

  int get totalLegendCount {
    return cards.fold<int>(
      0,
          (sum, card) {
        if (card['type'].toString() == '전설') {
          return sum + (card['deckCount'] as int);
        }

        return sum;
      },
    );
  }

  int get totalRuneCount {
    return cards.fold<int>(
      0,
          (sum, card) {
        if (card['type'].toString() == '룬') {
          return sum + (card['deckCount'] as int);
        }

        return sum;
      },
    );
  }

  int get totalBattlefieldCount {
    return cards.fold<int>(
      0,
          (sum, card) {
        if (card['color'].toString() == '무색') {
          return sum + (card['deckCount'] as int);
        }

        return sum;
      },
    );
  }

  Map<String, dynamic>? get selectedLegend {
    for (final card in cards) {
      if (card['type'].toString() == '전설' &&
          (card['deckCount'] as int) > 0) {
        return card;
      }
    }

    return null;
  }

  List<String> get allowedRuneColors {
    final legend = selectedLegend;

    if (legend == null) {
      return [];
    }

    return legend['color']
        .toString()
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // 선택한 전설의 속성에 맞는 카드인지 확인
  bool isCardColorAllowed(Map<String, dynamic> card) {
    final type = card['type'].toString();
    final color = card['color'].toString();

    // 전설은 속성 제한 대상이 아님
    if (type == '전설') {
      return true;
    }

    // 전장은 무색이므로 속성 제한 대상이 아님
    if (color == '무색') {
      return true;
    }

    // 아직 전설을 선택하지 않았다면 일반 카드는 허용
    if (selectedLegend == null) {
      return true;
    }

    final allowedColors = allowedRuneColors;

    // 일반 카드는 자신의 속성이 전설의 속성 중 하나여야 함
    return allowedColors.contains(color);
  }

  bool isRuneAllowed(Map<String, dynamic> card) {
    if (card['type'].toString() != '룬') {
      return true;
    }

    if (selectedLegend == null) {
      return false;
    }

    final runeColor = card['color'].toString();

    return allowedRuneColors.contains(runeColor);
  }

  List<Map<String, dynamic>> get filteredCards {
    return cards.where((card) {
      final name = card['name'].toString();
      final number = card['number'].toString();
      final series = card['series'].toString();
      final type = card['type'].toString();
      final color = card['color'].toString();

      final matchesSearch =
          searchText.isEmpty ||
              name.contains(searchText) ||
              number.contains(searchText);

      final matchesSeries =
          selectedSeries == '전체' ||
              series == selectedSeries;

      final matchesType =
          selectedType == '전체' ||
              type == selectedType;

      final matchesColor =
          selectedColor == '전체' ||
              (selectedColor == '전장' && color == '무색') ||
              color.split(',').contains(selectedColor);

      return matchesSearch &&
          matchesSeries &&
          matchesType &&
          matchesColor;
    }).toList();
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
                          padding: const EdgeInsets.only(
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
                      padding: const EdgeInsets.only(
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

  void _addCard(Map<String, dynamic> card) {
    final type = card['type'].toString();
    final color = card['color'].toString();
    final currentCount = card['deckCount'] as int;

    // 전설 선택 후 일반 카드의 속성 검사
    if (type != '전설' &&
        type != '룬' &&
        color != '무색' &&
        !isCardColorAllowed(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '선택한 전설의 속성에 맞는 카드만 넣을 수 있습니다.\n'
                '허용 속성: ${allowedRuneColors.join(', ')}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (type != '룬' && currentCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '같은 카드는 최대 3장까지 넣을 수 있습니다.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (type == '전설') {
      if (totalLegendCount >= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '전설은 1장만 넣을 수 있습니다.',
            ),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      setState(() {
        card['deckCount']++;
      });

      return;
    }

    if (type == '룬') {
      if (selectedLegend == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '먼저 전설을 선택해주세요.',
            ),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      if (!isRuneAllowed(card)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '선택한 전설의 속성에 맞는 룬만 넣을 수 있습니다.\n'
                  '허용 속성: ${allowedRuneColors.join(', ')}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      if (totalRuneCount >= 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '룬은 최대 12장까지 넣을 수 있습니다.',
            ),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      setState(() {
        card['deckCount']++;
      });

      return;
    }

    if (color == '무색') {
      if (totalBattlefieldCount >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '전장은 최대 3장까지 넣을 수 있습니다.',
            ),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }

      setState(() {
        card['deckCount']++;
      });

      return;
    }

    if (totalDeckCount >= 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '메인 덱은 최대 40장까지 넣을 수 있습니다.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      card['deckCount']++;
    });
  }

  void _removeCard(Map<String, dynamic> card) {
    if ((card['deckCount'] as int) <= 0) {
      return;
    }

    setState(() {
      card['deckCount']--;
    });
  }

  Future<void> importDeckCode() async {
    String inputCode = '';

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('덱 불러오기'),
          content: TextField(
            maxLines: 6,
            autofocus: true,
            onChanged: (value) {
              inputCode = value;
            },
            decoration: const InputDecoration(
              hintText: '덱 공유 코드를 붙여넣어 주세요.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  inputCode.trim(),
                );
              },
              child: const Text('불러오기'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == null || result.isEmpty) {
      return;
    }

    _applyDeckCode(result);
  }

  void _applyDeckCode(String code) {
    final parts = code.split('|');

    if (parts.isEmpty || parts[0].trim() != 'RB1') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('잘못된 덱 공유 코드입니다.'),
        ),
      );
      return;
    }

    String? importedName;

    final Map<String, int> importedCards = {};

    for (int i = 1; i < parts.length; i++) {
      final part = parts[i].trim();

      if (part.isEmpty) {
        continue;
      }

      if (part.startsWith('NAME=')) {
        try {
          importedName = Uri.decodeComponent(
            part.substring(5),
          );
        } catch (_) {
          importedName = part.substring(5);
        }

        continue;
      }

      final equalIndex = part.indexOf('=');

      if (equalIndex <= 0) {
        continue;
      }

      final number =
      part.substring(0, equalIndex).trim();

      final countText =
      part.substring(equalIndex + 1).trim();

      final count = int.tryParse(countText);

      if (number.isEmpty ||
          count == null ||
          count <= 0) {
        continue;
      }

      importedCards[number] = count;
    }

    if (importedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('불러올 카드가 없습니다.'),
        ),
      );
      return;
    }

    // 기존 카드 수 초기화
    for (final card in cards) {
      card['deckCount'] = 0;
    }

    int importedCount = 0;
    int notFoundCount = 0;

    // 공유 코드의 카드 번호와 DB 카드 번호 비교
    for (final entry in importedCards.entries) {
      final number = entry.key;
      final count = entry.value;

      Map<String, dynamic>? targetCard;

      for (final card in cards) {
        if (card['number'].toString() == number) {
          targetCard = card;
          break;
        }
      }

      if (targetCard == null) {
        notFoundCount++;
        continue;
      }

      targetCard['deckCount'] = count;
      importedCount++;
    }

    // 덱 이름 적용
    if (importedName != null &&
        importedName.trim().isNotEmpty) {
      deckNameController.text =
          importedName.trim();
    }

    if (!mounted) return;

    setState(() {});

    String message =
        '덱을 불러왔습니다.\n'
        '카드 $importedCount종이 적용되었습니다.';

    if (notFoundCount > 0) {
      message +=
      '\n현재 DB에서 찾을 수 없는 카드 '
          '$notFoundCount종이 있습니다.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> saveDeck() async {
    if (isSaving) return;

    final deckName =
    deckNameController.text.trim();

    if (deckName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('덱 이름을 입력해주세요.'),
        ),
      );
      return;
    }

    if (totalLegendCount != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '전설은 정확히 1장이어야 합니다. '
                '현재 $totalLegendCount장입니다.',
          ),
        ),
      );
      return;
    }

    if (totalRuneCount != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '룬은 정확히 12장이어야 합니다. '
                '현재 $totalRuneCount장입니다.',
          ),
        ),
      );
      return;
    }

    if (totalBattlefieldCount != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '전장은 정확히 3장이어야 합니다. '
                '현재 $totalBattlefieldCount장입니다.',
          ),
        ),
      );
      return;
    }

    if (totalDeckCount != 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '메인 덱은 정확히 40장이어야 합니다. '
                '현재 $totalDeckCount장입니다.',
          ),
        ),
      );
      return;
    }

    final selectedCards = cards.where((card) {
      return (card['deckCount'] as int) > 0;
    }).toList();

    // 같은 카드 3장 제한
    final hasOverLimit = selectedCards.any((card) {
      final type = card['type'].toString();

      if (type == '룬') {
        return false;
      }

      return (card['deckCount'] as int) > 3;
    });

    if (hasOverLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '같은 카드는 최대 3장까지 넣을 수 있습니다.',
          ),
        ),
      );
      return;
    }

    // 룬 속성 검사
    final invalidRune = selectedCards.any((card) {
      if (card['type'].toString() != '룬') {
        return false;
      }

      return !isRuneAllowed(card);
    });

    if (invalidRune) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '전설의 속성에 맞지 않는 룬이 포함되어 있습니다.',
          ),
        ),
      );
      return;
    }

    // 일반 카드 속성 검사
    final invalidNormalCard = selectedCards.any((card) {
      final type = card['type'].toString();
      final color = card['color'].toString();

      // 전설, 룬, 전장은 여기서 제외
      if (type == '전설' ||
          type == '룬' ||
          color == '무색') {
        return false;
      }

      return !isCardColorAllowed(card);
    });

    if (invalidNormalCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '전설의 속성에 맞지 않는 일반 카드가 포함되어 있습니다.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        final deckId = await txn.insert(
          'decks',
          {
            'name': deckName,
          },
        );

        for (final card in selectedCards) {
          await txn.insert(
            'deck_cards',
            {
              'deck_id': deckId,
              'card_id': card['id'],
              'count': card['deckCount'],
            },
          );
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('덱이 저장되었습니다.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '덱 저장 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // DeckDetailScreen과 동일한 카운터 UI
  Widget _buildDeckCount({
    required String title,
    required int current,
    required int max,
  }) {
    final isComplete = current == max;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $max',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isComplete
                ? Colors.green
                : Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('덱 생성'),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: deckNameController,
                  decoration: const InputDecoration(
                    labelText: '덱 이름',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '세트',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
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

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '종류',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
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

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '속성',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
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

          // =====================================================
          // 메인 덱 / 전설 / 룬 / 전장 UI
          // DeckDetailScreen과 동일한 UI
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildDeckCount(
                    title: '메인 덱',
                    current: totalDeckCount,
                    max: 40,
                  ),
                ),

                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: _buildDeckCount(
                    title: '전설',
                    current: totalLegendCount,
                    max: 1,
                  ),
                ),

                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: _buildDeckCount(
                    title: '룬',
                    current: totalRuneCount,
                    max: 12,
                  ),
                ),

                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),

                Expanded(
                  child: _buildDeckCount(
                    title: '전장',
                    current: totalBattlefieldCount,
                    max: 3,
                  ),
                ),
              ],
            ),
          ),

          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                if (selectedLegend != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '선택한 전설 속성: '
                          '${allowedRuneColors.join(', ')}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),

                if (selectedLegend != null)
                  const SizedBox(height: 8),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                      isSaving
                          ? null
                          : importDeckCode,
                      icon: const Icon(
                        Icons.download,
                        size: 18,
                      ),
                      label: const Text('불러오기'),
                    ),

                    const SizedBox(width: 8),

                    ElevatedButton(
                      onPressed:
                      isSaving
                          ? null
                          : saveDeck,
                      child: const Text('덱 저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredCards.isEmpty
                ? const Center(
              child: Text(
                '조건에 맞는 카드가 없습니다.',
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.only(
                bottom: 16,
              ),
              itemCount:
              filteredCards.length,
              itemBuilder:
                  (context, index) {
                final card =
                filteredCards[index];

                final deckCount =
                card['deckCount'] as int;

                final type =
                card['type'].toString();

                final cardColor =
                card['color'].toString();

                final colors =
                _getColors(cardColor);

                final isRune =
                    type == '룬';

                final isLegend =
                    type == '전설';

                final isBattlefield =
                    cardColor == '무색';

                final runeAllowed =
                    !isRune ||
                        isRuneAllowed(card);

                final normalCardAllowed =
                    type == '전설' ||
                        type == '룬' ||
                        cardColor == '무색' ||
                        isCardColorAllowed(card);

                final isDisabled =
                    (isRune &&
                        !runeAllowed) ||
                        (!isRune &&
                            !isLegend &&
                            !isBattlefield &&
                            !normalCardAllowed);

                return Card(
                  margin:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
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
                              style:
                              TextStyle(
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
                              style:
                              TextStyle(
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
                              style:
                              TextStyle(
                                fontSize: 12,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),

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
                              (color) =>
                              Padding(
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

                        if (isRune &&
                            !runeAllowed)
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              '전설 속성 불일치',
                              style:
                              TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),

                        if (!isRune &&
                            !isLegend &&
                            !isBattlefield &&
                            !normalCardAllowed)
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              left: 8,
                            ),
                            child: Text(
                              '전설 속성 불일치',
                              style:
                              TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                          ),
                          onPressed:
                          deckCount > 0
                              ? () {
                            _removeCard(
                              card,
                            );
                          }
                              : null,
                        ),

                        SizedBox(
                          width: 30,
                          child: Center(
                            child: Text(
                              '$deckCount',
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
                          icon: Icon(
                            Icons.add,
                            color:
                            isDisabled
                                ? Colors
                                .grey
                                : null,
                          ),
                          onPressed:
                          isDisabled
                              ? null
                              : () {
                            _addCard(
                              card,
                            );
                          },
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
    );
  }
}