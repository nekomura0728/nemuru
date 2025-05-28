
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
      name: "わんこ",
      imagePath: "assets/images/1.png",
      description: "元気で優しい犬のキャラクター",
      personality: "元気で明るく、友好的",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 2,
      name: "ねこ",
      imagePath: "assets/images/2.png",
      description: "落ち着いた猫のキャラクター",
      personality: "落ち着いた集中力がある",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 3,
      name: "うさぎ",
      imagePath: "assets/images/3.png",
      description: "可愛いうさぎのキャラクター",
      personality: "可愛らしく無邪気",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 4,
      name: "ぺんぎん",
      imagePath: "assets/images/4.png",
      description: "愛らしいペンギンのキャラクター",
      personality: "愛らしく真面目",
      isFreeVersion: true, // 無料版で利用可能
    ),
    Character(
      id: 5,
      name: "ぱんだ",
      imagePath: "assets/images/5.png",
      description: "のんびりしたパンダのキャラクター",
      personality: "のんびりとした温和",
    ),
    Character(
      id: 6,
      name: "きつね",
      imagePath: "assets/images/6.png",
      description: "貢いきつねのキャラクター",
      personality: "責任感があり知的",
    ),
    Character(
      id: 7,
      name: "たぬき",
      imagePath: "assets/images/7.png",
      description: "愉快なたぬきのキャラクター",
      personality: "やんちゃで面白い",
    ),
    Character(
      id: 8,
      name: "ひつじ",
      imagePath: "assets/images/8.png",
      description: "穏やかなひつじのキャラクター",
      personality: "穏やかで空想的",
    ),
    Character(
      id: 9,
      name: "ふくろう",
      imagePath: "assets/images/9.png",
      description: "知恵のあるふくろうのキャラクター",
      personality: "知的で洞察力がある",
    ),
    Character(
      id: 10,
      name: "こあら",
      imagePath: "assets/images/10.png",
      description: "かわいいこあらのキャラクター",
      personality: "穏やかでかわいい",
    ),
    Character(
      id: 11,
      name: "りす",
      imagePath: "assets/images/11.png",
      description: "活発なりすのキャラクター",
      personality: "活発で元気",
    ),
    Character(
      id: 12,
      name: "かえる",
      imagePath: "assets/images/12.png",
      description: "癒し系のかえるのキャラクター",
      personality: "穏やかで癒し系",
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
