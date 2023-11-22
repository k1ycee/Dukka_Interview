class DownloadInformation {
  final double? downloadProgress;
  final String? imagePath;
  final String imageUrl;
  final bool isFiltering;
  DownloadInformation({
    this.downloadProgress,
    this.imagePath,
    required this.imageUrl,
    this.isFiltering = false
  });

  DownloadInformation copyWith({
    double? downloadProgress,
    String? imagePath,
    String? imageUrl,
    bool? isFiltering
  }) {
    return DownloadInformation(
      downloadProgress: downloadProgress ?? this.downloadProgress,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isFiltering: isFiltering ?? this.isFiltering
    );
  }
}
