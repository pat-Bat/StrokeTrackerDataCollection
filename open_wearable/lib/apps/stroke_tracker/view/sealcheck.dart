import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';

class SimpleSealCheckScreen extends StatefulWidget {
  final String Function(String en, String de) t;
  final Future<Map<String, dynamic>?> Function(bool isLeft) sealCheck;

  const SimpleSealCheckScreen({
    super.key,
    required this.t,
    required this.sealCheck,
  });

  @override
  _SimpleSealCheckScreenState createState() => _SimpleSealCheckScreenState();
}

class _SimpleSealCheckScreenState extends State<SimpleSealCheckScreen> {
  Map<String, dynamic>? leftResult;
  Map<String, dynamic>? rightResult;
  bool isMeasuringLeft = false;
  bool isMeasuringRight = false;

  void checkSeal(Side side) async {
    setState(() {
      if (side == Side.left) {
        isMeasuringLeft = true;
      } else {
        isMeasuringRight = true;
      }
    });

    final result = await widget.sealCheck(side == Side.left);

    setState(() {
      if (side == Side.left) {
        leftResult = result;
        isMeasuringLeft = false;
      } else {
        rightResult = result;
        isMeasuringRight = false;
      }
    });
  }

  void resetResults() {
    setState(() {
      leftResult = null;
      rightResult = null;
      isMeasuringLeft = false;
      isMeasuringRight = false;
    });
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    Map<String, dynamic>? firstPeak;
    double quality = 0;
    if (result['points'].isNotEmpty) {
      firstPeak = result['points'].first.cast<String, dynamic>();

      (firstPeak!['magnitude'] as num?)?.toDouble() == null
          ? null
          : quality = (firstPeak!['magnitude'] as num?)!.toDouble();
    } else {
      firstPeak = null; // or provide a default
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(widget.t('Quality', 'Qualität') + ': ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              widget.t('Quality should be above 100. Quality: $quality',
                  'Qualität sollte über 100 sein. Qualität: $quality'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarbudSection(
      Side side, bool isMeasuring, Map<String, dynamic>? result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: (isMeasuringLeft || isMeasuringRight)
              ? null
              : () => checkSeal(side),
          child: Text(widget.t(
              side == Side.left ? "Check Left Earbud" : "Check Right Earbud",
              side == Side.left ? "Linkes Ohr prüfen" : "Rechtes Ohr prüfen")),
        ),
        const SizedBox(height: 8),
        if (isMeasuring)
          const Center(child: CircularProgressIndicator())
        else if (result != null)
          _buildResultCard(result),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = leftResult != null && rightResult != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.t("Sealcheck", "VerschlussTest"))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildEarbudSection(Side.left, isMeasuringLeft, leftResult),
            _buildEarbudSection(Side.right, isMeasuringRight, rightResult),
            if (!canContinue)
              Text(
                widget.t(
                  "Please test both earbuds before continuing.",
                  "Bitte teste beide Ohrhörer, bevor du fortfährst.",
                ),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: resetResults,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400]),
                    child: Text(
                        widget.t("Reset Results", "Ergebnisse zurücksetzen")),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.t("Continue", "Weiter")),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
