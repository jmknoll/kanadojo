import Foundation

// MARK: - All Kana Data

enum KanaData {

    // MARK: Hiragana Main (46)
    static let hiraganaMain: [KanaCharacter] = [
        // A row
        KanaCharacter(id: "hiragana-a",   character: "あ", romaji: "a",   type: .hiragana, group: .main, row: "a"),
        KanaCharacter(id: "hiragana-i",   character: "い", romaji: "i",   type: .hiragana, group: .main, row: "a"),
        KanaCharacter(id: "hiragana-u",   character: "う", romaji: "u",   type: .hiragana, group: .main, row: "a"),
        KanaCharacter(id: "hiragana-e",   character: "え", romaji: "e",   type: .hiragana, group: .main, row: "a"),
        KanaCharacter(id: "hiragana-o",   character: "お", romaji: "o",   type: .hiragana, group: .main, row: "a"),
        // Ka row
        KanaCharacter(id: "hiragana-ka",  character: "か", romaji: "ka",  type: .hiragana, group: .main, row: "ka"),
        KanaCharacter(id: "hiragana-ki",  character: "き", romaji: "ki",  type: .hiragana, group: .main, row: "ka"),
        KanaCharacter(id: "hiragana-ku",  character: "く", romaji: "ku",  type: .hiragana, group: .main, row: "ka"),
        KanaCharacter(id: "hiragana-ke",  character: "け", romaji: "ke",  type: .hiragana, group: .main, row: "ka"),
        KanaCharacter(id: "hiragana-ko",  character: "こ", romaji: "ko",  type: .hiragana, group: .main, row: "ka"),
        // Sa row
        KanaCharacter(id: "hiragana-sa",  character: "さ", romaji: "sa",  type: .hiragana, group: .main, row: "sa"),
        KanaCharacter(id: "hiragana-shi", character: "し", romaji: "shi", alternateRomaji: ["si"], type: .hiragana, group: .main, row: "sa"),
        KanaCharacter(id: "hiragana-su",  character: "す", romaji: "su",  type: .hiragana, group: .main, row: "sa"),
        KanaCharacter(id: "hiragana-se",  character: "せ", romaji: "se",  type: .hiragana, group: .main, row: "sa"),
        KanaCharacter(id: "hiragana-so",  character: "そ", romaji: "so",  type: .hiragana, group: .main, row: "sa"),
        // Ta row
        KanaCharacter(id: "hiragana-ta",  character: "た", romaji: "ta",  type: .hiragana, group: .main, row: "ta"),
        KanaCharacter(id: "hiragana-chi", character: "ち", romaji: "chi", alternateRomaji: ["ti"], type: .hiragana, group: .main, row: "ta"),
        KanaCharacter(id: "hiragana-tsu", character: "つ", romaji: "tsu", alternateRomaji: ["tu"], type: .hiragana, group: .main, row: "ta"),
        KanaCharacter(id: "hiragana-te",  character: "て", romaji: "te",  type: .hiragana, group: .main, row: "ta"),
        KanaCharacter(id: "hiragana-to",  character: "と", romaji: "to",  type: .hiragana, group: .main, row: "ta"),
        // Na row
        KanaCharacter(id: "hiragana-na",  character: "な", romaji: "na",  type: .hiragana, group: .main, row: "na"),
        KanaCharacter(id: "hiragana-ni",  character: "に", romaji: "ni",  type: .hiragana, group: .main, row: "na"),
        KanaCharacter(id: "hiragana-nu",  character: "ぬ", romaji: "nu",  type: .hiragana, group: .main, row: "na"),
        KanaCharacter(id: "hiragana-ne",  character: "ね", romaji: "ne",  type: .hiragana, group: .main, row: "na"),
        KanaCharacter(id: "hiragana-no",  character: "の", romaji: "no",  type: .hiragana, group: .main, row: "na"),
        // Ha row
        KanaCharacter(id: "hiragana-ha",  character: "は", romaji: "ha",  type: .hiragana, group: .main, row: "ha"),
        KanaCharacter(id: "hiragana-hi",  character: "ひ", romaji: "hi",  type: .hiragana, group: .main, row: "ha"),
        KanaCharacter(id: "hiragana-fu",  character: "ふ", romaji: "fu",  alternateRomaji: ["hu"], type: .hiragana, group: .main, row: "ha"),
        KanaCharacter(id: "hiragana-he",  character: "へ", romaji: "he",  type: .hiragana, group: .main, row: "ha"),
        KanaCharacter(id: "hiragana-ho",  character: "ほ", romaji: "ho",  type: .hiragana, group: .main, row: "ha"),
        // Ma row
        KanaCharacter(id: "hiragana-ma",  character: "ま", romaji: "ma",  type: .hiragana, group: .main, row: "ma"),
        KanaCharacter(id: "hiragana-mi",  character: "み", romaji: "mi",  type: .hiragana, group: .main, row: "ma"),
        KanaCharacter(id: "hiragana-mu",  character: "む", romaji: "mu",  type: .hiragana, group: .main, row: "ma"),
        KanaCharacter(id: "hiragana-me",  character: "め", romaji: "me",  type: .hiragana, group: .main, row: "ma"),
        KanaCharacter(id: "hiragana-mo",  character: "も", romaji: "mo",  type: .hiragana, group: .main, row: "ma"),
        // Ya row
        KanaCharacter(id: "hiragana-ya",  character: "や", romaji: "ya",  type: .hiragana, group: .main, row: "ya"),
        KanaCharacter(id: "hiragana-yu",  character: "ゆ", romaji: "yu",  type: .hiragana, group: .main, row: "ya"),
        KanaCharacter(id: "hiragana-yo",  character: "よ", romaji: "yo",  type: .hiragana, group: .main, row: "ya"),
        // Ra row
        KanaCharacter(id: "hiragana-ra",  character: "ら", romaji: "ra",  type: .hiragana, group: .main, row: "ra"),
        KanaCharacter(id: "hiragana-ri",  character: "り", romaji: "ri",  type: .hiragana, group: .main, row: "ra"),
        KanaCharacter(id: "hiragana-ru",  character: "る", romaji: "ru",  type: .hiragana, group: .main, row: "ra"),
        KanaCharacter(id: "hiragana-re",  character: "れ", romaji: "re",  type: .hiragana, group: .main, row: "ra"),
        KanaCharacter(id: "hiragana-ro",  character: "ろ", romaji: "ro",  type: .hiragana, group: .main, row: "ra"),
        // Wa row
        KanaCharacter(id: "hiragana-wa",  character: "わ", romaji: "wa",  type: .hiragana, group: .main, row: "wa"),
        KanaCharacter(id: "hiragana-wo",  character: "を", romaji: "wo",  alternateRomaji: ["o"], type: .hiragana, group: .main, row: "wa"),
        // N
        KanaCharacter(id: "hiragana-n",   character: "ん", romaji: "n",   alternateRomaji: ["nn"], type: .hiragana, group: .main, row: "n"),
    ]

    // MARK: Hiragana Dakuten (25)
    static let hiraganaDakuten: [KanaCharacter] = [
        // Ga row
        KanaCharacter(id: "hiragana-ga",  character: "が", romaji: "ga",  type: .hiragana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "hiragana-gi",  character: "ぎ", romaji: "gi",  type: .hiragana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "hiragana-gu",  character: "ぐ", romaji: "gu",  type: .hiragana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "hiragana-ge",  character: "げ", romaji: "ge",  type: .hiragana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "hiragana-go",  character: "ご", romaji: "go",  type: .hiragana, group: .dakuten, row: "ga"),
        // Za row
        KanaCharacter(id: "hiragana-za",  character: "ざ", romaji: "za",  type: .hiragana, group: .dakuten, row: "za"),
        KanaCharacter(id: "hiragana-ji",  character: "じ", romaji: "ji",  alternateRomaji: ["zi"], type: .hiragana, group: .dakuten, row: "za"),
        KanaCharacter(id: "hiragana-zu",  character: "ず", romaji: "zu",  type: .hiragana, group: .dakuten, row: "za"),
        KanaCharacter(id: "hiragana-ze",  character: "ぜ", romaji: "ze",  type: .hiragana, group: .dakuten, row: "za"),
        KanaCharacter(id: "hiragana-zo",  character: "ぞ", romaji: "zo",  type: .hiragana, group: .dakuten, row: "za"),
        // Da row
        KanaCharacter(id: "hiragana-da",  character: "だ", romaji: "da",  type: .hiragana, group: .dakuten, row: "da"),
        KanaCharacter(id: "hiragana-di",  character: "ぢ", romaji: "ji",  alternateRomaji: ["di"], type: .hiragana, group: .dakuten, row: "da"),
        KanaCharacter(id: "hiragana-du",  character: "づ", romaji: "zu",  alternateRomaji: ["du"], type: .hiragana, group: .dakuten, row: "da"),
        KanaCharacter(id: "hiragana-de",  character: "で", romaji: "de",  type: .hiragana, group: .dakuten, row: "da"),
        KanaCharacter(id: "hiragana-do",  character: "ど", romaji: "do",  type: .hiragana, group: .dakuten, row: "da"),
        // Ba row
        KanaCharacter(id: "hiragana-ba",  character: "ば", romaji: "ba",  type: .hiragana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "hiragana-bi",  character: "び", romaji: "bi",  type: .hiragana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "hiragana-bu",  character: "ぶ", romaji: "bu",  type: .hiragana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "hiragana-be",  character: "べ", romaji: "be",  type: .hiragana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "hiragana-bo",  character: "ぼ", romaji: "bo",  type: .hiragana, group: .dakuten, row: "ba"),
        // Pa row
        KanaCharacter(id: "hiragana-pa",  character: "ぱ", romaji: "pa",  type: .hiragana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "hiragana-pi",  character: "ぴ", romaji: "pi",  type: .hiragana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "hiragana-pu",  character: "ぷ", romaji: "pu",  type: .hiragana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "hiragana-pe",  character: "ぺ", romaji: "pe",  type: .hiragana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "hiragana-po",  character: "ぽ", romaji: "po",  type: .hiragana, group: .dakuten, row: "pa"),
    ]

    // MARK: Hiragana Combination (36)
    static let hiraganaCombination: [KanaCharacter] = [
        KanaCharacter(id: "hiragana-kya", character: "きゃ", romaji: "kya", type: .hiragana, group: .combination, row: "kya"),
        KanaCharacter(id: "hiragana-kyu", character: "きゅ", romaji: "kyu", type: .hiragana, group: .combination, row: "kya"),
        KanaCharacter(id: "hiragana-kyo", character: "きょ", romaji: "kyo", type: .hiragana, group: .combination, row: "kya"),
        KanaCharacter(id: "hiragana-sha", character: "しゃ", romaji: "sha", alternateRomaji: ["sya"], type: .hiragana, group: .combination, row: "sha"),
        KanaCharacter(id: "hiragana-shu", character: "しゅ", romaji: "shu", alternateRomaji: ["syu"], type: .hiragana, group: .combination, row: "sha"),
        KanaCharacter(id: "hiragana-sho", character: "しょ", romaji: "sho", alternateRomaji: ["syo"], type: .hiragana, group: .combination, row: "sha"),
        KanaCharacter(id: "hiragana-cha", character: "ちゃ", romaji: "cha", alternateRomaji: ["tya"], type: .hiragana, group: .combination, row: "cha"),
        KanaCharacter(id: "hiragana-chu", character: "ちゅ", romaji: "chu", alternateRomaji: ["tyu"], type: .hiragana, group: .combination, row: "cha"),
        KanaCharacter(id: "hiragana-cho", character: "ちょ", romaji: "cho", alternateRomaji: ["tyo"], type: .hiragana, group: .combination, row: "cha"),
        KanaCharacter(id: "hiragana-nya", character: "にゃ", romaji: "nya", type: .hiragana, group: .combination, row: "nya"),
        KanaCharacter(id: "hiragana-nyu", character: "にゅ", romaji: "nyu", type: .hiragana, group: .combination, row: "nya"),
        KanaCharacter(id: "hiragana-nyo", character: "にょ", romaji: "nyo", type: .hiragana, group: .combination, row: "nya"),
        KanaCharacter(id: "hiragana-hya", character: "ひゃ", romaji: "hya", type: .hiragana, group: .combination, row: "hya"),
        KanaCharacter(id: "hiragana-hyu", character: "ひゅ", romaji: "hyu", type: .hiragana, group: .combination, row: "hya"),
        KanaCharacter(id: "hiragana-hyo", character: "ひょ", romaji: "hyo", type: .hiragana, group: .combination, row: "hya"),
        KanaCharacter(id: "hiragana-mya", character: "みゃ", romaji: "mya", type: .hiragana, group: .combination, row: "mya"),
        KanaCharacter(id: "hiragana-myu", character: "みゅ", romaji: "myu", type: .hiragana, group: .combination, row: "mya"),
        KanaCharacter(id: "hiragana-myo", character: "みょ", romaji: "myo", type: .hiragana, group: .combination, row: "mya"),
        KanaCharacter(id: "hiragana-rya", character: "りゃ", romaji: "rya", type: .hiragana, group: .combination, row: "rya"),
        KanaCharacter(id: "hiragana-ryu", character: "りゅ", romaji: "ryu", type: .hiragana, group: .combination, row: "rya"),
        KanaCharacter(id: "hiragana-ryo", character: "りょ", romaji: "ryo", type: .hiragana, group: .combination, row: "rya"),
        KanaCharacter(id: "hiragana-gya", character: "ぎゃ", romaji: "gya", type: .hiragana, group: .combination, row: "gya"),
        KanaCharacter(id: "hiragana-gyu", character: "ぎゅ", romaji: "gyu", type: .hiragana, group: .combination, row: "gya"),
        KanaCharacter(id: "hiragana-gyo", character: "ぎょ", romaji: "gyo", type: .hiragana, group: .combination, row: "gya"),
        KanaCharacter(id: "hiragana-ja",  character: "じゃ", romaji: "ja",  alternateRomaji: ["zya"], type: .hiragana, group: .combination, row: "ja"),
        KanaCharacter(id: "hiragana-ju",  character: "じゅ", romaji: "ju",  alternateRomaji: ["zyu"], type: .hiragana, group: .combination, row: "ja"),
        KanaCharacter(id: "hiragana-jo",  character: "じょ", romaji: "jo",  alternateRomaji: ["zyo"], type: .hiragana, group: .combination, row: "ja"),
        KanaCharacter(id: "hiragana-dya", character: "ぢゃ", romaji: "ja",  alternateRomaji: ["dya"], type: .hiragana, group: .combination, row: "dya"),
        KanaCharacter(id: "hiragana-dyu", character: "ぢゅ", romaji: "ju",  alternateRomaji: ["dyu"], type: .hiragana, group: .combination, row: "dya"),
        KanaCharacter(id: "hiragana-dyo", character: "ぢょ", romaji: "jo",  alternateRomaji: ["dyo"], type: .hiragana, group: .combination, row: "dya"),
        KanaCharacter(id: "hiragana-bya", character: "びゃ", romaji: "bya", type: .hiragana, group: .combination, row: "bya"),
        KanaCharacter(id: "hiragana-byu", character: "びゅ", romaji: "byu", type: .hiragana, group: .combination, row: "bya"),
        KanaCharacter(id: "hiragana-byo", character: "びょ", romaji: "byo", type: .hiragana, group: .combination, row: "bya"),
        KanaCharacter(id: "hiragana-pya", character: "ぴゃ", romaji: "pya", type: .hiragana, group: .combination, row: "pya"),
        KanaCharacter(id: "hiragana-pyu", character: "ぴゅ", romaji: "pyu", type: .hiragana, group: .combination, row: "pya"),
        KanaCharacter(id: "hiragana-pyo", character: "ぴょ", romaji: "pyo", type: .hiragana, group: .combination, row: "pya"),
    ]

    // MARK: Katakana Main (46)
    static let katakanaMain: [KanaCharacter] = [
        // A row
        KanaCharacter(id: "katakana-a",   character: "ア", romaji: "a",   type: .katakana, group: .main, row: "a"),
        KanaCharacter(id: "katakana-i",   character: "イ", romaji: "i",   type: .katakana, group: .main, row: "a"),
        KanaCharacter(id: "katakana-u",   character: "ウ", romaji: "u",   type: .katakana, group: .main, row: "a"),
        KanaCharacter(id: "katakana-e",   character: "エ", romaji: "e",   type: .katakana, group: .main, row: "a"),
        KanaCharacter(id: "katakana-o",   character: "オ", romaji: "o",   type: .katakana, group: .main, row: "a"),
        // Ka row
        KanaCharacter(id: "katakana-ka",  character: "カ", romaji: "ka",  type: .katakana, group: .main, row: "ka"),
        KanaCharacter(id: "katakana-ki",  character: "キ", romaji: "ki",  type: .katakana, group: .main, row: "ka"),
        KanaCharacter(id: "katakana-ku",  character: "ク", romaji: "ku",  type: .katakana, group: .main, row: "ka"),
        KanaCharacter(id: "katakana-ke",  character: "ケ", romaji: "ke",  type: .katakana, group: .main, row: "ka"),
        KanaCharacter(id: "katakana-ko",  character: "コ", romaji: "ko",  type: .katakana, group: .main, row: "ka"),
        // Sa row
        KanaCharacter(id: "katakana-sa",  character: "サ", romaji: "sa",  type: .katakana, group: .main, row: "sa"),
        KanaCharacter(id: "katakana-shi", character: "シ", romaji: "shi", alternateRomaji: ["si"], type: .katakana, group: .main, row: "sa"),
        KanaCharacter(id: "katakana-su",  character: "ス", romaji: "su",  type: .katakana, group: .main, row: "sa"),
        KanaCharacter(id: "katakana-se",  character: "セ", romaji: "se",  type: .katakana, group: .main, row: "sa"),
        KanaCharacter(id: "katakana-so",  character: "ソ", romaji: "so",  type: .katakana, group: .main, row: "sa"),
        // Ta row
        KanaCharacter(id: "katakana-ta",  character: "タ", romaji: "ta",  type: .katakana, group: .main, row: "ta"),
        KanaCharacter(id: "katakana-chi", character: "チ", romaji: "chi", alternateRomaji: ["ti"], type: .katakana, group: .main, row: "ta"),
        KanaCharacter(id: "katakana-tsu", character: "ツ", romaji: "tsu", alternateRomaji: ["tu"], type: .katakana, group: .main, row: "ta"),
        KanaCharacter(id: "katakana-te",  character: "テ", romaji: "te",  type: .katakana, group: .main, row: "ta"),
        KanaCharacter(id: "katakana-to",  character: "ト", romaji: "to",  type: .katakana, group: .main, row: "ta"),
        // Na row
        KanaCharacter(id: "katakana-na",  character: "ナ", romaji: "na",  type: .katakana, group: .main, row: "na"),
        KanaCharacter(id: "katakana-ni",  character: "ニ", romaji: "ni",  type: .katakana, group: .main, row: "na"),
        KanaCharacter(id: "katakana-nu",  character: "ヌ", romaji: "nu",  type: .katakana, group: .main, row: "na"),
        KanaCharacter(id: "katakana-ne",  character: "ネ", romaji: "ne",  type: .katakana, group: .main, row: "na"),
        KanaCharacter(id: "katakana-no",  character: "ノ", romaji: "no",  type: .katakana, group: .main, row: "na"),
        // Ha row
        KanaCharacter(id: "katakana-ha",  character: "ハ", romaji: "ha",  type: .katakana, group: .main, row: "ha"),
        KanaCharacter(id: "katakana-hi",  character: "ヒ", romaji: "hi",  type: .katakana, group: .main, row: "ha"),
        KanaCharacter(id: "katakana-fu",  character: "フ", romaji: "fu",  alternateRomaji: ["hu"], type: .katakana, group: .main, row: "ha"),
        KanaCharacter(id: "katakana-he",  character: "ヘ", romaji: "he",  type: .katakana, group: .main, row: "ha"),
        KanaCharacter(id: "katakana-ho",  character: "ホ", romaji: "ho",  type: .katakana, group: .main, row: "ha"),
        // Ma row
        KanaCharacter(id: "katakana-ma",  character: "マ", romaji: "ma",  type: .katakana, group: .main, row: "ma"),
        KanaCharacter(id: "katakana-mi",  character: "ミ", romaji: "mi",  type: .katakana, group: .main, row: "ma"),
        KanaCharacter(id: "katakana-mu",  character: "ム", romaji: "mu",  type: .katakana, group: .main, row: "ma"),
        KanaCharacter(id: "katakana-me",  character: "メ", romaji: "me",  type: .katakana, group: .main, row: "ma"),
        KanaCharacter(id: "katakana-mo",  character: "モ", romaji: "mo",  type: .katakana, group: .main, row: "ma"),
        // Ya row
        KanaCharacter(id: "katakana-ya",  character: "ヤ", romaji: "ya",  type: .katakana, group: .main, row: "ya"),
        KanaCharacter(id: "katakana-yu",  character: "ユ", romaji: "yu",  type: .katakana, group: .main, row: "ya"),
        KanaCharacter(id: "katakana-yo",  character: "ヨ", romaji: "yo",  type: .katakana, group: .main, row: "ya"),
        // Ra row
        KanaCharacter(id: "katakana-ra",  character: "ラ", romaji: "ra",  type: .katakana, group: .main, row: "ra"),
        KanaCharacter(id: "katakana-ri",  character: "リ", romaji: "ri",  type: .katakana, group: .main, row: "ra"),
        KanaCharacter(id: "katakana-ru",  character: "ル", romaji: "ru",  type: .katakana, group: .main, row: "ra"),
        KanaCharacter(id: "katakana-re",  character: "レ", romaji: "re",  type: .katakana, group: .main, row: "ra"),
        KanaCharacter(id: "katakana-ro",  character: "ロ", romaji: "ro",  type: .katakana, group: .main, row: "ra"),
        // Wa row
        KanaCharacter(id: "katakana-wa",  character: "ワ", romaji: "wa",  type: .katakana, group: .main, row: "wa"),
        KanaCharacter(id: "katakana-wo",  character: "ヲ", romaji: "wo",  alternateRomaji: ["o"], type: .katakana, group: .main, row: "wa"),
        // N
        KanaCharacter(id: "katakana-n",   character: "ン", romaji: "n",   alternateRomaji: ["nn"], type: .katakana, group: .main, row: "n"),
    ]

    // MARK: Katakana Dakuten (25)
    static let katakanaDakuten: [KanaCharacter] = [
        KanaCharacter(id: "katakana-ga",  character: "ガ", romaji: "ga",  type: .katakana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "katakana-gi",  character: "ギ", romaji: "gi",  type: .katakana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "katakana-gu",  character: "グ", romaji: "gu",  type: .katakana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "katakana-ge",  character: "ゲ", romaji: "ge",  type: .katakana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "katakana-go",  character: "ゴ", romaji: "go",  type: .katakana, group: .dakuten, row: "ga"),
        KanaCharacter(id: "katakana-za",  character: "ザ", romaji: "za",  type: .katakana, group: .dakuten, row: "za"),
        KanaCharacter(id: "katakana-ji",  character: "ジ", romaji: "ji",  alternateRomaji: ["zi"], type: .katakana, group: .dakuten, row: "za"),
        KanaCharacter(id: "katakana-zu",  character: "ズ", romaji: "zu",  type: .katakana, group: .dakuten, row: "za"),
        KanaCharacter(id: "katakana-ze",  character: "ゼ", romaji: "ze",  type: .katakana, group: .dakuten, row: "za"),
        KanaCharacter(id: "katakana-zo",  character: "ゾ", romaji: "zo",  type: .katakana, group: .dakuten, row: "za"),
        KanaCharacter(id: "katakana-da",  character: "ダ", romaji: "da",  type: .katakana, group: .dakuten, row: "da"),
        KanaCharacter(id: "katakana-di",  character: "ヂ", romaji: "ji",  alternateRomaji: ["di"], type: .katakana, group: .dakuten, row: "da"),
        KanaCharacter(id: "katakana-du",  character: "ヅ", romaji: "zu",  alternateRomaji: ["du"], type: .katakana, group: .dakuten, row: "da"),
        KanaCharacter(id: "katakana-de",  character: "デ", romaji: "de",  type: .katakana, group: .dakuten, row: "da"),
        KanaCharacter(id: "katakana-do",  character: "ド", romaji: "do",  type: .katakana, group: .dakuten, row: "da"),
        KanaCharacter(id: "katakana-ba",  character: "バ", romaji: "ba",  type: .katakana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "katakana-bi",  character: "ビ", romaji: "bi",  type: .katakana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "katakana-bu",  character: "ブ", romaji: "bu",  type: .katakana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "katakana-be",  character: "ベ", romaji: "be",  type: .katakana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "katakana-bo",  character: "ボ", romaji: "bo",  type: .katakana, group: .dakuten, row: "ba"),
        KanaCharacter(id: "katakana-pa",  character: "パ", romaji: "pa",  type: .katakana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "katakana-pi",  character: "ピ", romaji: "pi",  type: .katakana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "katakana-pu",  character: "プ", romaji: "pu",  type: .katakana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "katakana-pe",  character: "ペ", romaji: "pe",  type: .katakana, group: .dakuten, row: "pa"),
        KanaCharacter(id: "katakana-po",  character: "ポ", romaji: "po",  type: .katakana, group: .dakuten, row: "pa"),
    ]

    // MARK: Katakana Combination (36)
    static let katakanaCombination: [KanaCharacter] = [
        KanaCharacter(id: "katakana-kya", character: "キャ", romaji: "kya", type: .katakana, group: .combination, row: "kya"),
        KanaCharacter(id: "katakana-kyu", character: "キュ", romaji: "kyu", type: .katakana, group: .combination, row: "kya"),
        KanaCharacter(id: "katakana-kyo", character: "キョ", romaji: "kyo", type: .katakana, group: .combination, row: "kya"),
        KanaCharacter(id: "katakana-sha", character: "シャ", romaji: "sha", alternateRomaji: ["sya"], type: .katakana, group: .combination, row: "sha"),
        KanaCharacter(id: "katakana-shu", character: "シュ", romaji: "shu", alternateRomaji: ["syu"], type: .katakana, group: .combination, row: "sha"),
        KanaCharacter(id: "katakana-sho", character: "ショ", romaji: "sho", alternateRomaji: ["syo"], type: .katakana, group: .combination, row: "sha"),
        KanaCharacter(id: "katakana-cha", character: "チャ", romaji: "cha", alternateRomaji: ["tya"], type: .katakana, group: .combination, row: "cha"),
        KanaCharacter(id: "katakana-chu", character: "チュ", romaji: "chu", alternateRomaji: ["tyu"], type: .katakana, group: .combination, row: "cha"),
        KanaCharacter(id: "katakana-cho", character: "チョ", romaji: "cho", alternateRomaji: ["tyo"], type: .katakana, group: .combination, row: "cha"),
        KanaCharacter(id: "katakana-nya", character: "ニャ", romaji: "nya", type: .katakana, group: .combination, row: "nya"),
        KanaCharacter(id: "katakana-nyu", character: "ニュ", romaji: "nyu", type: .katakana, group: .combination, row: "nya"),
        KanaCharacter(id: "katakana-nyo", character: "ニョ", romaji: "nyo", type: .katakana, group: .combination, row: "nya"),
        KanaCharacter(id: "katakana-hya", character: "ヒャ", romaji: "hya", type: .katakana, group: .combination, row: "hya"),
        KanaCharacter(id: "katakana-hyu", character: "ヒュ", romaji: "hyu", type: .katakana, group: .combination, row: "hya"),
        KanaCharacter(id: "katakana-hyo", character: "ヒョ", romaji: "hyo", type: .katakana, group: .combination, row: "hya"),
        KanaCharacter(id: "katakana-mya", character: "ミャ", romaji: "mya", type: .katakana, group: .combination, row: "mya"),
        KanaCharacter(id: "katakana-myu", character: "ミュ", romaji: "myu", type: .katakana, group: .combination, row: "mya"),
        KanaCharacter(id: "katakana-myo", character: "ミョ", romaji: "myo", type: .katakana, group: .combination, row: "mya"),
        KanaCharacter(id: "katakana-rya", character: "リャ", romaji: "rya", type: .katakana, group: .combination, row: "rya"),
        KanaCharacter(id: "katakana-ryu", character: "リュ", romaji: "ryu", type: .katakana, group: .combination, row: "rya"),
        KanaCharacter(id: "katakana-ryo", character: "リョ", romaji: "ryo", type: .katakana, group: .combination, row: "rya"),
        KanaCharacter(id: "katakana-gya", character: "ギャ", romaji: "gya", type: .katakana, group: .combination, row: "gya"),
        KanaCharacter(id: "katakana-gyu", character: "ギュ", romaji: "gyu", type: .katakana, group: .combination, row: "gya"),
        KanaCharacter(id: "katakana-gyo", character: "ギョ", romaji: "gyo", type: .katakana, group: .combination, row: "gya"),
        KanaCharacter(id: "katakana-ja",  character: "ジャ", romaji: "ja",  alternateRomaji: ["zya"], type: .katakana, group: .combination, row: "ja"),
        KanaCharacter(id: "katakana-ju",  character: "ジュ", romaji: "ju",  alternateRomaji: ["zyu"], type: .katakana, group: .combination, row: "ja"),
        KanaCharacter(id: "katakana-jo",  character: "ジョ", romaji: "jo",  alternateRomaji: ["zyo"], type: .katakana, group: .combination, row: "ja"),
        KanaCharacter(id: "katakana-dya", character: "ヂャ", romaji: "ja",  alternateRomaji: ["dya"], type: .katakana, group: .combination, row: "dya"),
        KanaCharacter(id: "katakana-dyu", character: "ヂュ", romaji: "ju",  alternateRomaji: ["dyu"], type: .katakana, group: .combination, row: "dya"),
        KanaCharacter(id: "katakana-dyo", character: "ヂョ", romaji: "jo",  alternateRomaji: ["dyo"], type: .katakana, group: .combination, row: "dya"),
        KanaCharacter(id: "katakana-bya", character: "ビャ", romaji: "bya", type: .katakana, group: .combination, row: "bya"),
        KanaCharacter(id: "katakana-byu", character: "ビュ", romaji: "byu", type: .katakana, group: .combination, row: "bya"),
        KanaCharacter(id: "katakana-byo", character: "ビョ", romaji: "byo", type: .katakana, group: .combination, row: "bya"),
        KanaCharacter(id: "katakana-pya", character: "ピャ", romaji: "pya", type: .katakana, group: .combination, row: "pya"),
        KanaCharacter(id: "katakana-pyu", character: "ピュ", romaji: "pyu", type: .katakana, group: .combination, row: "pya"),
        KanaCharacter(id: "katakana-pyo", character: "ピョ", romaji: "pyo", type: .katakana, group: .combination, row: "pya"),
    ]

    // MARK: Aggregated

    static let hiragana: [KanaCharacter] = hiraganaMain + hiraganaDakuten + hiraganaCombination
    static let katakana: [KanaCharacter] = katakanaMain + katakanaDakuten + katakanaCombination
    static let allCharacters: [KanaCharacter] = hiragana + katakana

    // MARK: Query Helpers

    static func getCharacters(kanaType: KanaTypeSelection, group: GroupSelection) -> [KanaCharacter] {
        let base: [KanaCharacter]
        switch kanaType {
        case .hiragana: base = hiragana
        case .katakana: base = katakana
        case .both: base = allCharacters
        }
        switch group {
        case .all: return base
        case .main: return base.filter { $0.group == .main }
        case .dakuten: return base.filter { $0.group == .dakuten }
        case .combination: return base.filter { $0.group == .combination }
        }
    }
}
