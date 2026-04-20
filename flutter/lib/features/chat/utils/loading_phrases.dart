import 'dart:math';

/// Loading phrases for AI chat responses
///
/// Contextual phrases for AI assistance tasks.
class LoadingPhrases {
  static final Random _random = Random();

  /// All available loading phrases
  static const List<String> _phrases = [
    // Thinking与分析
    'Analyzing your request...',
    'Processing your input...',
    'Thinking this through...',
    'Working on it...',
    'Let me think...',

    // Research & lookup
    'Gathering information...',
    'Researching the details...',
    'Looking into this...',
    'Consulting my knowledge...',
    'Fetching relevant data...',

    // Analysis
    'Analyzing the details...',
    'Evaluating options...',
    'Comparing alternatives...',
    'Assessing the situation...',
    'Reviewing the facts...',

    // Generation
    'Generating response...',
    'Formulating answer...',
    'Building solution...',
    'Crafting reply...',
    'Preparing output...',

    // Quality & verification
    'Checking accuracy...',
    'Validating response...',
    'Verifying information...',
    'Ensuring quality...',
    'Cross-checking...',

    // General assistance
    'Consulting best practices...',
    'Gathering insights...',
    'Formulating recommendations...',
    'Preparing detailed analysis...',
    'Compiling feedback...',
  ];

  /// Get a random loading phrase
  static String getRandom() {
    return _phrases[_random.nextInt(_phrases.length)];
  }

  /// Get a sequential phrase based on index
  static String getByIndex(int index) {
    return _phrases[index % _phrases.length];
  }

  /// Get all phrases
  static List<String> get all => List.unmodifiable(_phrases);

  /// Get the count of available phrases
  static int get count => _phrases.length;
}