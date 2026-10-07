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

  String selectedType = '전체';
  String selectedColor = '전체';
  String searchText = '';

  final TextEditingController searchController =
  TextEditingController();

  static const Color backgroundColor =
  Color(0xFF111318);

  static const Color panelColor =
  Color(0xFF1B1F27);

  static const Color borderColor =
  Color(0xFF292E38);

  static const Color secondaryTextColor =
  Color(0xFF9298A5);

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
          backgroundColor: const Color(0xFF2A2F38),
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
          (value) => _getColor(
        value.trim(),
      ),
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
          margin: const EdgeInsets.only(
            right: 3,
          ),
          decoration: BoxDecoration(
            color: value,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> get filteredCards {
    final query =
    searchText.trim().toLowerCase();

    return shortageCards.where((card) {
      final cardType =
      card['type'].toString();

      final cardColor =
      card['color'].toString();

      String displayType = cardType;

      if (cardColor == '무색') {
        displayType = '전장';
      }

      if (selectedType != '전체' &&
          displayType != selectedType) {
        return false;
      }

      if (selectedColor != '전체') {
        final colors = cardColor
            .split(',')
            .map(
              (value) => value.trim(),
        )
            .toList();

        if (selectedColor == '전장') {
          if (!colors.contains('무색')) {
            return false;
          }
        } else {
          if (!colors.contains(
            selectedColor,
          )) {
            return false;
          }
        }
      }

      if (query.isNotEmpty) {
        final name = card['name']
            .toString()
            .toLowerCase();

        final number = card['number']
            .toString()
            .toLowerCase();

        if (!name.contains(query) &&
            !number.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void resetFilters() {
    setState(() {
      selectedType = '전체';
      selectedColor = '전체';
      searchText = '';
      searchController.clear();
    });
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
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius:
          BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          children: [
            if (showColors &&
                value != '전체') ...[
              _buildAttributeDots(
                value == '전장'
                    ? '무색'
                    : value,
                size: 11,
              ),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Text(
                value,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons
                  .keyboard_arrow_down_rounded,
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
                if (showColors &&
                    item != '전체') ...[
                  _buildAttributeDots(
                    item == '전장'
                        ? '무색'
                        : item,
                    size: 11,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  item,
                  style:
                  const TextStyle(
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

  Widget _buildFilters() {
    return Row(
      children: [
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
              '전장',
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
    );
  }

  Widget _buildResetButton() {
    final bool isFiltered =
        selectedType != '전체' ||
            selectedColor != '전체' ||
            searchText.isNotEmpty;

    return SizedBox(
      height: 44,
      width: 44,
      child: IconButton(
        tooltip: '필터 초기화',
        onPressed: isFiltered
            ? resetFilters
            : null,
        style: IconButton.styleFrom(
          backgroundColor: panelColor,
          disabledBackgroundColor:
          panelColor,
          side: const BorderSide(
            color: borderColor,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
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
          padding:
          const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16,
          ),
          child: isLoading
              ? const Center(
            child:
            CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : shortageCards.isEmpty
              ? _buildEmptyState()
              : Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(
                height: 10,
              ),
              _buildShortageSummary(),
              const SizedBox(
                height: 10,
              ),
              _buildSearchField(),
              const SizedBox(
                height: 8,
              ),
              _buildFilters(),
              const SizedBox(
                height: 9,
              ),
              _buildResultCount(
                cards.length,
              ),
              const SizedBox(
                height: 7,
              ),
              Expanded(
                child: cards.isEmpty
                    ? _buildNoResult()
                    : ListView.builder(
                  padding:
                  const EdgeInsets
                      .only(
                    bottom: 8,
                  ),
                  itemCount:
                  cards.length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
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

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
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

  Widget _buildShortageSummary() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red
              .withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.redAccent
                  .withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons
                  .warning_amber_rounded,
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
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(10),
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
          hintText:
          '카드 이름 또는 번호 검색',
          hintStyle: const TextStyle(
            color: secondaryTextColor,
            fontSize: 13,
          ),
          suffixIcon:
          searchText.isNotEmpty
              ? IconButton(
            onPressed: () {
              searchController
                  .clear();

              setState(() {
                searchText = '';
              });
            },
            icon: const Icon(
              Icons.clear,
              color:
              secondaryTextColor,
              size: 18,
            ),
          )
              : null,
          contentPadding:
          const EdgeInsets.symmetric(
            vertical: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCount(int count) {
    final bool isFiltered =
        selectedType != '전체' ||
            selectedColor != '전체' ||
            searchText.isNotEmpty;

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

  Widget _buildNoResult() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius:
              BorderRadius.circular(17),
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
              backgroundColor:
              const Color(0xFF292E38),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(8),
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

  Widget _buildCardItem(
      Map<String, dynamic> card,
      ) {
    final int requiredCount =
        int.tryParse(
          card['required_count'].toString(),
        ) ??
            0;

    final int ownedCount =
        int.tryParse(
          card['owned_count'].toString(),
        ) ??
            0;

    final int shortageCount =
        requiredCount - ownedCount;

    final colors = _getColors(
      card['color'].toString(),
    );

    final type =
    card['type'].toString();

    final color =
    card['color'].toString();

    final bool isBattlefield =
        color == '무색';

    // ★ 모든 카드 타입을 이름 옆에 표시
    // 무색 카드는 실제 DB type과 관계없이 전장으로 표시
    final String displayType =
    isBattlefield ? '전장' : type;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 7,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
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
                color:
                const Color(0xFF15181E),
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Center(
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: colors.map(
                        (color) {
                      return Container(
                        width: 7,
                        height: 7,
                        margin:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 1,
                        ),
                        decoration:
                        BoxDecoration(
                          color: color,
                          shape:
                          BoxShape.circle,
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          card['name']
                              .toString(),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),

                      // ★ 카드 이름 오른쪽 타입 배지
                      _buildTypeBadge(
                        displayType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        card['number']
                            .toString(),
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        decoration:
                        const BoxDecoration(
                          color:
                          secondaryTextColor,
                          shape:
                          BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Flexible(
                        child: Text(
                          card['series']
                              .toString(),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            color:
                            secondaryTextColor,
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
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        '보유 $ownedCount장',
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
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
              constraints:
              const BoxConstraints(
                minWidth: 54,
              ),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent
                    .withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red
                      .withOpacity(0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '$shortageCount장',
                    style:
                    const TextStyle(
                      color:
                      Colors.redAccent,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    '부족',
                    style: TextStyle(
                      color:
                      secondaryTextColor,
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

  Widget _buildTypeBadge(
      String text,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        left: 7,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF292E38),
        borderRadius:
        BorderRadius.circular(5),
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

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                    border: Border.all(
                      color: borderColor,
                    ),
                  ),
                  child: const Icon(
                    Icons
                        .check_circle_outline,
                    size: 34,
                    color:
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '부족한 카드가 없습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  child: Text(
                    '현재 저장된 덱을 만들기에 충분한 카드를 보유하고 있습니다.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color:
                      secondaryTextColor,
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
}