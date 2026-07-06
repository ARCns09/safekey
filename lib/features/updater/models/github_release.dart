class GithubRelease {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final DateTime publishedAt;
  final List<GithubAsset> assets;

  GithubRelease({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.assets,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    var assetsList = json['assets'] as List? ?? [];
    List<GithubAsset> assets = assetsList.map((e) => GithubAsset.fromJson(e)).toList();

    // Clean version string by removing 'v' prefix if it exists
    String rawTag = json['tag_name'] ?? '';
    String cleanVersion = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;

    return GithubRelease(
      version: cleanVersion,
      tagName: rawTag,
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : DateTime.now(),
      assets: assets,
    );
  }

  GithubAsset? get apkAsset {
    try {
      return assets.firstWhere((asset) => asset.name.toLowerCase().endsWith('.apk'));
    } catch (e) {
      return null;
    }
  }
}

class GithubAsset {
  final String name;
  final int size;
  final String downloadUrl;

  GithubAsset({
    required this.name,
    required this.size,
    required this.downloadUrl,
  });

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      downloadUrl: json['browser_download_url'] ?? '',
    );
  }

  double get sizeInMB => size / (1024 * 1024);
}
