/*
 * score_and_date.dart
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

/// Class for recording results
/// - properties
///   * [score] : score
///   * [dateTime] : date and times
/// - methods
///   * [toString] : creates a string for saving records to [SharedPreferences]
/// - static methods
///   * [fromString] : creates an instance from a string that are loaded from
///       [SharedPreferences]
class ScoreAndDate {
  final int score;
  final DateTime dateTime;

  ScoreAndDate(this.score, this.dateTime);

  @override
  String toString() =>
      "${score.toString()},${dateTime.millisecondsSinceEpoch.toString()}";

  static ScoreAndDate? fromString(String scoreAndDateTime) {
    var split = scoreAndDateTime.split(',').map((e) => int.tryParse(e));
    return (split.length == 2 && split.first != null && split.last != null)
        ? ScoreAndDate(
            split.first!, DateTime.fromMillisecondsSinceEpoch(split.last!))
        : null;
  }
}
