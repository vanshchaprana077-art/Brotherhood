/// One week's worth of progress photos for a member.
class WeeklyProgressPhotos {
  final String memberId;
  final int weekNumber;
  final String? frontUrl;
  final String? sideUrl;
  final String? backUrl;
  final String? faceUrl;
  final DateTime? updatedAt;

  const WeeklyProgressPhotos({
    required this.memberId,
    required this.weekNumber,
    this.frontUrl,
    this.sideUrl,
    this.backUrl,
    this.faceUrl,
    this.updatedAt,
  });

  bool get isComplete =>
      frontUrl != null && sideUrl != null && backUrl != null && faceUrl != null;

  Map<String, dynamic> toMap() => {
        'memberId': memberId,
        'weekNumber': weekNumber,
        'frontUrl': frontUrl,
        'sideUrl': sideUrl,
        'backUrl': backUrl,
        'faceUrl': faceUrl,
      };

  factory WeeklyProgressPhotos.fromMap(Map<String, dynamic> map) =>
      WeeklyProgressPhotos(
        memberId: map['memberId'] as String,
        weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 0,
        frontUrl: map['frontUrl'] as String?,
        sideUrl: map['sideUrl'] as String?,
        backUrl: map['backUrl'] as String?,
        faceUrl: map['faceUrl'] as String?,
      );

  WeeklyProgressPhotos copyWith({
    String? frontUrl,
    String? sideUrl,
    String? backUrl,
    String? faceUrl,
  }) =>
      WeeklyProgressPhotos(
        memberId: memberId,
        weekNumber: weekNumber,
        frontUrl: frontUrl ?? this.frontUrl,
        sideUrl: sideUrl ?? this.sideUrl,
        backUrl: backUrl ?? this.backUrl,
        faceUrl: faceUrl ?? this.faceUrl,
      );
}

enum ProgressPhotoType { front, side, back, face }

extension ProgressPhotoTypeX on ProgressPhotoType {
  String get label {
    switch (this) {
      case ProgressPhotoType.front:
        return 'Front';
      case ProgressPhotoType.side:
        return 'Side';
      case ProgressPhotoType.back:
        return 'Back';
      case ProgressPhotoType.face:
        return 'Face';
    }
  }

  String get field {
    switch (this) {
      case ProgressPhotoType.front:
        return 'frontUrl';
      case ProgressPhotoType.side:
        return 'sideUrl';
      case ProgressPhotoType.back:
        return 'backUrl';
      case ProgressPhotoType.face:
        return 'faceUrl';
    }
  }
}
