import Foundation

// MARK: - Word Data

enum WordData {

    // MARK: - All Words

    /// Complete curated word list. Words with fewer than 3 kana characters are excluded.
    /// Loanwords with no hiragana form set hiragana = "".
    static let allWords: [WordEntry] = foodAndDrink + body + timeCalendar + people + nature + places + dailyLife + adjectives + verbs + other

    // MARK: - Query

    static func getWords(scriptType: WordScriptType, categories: [WordCategory]) -> [WordEntry] {
        allWords
            .filter { $0.kana(for: scriptType) != nil }
            .filter { categories.isEmpty || categories.contains($0.category) }
    }

    // MARK: - Categories

    static let foodAndDrink: [WordEntry] = [
        WordEntry(id: "gohan",       hiragana: "ごはん",       katakana: "",           romaji: "gohan",       english: "rice / meal",     category: .foodAndDrink),
        WordEntry(id: "ocha",        hiragana: "おちゃ",       katakana: "",           romaji: "ocha",        english: "tea",             category: .foodAndDrink),
        WordEntry(id: "sakana",      hiragana: "さかな",       katakana: "",           romaji: "sakana",      english: "fish",            category: .foodAndDrink),
        WordEntry(id: "yasai",       hiragana: "やさい",       katakana: "",           romaji: "yasai",       english: "vegetables",      category: .foodAndDrink),
        WordEntry(id: "kudamono",    hiragana: "くだもの",     katakana: "",           romaji: "kudamono",    english: "fruit",           category: .foodAndDrink),
        WordEntry(id: "tamago",      hiragana: "たまご",       katakana: "",           romaji: "tamago",      english: "egg",             category: .foodAndDrink),
        WordEntry(id: "satou",       hiragana: "さとう",       katakana: "",           romaji: "satou",       english: "sugar",           category: .foodAndDrink),
        WordEntry(id: "shouyu",      hiragana: "しょうゆ",     katakana: "",           romaji: "shouyu",      english: "soy sauce",       category: .foodAndDrink),
        WordEntry(id: "udon",        hiragana: "うどん",       katakana: "",           romaji: "udon",        english: "udon noodles",    category: .foodAndDrink),
        WordEntry(id: "tenpura",     hiragana: "てんぷら",     katakana: "",           romaji: "tenpura",     english: "tempura",         category: .foodAndDrink),
        WordEntry(id: "osake",       hiragana: "おさけ",       katakana: "",           romaji: "osake",       english: "sake / alcohol",  category: .foodAndDrink),
        WordEntry(id: "tabemono",    hiragana: "たべもの",     katakana: "",           romaji: "tabemono",    english: "food",            category: .foodAndDrink),
        WordEntry(id: "nomimono",    hiragana: "のみもの",     katakana: "",           romaji: "nomimono",    english: "drink / beverage", category: .foodAndDrink),
        WordEntry(id: "ringo",       hiragana: "りんご",       katakana: "",           romaji: "ringo",       english: "apple",           category: .foodAndDrink),
        WordEntry(id: "koohii",      hiragana: "",             katakana: "コーヒー",   romaji: "koohii",      english: "coffee",          category: .foodAndDrink),
        WordEntry(id: "juusu",       hiragana: "",             katakana: "ジュース",   romaji: "juusu",       english: "juice",           category: .foodAndDrink),
        WordEntry(id: "miruku",      hiragana: "",             katakana: "ミルク",     romaji: "miruku",      english: "milk",            category: .foodAndDrink),
        WordEntry(id: "biiru",       hiragana: "",             katakana: "ビール",     romaji: "biiru",       english: "beer",            category: .foodAndDrink),
        WordEntry(id: "raamen",      hiragana: "",             katakana: "ラーメン",   romaji: "raamen",      english: "ramen",           category: .foodAndDrink),
        WordEntry(id: "keeki",       hiragana: "",             katakana: "ケーキ",     romaji: "keeki",       english: "cake",            category: .foodAndDrink),
        WordEntry(id: "banana",      hiragana: "",             katakana: "バナナ",     romaji: "banana",      english: "banana",          category: .foodAndDrink),
        WordEntry(id: "tomato",      hiragana: "",             katakana: "トマト",     romaji: "tomato",      english: "tomato",          category: .foodAndDrink),
        WordEntry(id: "chiizu",      hiragana: "",             katakana: "チーズ",     romaji: "chiizu",      english: "cheese",          category: .foodAndDrink),
        WordEntry(id: "resutoran",   hiragana: "",             katakana: "レストラン", romaji: "resutoran",   english: "restaurant",      category: .foodAndDrink),
        WordEntry(id: "menyuu",      hiragana: "",             katakana: "メニュー",   romaji: "menyuu",      english: "menu",            category: .foodAndDrink),
    ]

    static let body: [WordEntry] = [
        WordEntry(id: "karada",   hiragana: "からだ",   katakana: "", romaji: "karada",  english: "body",        category: .body),
        WordEntry(id: "atama",    hiragana: "あたま",   katakana: "", romaji: "atama",   english: "head",        category: .body),
        WordEntry(id: "kokoro",   hiragana: "こころ",   katakana: "", romaji: "kokoro",  english: "heart / mind", category: .body),
        WordEntry(id: "onaka",    hiragana: "おなか",   katakana: "", romaji: "onaka",   english: "stomach",     category: .body),
        WordEntry(id: "senaka",   hiragana: "せなか",   katakana: "", romaji: "senaka",  english: "back",        category: .body),
        WordEntry(id: "hitai",    hiragana: "ひたい",   katakana: "", romaji: "hitai",   english: "forehead",    category: .body),
        WordEntry(id: "inochi",   hiragana: "いのち",   katakana: "", romaji: "inochi",  english: "life",        category: .body),
    ]

    static let timeCalendar: [WordEntry] = [
        WordEntry(id: "mainichi",    hiragana: "まいにち",     katakana: "", romaji: "mainichi",    english: "every day",   category: .timeCalendar),
        WordEntry(id: "kyou",        hiragana: "きょう",       katakana: "", romaji: "kyou",        english: "today",       category: .timeCalendar),
        WordEntry(id: "ashita",      hiragana: "あした",       katakana: "", romaji: "ashita",      english: "tomorrow",    category: .timeCalendar),
        WordEntry(id: "kinou",       hiragana: "きのう",       katakana: "", romaji: "kinou",       english: "yesterday",   category: .timeCalendar),
        WordEntry(id: "yuugata",     hiragana: "ゆうがた",     katakana: "", romaji: "yuugata",     english: "evening",     category: .timeCalendar),
        WordEntry(id: "shuukan",     hiragana: "しゅうかん",   katakana: "", romaji: "shuukan",     english: "week",        category: .timeCalendar),
        WordEntry(id: "jikan",       hiragana: "じかん",       katakana: "", romaji: "jikan",       english: "time / hours", category: .timeCalendar),
        WordEntry(id: "getsuyoubi",  hiragana: "げつようび",   katakana: "", romaji: "getsuyoubi",  english: "Monday",      category: .timeCalendar),
        WordEntry(id: "suiyoubi",    hiragana: "すいようび",   katakana: "", romaji: "suiyoubi",    english: "Wednesday",   category: .timeCalendar),
        WordEntry(id: "mokuyoubi",   hiragana: "もくようび",   katakana: "", romaji: "mokuyoubi",   english: "Thursday",    category: .timeCalendar),
        WordEntry(id: "kinyoubi",    hiragana: "きんようび",   katakana: "", romaji: "kinyoubi",    english: "Friday",      category: .timeCalendar),
        WordEntry(id: "shuumatsu",   hiragana: "しゅうまつ",   katakana: "", romaji: "shuumatsu",   english: "weekend",     category: .timeCalendar),
        WordEntry(id: "yasumi",      hiragana: "やすみ",       katakana: "", romaji: "yasumi",      english: "holiday / rest", category: .timeCalendar),
    ]

    static let people: [WordEntry] = [
        WordEntry(id: "tomodachi",  hiragana: "ともだち",   katakana: "", romaji: "tomodachi",  english: "friend",          category: .people),
        WordEntry(id: "kazoku",     hiragana: "かぞく",     katakana: "", romaji: "kazoku",     english: "family",          category: .people),
        WordEntry(id: "otoko",      hiragana: "おとこ",     katakana: "", romaji: "otoko",      english: "man",             category: .people),
        WordEntry(id: "onna",       hiragana: "おんな",     katakana: "", romaji: "onna",       english: "woman",           category: .people),
        WordEntry(id: "kodomo",     hiragana: "こども",     katakana: "", romaji: "kodomo",     english: "child",           category: .people),
        WordEntry(id: "sensei",     hiragana: "せんせい",   katakana: "", romaji: "sensei",     english: "teacher",         category: .people),
        WordEntry(id: "gakusei",    hiragana: "がくせい",   katakana: "", romaji: "gakusei",    english: "student",         category: .people),
        WordEntry(id: "okaasan",    hiragana: "おかあさん", katakana: "", romaji: "okaasan",    english: "mother",          category: .people),
        WordEntry(id: "otousan",    hiragana: "おとうさん", katakana: "", romaji: "otousan",    english: "father",          category: .people),
        WordEntry(id: "oneesan",    hiragana: "おねえさん", katakana: "", romaji: "oneesan",    english: "older sister",    category: .people),
        WordEntry(id: "oniisan",    hiragana: "おにいさん", katakana: "", romaji: "oniisan",    english: "older brother",   category: .people),
        WordEntry(id: "imouto",     hiragana: "いもうと",   katakana: "", romaji: "imouto",     english: "younger sister",  category: .people),
        WordEntry(id: "otouto",     hiragana: "おとうと",   katakana: "", romaji: "otouto",     english: "younger brother", category: .people),
        WordEntry(id: "ryoushin",   hiragana: "りょうしん", katakana: "", romaji: "ryoushin",   english: "parents",         category: .people),
        WordEntry(id: "otto",       hiragana: "おっと",     katakana: "", romaji: "otto",       english: "husband",         category: .people),
        WordEntry(id: "gaijin",     hiragana: "がいじん",   katakana: "", romaji: "gaijin",     english: "foreigner",       category: .people),
    ]

    static let nature: [WordEntry] = [
        WordEntry(id: "taiyou",   hiragana: "たいよう",   katakana: "", romaji: "taiyou",  english: "sun",          category: .nature),
        WordEntry(id: "sakura",   hiragana: "さくら",     katakana: "", romaji: "sakura",  english: "cherry blossom", category: .nature),
        WordEntry(id: "tenki",    hiragana: "てんき",     katakana: "", romaji: "tenki",   english: "weather",      category: .nature),
        WordEntry(id: "kuuki",    hiragana: "くうき",     katakana: "", romaji: "kuuki",   english: "air",          category: .nature),
        WordEntry(id: "kisetsu",  hiragana: "きせつ",     katakana: "", romaji: "kisetsu", english: "season",       category: .nature),
        WordEntry(id: "shizen",   hiragana: "しぜん",     katakana: "", romaji: "shizen",  english: "nature",       category: .nature),
        WordEntry(id: "hikari",   hiragana: "ひかり",     katakana: "", romaji: "hikari",  english: "light",        category: .nature),
        WordEntry(id: "koori",    hiragana: "こおり",     katakana: "", romaji: "koori",   english: "ice",          category: .nature),
    ]

    static let places: [WordEntry] = [
        WordEntry(id: "gakkou",        hiragana: "がっこう",       katakana: "",           romaji: "gakkou",        english: "school",            category: .places),
        WordEntry(id: "byouin",        hiragana: "びょういん",     katakana: "",           romaji: "byouin",        english: "hospital",          category: .places),
        WordEntry(id: "kuukou",        hiragana: "くうこう",       katakana: "",           romaji: "kuukou",        english: "airport",           category: .places),
        WordEntry(id: "yuubinkyoku",   hiragana: "ゆうびんきょく", katakana: "",           romaji: "yuubinkyoku",   english: "post office",       category: .places),
        WordEntry(id: "ginkou",        hiragana: "ぎんこう",       katakana: "",           romaji: "ginkou",        english: "bank",              category: .places),
        WordEntry(id: "toshokan",      hiragana: "としょかん",     katakana: "",           romaji: "toshokan",      english: "library",           category: .places),
        WordEntry(id: "kouen",         hiragana: "こうえん",       katakana: "",           romaji: "kouen",         english: "park",              category: .places),
        WordEntry(id: "jinja",         hiragana: "じんじゃ",       katakana: "",           romaji: "jinja",         english: "shrine",            category: .places),
        WordEntry(id: "otera",         hiragana: "おてら",         katakana: "",           romaji: "otera",         english: "temple",            category: .places),
        WordEntry(id: "hakubutsukan",  hiragana: "はくぶつかん",   katakana: "",           romaji: "hakubutsukan",  english: "museum",            category: .places),
        WordEntry(id: "kaisha",        hiragana: "かいしゃ",       katakana: "",           romaji: "kaisha",        english: "company / office",  category: .places),
        WordEntry(id: "chikatetsu",    hiragana: "ちかてつ",       katakana: "",           romaji: "chikatetsu",    english: "subway",            category: .places),
        WordEntry(id: "suupaa",        hiragana: "",               katakana: "スーパー",   romaji: "suupaa",        english: "supermarket",       category: .places),
        WordEntry(id: "konbini",       hiragana: "",               katakana: "コンビニ",   romaji: "konbini",       english: "convenience store", category: .places),
        WordEntry(id: "depaato",       hiragana: "",               katakana: "デパート",   romaji: "depaato",       english: "department store",  category: .places),
        WordEntry(id: "hoteru",        hiragana: "",               katakana: "ホテル",     romaji: "hoteru",        english: "hotel",             category: .places),
    ]

    static let dailyLife: [WordEntry] = [
        WordEntry(id: "densha",    hiragana: "でんしゃ",   katakana: "",           romaji: "densha",    english: "train",           category: .dailyLife),
        WordEntry(id: "kuruma",    hiragana: "くるま",     katakana: "",           romaji: "kuruma",    english: "car",             category: .dailyLife),
        WordEntry(id: "jitensha",  hiragana: "じてんしゃ", katakana: "",           romaji: "jitensha",  english: "bicycle",         category: .dailyLife),
        WordEntry(id: "denwa",     hiragana: "でんわ",     katakana: "",           romaji: "denwa",     english: "telephone",       category: .dailyLife),
        WordEntry(id: "shinbun",   hiragana: "しんぶん",   katakana: "",           romaji: "shinbun",   english: "newspaper",       category: .dailyLife),
        WordEntry(id: "okane",     hiragana: "おかね",     katakana: "",           romaji: "okane",     english: "money",           category: .dailyLife),
        WordEntry(id: "kaban",     hiragana: "かばん",     katakana: "",           romaji: "kaban",     english: "bag",             category: .dailyLife),
        WordEntry(id: "kaimono",   hiragana: "かいもの",   katakana: "",           romaji: "kaimono",   english: "shopping",        category: .dailyLife),
        WordEntry(id: "ryouri",    hiragana: "りょうり",   katakana: "",           romaji: "ryouri",    english: "cooking",         category: .dailyLife),
        WordEntry(id: "souji",     hiragana: "そうじ",     katakana: "",           romaji: "souji",     english: "cleaning",        category: .dailyLife),
        WordEntry(id: "sentaku",   hiragana: "せんたく",   katakana: "",           romaji: "sentaku",   english: "laundry",         category: .dailyLife),
        WordEntry(id: "shigoto",   hiragana: "しごと",     katakana: "",           romaji: "shigoto",   english: "work / job",      category: .dailyLife),
        WordEntry(id: "omise",     hiragana: "おみせ",     katakana: "",           romaji: "omise",     english: "shop / store",    category: .dailyLife),
        WordEntry(id: "kippu",     hiragana: "きっぷ",     katakana: "",           romaji: "kippu",     english: "ticket",          category: .dailyLife),
        WordEntry(id: "deguchi",   hiragana: "でぐち",     katakana: "",           romaji: "deguchi",   english: "exit",            category: .dailyLife),
        WordEntry(id: "enpitsu",   hiragana: "えんぴつ",   katakana: "",           romaji: "enpitsu",   english: "pencil",          category: .dailyLife),
        WordEntry(id: "terebi",    hiragana: "",           katakana: "テレビ",     romaji: "terebi",    english: "television",      category: .dailyLife),
        WordEntry(id: "pasokon",   hiragana: "",           katakana: "パソコン",   romaji: "pasokon",   english: "computer",        category: .dailyLife),
        WordEntry(id: "sumaho",    hiragana: "",           katakana: "スマホ",     romaji: "sumaho",    english: "smartphone",      category: .dailyLife),
        WordEntry(id: "takushii",  hiragana: "",           katakana: "タクシー",   romaji: "takushii",  english: "taxi",            category: .dailyLife),
        WordEntry(id: "teebu",     hiragana: "",           katakana: "テーブル",   romaji: "teebu",     english: "table",           category: .dailyLife),
    ]

    static let adjectives: [WordEntry] = [
        WordEntry(id: "ookii",        hiragana: "おおきい",   katakana: "", romaji: "ookii",       english: "big",          category: .adjectives),
        WordEntry(id: "chiisai",      hiragana: "ちいさい",   katakana: "", romaji: "chiisai",     english: "small",        category: .adjectives),
        WordEntry(id: "atarashii",    hiragana: "あたらしい", katakana: "", romaji: "atarashii",   english: "new",          category: .adjectives),
        WordEntry(id: "furui",        hiragana: "ふるい",     katakana: "", romaji: "furui",       english: "old",          category: .adjectives),
        WordEntry(id: "takai",        hiragana: "たかい",     katakana: "", romaji: "takai",       english: "expensive / tall", category: .adjectives),
        WordEntry(id: "yasui",        hiragana: "やすい",     katakana: "", romaji: "yasui",       english: "cheap / low",  category: .adjectives),
        WordEntry(id: "atsui",        hiragana: "あつい",     katakana: "", romaji: "atsui",       english: "hot",          category: .adjectives),
        WordEntry(id: "samui",        hiragana: "さむい",     katakana: "", romaji: "samui",       english: "cold",         category: .adjectives),
        WordEntry(id: "warui",        hiragana: "わるい",     katakana: "", romaji: "warui",       english: "bad",          category: .adjectives),
        WordEntry(id: "hayai",        hiragana: "はやい",     katakana: "", romaji: "hayai",       english: "fast / early", category: .adjectives),
        WordEntry(id: "osoi",         hiragana: "おそい",     katakana: "", romaji: "osoi",        english: "slow / late",  category: .adjectives),
        WordEntry(id: "nagai",        hiragana: "ながい",     katakana: "", romaji: "nagai",       english: "long",         category: .adjectives),
        WordEntry(id: "mijikai",      hiragana: "みじかい",   katakana: "", romaji: "mijikai",     english: "short",        category: .adjectives),
        WordEntry(id: "omoi",         hiragana: "おもい",     katakana: "", romaji: "omoi",        english: "heavy",        category: .adjectives),
        WordEntry(id: "karui",        hiragana: "かるい",     katakana: "", romaji: "karui",       english: "light",        category: .adjectives),
        WordEntry(id: "kantan",       hiragana: "かんたん",   katakana: "", romaji: "kantan",      english: "easy",         category: .adjectives),
        WordEntry(id: "muzukashii",   hiragana: "むずかしい", katakana: "", romaji: "muzukashii",  english: "difficult",    category: .adjectives),
        WordEntry(id: "omoshiroi",    hiragana: "おもしろい", katakana: "", romaji: "omoshiroi",   english: "interesting",  category: .adjectives),
        WordEntry(id: "tsumaranai",   hiragana: "つまらない", katakana: "", romaji: "tsumaranai",  english: "boring",       category: .adjectives),
        WordEntry(id: "isogashii",    hiragana: "いそがしい", katakana: "", romaji: "isogashii",   english: "busy",         category: .adjectives),
        WordEntry(id: "yasashii",     hiragana: "やさしい",   katakana: "", romaji: "yasashii",    english: "kind / easy",  category: .adjectives),
        WordEntry(id: "kirei",        hiragana: "きれい",     katakana: "", romaji: "kirei",       english: "beautiful",    category: .adjectives),
        WordEntry(id: "oishii",       hiragana: "おいしい",   katakana: "", romaji: "oishii",      english: "delicious",    category: .adjectives),
        WordEntry(id: "kowai",        hiragana: "こわい",     katakana: "", romaji: "kowai",       english: "scary",        category: .adjectives),
        WordEntry(id: "tanoshii",     hiragana: "たのしい",   katakana: "", romaji: "tanoshii",    english: "fun",          category: .adjectives),
        WordEntry(id: "kanashii",     hiragana: "かなしい",   katakana: "", romaji: "kanashii",    english: "sad",          category: .adjectives),
        WordEntry(id: "ureshii",      hiragana: "うれしい",   katakana: "", romaji: "ureshii",     english: "happy",        category: .adjectives),
        WordEntry(id: "karai",        hiragana: "からい",     katakana: "", romaji: "karai",       english: "spicy",        category: .adjectives),
        WordEntry(id: "amai",         hiragana: "あまい",     katakana: "", romaji: "amai",        english: "sweet",        category: .adjectives),
        WordEntry(id: "akai",         hiragana: "あかい",     katakana: "", romaji: "akai",        english: "red",          category: .adjectives),
        WordEntry(id: "aoi",          hiragana: "あおい",     katakana: "", romaji: "aoi",         english: "blue",         category: .adjectives),
        WordEntry(id: "shiroi",       hiragana: "しろい",     katakana: "", romaji: "shiroi",      english: "white",        category: .adjectives),
        WordEntry(id: "kuroi",        hiragana: "くろい",     katakana: "", romaji: "kuroi",       english: "black",        category: .adjectives),
        WordEntry(id: "kiiroi",       hiragana: "きいろい",   katakana: "", romaji: "kiiroi",      english: "yellow",       category: .adjectives),
    ]

    static let verbs: [WordEntry] = [
        WordEntry(id: "taberu",       hiragana: "たべる",       katakana: "", romaji: "taberu",      english: "to eat",           category: .verbs),
        WordEntry(id: "hanasu",       hiragana: "はなす",       katakana: "", romaji: "hanasu",      english: "to speak",         category: .verbs),
        WordEntry(id: "kaeru",        hiragana: "かえる",       katakana: "", romaji: "kaeru",       english: "to return home",   category: .verbs),
        WordEntry(id: "tsukau",       hiragana: "つかう",       katakana: "", romaji: "tsukau",      english: "to use",           category: .verbs),
        WordEntry(id: "tsukuru",      hiragana: "つくる",       katakana: "", romaji: "tsukuru",     english: "to make",          category: .verbs),
        WordEntry(id: "omou",         hiragana: "おもう",       katakana: "", romaji: "omou",        english: "to think",         category: .verbs),
        WordEntry(id: "wakaru",       hiragana: "わかる",       katakana: "", romaji: "wakaru",      english: "to understand",    category: .verbs),
        WordEntry(id: "okiru",        hiragana: "おきる",       katakana: "", romaji: "okiru",       english: "to wake up",       category: .verbs),
        WordEntry(id: "hataraku",     hiragana: "はたらく",     katakana: "", romaji: "hataraku",    english: "to work",          category: .verbs),
        WordEntry(id: "benkyousuru",  hiragana: "べんきょうする", katakana: "", romaji: "benkyou suru", english: "to study",       category: .verbs),
        WordEntry(id: "asobu",        hiragana: "あそぶ",       katakana: "", romaji: "asobu",       english: "to play",          category: .verbs),
        WordEntry(id: "hashiru",      hiragana: "はしる",       katakana: "", romaji: "hashiru",     english: "to run",           category: .verbs),
        WordEntry(id: "aruku",        hiragana: "あるく",       katakana: "", romaji: "aruku",       english: "to walk",          category: .verbs),
        WordEntry(id: "akeru",        hiragana: "あける",       katakana: "", romaji: "akeru",       english: "to open",          category: .verbs),
        WordEntry(id: "shimeru",      hiragana: "しめる",       katakana: "", romaji: "shimeru",     english: "to close",         category: .verbs),
        WordEntry(id: "ageru",        hiragana: "あげる",       katakana: "", romaji: "ageru",       english: "to give",          category: .verbs),
        WordEntry(id: "morau",        hiragana: "もらう",       katakana: "", romaji: "morau",       english: "to receive",       category: .verbs),
        WordEntry(id: "miseru",       hiragana: "みせる",       katakana: "", romaji: "miseru",      english: "to show",          category: .verbs),
        WordEntry(id: "oshieru",      hiragana: "おしえる",     katakana: "", romaji: "oshieru",     english: "to teach",         category: .verbs),
        WordEntry(id: "oboeru",       hiragana: "おぼえる",     katakana: "", romaji: "oboeru",      english: "to remember",      category: .verbs),
        WordEntry(id: "wasureru",     hiragana: "わすれる",     katakana: "", romaji: "wasureru",    english: "to forget",        category: .verbs),
        WordEntry(id: "hajimeru",     hiragana: "はじめる",     katakana: "", romaji: "hajimeru",    english: "to start",         category: .verbs),
        WordEntry(id: "owaru",        hiragana: "おわる",       katakana: "", romaji: "owaru",       english: "to finish",        category: .verbs),
        WordEntry(id: "kangaeru",     hiragana: "かんがえる",   katakana: "", romaji: "kangaeru",    english: "to think / consider", category: .verbs),
        WordEntry(id: "narau",        hiragana: "ならう",       katakana: "", romaji: "narau",       english: "to learn",         category: .verbs),
        WordEntry(id: "erabu",        hiragana: "えらぶ",       katakana: "", romaji: "erabu",       english: "to choose",        category: .verbs),
        WordEntry(id: "noboru",       hiragana: "のぼる",       katakana: "", romaji: "noboru",      english: "to climb",         category: .verbs),
    ]

    static let other: [WordEntry] = [
        WordEntry(id: "kotoba",      hiragana: "ことば",     katakana: "",         romaji: "kotoba",      english: "word / language",  category: .other),
        WordEntry(id: "nihongo",     hiragana: "にほんご",   katakana: "",         romaji: "nihongo",     english: "Japanese language", category: .other),
        WordEntry(id: "eigo",        hiragana: "えいご",     katakana: "",         romaji: "eigo",        english: "English language",  category: .other),
        WordEntry(id: "ongaku",      hiragana: "おんがく",   katakana: "",         romaji: "ongaku",      english: "music",            category: .other),
        WordEntry(id: "eiga",        hiragana: "えいが",     katakana: "",         romaji: "eiga",        english: "movie",            category: .other),
        WordEntry(id: "kenkou",      hiragana: "けんこう",   katakana: "",         romaji: "kenkou",      english: "health",           category: .other),
        WordEntry(id: "arigatou",    hiragana: "ありがとう", katakana: "",         romaji: "arigatou",    english: "thank you",        category: .other),
        WordEntry(id: "gomennasai",  hiragana: "ごめんなさい", katakana: "",       romaji: "gomennasai",  english: "sorry",            category: .other),
        WordEntry(id: "onegai",      hiragana: "おねがい",   katakana: "",         romaji: "onegai",      english: "please (request)", category: .other),
        WordEntry(id: "youkoso",     hiragana: "ようこそ",   katakana: "",         romaji: "youkoso",     english: "welcome",          category: .other),
        WordEntry(id: "sayounara",   hiragana: "さようなら", katakana: "",         romaji: "sayounara",   english: "goodbye",          category: .other),
        WordEntry(id: "omedetou",    hiragana: "おめでとう", katakana: "",         romaji: "omedetou",    english: "congratulations",  category: .other),
        WordEntry(id: "itadakimasu", hiragana: "いただきます", katakana: "",       romaji: "itadakimasu", english: "let's eat",        category: .other),
        WordEntry(id: "gochisousama", hiragana: "ごちそうさま", katakana: "",      romaji: "gochisousama", english: "thank you for the meal", category: .other),
        WordEntry(id: "sekai",       hiragana: "せかい",     katakana: "",         romaji: "sekai",       english: "world",            category: .other),
        WordEntry(id: "shukudai",    hiragana: "しゅくだい", katakana: "",         romaji: "shukudai",    english: "homework",         category: .other),
        WordEntry(id: "ryokou",      hiragana: "りょこう",   katakana: "",         romaji: "ryokou",      english: "travel",           category: .other),
        WordEntry(id: "tegami",      hiragana: "てがみ",     katakana: "",         romaji: "tegami",      english: "letter",           category: .other),
        WordEntry(id: "nikki",       hiragana: "にっき",     katakana: "",         romaji: "nikki",       english: "diary",            category: .other),
        WordEntry(id: "kanji",       hiragana: "かんじ",     katakana: "",         romaji: "kanji",       english: "kanji characters", category: .other),
        WordEntry(id: "hiragana",    hiragana: "ひらがな",   katakana: "",         romaji: "hiragana",    english: "hiragana",         category: .other),
        WordEntry(id: "katakana",    hiragana: "かたかな",   katakana: "",         romaji: "katakana",    english: "katakana",         category: .other),
        WordEntry(id: "nihon",       hiragana: "にほん",     katakana: "",         romaji: "nihon",       english: "Japan",            category: .other),
        WordEntry(id: "toukyou",     hiragana: "とうきょう", katakana: "",         romaji: "toukyou",     english: "Tokyo",            category: .other),
        WordEntry(id: "geemu",       hiragana: "",           katakana: "ゲーム",   romaji: "geemu",       english: "game",             category: .other),
        WordEntry(id: "supootsu",    hiragana: "",           katakana: "スポーツ", romaji: "supootsu",    english: "sport",            category: .other),
    ]
}
