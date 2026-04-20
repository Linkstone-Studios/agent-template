// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from database table: app_versions

enum AiProvider {
  hermes('hermes'),
  firebaseAi('firebase_ai');

  const AiProvider(this.value);
  final String value;

  static AiProvider? fromString(String? value) {
    if (value == null) return null;
    try {
      return AiProvider.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

enum DeploymentType {
  web('web'),
  ios('ios'),
  android('android');

  const DeploymentType(this.value);
  final String value;

  static DeploymentType? fromString(String? value) {
    if (value == null) return null;
    try {
      return DeploymentType.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

class AppVersions {
  final String id;
  final String version;
  final AiProvider provider;
  final String? featureSuffix;
  final int buildNumber;
  final DateTime deployedAt;
  final DeploymentType deploymentType;
  final String? gitCommitHash;
  final bool? active;

  const AppVersions({
    required this.id,
    required this.version,
    required this.provider,
    this.featureSuffix,
    required this.buildNumber,
    required this.deployedAt,
    required this.deploymentType,
    this.gitCommitHash,
    this.active,
  });

  factory AppVersions.fromJson(Map<String, dynamic> json) => AppVersions(
      id: json['id'] as String,
      version: json['version'] as String,
      provider: AiProvider.fromString(json['provider'])!,
      featureSuffix: json['feature_suffix'] as String?,
      buildNumber: json['build_number'] as int,
      deployedAt: DateTime.parse(json['deployed_at']),
      deploymentType: DeploymentType.fromString(json['deployment_type'])!,
      gitCommitHash: json['git_commit_hash'] as String?,
      active: json['active'] as bool?,
      );

  Map<String, dynamic> toJson() => {
      'id': id,
      'version': version,
      'provider': provider.value,
      'feature_suffix': featureSuffix,
      'build_number': buildNumber,
      'deployed_at': deployedAt.toIso8601String(),
      'deployment_type': deploymentType.value,
      'git_commit_hash': gitCommitHash,
      'active': active,
      };

  AppVersions copyWith({
    String? id,
    String? version,
    AiProvider? provider,
    String? featureSuffix,
    int? buildNumber,
    DateTime? deployedAt,
    DeploymentType? deploymentType,
    String? gitCommitHash,
    bool? active,
  }) => AppVersions(
      id: id ?? this.id,
      version: version ?? this.version,
      provider: provider ?? this.provider,
      featureSuffix: featureSuffix ?? this.featureSuffix,
      buildNumber: buildNumber ?? this.buildNumber,
      deployedAt: deployedAt ?? this.deployedAt,
      deploymentType: deploymentType ?? this.deploymentType,
      gitCommitHash: gitCommitHash ?? this.gitCommitHash,
      active: active ?? this.active,
      );
}
