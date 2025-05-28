
class Character {
  final int id;
  final String name;
  final String imagePath;
  final String description;
  final String personality; // 性格特徴
  final bool isFreeVersion; // 無料版で利用可能かどうか

  const Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.personality,
    this.isFreeVersion = false,
  });
  
  // デフォルトのキャラクターID（左上のキャラクター）
  static const int defaultCharacterId = 1;

  // IDからキャラクターを取得
  static Character getCharacterById(int id) {
    return CharacterService.characters.firstWhere(
      (character) => character.id == id,
      orElse: () => CharacterService.characters[defaultCharacterId - 1], // 配列は0から始まるので-1する
    );
  }
  
  // 無料版で利用可能なキャラクターのみを取得
  static List<Character> getFreeCharacters() {
    return CharacterService.characters.where((character) => character.isFreeVersion).toList();
  }
  
  // プレミアム版で利用可能なキャラクターを取得（全キャラクター）
  static List<Character> getAllCharacters() {
    return CharacterService.characters;
  }
}

class CharacterService {
  // 12種類のキャラクターを定義
  static const List<Character> characters = [
    Character(
      id: 1,
      name: "ポチ",
      imagePath: "assets/images/1.png",
      description: "元気で優しい犬のキャラクター",
      personality: "元気で明るく、友好的",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 2,
      name: "ミケ",
      imagePath: "assets/images/2.png",
      description: "落ち着いた猫のキャラクター",
      personality: "落ち着いた集中力がある",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 3,
      name: "クマ太",
      imagePath: "assets/images/3.png",
      description: "力強いくまのキャラクター",
      personality: "優しくて力強い",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 4,
      name: "ピョン子",
      imagePath: "assets/images/4.png",
      description: "可愛いうさぎのキャラクター",
      personality: "可愛らしく無邪気",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 5,
      name: "ハチ",
      imagePath: "assets/images/5.png",
      description: "忠実な犬のキャラクター",
      personality: "忠実で優しい",
    ),
    Character(
      id: 6,
      name: "ハム吉",
      imagePath: "assets/images/6.png",
      description: "可愛いハムスターのキャラクター",
      personality: "元気で好奇心旺盛",
    ),
    Character(
      id: 7,
      name: "クマ次郎",
      imagePath: "assets/images/7.png",
      description: "力強いくまのキャラクター",
      personality: "優しくて包容力がある",
    ),
    Character(
      id: 8,
      name: "ペン太",
      imagePath: "assets/images/8.png",
      description: "かわいいペンギンのキャラクター",
      personality: "真面目で愛らしい",
    ),
    Character(
      id: 9,
      name: "タマ",
      imagePath: "assets/images/9.png",
      description: "クールな猫のキャラクター",
      personality: "マイペースで落ち着いている",
    ),
    Character(
      id: 10,
      name: "ピヨ助",
      imagePath: "assets/images/10.png",
      description: "元気なひよこのキャラクター",
      personality: "無邪気で明るい",
    ),
    Character(
      id: 11,
      name: "シロ",
      imagePath: "assets/images/11.png",
      description: "優雅な猫のキャラクター",
      personality: "優雅で気品がある",
    ),
    Character(
      id: 12,
      name: "コロ",
      imagePath: "assets/images/12.png",
      description: "陽気な犬のキャラクター",
      personality: "陽気でフレンドリー",
    ),
  ];

  // デフォルトのキャラクターID（左上のキャラクター）
  static const int defaultCharacterId = 1;

  // IDからキャラクターを取得
  static Character getCharacterById(int id) {
    return characters.firstWhere(
      (character) => character.id == id,
      orElse: () => characters[defaultCharacterId - 1], // 配列は0から始まるので-1する
    );
  }
  
  // 画像パスからキャラクターIDを取得
  static int getCharacterIdByImagePath(String imagePath) {
    final character = characters.firstWhere(
      (character) => character.imagePath == imagePath,
      orElse: () => characters[defaultCharacterId - 1],
    );
    return character.id;
  }
  
  // 無料版で利用可能なキャラクターのみを取得
  static List<Character> getFreeCharacters() {
    return characters.where((character) => character.isFreeVersion).toList();
  }
  
  // プレミアム版で利用可能なキャラクターを取得（全キャラクター）
  static List<Character> getAllCharacters() {
    return characters;
  }
}
