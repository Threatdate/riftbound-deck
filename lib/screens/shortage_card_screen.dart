
import 'dart:math' as math;

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
  List<String> seriesOptions = ['전체'];

  bool isLoading = true;

  String selectedSeries = '전체';
  String selectedType = '전체';
  String selectedColor = '전체';
  String selectedRarity = '전체';
  String searchText = '';

  final TextEditingController searchController =
  TextEditingController();

  static const List<String> rarityOptions = [
    '전체',
    '커먼',
    '언커먼',
    '레어',
    '에픽',
  ];

  static const Color backgroundColor = Color(0xFF111318);
  static const Color panelColor = Color(0xFF1B1F27);
  static const Color borderColor = Color(0xFF292E38);
  static const Color secondaryTextColor = Color(0xFF9298A5);

  @override
  void initState() {
    super.initState();
    loadShortageCards();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // 부족 카드 및 시리즈 불러오기
  // ============================================================

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
          cards.rarity,
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

      final seriesResult = await db.rawQuery(
        '''
        SELECT DISTINCT series
        FROM cards
        WHERE series IS NOT NULL
          AND TRIM(series) != ''
        ORDER BY series ASC
        ''',
      );

      final loadedSeries = seriesResult
          .map((row) => row['series'].toString())
          .toList();

      if (!mounted) return;

      setState(() {
        shortageCards = result;
        seriesOptions = ['전체', ...loadedSeries];

        if (!seriesOptions.contains(selectedSeries)) {
          selectedSeries = '전체';
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A2F38),
          content: Text('부족 카드 불러오기 오류: $e'),
        ),
      );
    }
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
        .map((value) => _getColor(value.trim()))
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

  // ============================================================
  // 레어리티 도형 색상
  // ============================================================

  Color _getRarityShapeColor(String rarity) {
    switch (rarity) {
      case '커먼':
        return const Color(0xFF9AA0AA);
      case '언커먼':
        return const Color(0xFF64A8FF);
      case '레어':
        return const Color(0xFFBB86FC);
      case '에픽':
        return const Color(0xFFFFC107);
      default:
        return Colors.transparent;
    }
  }

  // ============================================================
  // 레어리티 도형
  // 커먼: 원 / 언커먼: 삼각형
  // 레어: 마름모 / 에픽: 오각형
  // ============================================================

  Widget _buildRarityShape(
      String rarity, {
        double size = 12,
      }) {
    final color = _getRarityShapeColor(rarity);

    switch (rarity) {
      case '커먼':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );

      case '언커먼':
        return CustomPaint(
          size: Size(size, size),
          painter: _RarityShapePainter(
            color: color,
            sides: 3,
          ),
        );

      case '레어':
        return CustomPaint(
          size: Size(size, size),
          painter: _RarityShapePainter(
            color: color,
            sides: 4,
          ),
        );

      case '에픽':
        return CustomPaint(
          size: Size(size, size),
          painter: _RarityShapePainter(
            color: color,
            sides: 5,
          ),
        );

      default:
        return SizedBox(
          width: size,
          height: size,
        );
    }
  }

  // ============================================================
  // 부족 카드 필터링
  // ============================================================

  List<Map<String, dynamic>> get filteredCards {
    final query = searchText.trim().toLowerCase();

    return shortageCards.where((card) {
      final cardName = card['name'].toString();
      final cardNumber = card['number'].toString();
      final cardSeries = card['series'].toString();
      final cardType = card['type'].toString();
      final cardColor = card['color'].toString();
      final cardRarity = card['rarity']?.toString() ?? '';

      final displayType =
      cardColor == '무색' ? '전장' : cardType;

      // 카드 세트 필터
      if (selectedSeries != '전체' &&
          cardSeries != selectedSeries) {
        return false;
      }

      // 카드 종류 필터
      if (selectedType != '전체' &&
          displayType != selectedType) {
        return false;
      }

      // 속성 필터
      if (selectedColor != '전체') {
        final colors = cardColor
            .split(',')
            .map((value) => value.trim())
            .toList();

        if (selectedColor == '전장') {
          if (!colors.contains('무색')) {
            return false;
          }
        } else if (!colors.contains(selectedColor)) {
          return false;
        }
      }

      // 희귀도 필터
      if (selectedRarity != '전체' &&
          cardRarity != selectedRarity) {
        return false;
      }

      // 카드 이름 및 번호 검색
      if (query.isNotEmpty) {
        final matchesName =
        cardName.toLowerCase().contains(query);

        final matchesNumber =
        cardNumber.toLowerCase().contains(query);

        if (!matchesName && !matchesNumber) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // ============================================================
  // 필터 초기화
  // ============================================================

  bool get isFiltered {
    return selectedSeries != '전체' ||
        selectedType != '전체' ||
        selectedColor != '전체' ||
        selectedRarity != '전체' ||
        searchText.isNotEmpty;
  }

  void resetFilters() {
    setState(() {
      selectedSeries = '전체';
      selectedType = '전체';
      selectedColor = '전체';
      selectedRarity = '전체';
      searchText = '';
      searchController.clear();
    });
  }

  // ============================================================
  // 필터 라벨
  // ============================================================

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        bottom: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // 공통 드롭다운
  // ============================================================

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onSelected,
    bool showColors = false,
    bool showRarityShapes = false,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      color: panelColor,
      constraints: const BoxConstraints(
        minWidth: 130,
        maxWidth: 220,
      ),
      onSelected: onSelected,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
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
              const SizedBox(width: 6),
            ],

            if (showRarityShapes && value != '전체') ...[
              _buildRarityShape(
                value,
                size: 12,
              ),
              const SizedBox(width: 6),
            ],

            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: secondaryTextColor,
              size: 18,
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

                if (showRarityShapes && item != '전체') ...[
                  _buildRarityShape(
                    item,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                ],

                Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
  // 필터 UI
  // 첫 번째 줄: 카드 세트 / 카드 종류
  // 두 번째 줄: 속성 / 희귀도
  // ============================================================

  Widget _buildFilters() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterLabel('카드 세트'),
                  _buildDropdown(
                    value: selectedSeries,
                    items: seriesOptions,
                    onSelected: (value) {
                      setState(() {
                        selectedSeries = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterLabel('카드 종류'),
                  _buildDropdown(
                    value: selectedType,
                    items: const [
                      '전체',
                      '전설',
                      '유닛',
                      '주문',
                      '도구',
                      '룬',
                      '전장',
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
          ],
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterLabel('속성'),
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

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterLabel('희귀도'),
                  _buildDropdown(
                    value: selectedRarity,
                    items: rarityOptions,
                    showRarityShapes: true,
                    onSelected: (value) {
                      setState(() {
                        selectedRarity = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // 검색창 + 필터 초기화 버튼
  // ============================================================

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search,
                  color: secondaryTextColor,
                  size: 20,
                ),
                hintText: '카드 이름 또는 번호 검색',
                hintStyle: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                ),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController.clear();

                    setState(() {
                      searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: secondaryTextColor,
                    size: 18,
                  ),
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 44,
          height: 44,
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
              Icons.refresh_rounded,
              size: 19,
              color: isFiltered
                  ? Colors.white
                  : secondaryTextColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 결과 개수
  // ============================================================

  Widget _buildResultCount(int count) {
    return Row(
      children: [
        Text(
          isFiltered
              ? '검색 결과 $count종'
              : '전체 부족 카드 $count종',
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Spacer(),

        if (isFiltered)
          GestureDetector(
            onTap: resetFilters,
            child: const Text(
              '필터 초기화',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // 검색 결과 없음
  // ============================================================

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.search_off,
              size: 28,
              color: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            '조건에 맞는 부족 카드가 없습니다.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '필터나 검색어를 변경해보세요.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          TextButton(
            onPressed: resetFilters,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF292E38),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '필터 초기화',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 부족 카드 아이템
  // ============================================================

  Widget _buildCardItem(Map<String, dynamic> card) {
    final int requiredCount =
        int.tryParse(card['required_count'].toString()) ?? 0;

    final int ownedCount =
        int.tryParse(card['owned_count'].toString()) ?? 0;

    final int shortageCount = requiredCount - ownedCount;

    final String cardName = card['name'].toString();
    final String cardNumber = card['number'].toString();
    final String cardSeries = card['series'].toString();
    final String cardType = card['type'].toString();
    final String cardColor = card['color'].toString();
    final String rarity = card['rarity']?.toString() ?? '';

    final String displayType =
    cardColor == '무색' ? '전장' : cardType;

    final bool hasRarityShape =
        rarityOptions.contains(rarity) && rarity != '전체';

    final colors = _getColors(cardColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          9,
          10,
          9,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF15181E),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colors.map((color) {
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (hasRarityShape) ...[
                        _buildRarityShape(
                          rarity,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                      ],

                      Flexible(
                        child: Text(
                          cardName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _buildTypeBadge(displayType),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        cardNumber,
                        style: const TextStyle(
                          color: secondaryTextColor,
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

                      Flexible(
                        child: Text(
                          cardSeries,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Text(
                        '필요 $requiredCount장',
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '보유 $ownedCount장',
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              constraints: const BoxConstraints(
                minWidth: 54,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$shortageCount장',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 1),

                  const Text(
                    '부족',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 카드 타입 배지
  // ============================================================

  Widget _buildTypeBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF292E38),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // 부족 카드가 없는 경우
  // ============================================================

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),

        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 34,
                    color: Colors.greenAccent,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '부족한 카드가 없습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  child: Text(
                    '현재 저장된 덱을 만들기에 충분한 카드를 보유하고 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 상단 제목
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '부족한 카드',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 3),

        Text(
          '현재 저장된 덱을 기준으로 필요한 카드를 확인하세요.',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 부족 카드 요약
  // ============================================================

  Widget _buildShortageSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 19,
              color: Colors.redAccent,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              '현재 부족한 카드가 ${shortageCards.length}종 있습니다.',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 화면 구성
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final cards = filteredCards;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '부족 카드 목록',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16,
          ),
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : shortageCards.isEmpty
              ? _buildEmptyState()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 10),

              _buildShortageSummary(),

              const SizedBox(height: 10),

              _buildSearchField(),

              const SizedBox(height: 12),

              _buildFilters(),

              const SizedBox(height: 9),

              _buildResultCount(cards.length),

              const SizedBox(height: 7),

              Expanded(
                child: cards.isEmpty
                    ? _buildNoResult()
                    : ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return _buildCardItem(
                      cards[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 등급 도형 그리기
// ============================================================

class _RarityShapePainter extends CustomPainter {
  final Color color;
  final int sides;

  const _RarityShapePainter({
    required this.color,
    required this.sides,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.shortestSide / 2;
    final path = Path();

    for (int i = 0; i < sides; i++) {
      final angle =
          -math.pi / 2 + (2 * math.pi * i / sides);

      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
      covariant _RarityShapePainter oldDelegate,
      ) {
    return oldDelegate.color != color ||
        oldDelegate.sides != sides;
  }
}