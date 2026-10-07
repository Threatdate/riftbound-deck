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

  final TextEditingController searchController =
  TextEditingController();

  List<Map<String, dynamic>> cards = [];

  String selectedSeries = '전체';
  String selectedType = '전체';
  String selectedColor = '전체';
  String searchText = '';

  bool isLoading = true;
  bool isSaving = false;

  static const Color backgroundColor = Color(0xFF111318);
  static const Color panelColor = Color(0xFF1B1F27);
  static const Color borderColor = Color(0xFF292E38);
  static const Color secondaryTextColor = Color(0xFF9298A5);

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  @override
  void dispose() {
    deckNameController.dispose();
    searchController.dispose();
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

  bool isCardColorAllowed(Map<String, dynamic> card) {
    final type = card['type'].toString();
    final color = card['color'].toString();

    if (type == '전설') {
      return true;
    }

    if (color == '무색') {
      return true;
    }

    if (selectedLegend == null) {
      return true;
    }

    final allowedColors = allowedRuneColors;

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

  Widget _buildAttributeDots(
      String color, {
        double size = 10,
      }) {
    if (color == '무색') {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      );
    }

    final colors = _getColors(color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((value) {
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: value,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
    bool showColors = false,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      color: panelColor,
      constraints: const BoxConstraints(
        minWidth: 130,
        maxWidth: 190,
      ),
      onSelected: onSelected,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            if (showColors && value != '전체') ...[
              _buildAttributeDots(
                value == '전장' ? '무색' : value,
                size: 11,
              ),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: secondaryTextColor,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<String>(
            value: item,
            child: Row(
              children: [
                if (showColors && item != '전체') ...[
                  _buildAttributeDots(
                    item == '전장' ? '무색' : item,
                    size: 11,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  // ============================================================
  // 필터 초기화
  // ============================================================

  void resetFilters() {
    searchController.clear();

    setState(() {
      selectedSeries = '전체';
      selectedType = '전체';
      selectedColor = '전체';
      searchText = '';
    });
  }

  Widget _buildResetButton() {
    final bool isFiltered =
        selectedSeries != '전체' ||
            selectedType != '전체' ||
            selectedColor != '전체' ||
            searchText.isNotEmpty;

    return SizedBox(
      height: 44,
      width: 44,
      child: IconButton(
        tooltip: '필터 초기화',
        onPressed: isFiltered ? resetFilters : null,
        style: IconButton.styleFrom(
          backgroundColor: panelColor,
          disabledBackgroundColor: panelColor,
          side: const BorderSide(
            color: borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          Icons.refresh,
          size: 19,
          color: isFiltered
              ? Colors.white
              : secondaryTextColor,
        ),
      ),
    );
  }

  void _addCard(Map<String, dynamic> card) {
    final type = card['type'].toString();
    final color = card['color'].toString();
    final currentCount = card['deckCount'] as int;

    if (type != '전설' &&
        type != '룬' &&
        color != '무색' &&
        !isCardColorAllowed(card)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A2E37),
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
          backgroundColor: Color(0xFF2A2E37),
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
            backgroundColor: Color(0xFF2A2E37),
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
            backgroundColor: Color(0xFF2A2E37),
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
            backgroundColor: const Color(0xFF2A2E37),
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
            backgroundColor: Color(0xFF2A2E37),
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
            backgroundColor: Color(0xFF2A2E37),
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
          backgroundColor: Color(0xFF2A2E37),
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
          backgroundColor: panelColor,
          title: const Text(
            '덱 불러오기',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            maxLines: 6,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
            ),
            onChanged: (value) {
              inputCode = value;
            },
            decoration: InputDecoration(
              hintText: '덱 공유 코드를 붙여넣어 주세요.',
              hintStyle: const TextStyle(
                color: secondaryTextColor,
              ),
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: borderColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: borderColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.white24,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
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

    for (final card in cards) {
      card['deckCount'] = 0;
    }

    int importedCount = 0;
    int notFoundCount = 0;

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

    final invalidNormalCard = selectedCards.any((card) {
      final type = card['type'].toString();
      final color = card['color'].toString();

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

  Widget _buildDeckCount({
    required String title,
    required int current,
    required int max,
  }) {
    final isComplete = current == max;
    final progress =
    (current / max).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$current / $max',
            style: TextStyle(
              color: isComplete
                  ? Colors.greenAccent
                  : Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFF303641),
                valueColor:
                AlwaysStoppedAnimation<Color>(
                  isComplete
                      ? Colors.greenAccent
                      : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildDeckCount(
                title: '메인 덱',
                current: totalDeckCount,
                max: 40,
              ),
              Container(
                width: 1,
                height: 55,
                color: borderColor,
              ),
              _buildDeckCount(
                title: '전설',
                current: totalLegendCount,
                max: 1,
              ),
              Container(
                width: 1,
                height: 55,
                color: borderColor,
              ),
              _buildDeckCount(
                title: '룬',
                current: totalRuneCount,
                max: 12,
              ),
              Container(
                width: 1,
                height: 55,
                color: borderColor,
              ),
              _buildDeckCount(
                title: '전장',
                current: totalBattlefieldCount,
                max: 3,
              ),
            ],
          ),
          if (selectedLegend != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.white70,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '전설 속성',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...allowedRuneColors.map(
                        (color) {
                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          right: 10,
                        ),
                        child: Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            _buildAttributeDots(
                              color,
                              size: 9,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              color,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(
      Map<String, dynamic> card,
      ) {
    final deckCount = card['deckCount'] as int;
    final type = card['type'].toString();
    final cardColor = card['color'].toString();

    final isRune = type == '룬';
    final isLegend = type == '전설';
    final isBattlefield = cardColor == '무색';

    final runeAllowed =
        !isRune || isRuneAllowed(card);

    final normalCardAllowed =
        type == '전설' ||
            type == '룬' ||
            cardColor == '무색' ||
            isCardColorAllowed(card);

    final isDisabled =
        (isRune && !runeAllowed) ||
            (!isRune &&
                !isLegend &&
                !isBattlefield &&
                !normalCardAllowed);

    String? restrictionText;

    if (isRune && !runeAllowed) {
      restrictionText = '전설 속성 불일치';
    } else if (!isRune &&
        !isLegend &&
        !isBattlefield &&
        !normalCardAllowed) {
      restrictionText = '전설 속성 불일치';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: deckCount > 0
              ? Colors.white24
              : borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.grey.shade700
                  : deckCount > 0
                  ? Colors.white
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAttributeDots(
                      cardColor,
                      size: 9,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card['name'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDisabled
                              ? Colors.white38
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      card['number'].toString(),
                      style: TextStyle(
                        color: isDisabled
                            ? Colors.white24
                            : secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      card['series'].toString(),
                      style: TextStyle(
                        color: isDisabled
                            ? Colors.white24
                            : secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(5),
                      ),
                      child: Text(
                        isLegend
                            ? '전설'
                            : isRune
                            ? '룬'
                            : isBattlefield
                            ? '전장'
                            : type,
                        style: TextStyle(
                          color: isDisabled
                              ? Colors.white24
                              : secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (restrictionText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    restrictionText,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 34,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.remove,
                      size: 17,
                    ),
                    color: deckCount > 0
                        ? Colors.white
                        : Colors.white24,
                    onPressed: deckCount > 0
                        ? () {
                      _removeCard(card);
                    }
                        : null,
                  ),
                ),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text(
                    '$deckCount',
                    style: TextStyle(
                      color: deckCount > 0
                          ? Colors.white
                          : secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 34,
                  height: 38,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.add,
                      size: 17,
                    ),
                    color: isDisabled
                        ? Colors.white24
                        : Colors.white,
                    onPressed: isDisabled
                        ? null
                        : () {
                      _addCard(card);
                    },
                  ),
                ),
              ],
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
          '덱 생성',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              14,
            ),
            child: Column(
              children: [
                TextField(
                  controller: deckNameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: '덱 이름',
                    labelStyle: const TextStyle(
                      color: secondaryTextColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      color: secondaryTextColor,
                    ),
                    filled: true,
                    fillColor: panelColor,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: searchController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText:
                    '카드 이름 또는 번호 검색',
                    hintStyle: const TextStyle(
                      color: secondaryTextColor,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: secondaryTextColor,
                    ),
                    suffixIcon:
                    searchText.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        searchController
                            .clear();

                        setState(() {
                          searchText =
                          '';
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                        color:
                        secondaryTextColor,
                        size: 19,
                      ),
                    )
                        : null,
                    filled: true,
                    fillColor: panelColor,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: borderColor,
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdown(
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
                    ),
                    const SizedBox(width: 8),
                    _buildResetButton(),
                  ],
                ),
              ],
            ),
          ),

          _buildStatusPanel(),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              10,
            ),
            child: Row(
              children: [
                Text(
                  '카드 ${filteredCards.length}장',
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed:
                  isSaving
                      ? null
                      : importDeckCode,
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: borderColor,
                    ),
                    backgroundColor: panelColor,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(9),
                    ),
                  ),
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    '불러오기',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                  isSaving ? null : saveDeck,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(9),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                    width: 14,
                    height: 14,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                    size: 16,
                  ),
                  label: Text(
                    isSaving ? '저장 중' : '덱 저장',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredCards.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color:
                    secondaryTextColor,
                    size: 42,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '조건에 맞는 카드가 없습니다.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '검색어나 필터 조건을 변경해보세요.',
                    style: TextStyle(
                      color:
                      secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.only(
                bottom: 20,
              ),
              itemCount:
              filteredCards.length,
              itemBuilder:
                  (context, index) {
                return _buildCardItem(
                  filteredCards[index],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}