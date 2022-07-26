/*
 * which_is_same_color_page.dart
 *
 * Copyright 2022 Yasuhiro Yamakawa <withlet11@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_over_dialog.dart';
import 'target_color_rectangle.dart';
import 'score_and_date.dart';

// Here are constants.
/// Constants for animation of timer, the unit is milliseconds.
const int timeStep = 50; // 0.05 seconds
const int limitTime = 5000; // 5 seconds

/// Max difference of RGB values.
const int maxDifference = 40;

/// Color codes for displaying winning rate bars on each color
const Color colorRed = Color.fromRGBO(255, 0, 0, 0.9);
const Color colorLightRed = Color.fromRGBO(255, 192, 192, 1);
const Color colorYellow = Color.fromRGBO(255, 255, 0, 0.8);
const Color colorLightYellow = Color.fromRGBO(255, 255, 192, 1);
const Color colorGreen = Color.fromRGBO(0, 255, 0, 0.9);
const Color colorLightGreen = Color.fromRGBO(192, 255, 192, 1);
const Color colorCyan = Color.fromRGBO(0, 255, 255, 0.9);
const Color colorLightCyan = Color.fromRGBO(192, 255, 255, 1);
const Color colorBlue = Color.fromRGBO(0, 0, 255, 0.8);
const Color colorLightBlue = Color.fromRGBO(192, 192, 255, 1);
const Color colorMagenta = Color.fromRGBO(255, 0, 255, 0.9);
const Color colorLightMagenta = Color.fromRGBO(255, 192, 255, 1);

/// Constants for scoring.
/// base point, point weight against difficulty difference of value and
/// saturation from hue, and marks that depends on the difficulties.
const int basePoint = 100;
const double pointWeight = 8.0;
const distanceAndPoint = [
  [1.0, 100],
  [2.0, 75],
  [3.0, 50],
  [4.0, 25],
  [6.0, 20],
  [8.0, 15],
  [10.0, 10]
];

/// Max length of [_scoreRecordList]
const int maxNumberOfRecords = 15;

class WhichIsSameColorPage extends StatefulWidget {
  const WhichIsSameColorPage({super.key, required this.title});

  final String title;

  @override
  State<WhichIsSameColorPage> createState() => _WhichIsSameColorPageState();
}

class _WhichIsSameColorPageState extends State<WhichIsSameColorPage> with WidgetsBindingObserver {
  bool _isAppResumed = true;

  /// The counters of wins.
  /// 1 for total and 7 for colors
  int _winTotal = 0;
  int _winRed = 0;
  int _winYellow = 0;
  int _winGreen = 0;
  int _winCyan = 0;
  int _winBlue = 0;
  int _winMagenta = 0;

  /// The counters of trials.
  /// 1 for total and 7 for colors
  int _trialTotal = 0;
  int _trialRed = 0;
  int _trialYellow = 0;
  int _trialGreen = 0;
  int _trialCyan = 0;
  int _trialBlue = 0;
  int _trialMagenta = 0;

  int _selectedIndex = 0;
  int _score = 0;

  /// Status and result messages
  String _message = "";

  /// Score record list
  /// Max length is limited by [maxNumberOfRecords]
  List<ScoreAndDate> _scoreRecordList = [];

  /// Color options on each trial
  /// Initial values are dummies.
  final _colorOption = [Colors.black, Colors.black, Colors.black];

  /// Periodical timer
  /// For displaying the timer, and for limiting trial time
  late Timer _timer;

  /// Check if the main panel is in the foreground.
  bool _isDrawerClosed = true;

  /// Countdown time for each trial
  int _currentTime = 0;

  // Rectangle widgets for displaying the target color.
  final TargetColorRectangle _targetColorRectangle = TargetColorRectangle();

  // Resets all values.
  void resetAll() {
    _winTotal = 0;
    _winRed = 0;
    _winYellow = 0;
    _winGreen = 0;
    _winCyan = 0;
    _winBlue = 0;
    _winMagenta = 0;
    _trialTotal = 0;
    _trialRed = 0;
    _trialYellow = 0;
    _trialGreen = 0;
    _trialCyan = 0;
    _trialBlue = 0;
    _trialMagenta = 0;
    _selectedIndex = 0;
    _score = 0;
    _message = AppLocalizations.of(context)!.start;
  }

  /// Sets the target color and the color options.
  void changeColorSet() {
    _currentTime = limitTime;
    var rand = Random();
    _selectedIndex = rand.nextInt(3);
    int baseColorR = rand.nextInt(256);
    int baseColorG = rand.nextInt(256);
    int baseColorB = rand.nextInt(256);

    for (int i = 0; i < 3; ++i) {
      int red = max(min(baseColorR + rand.nextInt(maxDifference) ~/ 2, 255), 0);
      int green =
          max(min(baseColorG + rand.nextInt(maxDifference) ~/ 2, 255), 0);
      int blue =
          max(min(baseColorB + rand.nextInt(maxDifference) ~/ 2, 255), 0);
      _colorOption[i] = Color.fromRGBO(red, green, blue, 1);
    }
    _targetColorRectangle.color = _colorOption[_selectedIndex];
  }

  /// Goes next trial
  void goNextTrial() async {
    if (_trialTotal >= 50) {
      _timer.cancel();
      final bool? willContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            _scoreRecordList.insert(0, ScoreAndDate(_score, DateTime.now()));
            while (_scoreRecordList.length > maxNumberOfRecords) {
              _scoreRecordList.removeLast();
            }
            var parsed = _scoreRecordList.map((e) => e.toString()).toList();
            if (kDebugMode) stdout.writeln("records: $parsed");
            saveRecords(parsed);
            return GameOverDialog(score: _score, win: _winTotal);
          });
      if (willContinue!) {
        resetAll();
        _timer = startTimer();
      } else {
        SystemNavigator.pop();
      }
    }

    setState(() {
      changeColorSet();
    });
  }

  /// Starts the timer. If the rest of time is almost 0, go next trial. If not,
  /// update the display of timer.
  Timer startTimer() =>
      Timer.periodic(const Duration(milliseconds: timeStep), (Timer timer) {
        if (_currentTime < timeStep) {
          incrementCount(false);
          goNextTrial();
        } else {
          if (_isDrawerClosed && _isAppResumed) {
            setState(() {
              _currentTime -= timeStep;
            });
          }
        }
      });

  /// Increments the trial counts, and calculates the win rates and the score.
  void incrementCount(bool win) {
    ++_trialTotal;
    if (win) {
      _message = AppLocalizations.of(context)!.ok;
      _score += calculateScore();
      ++_winTotal;
    } else {
      _message = AppLocalizations.of(context)!.oops;
      _score -= basePoint - calculateScore();
    }
    double hue = HSVColor.fromColor(_colorOption[_selectedIndex]).hue;
    if (hue < 30) {
      ++_trialRed;
      if (win) ++_winRed;
    } else if (hue < 90) {
      ++_trialYellow;
      if (win) ++_winYellow;
    } else if (hue < 150) {
      ++_trialGreen;
      if (win) ++_winGreen;
    } else if (hue < 210) {
      ++_trialCyan;
      if (win) ++_winCyan;
    } else if (hue < 270) {
      ++_trialBlue;
      if (win) ++_winBlue;
    } else if (hue < 330) {
      ++_trialMagenta;
      if (win) ++_winMagenta;
    } else {
      ++_trialRed;
      if (win) ++_winRed;
    }
  }

  /// Calculates the score with considering the difficulties.
  int calculateScore() {
    var distance =
        [_selectedIndex == 0 ? 1 : 0, _selectedIndex == 2 ? 1 : 2].map((i) {
      var wrongHSV = HSVColor.fromColor(_colorOption[i]);
      var correctHSV = HSVColor.fromColor(_colorOption[_selectedIndex]);
      var hueDifference = (wrongHSV.hue - correctHSV.hue).abs();
      var saturationDifference =
          (wrongHSV.saturation - correctHSV.saturation).abs();
      var valueDifference = (wrongHSV.value - correctHSV.value).abs();
      return (hueDifference * correctHSV.saturation +
              saturationDifference * pointWeight +
              valueDifference * pointWeight)
          .abs();
    }).toList();

    double minDistance = min(distance[0], distance[1]);

    for (int i = 0; i < distanceAndPoint.length; ++i) {
      if (minDistance < distanceAndPoint[i][0]) {
        return distanceAndPoint[i][1] as int;
      }
    }
    return 1;
  }

  /// Saves the score record list to SharePreferences
  Future saveRecords(List<String> recordList) async {
    if (kDebugMode) stdout.writeln("Saving the score record list");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wsc_records', recordList);
    if (kDebugMode) {
      stdout.writeln("Finished saving: ${_scoreRecordList.length} record(s)");
    }
  }

  /// Loads the score record list from SharePreferences
  /// [_scoreRecordList] is changed.
  Future loadRecords() async {
    if (kDebugMode) stdout.writeln("Loading the score record list");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> rawList = prefs.getStringList('wsc_records') ?? [];
    _scoreRecordList = rawList
        .map(ScoreAndDate.fromString)
        .whereType<ScoreAndDate>()
        .take(maxNumberOfRecords)
        .toList();
    if (kDebugMode) {
      stdout.writeln("Finished loading: ${_scoreRecordList.length} record(s)");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadRecords();
    changeColorSet();
    _timer = startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppResumed = state == AppLifecycleState.resumed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_trialTotal == 0) _message = AppLocalizations.of(context)!.start;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: Drawer(
          child: ListView(children: [
        DrawerHeader(
            child: Column(children: [
          Image.asset("images/app_icon.png", height: 48, width: 48),
          const Text("Color Sense Test",
              style: TextStyle(height: 1.5, fontSize: 24)),
        ])),
        ..._scoreRecordList.toList().map((elem) => Row(children: [
              Expanded(
                flex: 2,
                child: Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text(
                      DateFormat("yyyy-MM-dd HH:mm").format(elem.dateTime),
                      textAlign: TextAlign.left,
                      style: const TextStyle(height: 1.5, fontSize: 18),
                    )),
              ),
              Expanded(
                  flex: 1,
                  child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Text(elem.score.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              height: 1.5,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))))
            ])),
        AboutListTile(
            icon: const Icon(Icons.info),
            applicationIcon:
                Image.asset("images/app_icon.png", height: 32, width: 32),
            applicationName: "Color Sense Test",
            applicationVersion: "1.0.0",
            applicationLegalese:
                '\u{a9} 2022 Yasuhiro Yamakawa <withlet11@gmail.com>',
            aboutBoxChildren: const <Widget>[
              Text(
                  style: TextStyle(height: 1.5, fontSize: 12),
                  'Permission is hereby granted, free of charge, to any person '
                  'obtaining a copy of this software and associated documentation '
                  'files (the "Software"), to deal in the Software without '
                  'restriction, including without limitation the rights to use, '
                  'copy, modify, merge, publish, distribute, sublicense, and/or '
                  'sell copies of the Software, and to permit persons to whom the '
                  'Software is furnished to do so, subject to the following '
                  'conditions:\n\n'
                  'The above copyright notice and this permission notice shall be '
                  'included in all copies or substantial portions of the Software.\n\n'
                  'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, '
                  'EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES '
                  'OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND '
                  'NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT '
                  'HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, '
                  'WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING '
                  'FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR '
                  'OTHER DEALINGS IN THE SOFTWARE.')
            ]),
      ])),
      onDrawerChanged: (isOpened) {
        _isDrawerClosed = !isOpened;
      },
      body: OrientationBuilder(
          builder: (context, orientation) => orientation == Orientation.portrait
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...makeMainPanel(context),
                    ...makeScorePanel(context)
                  ],
                )
              : Center(
                  child: Row(children: <Widget>[
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: makeMainPanel(context)),
                    ),
                    Expanded(child: Column(children: makeScorePanel(context)))
                  ]),
                )),
    );
  }

  List<Widget> makeMainPanel(context) {
    return <Widget>[
      CustomPaint(
          size: const Size(100.0, 100.0), painter: _targetColorRectangle),
      Text(
        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.5),
        AppLocalizations.of(context)!
            .whichIsTheSameColor, // 'Which is the same color?',
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: _colorOption[0],
              onPrimary: Colors.white,
            ),
            onPressed: () {
              incrementCount(_selectedIndex == 0);
              goNextTrial();
            },
            child: const Text('Color 1')),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: _colorOption[1],
              onPrimary: Colors.white,
            ),
            onPressed: () {
              incrementCount(_selectedIndex == 1);
              goNextTrial();
            },
            child: const Text('Color 2')),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: _colorOption[2],
              onPrimary: Colors.white,
            ),
            onPressed: () {
              incrementCount(_selectedIndex == 2);
              goNextTrial();
            },
            child: const Text('Color 3'))
      ]),
      Text(
        _message,
        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 3.0),
      )
    ];
  }

  List<Widget> makeScorePanel(context) {
    return <Widget>[
      Text(
        '${AppLocalizations.of(context)!.score}$_score',
        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 3.0),
      ),
      Text(
        '${_trialTotal > 0 ? _winTotal * 100 ~/ _trialTotal : "-"}% ($_winTotal / $_trialTotal)',
        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0),
      ),
      makeIndicators(),
    ];
  }

  Widget makeIndicators() {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        children: [
          CircularProgressIndicator(
// backgroundColor: Colors.grey,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
            value: 1 - _currentTime / limitTime,
          ),
          const SizedBox(
            height: 15,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightRed,
            valueColor: const AlwaysStoppedAnimation<Color>(colorRed),
            minHeight: 10,
            value: _trialRed > 0 ? _winRed / _trialRed : 0,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightYellow,
            valueColor: const AlwaysStoppedAnimation<Color>(colorYellow),
            minHeight: 10,
            value: _trialYellow > 0 ? _winYellow / _trialYellow : 0,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(colorGreen),
            minHeight: 10,
            value: _trialGreen > 0 ? _winGreen / _trialGreen : 0,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightCyan,
            valueColor: const AlwaysStoppedAnimation<Color>(colorCyan),
            minHeight: 10,
            value: _trialCyan > 0 ? _winCyan / _trialCyan : 0,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightBlue,
            valueColor: const AlwaysStoppedAnimation<Color>(colorBlue),
            minHeight: 10,
            value: _trialBlue > 0 ? _winBlue / _trialBlue : 0,
          ),
          LinearProgressIndicator(
            backgroundColor: colorLightMagenta,
            valueColor: const AlwaysStoppedAnimation<Color>(colorMagenta),
            minHeight: 10,
            value: _trialMagenta > 0 ? _winMagenta / _trialMagenta : 0,
          ),
        ],
      ),
    );
  }
}
