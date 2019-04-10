import 'package:flutter/material.dart';

import '../widgets/size_selector.dart';
import '../widgets/word_selector.dart';

class CreateGameScreen extends StatelessWidget {
  final _sizeController = SizeSelectionController();
  final _wordController = WordSelectionController();

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
          SizedBox(height: 16),
          SizeSelector(controller: _sizeController),
          SizedBox(height: 16),
          WordSelector(controller: _wordController),
          SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.play_arrow),
        label: Text('Start the game'),
        backgroundColor: Colors.white,
        onPressed: () {},
      ),
    );
  }
}
