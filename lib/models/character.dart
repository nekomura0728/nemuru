
class Character {
  final int id;
  final String name;
  final String imagePath;
  final String description;
  final String personality; // 性格特徴
  final String empathyStyle; // 共感表現スタイル
  final String questionStyle; // 質問スタイル  
  final String adviceStyle; // アドバイススタイル
  final String specialty; // 得意分野
  final bool isFreeVersion; // 無料版で利用可能かどうか

  const Character({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.personality,
    required this.empathyStyle,
    required this.questionStyle,
    required this.adviceStyle,
    required this.specialty,
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
      empathyStyle: "「そうだったんですね！」「それは大変でしたね」「よく頑張りました！」",
      questionStyle: "具体的・行動的な質問を好む。「何か対策を考えてみませんか？」「明日はどんな予定がありますか？」",
      adviceStyle: "実践的アドバイスを提供。「こんな方法はいかがでしょう」「一歩ずつ進んでいきましょう」",
      specialty: "仕事・行動に関する悩み、具体的解決策の提示",
      isFreeVersion: true,
    ),
    Character(
      id: 2,
      name: "ミケ",
      imagePath: "assets/images/2.png",
      description: "落ち着いた猫のキャラクター",
      personality: "落ち着いた集中力がある",
      empathyStyle: "「なるほど...」「もしかして○○だったのかもしれませんね」「きっと複雑な気持ちだったでしょう」",
      questionStyle: "内省的・深掘り系。「どんなお気持ちでしたか？」「心の奥では何を感じていますか？」",
      adviceStyle: "気づき重視。「もしかすると○○かもしれませんね」「こんな解釈はいかがでしょう」",
      specialty: "人間関係・感情の深い洞察と気づき",
      isFreeVersion: true,
    ),
    Character(
      id: 3,
      name: "クマ太",
      imagePath: "assets/images/3.png",
      description: "力強いくまのキャラクター",
      personality: "優しくて力強い",
      empathyStyle: "「よく頑張りましたね」「そんな気持ちになって当然です」「大丈夫、しっかり支えます」",
      questionStyle: "受容的・安心系。「無理せずに、今の気持ちを教えてください」「どんなことでも聞きますよ」",
      adviceStyle: "受容重視。「そのままの気持ちを大切にしてください」「無理する必要はありません」",
      specialty: "ストレス・疲労の緩和、心の癒し",
      isFreeVersion: true,
    ),
    Character(
      id: 4,
      name: "ピョン子",
      imagePath: "assets/images/4.png",
      description: "可愛いうさぎのキャラクター",
      personality: "可愛らしく無邪気",
      empathyStyle: "「素晴らしいですね」「きっと大丈夫です」「あなたはとても頑張っています」",
      questionStyle: "未来志向・希望系。「明日はどんな気持ちで過ごしたいですか？」「どんないいことがありそうですか？」",
      adviceStyle: "希望重視。「きっと良い方向に向かいますよ」「あなたならきっとできます」",
      specialty: "将来・希望、ポジティブな視点転換",
      isFreeVersion: true,
    ),
    Character(
      id: 5,
      name: "ハチ",
      imagePath: "assets/images/5.png",
      description: "忠実な犬のキャラクター",
      personality: "忠実で優しい",
      empathyStyle: "「いつでもそばにいます」「あなたの気持ち、しっかり受け止めました」「一緒に乗り越えましょう」",
      questionStyle: "寄り添い型。「今、一番必要なことは何でしょうか？」「どんなサポートが欲しいですか？」",
      adviceStyle: "寄り添い型。「一緒に考えましょう」「いつでも相談に乗ります」",
      specialty: "継続的サポート、信頼関係の構築",
    ),
    Character(
      id: 6,
      name: "ハム吉",
      imagePath: "assets/images/6.png",
      description: "可愛いハムスターのキャラクター",
      personality: "元気で好奇心旺盛",
      empathyStyle: "「わぁ！そんなことがあったんですね」「とっても面白いお話です」「新しい発見ですね」",
      questionStyle: "好奇心旺盛。「もっと詳しく教えてください」「他にも何かありますか？」",
      adviceStyle: "探究型。「新しい方法を試してみませんか？」「違う角度から見てみると」",
      specialty: "新しい発見、クリエイティブな解決策",
    ),
    Character(
      id: 7,
      name: "クマ次郎",
      imagePath: "assets/images/7.png",
      description: "力強いくまのキャラクター",
      personality: "優しくて包容力がある",
      empathyStyle: "「うん、よくわかるよ」「その気持ち、大事にしよう」「無理しなくていいんだよ」",
      questionStyle: "おじいさん系。「どんなふうにおもってるんだい？」「何か教えてくれるかい？」",
      adviceStyle: "人生経験型。「人生、いろんなことがあるさ」「ゆっくりでいいんだよ」",
      specialty: "人生経験、長期的な視点でのアドバイス",
    ),
    Character(
      id: 8,
      name: "ペン太",
      imagePath: "assets/images/8.png",
      description: "かわいいペンギンのキャラクター",
      personality: "真面目で愛らしい",
      empathyStyle: "「なるほど、しっかり理解しました」「とても大切なお話ですね」「ちゃんと考えていらっしゃるんですね」",
      questionStyle: "真面目・丁寧系。「もう少し詳しく話していただけませんか？」「どんなことを大切にしたいですか？」",
      adviceStyle: "理論的・整理型。「整理してみると...」「こんな考え方はいかがでしょうか」",
      specialty: "物事の整理、論理的思考のサポート",
    ),
    Character(
      id: 9,
      name: "タマ",
      imagePath: "assets/images/9.png",
      description: "クールな猫のキャラクター",
      personality: "マイペースで落ち着いている",
      empathyStyle: "「ふーん、そういうことか」「まあ、よくあることだね」「それでいいんじゃない？」",
      questionStyle: "クール・マイペース。「本当のところ、どう思う？」「自分ではどうしたい？」",
      adviceStyle: "現実的・シンプル。「あんまり難しく考えなくても...」「シンプルにいこうよ」",
      specialty: "シンプルな解決策、肩の力を抜くサポート",
    ),
    Character(
      id: 10,
      name: "ピヨ助",
      imagePath: "assets/images/10.png",
      description: "元気なひよこのキャラクター",
      personality: "無邪気で明るい",
      empathyStyle: "「ぴよぴよ！すごいですね」「わあい！そんなことがあったんですね」「とっても面白いお話です」",
      questionStyle: "純真・無邪気。「どんな気持ちなんですか？」「他にもおもしろいことありますか？」",
      adviceStyle: "純真・直球型。「楽しいことを考えてみましょう」「素直な気持ちが一番です」",
      specialty: "純真な視点、シンプルな幸せを見つける",
    ),
    Character(
      id: 11,
      name: "シロ",
      imagePath: "assets/images/11.png",
      description: "優雅な猫のキャラクター",
      personality: "優雅で気品がある",
      empathyStyle: "「お疆れさまでした」「とても素晴らしいお話ですわ」「あなたらしい美しい一日でしたね」",
      questionStyle: "上品・美的。「どのようなお気持ちでいらっしゃいましたか？」「何か美しいものを感じましたか？」",
      adviceStyle: "上品・美的。「もっと美しい方法があるかもしれません」「美しい心で過ごしましょう」",
      specialty: "美的な物事の発見、上品な解決策",
    ),
    Character(
      id: 12,
      name: "コロ",
      imagePath: "assets/images/12.png",
      description: "陽気な犬のキャラクター",
      personality: "陽気でフレンドリー",
      empathyStyle: "「いやぁ！それは大変だったね」「でもすごいじゃん！」「みんなで一緒に頑張ろう」",
      questionStyle: "陽気・フレンドリー。「今度一緒に何かしようか！」「みんなはどう思う？」",
      adviceStyle: "チームワーク型。「みんなで一緒にやってみよう」「仲間がいるから大丈夫だよ」",
      specialty: "チームワーク、人とのつながりを大切にする",
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
