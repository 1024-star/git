class AssessmentStep {
  const AssessmentStep({
    required this.name,
    required this.tip,
    required this.buttonText,
    required this.audioAsset,
    required this.overlayImageAsset,
  });

  final String name;
  final String tip;
  final String buttonText;

  final String audioAsset;
  final String overlayImageAsset;
}

class CapturedAssessmentImage {
  const CapturedAssessmentImage({
    required this.stepIndex,
    required this.stepName,
    required this.path,
  });

  final int stepIndex;
  final String stepName;
  final String path;
}
