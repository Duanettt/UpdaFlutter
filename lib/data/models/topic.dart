class Topic {
  final int? id;
  final String name;
  final int createdAt;

  Topic({this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': createdAt};
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      name: map['name'],
      createdAt: map['createdAt'],
    );
  }
}

