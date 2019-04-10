import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import 'bloc_provider.dart';
import 'models.dart';
import 'streamed_property.dart';

export 'models.dart';

class Bloc {
  final _game = StreamedProperty<BingoGame>();
  BingoGame get game => _game.value;
  ValueObservable<BingoGame> get gameStream => _game.stream;

  final _field = StreamedProperty<BingoField>();
  BingoField get field => _field.value;
  ValueObservable<BingoField> get fieldStream => _field.stream;

  final votedWords = <String>{};

  // Firestore helpers.
  CollectionReference get _firestoreGames =>
      Firestore.instance.collection('games');
  CollectionReference get _firestorePlayers => Firestore.instance
      .collection('games')
      .document(_game.value.id)
      .collection('players');

  /// This method allows subtree widgets to access this bloc.
  static Bloc of(BuildContext context) {
    assert(context != null);
    final BlocProvider holder = context.ancestorWidgetOfExactType(BlocProvider);
    return holder?.bloc;
  }

  Future<void> dispose() async {
    await _game.dispose();
    await _field.dispose();
  }

  // Loads the game.
  Future<BingoGame> _getGame(String id) async {
    var snapshot = await _firestoreGames.document(id).get();
    if (!snapshot.exists) {
      throw StateError("Game doesn't exist."); //GameDoesNotExistError();
    }
    var data = snapshot.data;

    return BingoGame(
      id: id,
      size: data['size'] as int,
      numPlayers: data['numPlayers'] as int,
      labels: Set.from((data['labels'] as List)),
      voteQueue: Queue.from(data['voteQueue'] as List),
      marked: Set.from(data['marked'] as List),
    );
  }

  // Loads a player.
  Future<BingoField> _getField(id) async {
    var snapshot = await _firestorePlayers.document(id).get();
    if (!snapshot.exists) {
      throw StateError("Field doesn't exist.");
    }
    var data = snapshot.data;

    return BingoField(
      id: id,
      size: _game.value.size,
      tiles: (data['tiles'] as List<String>).map((label) {
        return BingoTile(label, isMarked: _game.value.marked.contains(label));
      }).toList(),
    );
  }

  // Creates a new game.
  Future<void> createGame(
      {@required int size, @required Set<String> labels}) async {
    var doc = await _firestoreGames.add({
      'size': size,
      'numPlayers': 0,
      'labels': List.from(labels),
      'voteQueue': [],
      'marked': [],
    });
    _game.value = BingoGame.newGame(
      id: doc.documentID,
      size: size,
      numPlayers: 0,
      labels: labels,
    );
  }

  // Joins a game.
  Future<void> joinGame(String id) async {
    var game = await _getGame(id);
    game = game.copyWith(numPlayers: game.numPlayers + 1);

    await _firestoreGames.document(id).setData(
      {'numPlayers': game.numPlayers},
      merge: true,
    );
    _game.value = game;
  }

  // Selects labels.
  Future<void> selectLabels(Set<String> labels) async {
    var doc = await _firestorePlayers.add({
      'tiles': List.from(labels, growable: false),
    });
    _field.value = BingoField.fromLabels(
      id: doc.documentID,
      size: game.size,
      labels: labels,
    );
  }

  // Propose a marking to the crowd.
  Future<void> proposeMarking(String label) async {
    var g = game.copyWith(
      voteQueue: game.voteQueue..add(Vote.newVote(label: label)),
    );
    await _firestoreGames.document(g.id).setData({
      'voteQueue': List.from(g.voteQueue),
    }, merge: true);
    _game.value = g;
  }

  // Votes for a label.
  Future<void> voteFor(String label) async {
    var vote = game.getVote(label);
    var g = game.copyWithUpdatedVote(original: vote, updated: vote.voteFor());

    if (vote.isApproved(g.numPlayers)) {
      vote = null;
      g = game.copyWithUpdatedVote(original: vote, updated: null).copyWith(
            marked: g.marked.union({label}),
          );
    }

    // TODO: check if won

    await _firestoreGames.document(g.id).setData({
      'voteQueue': List.from(g.voteQueue),
      'marked': List.from(g.marked),
    }, merge: true);
    _game.value = g;
  }

  // Votes against a label.
  Future<void> voteAgainst(String label) async {
    var vote = game.getVote(label);
    var g =
        game.copyWithUpdatedVote(original: vote, updated: vote.voteAgainst());

    if (vote.isRejected(g.numPlayers)) {
      vote = null;
      g = game.copyWithUpdatedVote(original: vote, updated: null);
    }

    await _firestoreGames.document(g.id).setData({
      'voteQueue': List.from(g.voteQueue),
    }, merge: true);
    _game.value = g;
  }

  void _onUpdated(BingoGame game) {
    // TODO: implement
    /*var f = field.withMarked(label);
    await _firestorePlayers.document(f.id).setData({'tiles': f.tiles});
    _field.value = f;*/
  }

  void _checkIfWon() {}
}