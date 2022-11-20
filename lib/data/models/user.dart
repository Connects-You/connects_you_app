class User {
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final String publicKey;

  const User({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.publicKey,
  });
}

class AuthenticatedUser extends User {
  final String privateKey;
  final String token;

  const AuthenticatedUser({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
    required String publicKey,
    required this.privateKey,
    required this.token,
  }) : super(
          email: email,
          userId: userId,
          name: name,
          photoUrl: photoUrl,
          publicKey: publicKey,
        );

  @override
  String toString() {
    return 'userId:$userId, name:$name, email:$email, photo:$photoUrl, publicKey:$publicKey, privateKey:$privateKey, token:$token';
  }
}

class LocalDBUser extends User {
  final String? privateKey;

  const LocalDBUser({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
    required String publicKey,
    this.privateKey,
  }) : super(
          email: email,
          userId: userId,
          name: name,
          photoUrl: photoUrl,
          publicKey: publicKey,
        );

  @override
  String toString() {
    return 'userId:$userId, name:$name, email:$email, photo:$photoUrl, publicKey:$publicKey, privateKey:$privateKey';
  }
}
