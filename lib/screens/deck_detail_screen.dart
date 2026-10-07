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
  State<DeckDetailScreen> createState() =>
      _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> cards = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isDeleting = false;

  String currentDeckName = '';

  bool showShortageOnly = false;

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

    // 룬을 제외한 카드는 동일 카드 최대 3장
    if (type != '룬' && currentCount >= 3) {
      return false;
    }

    // 전설 총 1장
    if (type == '전설' && legendCount >= 1) {
      return false;
    }

    // 룬 총 12장
    if (type == '룬' && runeCount >= 12) {
      return false;
    }

    // 전장 총 3장
    if (color == '무색' && battlefieldCount >= 3) {
      return false;
    }

    // 메인 덱 총 40장
    if (isMainDeckCard(card) && mainDeckCount >= 40) {
      return false;
    }

    // 전설 속성 제한
    if (!isCardColorAllowed(card)) {
      return false;
    }

    // 룬 속성 제한
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

    // 전설
    if (type == '전설' && legendCount >= 1) {
      return false;
    }

    // 룬
    if (type == '룬' && runeCount >= 12) {
      return false;
    }

    // 전장
    if (color == '무색' && battlefieldCount >= 3) {
      return false;
    }

    // 메인 덱
    if (isMainDeckCard(card) && mainDeckCount >= 40) {
      return false;
    }

    // 전설 속성 제한
    if (!isCardColorAllowed(card)) {
      return false;
    }

    // 룬 속성 제한
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
          title: const Text('덱 삭제'),
          content: Text(
            '정말 "$currentDeckName" 덱을 삭제하시겠습니까?\n\n'
                '이 덱에 저장된 카드 정보도 함께 삭제됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
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
            content: Text('추가할 수 있는 카드가 없습니다.'),
          ),
        );

        return;
      }

      final selectedCard =
      await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
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
                          decoration:
                          InputDecoration(
                            hintText:
                            '카드 이름 또는 번호 검색',
                            prefixIcon:
                            const Icon(
                              Icons.search,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(
                                10,
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
                                Colors.grey,
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

                              return Card(
                                margin:
                                const EdgeInsets
                                    .only(
                                  bottom: 8,
                                ),
                                child:
                                ListTile(
                                  enabled:
                                  canAdd,
                                  leading:
                                  Row(
                                    mainAxisSize:
                                    MainAxisSize
                                        .min,
                                    children:
                                    _getColors(
                                      card['color']
                                          .toString(),
                                    ).map(
                                          (
                                          color,
                                          ) {
                                        return Container(
                                          width:
                                          20,
                                          height:
                                          20,
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
                                    const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                  subtitle:
                                  Text(
                                    canAdd
                                        ? '${card['number']} · ${card['series']}'
                                        : _getAddBlockedReason(
                                      card,
                                    ),
                                  ),
                                  trailing:
                                  Icon(
                                    Icons
                                        .add_circle,
                                    color: canAdd
                                        ? null
                                        : Colors
                                        .grey,
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

      // ========================================================
      // ★ 전설은 DB 기준으로 다시 확인
      //
      // 화면의 legendCount만 믿지 않고
      // 실제 deck_cards + cards를 다시 확인한다.
      // ========================================================

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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '전설은 1장만 사용할 수 있습니다.',
              ),
            ),
          );

          return;
        }
      }

      // --------------------------------------------------------
      // 선택 후 한 번 더 제한 확인
      // --------------------------------------------------------

      if (isMainDeckCard(selectedCard) &&
          mainDeckCount >= 40) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '전장은 총 3장까지 사용할 수 있습니다.',
            ),
          ),
        );

        return;
      }

      if (!isCardColorAllowed(selectedCard)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '현재 전설의 속성과 맞지 않는 카드입니다.',
            ),
          ),
        );

        return;
      }

      if (!isRuneAllowed(selectedCard)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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

      // ========================================================
      // 새 카드는 무조건 1장으로 추가
      // ========================================================

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
          content: Text(
            '${selectedCard['name']} 카드가 1장 추가되었습니다.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
          content: Text('덱이 수정되었습니다.'),
        ),
      );

      await loadDeckCards();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

    final filteredCards =
    showShortageOnly
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
      appBar: AppBar(
        title: Text(currentDeckName),
        actions: [
          IconButton(
            onPressed: exportDeckCode,
            icon: const Icon(Icons.copy),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : cards.isEmpty
            ? Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentDeckName,
                    style:
                    const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                  editDeckName,
                  icon: const Icon(
                    Icons.edit,
                  ),
                  tooltip:
                  '덱 이름 수정',
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            const Expanded(
              child: Center(
                child: Text(
                  '이 덱에는 카드가 없습니다.',
                ),
              ),
            ),
            SizedBox(
              width:
              double.infinity,
              height: 50,
              child:
              OutlinedButton
                  .icon(
                onPressed:
                addCardToDeck,
                icon: const Icon(
                  Icons.add,
                ),
                label:
                const Text(
                  '카드 추가',
                  style:
                  TextStyle(
                    fontSize:
                    16,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentDeckName,
                    style:
                    const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                  editDeckName,
                  icon: const Icon(
                    Icons.edit,
                  ),
                  tooltip:
                  '덱 이름 수정',
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '총 $totalCount장',
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // 덱 구성 현황
            // ==================================================

            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color:
              Colors.grey.shade100,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        '메인 덱: $mainDeckCount / 40',
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                      Text(
                        '전설: $legendCount / 1',
                        style:
                        const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        '룬: $runeCount / 12',
                        style:
                        const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                      Text(
                        '전장: $battlefieldCount / 3',
                        style:
                        const TextStyle(
                          fontSize: 14,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (selectedLegend !=
                      null)
                    Align(
                      alignment:
                      Alignment
                          .centerLeft,
                      child: Text(
                        '선택한 전설 속성: '
                            '${allowedLegendColors.join(', ')}',
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 45,
              child:
              OutlinedButton
                  .icon(
                onPressed:
                addCardToDeck,
                icon: const Icon(
                  Icons.add,
                ),
                label:
                const Text(
                  '카드 추가',
                  style:
                  TextStyle(
                    fontSize:
                    15,
                    fontWeight:
                    FontWeight
                        .bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(16),
              decoration:
              BoxDecoration(
                color:
                shortageCount >
                    0
                    ? Colors
                    .red
                    .shade50
                    : Colors
                    .green
                    .shade50,
                borderRadius:
                BorderRadius
                    .circular(
                  12,
                ),
                border:
                Border.all(
                  color:
                  shortageCount >
                      0
                      ? Colors
                      .red
                      .shade200
                      : Colors
                      .green
                      .shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    shortageCount >
                        0
                        ? Icons
                        .warning_amber_rounded
                        : Icons
                        .check_circle,
                    color:
                    shortageCount >
                        0
                        ? Colors
                        .red
                        : Colors
                        .green,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      shortageCount >
                          0
                          ? '$shortageCount장 부족합니다.'
                          : '이 덱의 모든 카드를 보유하고 있습니다.',
                      style:
                      TextStyle(
                        fontWeight:
                        FontWeight
                            .bold,
                        color:
                        shortageCount >
                            0
                            ? Colors
                            .red
                            : Colors
                            .green,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child:
                  _buildFilterButton(
                    title:
                    '전체 카드',
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
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child:
                  _buildFilterButton(
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

            const SizedBox(
              height: 12,
            ),

            Expanded(
              child:
              filteredCards.isEmpty
                  ? Center(
                child:
                Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    Icon(
                      Icons
                          .check_circle_outline,
                      size: 60,
                      color: Colors
                          .green
                          .shade400,
                    ),
                    const SizedBox(
                      height:
                      12,
                    ),
                    const Text(
                      '부족한 카드가 없습니다.',
                      style:
                      TextStyle(
                        fontSize:
                        16,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView
                  .builder(
                padding:
                const EdgeInsets
                    .only(
                  bottom:
                  16,
                ),
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

                  final int
                  need =
                      int.tryParse(
                        card[
                        'deck_count']
                            .toString(),
                      ) ??
                          0;

                  final int
                  owned =
                      int.tryParse(
                        card[
                        'owned_count']
                            .toString(),
                      ) ??
                          0;

                  final int
                  shortage =
                  need >
                      owned
                      ? need -
                      owned
                      : 0;

                  final type =
                  card[
                  'type']
                      .toString();

                  final cardColor =
                  card[
                  'color']
                      .toString();

                  final colors =
                  _getColors(
                    cardColor,
                  );

                  final isLegend =
                      type ==
                          '전설';

                  final isRune =
                      type ==
                          '룬';

                  final isBattlefield =
                      cardColor ==
                          '무색';

                  final canIncrease =
                  canIncreaseCard(
                    card,
                  );

                  return Card(
                    margin:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      0,
                      vertical:
                      4,
                    ),
                    child:
                    ListTile(
                      title:
                      Row(
                        children: [
                          Flexible(
                            child:
                            Text(
                              card[
                              'name']
                                  .toString(),
                            ),
                          ),
                          if (isLegend)
                            const Padding(
                              padding:
                              EdgeInsets.only(
                                left:
                                8,
                              ),
                              child:
                              Text(
                                '전설',
                                style:
                                TextStyle(
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isRune)
                            const Padding(
                              padding:
                              EdgeInsets.only(
                                left:
                                8,
                              ),
                              child:
                              Text(
                                '룬',
                                style:
                                TextStyle(
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isBattlefield)
                            const Padding(
                              padding:
                              EdgeInsets.only(
                                left:
                                8,
                              ),
                              child:
                              Text(
                                '전장',
                                style:
                                TextStyle(
                                  fontSize:
                                  12,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Row(
                            children: [
                              Text(
                                card[
                                'number']
                                    .toString(),
                              ),
                              const SizedBox(
                                width:
                                8,
                              ),
                              ...colors.map(
                                    (
                                    color,
                                    ) =>
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(
                                        right:
                                        3,
                                      ),
                                      child:
                                      Container(
                                        width:
                                        14,
                                        height:
                                        14,
                                        decoration:
                                        BoxDecoration(
                                          color:
                                          color,
                                          shape:
                                          BoxShape.circle,
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height:
                            4,
                          ),
                          Text(
                            '필요 $need장  ·  보유 $owned장',
                            style:
                            const TextStyle(
                              fontSize:
                              14,
                            ),
                          ),
                          const SizedBox(
                            height:
                            4,
                          ),
                          Text(
                            shortage >
                                0
                                ? '$shortage장 부족'
                                : '보유',
                            style:
                            TextStyle(
                              fontSize:
                              14,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              shortage > 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      trailing:
                      Row(
                        mainAxisSize:
                        MainAxisSize
                            .min,
                        children: [
                          IconButton(
                            icon:
                            const Icon(
                              Icons
                                  .remove,
                            ),
                            onPressed:
                            need >
                                0
                                ? () {
                              setState(
                                    () {
                                  card[
                                  'deck_count'] = need - 1;
                                },
                              );
                            }
                                : null,
                          ),
                          SizedBox(
                            width:
                            30,
                            child:
                            Center(
                              child:
                              Text(
                                '$need',
                                style:
                                const TextStyle(
                                  fontSize:
                                  16,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon:
                            const Icon(
                              Icons
                                  .add,
                            ),
                            onPressed:
                            canIncrease
                                ? () {
                              setState(
                                    () {
                                  card[
                                  'deck_count'] = need + 1;
                                },
                              );
                            }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 50,
              child:
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : saveDeckChanges,
                icon: isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                  ),
                )
                    : const Icon(
                  Icons.save,
                ),
                label: Text(
                  isSaving
                      ? '저장 중...'
                      : '덱 수정 저장',
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 전체 / 부족 카드 버튼
  // ============================================================

  Widget _buildFilterButton({
    required String title,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
          selected
              ? Colors.grey.shade200
              : null,
          side: BorderSide(
            color: selected
                ? Colors.black54
                : Colors.grey.shade400,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight:
            selected
                ? FontWeight.bold
                : FontWeight.normal,
            color: Colors.black87,
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
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(
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
      title: const Text('덱 이름 수정'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '덱 이름을 입력하세요',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('취소'),
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
          child: const Text('저장'),
        ),
      ],
    );
  }
}