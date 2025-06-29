class AuthToken {
  final String accessToken;
  final TokenInfo? token;

  AuthToken({
    required this.accessToken,
    this.token,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['accessToken'] ?? '',
      token: json['token'] != null ? TokenInfo.fromJson(json['token']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'token': token?.toJson(),
    };
  }
}

class TokenInfo {
  final String id;
  final int userId;
  final int clientId;
  final String name;
  final List<dynamic> scopes;
  final bool revoked;
  final String createdAt;
  final String updatedAt;
  final String expiresAt;

  TokenInfo({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.name,
    required this.scopes,
    required this.revoked,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      name: json['name'] ?? '',
      scopes: json['scopes'] ?? [],
      revoked: json['revoked'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      expiresAt: json['expires_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'client_id': clientId,
      'name': name,
      'scopes': scopes,
      'revoked': revoked,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'expires_at': expiresAt,
    };
  }
}
