import 'package:flutter/material.dart';

class Atom {
  final String name;
  final IconData? icon;
  final String? imagePath;
  final List<String> tags;
  final String? description; 
  bool isDone;

  Atom({required this.name, this.icon, this.isDone = false, this.tags = const[], this.imagePath, this.description});

  Map<String, dynamic> toJson() => {
        "name": name,
        "icon": icon?.codePoint,
        "imagePath" : imagePath,
        "isDone": isDone,
        "tags" : tags,
        "description" : description
      };

  static Atom fromJson(Map<String, dynamic> json) {
    return Atom(
      name: json["name"],
      imagePath: json["imagePath"],
      icon: json["icon"] != null
          ? IconData(json["icon"], fontFamily: 'MaterialIcons')
          : null,
      tags: List<String>.from(json["tags"] ?? []),
      isDone: json["isDone"],
      description: json["description"], 
    );
  }
}
