class AIResult {
  final String label;
  final double confidence;
  final int index;

  AIResult({
    required this.label,
    required this.confidence,
    required this.index,
  });

  @override
  String toString() => 'AIResult(label: $label, confidence: $confidence, index: $index)';
}
