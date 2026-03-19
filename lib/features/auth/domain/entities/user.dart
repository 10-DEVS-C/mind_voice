class User {
  final String id;
  final String email;
  final String username;
  final String name;
  final String plan;

  const User({
    required this.id,
    required this.email,
    this.username = '',
    this.name = '',
    this.plan = 'basic',
  });
}
