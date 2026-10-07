import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> cards = [];

  String selectedSeries = '전체';
  String selectedType = '전체';
  String selectedColor = '전체';
  String searchText = '';

  bool isLoading = true;

  final TextEditingController searchController =
  TextEditingController();

  // ============================================================
  // 색상
  // ============================================================

  static const Color backgroundColor = Color(0xFF111318);
  static const Color panelColor = Color(0xFF1B1F27);
  static const Color borderColor = Color(0xFF292E38);
  static const Color secondaryTextColor = Color(0xFF9298A5);

  // ============================================================
  // 초기화
  // ============================================================

  @override
  void initState() {
    super.initState();
    loadCards();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
  // 필터 초기화
  // ============================================================

  void resetFilters() {
    setState(() {
      selectedSeries = '전체';
      selectedType = '전체';
      selectedColor = '전체';
      searchText = '';
      searchController.clear();
    });
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
  // 속성 점
  // ============================================================

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
  // 드롭다운
  // ============================================================

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
  // 필터 초기화 버튼
  // ============================================================

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

  // ============================================================
  // 검색창
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: '카드 이름 또는 번호 검색',
        hintStyle: const TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: secondaryTextColor,
          size: 21,
        ),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
          icon: const Icon(
            Icons.clear,
            color: secondaryTextColor,
            size: 19,
          ),
          onPressed: () {
            searchController.clear();

            setState(() {
              searchText = '';
            });
          },
        )
            : null,
        filled: true,
        fillColor: panelColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
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
      onChanged: (value) {
        setState(() {
          searchText = value;
        });
      },
    );
  }

  // ============================================================
  // 필터
  // ============================================================

  Widget _buildFilters() {
    return Row(
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

  // ============================================================
  // 카드 한 장
  // ============================================================

  Widget _buildCardItem(
      Map<String, dynamic> card,
      ) {
    final int count = card['count'] as int;

    final String name = card['name'].toString();
    final String number = card['number'].toString();
    final String series = card['series'].toString();
    final String type = card['type'].toString();
    final String cardColor = card['color'].toString();

    final bool isBattlefield = cardColor == '무색';

    final String displayType =
    isBattlefield ? '전장' : type;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          // ==================================================
          // 속성
          // ==================================================

          SizedBox(
            width: 28,
            child: Center(
              child: _buildAttributeDots(
                cardColor,
                size: 10,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ==================================================
          // 카드 정보
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
                        color: Colors.white.withOpacity(
                          0.06,
                        ),
                        borderRadius:
                        BorderRadius.circular(5),
                      ),
                      child: Text(
                        displayType,
                        style: const TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Text(
                      number,
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
                    Text(
                      series,
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

          // ==================================================
          // 수량 조절
          // ==================================================

          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
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
                    onPressed: count > 0
                        ? () {
                      setState(() {
                        card['count']--;
                      });
                    }
                        : null,
                    icon: Icon(
                      Icons.remove_rounded,
                      size: 17,
                      color: count > 0
                          ? Colors.white
                          : secondaryTextColor,
                    ),
                  ),
                ),

                Container(
                  width: 34,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
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
                    onPressed: () {
                      setState(() {
                        card['count']++;
                      });
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 화면
  // ============================================================

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
          '보유 카드',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(
              16,
              4,
              16,
              10,
            ),
            child: Column(
              children: [
                _buildSearchField(),

                const SizedBox(height: 10),

                _buildFilters(),

                const SizedBox(height: 10),

                // 결과 수
                Row(
                  children: [
                    Text(
                      '총 ${filteredCards.length}장',
                      style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (selectedSeries != '전체' ||
                        selectedType != '전체' ||
                        selectedColor != '전체' ||
                        searchText.isNotEmpty)
                      const Text(
                        '필터 적용 중',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ==================================================
          // 카드 목록
          // ==================================================

          Expanded(
            child: filteredCards.isEmpty
                ? const Center(
              child: Text(
                '조건에 맞는 카드가 없습니다.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            )
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                2,
                16,
                16,
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

          // ==================================================
          // 저장 버튼
          // ==================================================

          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              16,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: const Border(
                top: BorderSide(
                  color: borderColor,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: saveCards,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '보유 카드 저장',
                  style: TextStyle(
                    fontSize: 14,
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