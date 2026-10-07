import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';

class DeckDetailScreen extends StatefulWidget {
  final int deckId;
  final String deckName;

  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> cards = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isDeleting = false;

  String currentDeckName = '';

  bool showShortageOnly = false;

  static const Color backgroundColor = Color(0xFF111318);
  static const Color panelColor = Color(0xFF1B1F27);
  static const Color borderColor = Color(0xFF292E38);
  static const Color secondaryTextColor = Color(0xFF9298A5);

  @override
  void initState() {
    super.initState();

    currentDeckName = widget.deckName;

    loadDeckCards();
  }

  // ============================================================
  // 덱 카드 불러오기
  // ============================================================

  Future<void> loadDeckCards() async {
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
          deck_cards.id AS deck_card_id,
          deck_cards.count AS deck_count
        FROM deck_cards
        INNER JOIN cards
          ON deck_cards.card_id = cards.id
        WHERE deck_cards.deck_id = ?
        ORDER BY cards.number ASC
        ''',
        [widget.deckId],
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
            'owned_count': card['owned_count'],
            'deck_card_id': card['deck_card_id'],
            'deck_count': card['deck_count'] ?? 0,
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
          backgroundColor: const Color(0xFF2A2F38),
          content: Text(
            '덱 정보를 불러오는 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 현재 덱 구성 개수
  // ============================================================

  int get mainDeckCount {
    int count = 0;

    for (final card in cards) {
      final type = card['type'].toString();
      final color = card['color'].toString();

      final need =
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;

      if (type == '전설') continue;
      if (type == '룬') continue;
      if (color == '무색') continue;

      count += need;
    }

    return count;
  }

  int get legendCount {
    int count = 0;

    for (final card in cards) {
      if (card['type'].toString() != '전설') {
        continue;
      }

      count +=
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;
    }

    return count;
  }

  int get runeCount {
    int count = 0;

    for (final card in cards) {
      if (card['type'].toString() != '룬') {
        continue;
      }

      count +=
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;
    }

    return count;
  }

  int get battlefieldCount {
    int count = 0;

    for (final card in cards) {
      if (card['color'].toString() != '무색') {
        continue;
      }

      count +=
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;
    }

    return count;
  }

  // ============================================================
  // 현재 선택된 전설
  // ============================================================

  Map<String, dynamic>? get selectedLegend {
    for (final card in cards) {
      if (card['type'].toString() != '전설') {
        continue;
      }

      final count =
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;

      if (count > 0) {
        return card;
      }
    }

    return null;
  }

  // ============================================================
  // 전설이 허용하는 속성
  // ============================================================

  List<String> get allowedLegendColors {
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

  // ============================================================
  // 카드 속성이 전설과 맞는지 확인
  // ============================================================

  bool isCardColorAllowed(
      Map<String, dynamic> card,
      ) {
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

    final cardColors = color
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    for (final cardColor in cardColors) {
      if (allowedLegendColors.contains(cardColor)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // 룬 속성 확인
  // ============================================================

  bool isRuneAllowed(
      Map<String, dynamic> card,
      ) {
    if (card['type'].toString() != '룬') {
      return true;
    }

    if (selectedLegend == null) {
      return false;
    }

    final runeColors = card['color']
        .toString()
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    for (final runeColor in runeColors) {
      if (allowedLegendColors.contains(runeColor)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // 메인 덱 카드인지 확인
  // ============================================================

  bool isMainDeckCard(
      Map<String, dynamic> card,
      ) {
    final type = card['type'].toString();
    final color = card['color'].toString();

    if (type == '전설') return false;
    if (type == '룬') return false;
    if (color == '무색') return false;

    return true;
  }

  // ============================================================
  // 특정 카드 현재 수량
  // ============================================================

  int getCardCount(
      Map<String, dynamic> card,
      ) {
    return int.tryParse(
      card['deck_count'].toString(),
    ) ??
        0;
  }

  // ============================================================
  // 카드 + 버튼 사용 가능 여부
  // ============================================================

  bool canIncreaseCard(
      Map<String, dynamic> card,
      ) {
    final type = card['type'].toString();
    final color = card['color'].toString();
    final currentCount = getCardCount(card);

    if (type != '룬' && currentCount >= 3) {
      return false;
    }

    if (type == '전설' && legendCount >= 1) {
      return false;
    }

    if (type == '룬' && runeCount >= 12) {
      return false;
    }

    if (color == '무색' && battlefieldCount >= 3) {
      return false;
    }

    if (isMainDeckCard(card) && mainDeckCount >= 40) {
      return false;
    }

    if (!isCardColorAllowed(card)) {
      return false;
    }

    if (!isRuneAllowed(card)) {
      return false;
    }

    return true;
  }

  // ============================================================
  // 새 카드 추가 가능 여부
  // ============================================================

  bool canAddNewCard(
      Map<String, dynamic> card,
      ) {
    final type = card['type'].toString();
    final color = card['color'].toString();

    if (type == '전설' && legendCount >= 1) {
      return false;
    }

    if (type == '룬' && runeCount >= 12) {
      return false;
    }

    if (color == '무색' && battlefieldCount >= 3) {
      return false;
    }

    if (isMainDeckCard(card) && mainDeckCount >= 40) {
      return false;
    }

    if (!isCardColorAllowed(card)) {
      return false;
    }

    if (!isRuneAllowed(card)) {
      return false;
    }

    return true;
  }

  // ============================================================
  // 덱 코드 생성
  // ============================================================

  String _generateDeckCode() {
    final buffer = StringBuffer();

    buffer.write('RB1');

    buffer.write('|NAME=');
    buffer.write(
      Uri.encodeComponent(currentDeckName),
    );

    for (final card in cards) {
      final number = card['number'].toString();

      final count =
          int.tryParse(
            card['deck_count'].toString(),
          ) ??
              0;

      if (count <= 0) {
        continue;
      }

      buffer.write('|');
      buffer.write(number);
      buffer.write('=');
      buffer.write(count);
    }

    return buffer.toString();
  }

  // ============================================================
  // 덱 코드 복사
  // ============================================================

  Future<void> exportDeckCode() async {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2A2F38),
          content: Text('내보낼 카드가 없습니다.'),
        ),
      );

      return;
    }

    final deckCode = _generateDeckCode();

    await Clipboard.setData(
      ClipboardData(text: deckCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2A2F38),
        content: Text('덱 코드가 클립보드에 복사되었습니다.'),
      ),
    );
  }

  // ============================================================
  // 덱 이름 수정
  // ============================================================

  Future<void> editDeckName() async {
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _DeckNameDialog(
          initialName: currentDeckName,
        );
      },
    );

    if (!mounted) return;

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    final trimmedName = newName.trim();

    if (trimmedName == currentDeckName) {
      return;
    }

    setState(() {
      currentDeckName = trimmedName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF2A2F38),
        content: Text(
          '덱 이름이 변경되었습니다. 저장 버튼을 눌러 적용하세요.',
        ),
      ),
    );
  }

  // ============================================================
  // 덱 삭제
  // ============================================================

  Future<void> deleteDeck() async {
    if (isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panelColor,
          title: const Text(
            '덱 삭제',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '정말 "$currentDeckName" 덱을 삭제하시겠습니까?\n\n'
                '이 덱에 저장된 카드 정보도 함께 삭제됩니다.',
            style: const TextStyle(
              color: secondaryTextColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                '취소',
                style: TextStyle(
                  color: secondaryTextColor,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      return;
    }

    setState(() {
      isDeleting = true;
    });

    try {
      final db = await dbHelper.database;

      await db.delete(
        'deck_cards',
        where: 'deck_id = ?',
        whereArgs: [widget.deckId],
      );

      await db.delete(
        'decks',
        where: 'id = ?',
        whereArgs: [widget.deckId],
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A2F38),
          content: Text(
            '덱 삭제 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 카드 추가
  // ============================================================

  Future<void> addCardToDeck() async {
    try {
      final db = await dbHelper.database;

      final existingCardIds = cards
          .map(
            (card) => int.tryParse(
          card['id'].toString(),
        ),
      )
          .whereType<int>()
          .toSet();

      final allCards = await db.query(
        'cards',
        orderBy: 'number ASC',
      );

      final availableCards = allCards.where((card) {
        final cardId =
            int.tryParse(
              card['id'].toString(),
            ) ??
                0;

        return !existingCardIds.contains(cardId);
      }).toList();

      if (!mounted) return;

      if (availableCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF2A2F38),
            content: Text('추가할 수 있는 카드가 없습니다.'),
          ),
        );

        return;
      }

      final selectedCard =
      await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: backgroundColor,
        builder: (context) {
          String searchText = '';

          return StatefulBuilder(
            builder: (
                context,
                setModalState,
                ) {
              final filteredCards =
              availableCards.where((card) {
                final query =
                searchText.toLowerCase();

                return query.isEmpty ||
                    card['name']
                        .toString()
                        .toLowerCase()
                        .contains(query) ||
                    card['number']
                        .toString()
                        .toLowerCase()
                        .contains(query);
              }).toList();

              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom:
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                        16,
                  ),
                  child: SizedBox(
                    height:
                    MediaQuery.of(context)
                        .size
                        .height *
                        0.75,
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '카드 추가',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (value) {
                            setModalState(() {
                              searchText = value;
                            });
                          },
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration:
                          InputDecoration(
                            hintText:
                            '카드 이름 또는 번호 검색',
                            hintStyle:
                            const TextStyle(
                              color:
                              secondaryTextColor,
                            ),
                            prefixIcon:
                            const Icon(
                              Icons.search,
                              color:
                              secondaryTextColor,
                            ),
                            filled: true,
                            fillColor:
                            panelColor,
                            enabledBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                borderColor,
                              ),
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                              borderSide:
                              const BorderSide(
                                color:
                                Colors.white24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                          filteredCards.isEmpty
                              ? const Center(
                            child: Text(
                              '검색 결과가 없습니다.',
                              style:
                              TextStyle(
                                color:
                                secondaryTextColor,
                              ),
                            ),
                          )
                              : ListView.builder(
                            itemCount:
                            filteredCards
                                .length,
                            itemBuilder:
                                (
                                context,
                                index,
                                ) {
                              final card =
                              filteredCards[
                              index];

                              final bool
                              canAdd =
                              canAddNewCard(
                                card,
                              );

                              final colors =
                              _getColors(
                                card['color']
                                    .toString(),
                              );

                              return Container(
                                margin:
                                const EdgeInsets
                                    .only(
                                  bottom: 8,
                                ),
                                decoration:
                                BoxDecoration(
                                  color:
                                  panelColor,
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    12,
                                  ),
                                  border:
                                  Border.all(
                                    color:
                                    borderColor,
                                  ),
                                ),
                                child:
                                ListTile(
                                  enabled:
                                  canAdd,
                                  contentPadding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    14,
                                    vertical:
                                    4,
                                  ),
                                  leading:
                                  Row(
                                    mainAxisSize:
                                    MainAxisSize
                                        .min,
                                    children:
                                    colors
                                        .map(
                                          (
                                          color,
                                          ) {
                                        return Container(
                                          width:
                                          12,
                                          height:
                                          12,
                                          margin:
                                          const EdgeInsets
                                              .symmetric(
                                            horizontal:
                                            2,
                                          ),
                                          decoration:
                                          BoxDecoration(
                                            color:
                                            color,
                                            shape:
                                            BoxShape.circle,
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                  title:
                                  Text(
                                    card['name']
                                        .toString(),
                                    style:
                                    TextStyle(
                                      color:
                                      canAdd
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  subtitle:
                                  Padding(
                                    padding:
                                    const EdgeInsets
                                        .only(
                                      top: 3,
                                    ),
                                    child:
                                    Text(
                                      canAdd
                                          ? '${card['number']} · ${card['series']}'
                                          : _getAddBlockedReason(
                                        card,
                                      ),
                                      style:
                                      const TextStyle(
                                        color:
                                        secondaryTextColor,
                                        fontSize:
                                        12,
                                      ),
                                    ),
                                  ),
                                  trailing:
                                  Icon(
                                    Icons
                                        .add_circle_outline,
                                    color:
                                    canAdd
                                        ? Colors.white
                                        : Colors.grey,
                                  ),
                                  onTap:
                                  canAdd
                                      ? () {
                                    Navigator.pop(
                                      context,
                                      card,
                                    );
                                  }
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (selectedCard == null) {
        return;
      }

      final type =
      selectedCard['type'].toString();

      final color =
      selectedCard['color'].toString();

      if (type == '전설') {
        final legendRows = await db.rawQuery(
          '''
          SELECT
            deck_cards.id,
            deck_cards.count,
            cards.name,
            cards.number
          FROM deck_cards
          INNER JOIN cards
            ON deck_cards.card_id = cards.id
          WHERE deck_cards.deck_id = ?
            AND cards.type = ?
            AND deck_cards.count > 0
          LIMIT 1
          ''',
          [
            widget.deckId,
            '전설',
          ],
        );

        if (legendRows.isNotEmpty) {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              backgroundColor:
              Color(0xFF2A2F38),
              content: Text(
                '전설은 1장만 사용할 수 있습니다.',
              ),
            ),
          );

          return;
        }
      }

      if (isMainDeckCard(selectedCard) &&
          mainDeckCount >= 40) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '메인 덱은 최대 40장입니다.',
            ),
          ),
        );

        return;
      }

      if (type == '전설' &&
          legendCount >= 1) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '전설은 1장만 사용할 수 있습니다.',
            ),
          ),
        );

        return;
      }

      if (type == '룬' &&
          runeCount >= 12) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '룬은 총 12장까지 사용할 수 있습니다.',
            ),
          ),
        );

        return;
      }

      if (color == '무색' &&
          battlefieldCount >= 3) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '전장은 총 3장까지 사용할 수 있습니다.',
            ),
          ),
        );

        return;
      }

      if (!isCardColorAllowed(
        selectedCard,
      )) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '현재 전설의 속성과 맞지 않는 카드입니다.',
            ),
          ),
        );

        return;
      }

      if (!isRuneAllowed(selectedCard)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            backgroundColor:
            Color(0xFF2A2F38),
            content: Text(
              '현재 전설의 속성과 맞지 않는 룬입니다.',
            ),
          ),
        );

        return;
      }

      final int cardId =
          int.tryParse(
            selectedCard['id'].toString(),
          ) ??
              0;

      if (cardId == 0) {
        return;
      }

      final existingRows = await db.query(
        'deck_cards',
        where:
        'deck_id = ? AND card_id = ?',
        whereArgs: [
          widget.deckId,
          cardId,
        ],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        await db.insert(
          'deck_cards',
          {
            'deck_id': widget.deckId,
            'card_id': cardId,
            'count': 1,
          },
        );
      } else {
        final existingCount =
            int.tryParse(
              existingRows.first['count']
                  .toString(),
            ) ??
                0;

        final newCount =
            existingCount + 1;

        if (type != '룬' &&
            newCount > 3) {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              backgroundColor:
              Color(0xFF2A2F38),
              content: Text(
                '같은 카드는 최대 3장까지 사용할 수 있습니다.',
              ),
            ),
          );

          return;
        }

        await db.update(
          'deck_cards',
          {
            'count': newCount,
          },
          where: 'id = ?',
          whereArgs: [
            existingRows.first['id'],
          ],
        );
      }

      await loadDeckCards();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          const Color(0xFF2A2F38),
          content: Text(
            '${selectedCard['name']} 카드가 1장 추가되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          const Color(0xFF2A2F38),
          content: Text(
            '카드 추가 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // 카드 추가 불가 사유
  // ============================================================

  String _getAddBlockedReason(
      Map<String, dynamic> card,
      ) {
    final type = card['type'].toString();
    final color = card['color'].toString();

    if (type == '전설' &&
        legendCount >= 1) {
      return '전설은 1장만 사용할 수 있습니다.';
    }

    if (type == '룬' &&
        runeCount >= 12) {
      return '룬은 총 12장까지 사용할 수 있습니다.';
    }

    if (color == '무색' &&
        battlefieldCount >= 3) {
      return '전장은 총 3장까지 사용할 수 있습니다.';
    }

    if (isMainDeckCard(card) &&
        mainDeckCount >= 40) {
      return '메인 덱은 총 40장입니다.';
    }

    if (type == '룬' &&
        !isRuneAllowed(card)) {
      return '현재 전설의 속성과 맞지 않는 룬입니다.';
    }

    if (type != '전설' &&
        type != '룬' &&
        color != '무색' &&
        !isCardColorAllowed(card)) {
      return '현재 전설의 속성과 맞지 않는 카드입니다.';
    }

    return '현재 덱 규칙상 추가할 수 없습니다.';
  }

  // ============================================================
  // 덱 수정 저장
  // ============================================================

  Future<void> saveDeckChanges() async {
    if (isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      final db = await dbHelper.database;

      await db.transaction((txn) async {
        final existingDeckCards =
        await txn.query(
          'deck_cards',
          where: 'deck_id = ?',
          whereArgs: [widget.deckId],
        );

        final currentDeckCardIds = cards
            .map(
              (card) => int.tryParse(
            card['deck_card_id'].toString(),
          ),
        )
            .whereType<int>()
            .where((id) => id > 0)
            .toSet();

        for (final oldCard
        in existingDeckCards) {
          final oldId =
          oldCard['id'] as int;

          if (!currentDeckCardIds
              .contains(oldId)) {
            await txn.delete(
              'deck_cards',
              where: 'id = ?',
              whereArgs: [oldId],
            );
          }
        }

        for (final card in cards) {
          final int deckCardId =
              int.tryParse(
                card['deck_card_id']
                    .toString(),
              ) ??
                  0;

          final int cardId =
              int.tryParse(
                card['id'].toString(),
              ) ??
                  0;

          final int count =
              int.tryParse(
                card['deck_count']
                    .toString(),
              ) ??
                  0;

          if (cardId == 0) {
            continue;
          }

          if (count <= 0) {
            if (deckCardId > 0) {
              await txn.delete(
                'deck_cards',
                where: 'id = ?',
                whereArgs: [
                  deckCardId,
                ],
              );
            }

            continue;
          }

          if (deckCardId == 0) {
            await txn.insert(
              'deck_cards',
              {
                'deck_id': widget.deckId,
                'card_id': cardId,
                'count': count,
              },
            );
          } else {
            await txn.update(
              'deck_cards',
              {
                'count': count,
              },
              where: 'id = ?',
              whereArgs: [
                deckCardId,
              ],
            );
          }
        }

        await txn.update(
          'decks',
          {
            'name': currentDeckName,
          },
          where: 'id = ?',
          whereArgs: [widget.deckId],
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2A2F38),
          content: Text('덱이 수정되었습니다.'),
        ),
      );

      await loadDeckCards();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
          const Color(0xFF2A2F38),
          content: Text(
            '덱 수정 중 오류가 발생했습니다: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  // ============================================================
  // 색상
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
          (value) => _getColor(
        value.trim(),
      ),
    )
        .toList();
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    int totalCount = 0;
    int shortageCount = 0;

    for (final card in cards) {
      final int need =
          int.tryParse(
            card['deck_count'].toString(),
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

    final filteredCards = showShortageOnly
        ? cards.where((card) {
      final int need =
          int.tryParse(
            card['deck_count']
                .toString(),
          ) ??
              0;

      final int owned =
          int.tryParse(
            card['owned_count']
                .toString(),
          ) ??
              0;

      return need > owned;
    }).toList()
        : cards;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '덱 수정',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: exportDeckCode,
            icon: const Icon(
              Icons.copy_outlined,
            ),
            tooltip: '덱 코드 복사',
          ),
          IconButton(
            onPressed:
            isDeleting
                ? null
                : deleteDeck,
            icon: const Icon(
              Icons.delete_outline,
            ),
            tooltip: '덱 삭제',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            16,
            4,
            16,
            12,
          ),
          child: isLoading
              ? const Center(
            child:
            CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : cards.isEmpty
              ? _buildEmptyDeck()
              : _buildDeckContent(
            totalCount,
            shortageCount,
            filteredCards,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 빈 덱 화면
  // ============================================================

  Widget _buildEmptyDeck() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildDeckHeader(),

        const SizedBox(height: 12),

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
                    Icons.style_outlined,
                    size: 34,
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  '이 덱에는 카드가 없습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  '카드를 추가해서 덱을 구성해보세요.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildAddCardButton(),
      ],
    );
  }

  // ============================================================
  // 덱 내용
  // ============================================================

  Widget _buildDeckContent(
      int totalCount,
      int shortageCount,
      List<Map<String, dynamic>>
      filteredCards,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildDeckHeader(),

        const SizedBox(height: 4),

        Row(
          children: [
            Text(
              '총 $totalCount장',
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 3,
              decoration:
              const BoxDecoration(
                color: secondaryTextColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '수록 카드 ${cards.length}종',
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 기존 구성 현황 디자인 유지 + 세로 여백만 압축
        _buildDeckStatus(),

        const SizedBox(height: 7),

        // 카드 추가 버튼도 조금 얇게
        _buildAddCardButtonCompact(),

        const SizedBox(height: 7),

        // 부족 안내를 작은 한 줄로 표시
        _buildShortageCompact(
          shortageCount,
        ),

        const SizedBox(height: 7),

        // 필터 버튼도 기존 디자인 유지하면서 높이 축소
        Row(
          children: [
            Expanded(
              child: _buildFilterButtonCompact(
                title: '전체 카드',
                selected:
                !showShortageOnly,
                onPressed: () {
                  setState(() {
                    showShortageOnly =
                    false;
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildFilterButtonCompact(
                title:
                '부족 카드 $shortageCount장',
                selected:
                showShortageOnly,
                onPressed: () {
                  setState(() {
                    showShortageOnly =
                    true;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        // 이 영역이 남은 공간을 모두 사용하므로
        // 카드가 여러 장 보이면서 아래로 스크롤 가능
        Expanded(
          child: filteredCards.isEmpty
              ? _buildNoShortage()
              : ListView.builder(
            padding:
            const EdgeInsets.only(
              bottom: 8,
            ),
            itemCount:
            filteredCards.length,
            itemBuilder:
                (
                context,
                index,
                ) {
              return _buildCardItem(
                filteredCards[index],
              );
            },
          ),
        ),

        const SizedBox(height: 7),

        _buildSaveButtonCompact(),
      ],
    );
  }

  // ============================================================
  // 덱 헤더
  // ============================================================

  Widget _buildDeckHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      currentDeckName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed:
                    editDeckName,
                    padding: EdgeInsets.zero,
                    constraints:
                    const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color:
                      secondaryTextColor,
                    ),
                    tooltip: '덱 이름 수정',
                  ),
                ],
              ),
              const SizedBox(height: 0),
              const Text(
                '덱 구성 및 카드 수량을 관리하세요.',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 덱 구성 현황
  // ============================================================

  Widget _buildDeckStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCountItem(
                  icon: Icons.layers_outlined,
                  title: '메인 덱',
                  current: mainDeckCount,
                  max: 40,
                  accent:
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildCountItem(
                  icon:
                  Icons.workspace_premium_outlined,
                  title: '전설',
                  current: legendCount,
                  max: 1,
                  accent: Colors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _buildCountItem(
                  icon: Icons.auto_awesome_outlined,
                  title: '룬',
                  current: runeCount,
                  max: 12,
                  accent: Colors.purple,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _buildCountItem(
                  icon:
                  Icons.landscape_outlined,
                  title: '전장',
                  current:
                  battlefieldCount,
                  max: 3,
                  accent: Colors.grey,
                ),
              ),
            ],
          ),

          if (selectedLegend != null) ...[
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color:
                const Color(0xFF15181E),
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tune,
                    size: 14,
                    color:
                    secondaryTextColor,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '전설 속성',
                    style: TextStyle(
                      color:
                      secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children:
                      allowedLegendColors
                          .map(
                            (colorName) =>
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                right: 8,
                              ),
                              child:
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration:
                                    BoxDecoration(
                                      color:
                                      _getColor(
                                        colorName,
                                      ),
                                      shape:
                                      BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    colorName,
                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.white,
                                      fontSize:
                                      11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountItem({
    required IconData icon,
    required String title,
    required int current,
    required int max,
    required Color accent,
  }) {
    final progress =
    (current / max).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius:
        BorderRadius.circular(9),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: accent,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                '$current / $max',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius:
            BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor:
              const Color(0xFF292E38),
              valueColor:
              AlwaysStoppedAnimation<
                  Color>(
                accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 카드 추가 버튼 - 압축 버전
  // ============================================================

  Widget _buildAddCardButtonCompact() {
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: OutlinedButton.icon(
        onPressed: addCardToDeck,
        icon: const Icon(
          Icons.add,
          size: 17,
        ),
        label: const Text(
          '카드 추가',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(
            color: borderColor,
          ),
          backgroundColor: panelColor,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // 기존 함수도 유지
  Widget _buildAddCardButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: addCardToDeck,
        icon: const Icon(
          Icons.add,
          size: 19,
        ),
        label: const Text(
          '카드 추가',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(
            color: borderColor,
          ),
          backgroundColor: panelColor,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 부족 카드 안내 - 작은 버전
  // ============================================================

  Widget _buildShortageCompact(
      int shortageCount,
      ) {
    final bool hasShortage =
        shortageCount > 0;

    final Color accent = hasShortage
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      width: double.infinity,
      height: 30,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color: hasShortage
              ? Colors.red.withOpacity(0.28)
              : Colors.green.withOpacity(
            0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasShortage
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasShortage
                  ? '$shortageCount장 부족합니다.'
                  : '모든 카드를 보유하고 있습니다.',
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight:
                FontWeight.bold,
              ),
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 기존 부족 카드 안내
  // ============================================================

  Widget _buildShortageBanner(
      int shortageCount,
      ) {
    final bool hasShortage =
        shortageCount > 0;

    final Color accent = hasShortage
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color: hasShortage
              ? Colors.red.withOpacity(0.35)
              : Colors.green.withOpacity(
            0.30,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(
                0.10,
              ),
              borderRadius:
              BorderRadius.circular(9),
            ),
            child: Icon(
              hasShortage
                  ? Icons
                  .warning_amber_rounded
                  : Icons
                  .check_circle_outline,
              size: 19,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasShortage
                  ? '$shortageCount장 부족합니다.'
                  : '이 덱의 모든 카드를 보유하고 있습니다.',
              style: TextStyle(
                color: accent,
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

  // ============================================================
  // 카드 필터 - 압축 버전
  // ============================================================

  Widget _buildFilterButtonCompact({
    required String title,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF292E38)
              : panelColor,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: selected
                ? Colors.white24
                : borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(8),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
            color: selected
                ? Colors.white
                : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 기존 카드 필터
  // ============================================================

  Widget _buildFilterButton({
    required String title,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFF292E38)
              : panelColor,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: selected
                ? Colors.white24
                : borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
          ),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected
                ? FontWeight.bold
                : FontWeight.normal,
            color: selected
                ? Colors.white
                : secondaryTextColor,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 카드 목록 아이템
  // ============================================================

  Widget _buildCardItem(
      Map<String, dynamic> card,
      ) {
    final int need =
        int.tryParse(
          card['deck_count'].toString(),
        ) ??
            0;

    final int owned =
        int.tryParse(
          card['owned_count'].toString(),
        ) ??
            0;

    final int shortage =
    need > owned
        ? need - owned
        : 0;

    final type =
    card['type'].toString();

    final cardColor =
    card['color'].toString();

    final colors =
    _getColors(cardColor);

    final isLegend =
        type == '전설';

    final isRune =
        type == '룬';

    final isBattlefield =
        cardColor == '무색';

    final canIncrease =
    canIncreaseCard(card);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 5,
      ),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
        BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          10,
          7,
          7,
          7,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color:
                const Color(0xFF15181E),
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: colors
                      .map(
                        (color) =>
                        Container(
                          width: 6,
                          height: 6,
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
                        ),
                  )
                      .toList(),
                ),
              ),
            ),

            const SizedBox(width: 9),

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
                            fontSize: 13,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),

                      if (isLegend)
                        _buildTypeBadge(
                          '전설',
                        ),

                      if (isRune)
                        _buildTypeBadge(
                          '룬',
                        ),

                      if (isBattlefield)
                        _buildTypeBadge(
                          '전장',
                        ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Text(
                        card['number']
                            .toString(),
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
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
                        width: 6,
                      ),
                      Text(
                        card['series']
                            .toString(),
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Text(
                        '필요 $need장',
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Text(
                        '보유 $owned장',
                        style:
                        const TextStyle(
                          color:
                          secondaryTextColor,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(
                        width: 7,
                      ),
                      Text(
                        shortage > 0
                            ? '$shortage장 부족'
                            : '보유',
                        style: TextStyle(
                          color: shortage > 0
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 10,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 3),

            Container(
              height: 34,
              decoration: BoxDecoration(
                color:
                const Color(0xFF15181E),
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    enabled: need > 0,
                    onPressed: need > 0
                        ? () {
                      setState(() {
                        card[
                        'deck_count'] =
                            need - 1;
                      });
                    }
                        : null,
                  ),

                  SizedBox(
                    width: 26,
                    child: Center(
                      child: Text(
                        '$need',
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 13,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  _buildQuantityButton(
                    icon: Icons.add,
                    enabled:
                    canIncrease,
                    onPressed:
                    canIncrease
                        ? () {
                      setState(() {
                        card[
                        'deck_count'] =
                            need + 1;
                      });
                    }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(
      String text,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        left: 6,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF292E38),
        borderRadius:
        BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: secondaryTextColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 28,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(
          icon,
          color: enabled
              ? Colors.white
              : const Color(0xFF555B66),
        ),
      ),
    );
  }

  // ============================================================
  // 부족 카드 없음
  // ============================================================

  Widget _buildNoShortage() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius:
              BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 30,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '부족한 카드가 없습니다.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 저장 버튼 - 압축 버전
  // ============================================================

  Widget _buildSaveButtonCompact() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        onPressed:
        isSaving
            ? null
            : saveDeckChanges,
        style: FilledButton.styleFrom(
          backgroundColor:
          const Color(0xFFE8EAF0),
          foregroundColor:
          const Color(0xFF111318),
          disabledBackgroundColor:
          const Color(0xFF292E38),
          disabledForegroundColor:
          secondaryTextColor,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
          width: 17,
          height: 17,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Icon(
          Icons.save_outlined,
          size: 18,
        ),
        label: Text(
          isSaving
              ? '저장 중...'
              : '덱 수정 저장',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 기존 저장 버튼
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed:
        isSaving
            ? null
            : saveDeckChanges,
        style: FilledButton.styleFrom(
          backgroundColor:
          const Color(0xFFE8EAF0),
          foregroundColor:
          const Color(0xFF111318),
          disabledBackgroundColor:
          const Color(0xFF292E38),
          disabledForegroundColor:
          secondaryTextColor,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        icon: isSaving
            ? const SizedBox(
          width: 19,
          height: 19,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
            : const Icon(
          Icons.save_outlined,
          size: 19,
        ),
        label: Text(
          isSaving
              ? '저장 중...'
              : '덱 수정 저장',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 덱 이름 수정 다이얼로그
// ================================================================

class _DeckNameDialog extends StatefulWidget {
  final String initialName;

  const _DeckNameDialog({
    required this.initialName,
  });

  @override
  State<_DeckNameDialog> createState() =>
      _DeckNameDialogState();
}

class _DeckNameDialogState
    extends State<_DeckNameDialog> {
  late final TextEditingController
  controller;

  static const Color panelColor =
  Color(0xFF1B1F27);

  static const Color borderColor =
  Color(0xFF292E38);

  static const Color secondaryTextColor =
  Color(0xFF9298A5);

  @override
  void initState() {
    super.initState();

    controller =
        TextEditingController(
          text: widget.initialName,
        );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: panelColor,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
        side: const BorderSide(
          color: borderColor,
        ),
      ),
      title: const Text(
        '덱 이름 수정',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: '덱 이름을 입력하세요',
          hintStyle: const TextStyle(
            color: secondaryTextColor,
          ),
          filled: true,
          fillColor:
          const Color(0xFF15181E),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide:
            const BorderSide(
              color: borderColor,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide:
            const BorderSide(
              color: Colors.white24,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            '취소',
            style: TextStyle(
              color: secondaryTextColor,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            final name =
            controller.text.trim();

            if (name.isEmpty) {
              return;
            }

            Navigator.pop(
              context,
              name,
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor:
            const Color(0xFFE8EAF0),
            foregroundColor:
            const Color(0xFF111318),
          ),
          child: const Text('저장'),
        ),
      ],
    );
  }
}