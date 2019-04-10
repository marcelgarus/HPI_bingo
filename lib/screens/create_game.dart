import 'package:flutter/material.dart';

import '../bloc/bloc.dart';
import '../screens/select_words.dart';
import '../widgets/size_selector.dart';
import '../widgets/words_input.dart';

class CreateGameScreen extends StatefulWidget {
  @override
  _CreateGameScreenState createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  int size = 2;
  List<String> words = [];

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: ListView(
        padding: MediaQuery.of(context).padding +
            EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        children: <Widget>[
          Center(
            child: Text('Create a new game', style: TextStyle(fontSize: 32)),
          ),
          SizedBox(height: 32),
          SizeSelector(
            sizes: [2, 3, 4, 5],
            selectedSize: size,
            onSizeSelected: (s) => setState(() => size = s),
          ),
          SizedBox(height: 32),
          WordsInput(
            words: words,
            onWordsChanged: (w) => setState(() => words = w),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.play_arrow),
        label: Text('Start the game'),
        backgroundColor: Colors.white,
        onPressed: () {
          setState(() async {
            await Bloc.of(context)
                .createGame(size: size, labels: Set.from(words));
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => SelectWordsScreen(),
            ));
          });
        },
      ),
    );
  }
}