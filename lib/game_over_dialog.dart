/*
 * game_over_dialog.dart
 *
 * Copyright 2022 Yasuhiro Yamakawa <withlet11@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute,
 * sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or
 * substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
 * BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({Key? key, required this.score, required this.win})
      : super(key: key);

  final int score;
  final int win;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${AppLocalizations.of(context)!.yourScore}$score',
          style: const TextStyle(height: 1.5, fontSize: 32)),
      content: Text(
          '${AppLocalizations.of(context)!.winningRate}${win * 100 / 50}%',
          style: const TextStyle(height: 1.5, fontSize: 24)),
      actions: [
        SimpleDialogOption(
          child: Text(AppLocalizations.of(context)!.tryAgain,
              style: const TextStyle(height: 1.5, fontSize: 24)),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        SimpleDialogOption(
          child: Text(AppLocalizations.of(context)!.quit,
              style: const TextStyle(height: 1.5, fontSize: 24)),
          onPressed: () {
            Navigator.pop(context, false);
          },
        )
      ],
    );
  }
}
