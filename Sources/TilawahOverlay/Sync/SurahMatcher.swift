import Foundation

enum SurahMatcher {
    /// Canonical spellings from Quran.com `name_simple`, Wikipedia, and common reciter metadata.
    private static let aliases: [(Int, [String])] = [
        (1, ["fatihah", "fatiha", "fateha", "fatehah", "alhamd", "the opening", "the opener", "الفاتحة"]),
        (2, ["baqarah", "baqara", "the cow", "البقرة"]),
        (3, ["imran", "alimran", "aliimran", "aleimran", "family of imran", "آل عمران"]),
        (4, ["nisa", "nisaa", "nisa'", "the women", "النساء"]),
        (5, ["maidah", "maida", "maedah", "the table", "table spread", "المائدة"]),
        (6, ["anam", "anaam", "an3am", "the cattle", "الأنعام"]),
        (7, ["araf", "araaf", "the heights", "الأعراف"]),
        (8, ["anfal", "the spoils", "spoils of war", "الأنفال"]),
        (9, ["tawbah", "tawba", "taubah", "tauba", "toba", "baraah", "baraat", "the repentance", "التوبة", "براءة"]),
        (10, ["yunus", "yonus", "younus", "younis", "jonah", "يونس"]),
        (11, ["hud", "hood", "هود"]),
        (12, ["yusuf", "yousuf", "yousef", "joseph", "يوسف"]),
        (13, ["rad", "raad", "the thunder", "الرعد"]),
        (14, ["ibrahim", "ebrahim", "abraham", "ابراهيم", "إبراهيم"]),
        (15, ["hijr", "hijri", "rocky tract", "الحجر"]),
        (16, ["nahl", "the bee", "the bees", "النحل"]),
        (17, ["isra", "israa", "isra'", "bani israel", "bani israil", "children of israel", "night journey", "subhan", "الإسراء"]),
        (18, ["kahf", "kahaf", "the cave", "الكهف"]),
        (19, ["maryam", "mariam", "mary", "مريم"]),
        (20, ["taha", "ta ha", "taa haa", "طه"]),
        (21, ["anbya", "anbiya", "anbiyaa", "anbyaa", "anbia", "anbya'a", "the prophets", "الأنبياء"]),
        (22, ["hajj", "haj", "the pilgrimage", "الحج"]),
        (23, ["muminun", "muminoon", "mominun", "mominoon", "muminon", "the believers", "المؤمنون"]),
        (24, ["nur", "noor", "the light", "النور"]),
        (25, ["furqan", "furqaan", "the criterion", "الفرقان"]),
        (26, ["shuara", "shuaraa", "shuara'", "the poets", "الشعراء"]),
        (27, ["naml", "the ant", "the ants", "النمل"]),
        (28, ["qasas", "qassas", "the stories", "القصص"]),
        (29, ["ankabut", "ankaboot", "the spider", "العنكبوت"]),
        (30, ["rum", "room", "the romans", "byzantine", "الروم"]),
        (31, ["luqman", "luqmaan", "lokman", "لقمان"]),
        (32, ["sajdah", "sajda", "the prostration", "السجدة"]),
        (33, ["ahzab", "ahzaab", "combined forces", "the clans", "الأحزاب"]),
        (34, ["saba", "sabaa", "sheba", "سبأ"]),
        (35, ["fatir", "faatir", "malaika", "malaikah", "originator", "فاطر"]),
        (36, ["yasin", "ya sin", "yaseen", "ya-seen", "yaseen", "يس"]),
        (37, ["saffat", "saaffat", "saffaat", "those who set the ranks", "الصافات"]),
        (38, ["sad", "saad", "ص"]),
        (39, ["zumar", "the troops", "the groups", "الزمر"]),
        (40, ["ghafir", "ghaafir", "mumin", "the forgiver", "غافر", "المؤمن"]),
        (41, ["fussilat", "fussilat", "fusilat", "ha mim sajdah", "explained in detail", "فصلت"]),
        (42, ["shura", "shuraa", "shoora", "the consultation", "الشورى"]),
        (43, ["zukhruf", "zokhrof", "ornaments of gold", "الزخرف"]),
        (44, ["dukhan", "dukhaan", "the smoke", "الدخان"]),
        (45, ["jathiyah", "jathiya", "jasiya", "jasiyah", "the crouching", "the kneeling", "الجاثية"]),
        (46, ["ahqaf", "ahqaaf", "sandhills", "الأحقاف"]),
        (47, ["muhammad", "mohammad", "qital", "القتال", "محمد"]),
        (48, ["fath", "fat-h", "the victory", "الفتح"]),
        (49, ["hujurat", "hujuraat", "hujurat", "the rooms", "the chambers", "الحجرات"]),
        (50, ["qaf", "qaaf", "ق"]),
        (51, ["dhariyat", "zariyat", "zaariyat", "winnowing winds", "الذاريات"]),
        (52, ["tur", "toor", "the mount", "الطور"]),
        (53, ["najm", "the star", "the stars", "النجم"]),
        (54, ["qamar", "the moon", "القمر"]),
        (55, ["rahman", "rahmaan", "the beneficent", "the merciful", "الرحمن"]),
        (56, ["waqiah", "waqia", "waaqiah", "the inevitable", "الواقعة"]),
        (57, ["hadid", "hadeed", "the iron", "الحديد"]),
        (58, ["mujadila", "mujadilah", "mujaadila", "mujadalah", "pleading woman", "المجادلة"]),
        (59, ["hashr", "the exile", "the gathering", "الحشر"]),
        (60, ["mumtahanah", "mumtahana", "mumtahinah", "examined", "الممتحنة"]),
        (61, ["saff", "the ranks", "الصف"]),
        (62, ["jumuah", "jumua", "jumu'a", "juma", "friday", "the congregation", "الجمعة"]),
        (63, ["munafiqun", "munafiqoon", "the hypocrites", "المنافقون"]),
        (64, ["taghabun", "tagabun", "mutual disillusion", "التغابن"]),
        (65, ["talaq", "the divorce", "الطلاق"]),
        (66, ["tahrim", "the prohibition", "التحريم"]),
        (67, ["mulk", "the sovereignty", "the kingdom", "الملك"]),
        (68, ["qalam", "the pen", "القلم"]),
        (69, ["haqqah", "haqqa", "haaqqah", "the reality", "الحاقة"]),
        (70, ["maarij", "maarij", "ma'arij", "mearij", "ascending stairways", "المعارج"]),
        (71, ["nuh", "nooh", "noah", "نوح"]),
        (72, ["jinn", "the jinn", "الجن"]),
        (73, ["muzzammil", "muzzamil", "muzammil", "enshrouded", "المزمل"]),
        (74, ["muddaththir", "muddathir", "mudathir", "moddathir", "the cloaked", "المدثر"]),
        (75, ["qiyamah", "qiyama", "qiyamat", "the resurrection", "القيامة"]),
        (76, ["insan", "insaan", "dahr", "the man", "الانسان", "الدهر"]),
        (77, ["mursalat", "mursalaat", "the emissaries", "المرسلات"]),
        (78, ["naba", "nabaa", "the tidings", "the news", "النبأ"]),
        (79, ["naziat", "naziaat", "nazi'at", "those who drag forth", "النازعات"]),
        (80, ["abasa", "he frowned", "عبس"]),
        (81, ["takwir", "takweer", "the overthrowing", "التكوير"]),
        (82, ["infitar", "infitaar", "the cleaving", "الإنفطار"]),
        (83, ["mutaffifin", "mutaffifeen", "tatfif", "the defrauding", "المطففين"]),
        (84, ["inshiqaq", "inshiqaaq", "the sundering", "الإنشقاق"]),
        (85, ["buruj", "burooj", "the constellations", "البروج"]),
        (86, ["tariq", "taariq", "the nightcommer", "night visitor", "الطارق"]),
        (87, ["ala", "a'la", "alaa", "the most high", "الأعلى"]),
        (88, ["ghashiyah", "ghashiya", "gashiya", "ghashiah", "the overwhelming", "الغاشية"]),
        (89, ["fajr", "the dawn", "الفجر"]),
        (90, ["balad", "the city", "البلد"]),
        (91, ["shams", "the sun", "الشمس"]),
        (92, ["layl", "lail", "layel", "the night", "الليل"]),
        (93, ["duha", "duhaa", "dhuha", "dhuhaa", "the morning hours", "الضحى"]),
        (94, ["sharh", "inshirah", "inshiraah", "ashsharh", "the relief", "الشرح"]),
        (95, ["tin", "teen", "the fig", "التين"]),
        (96, ["alaq", "alaaq", "iqra", "iqraa", "the clot", "العلق"]),
        (97, ["qadr", "qadar", "the power", "the decree", "القدر"]),
        (98, ["bayyinah", "bayyina", "baiyina", "the clear proof", "البينة"]),
        (99, ["zalzalah", "zalzala", "zilzal", "zilzaal", "the earthquake", "الزلزلة"]),
        (100, ["adiyat", "aadiyat", "the courser", "العاديات"]),
        (101, ["qariah", "qaria", "qari'ah", "the calamity", "القارعة"]),
        (102, ["takathur", "takaathur", "rivalry", "التكاثر"]),
        (103, ["asr", "asar", "the declining day", "time", "العصر"]),
        (104, ["humazah", "humaza", "the traducer", "الهمزة"]),
        (105, ["fil", "feel", "the elephant", "الفيل"]),
        (106, ["quraysh", "quraish", "quraysh", "قريش"]),
        (107, ["maun", "maaun", "ma'un", "small kindnesses", "الماعون"]),
        (108, ["kawthar", "kauthar", "kawther", "the abundance", "الكوثر"]),
        (109, ["kafirun", "kafiroon", "kaafiroon", "the disbelievers", "الكافرون"]),
        (110, ["nasr", "naser", "divine support", "the help", "النصر"]),
        (111, ["masad", "lahab", "lahab", "palm fiber", "the flame", "المسد", "اللهب"]),
        (112, ["ikhlas", "ikhlaas", "tawhid", "tauhid", "the sincerity", "الإخلاص"]),
        (113, ["falaq", "the daybreak", "الفلق"]),
        (114, ["nas", "naas", "mankind", "الناس"]),
    ]

    private static let normalizedLookup: [(alias: String, surah: Int)] = {
        var rows: [(String, Int)] = []
        for (number, names) in aliases {
            for name in names {
                let key = normalize(name, stripArticles: true)
                if !key.isEmpty {
                    rows.append((key, number))
                }
            }
        }
        return rows.sorted { $0.0.count > $1.0.count }
    }()

    static func surahNumber(from title: String) -> Int? {
        if let arabic = matchArabic(title) {
            return arabic
        }

        if let numbered = matchNumber(title) {
            return numbered
        }

        let folded = normalize(title, stripArticles: true)
        guard !folded.isEmpty else { return nil }

        if let exact = matchExact(folded) {
            return exact
        }

        return matchFuzzy(folded)
    }

    private static func matchArabic(_ title: String) -> Int? {
        for (number, names) in aliases {
            for name in names where name.unicodeScalars.contains(where: { $0.value >= 0x0600 }) {
                if title.contains(name) {
                    return number
                }
            }
        }
        return nil
    }

    private static func matchNumber(_ title: String) -> Int? {
        let patterns = [
            #"\b(?:surah?|soorah|chapter)\s+0*(\d{1,3})\b"#,
            #"^\s*0*(\d{1,3})\b"#,
        ]
        for pattern in patterns {
            if let match = title.range(of: pattern, options: [.regularExpression, .caseInsensitive]),
               let number = Int(title[match].filter(\.isNumber)),
               (1 ... 114).contains(number)
            {
                return number
            }
        }
        return nil
    }

    private static func matchExact(_ folded: String) -> Int? {
        let tokens = Set(folded.split(separator: " ").map(String.init))
        for (alias, number) in normalizedLookup {
            if alias.count <= 3 {
                if tokens.contains(alias) { return number }
            } else if folded == alias || tokens.contains(alias) || folded.contains(alias) {
                return number
            }
        }
        return nil
    }

    private static func matchFuzzy(_ folded: String) -> Int? {
        let tokens = folded.split(separator: " ").map(String.init).filter { $0.count >= 4 }
        let candidates = tokens + [folded.replacingOccurrences(of: " ", with: "")]

        var best: (distance: Int, surah: Int, aliasCount: Int)?

        for candidate in candidates {
            let phoneticCandidate = phonetic(candidate)
            for (alias, number) in normalizedLookup where alias.count >= 4 {
                let distance = min(
                    levenshtein(candidate, alias),
                    levenshtein(phoneticCandidate, phonetic(alias))
                )
                let allowed = alias.count >= 8 ? 2 : 1
                guard distance > 0, distance <= allowed else { continue }
                if best == nil
                    || distance < best!.distance
                    || (distance == best!.distance && alias.count > best!.aliasCount)
                {
                    best = (distance, number, alias.count)
                }
            }
        }

        return best?.surah
    }

    private static func normalize(_ value: String, stripArticles: Bool) -> String {
        var text = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let punctuation = CharacterSet.alphanumerics.union(.whitespaces).inverted
        text = text.components(separatedBy: punctuation).joined(separator: " ")
        text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let stopwords: Set<String> = [
            "surah", "sura", "surat", "soorah", "chapter", "recitation",
            "quran", "quraan", "holy", "complete", "full", "mp3",
        ]
        var tokens = text.split(separator: " ").map(String.init).filter { !stopwords.contains($0) }

        if stripArticles {
            tokens = tokens.map(stripLeadingArticle)
        }

        return tokens.joined(separator: " ")
    }

    private static func stripLeadingArticle(_ token: String) -> String {
        let prefixes = ["ash", "adh", "al", "an", "ar", "as", "at", "ad", "az"]
        for prefix in prefixes where token.hasPrefix(prefix) && token.count - prefix.count >= 3 {
            return String(token.dropFirst(prefix.count))
        }
        return token
    }

    private static func phonetic(_ value: String) -> String {
        var text = value
        let pairs = [
            "aa": "a", "ee": "i", "ii": "i", "oo": "u", "uu": "u", "ou": "u",
            "iy": "i", "yi": "i", "kh": "k", "gh": "g", "dh": "d", "th": "t",
        ]
        for (from, to) in pairs {
            text = text.replacingOccurrences(of: from, with: to)
        }

        var chars = Array(text)
        for index in chars.indices.dropFirst() where chars[index] == "y" {
            chars[index] = "i"
        }
        text = String(chars)

        var collapsed = ""
        for character in text {
            if collapsed.last != character {
                collapsed.append(character)
            }
        }
        return collapsed
    }

    private static func levenshtein(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let aChars = Array(a)
        let bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var previous = Array(0 ... bChars.count)
        for i in 1 ... aChars.count {
            var current = [Int](repeating: 0, count: bChars.count + 1)
            current[0] = i
            for j in 1 ... bChars.count {
                let cost = aChars[i - 1] == bChars[j - 1] ? 0 : 1
                current[j] = min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + cost
                )
            }
            previous = current
        }
        return previous[bChars.count]
    }
}

enum ReciterMatcher {
    /// Quran.com recitation IDs for common reciters (expand in Phase 1).
    private static let aliases: [String: Int] = [
        "mishary": 7,
        "mishari": 7,
        "alafasy": 7,
        "abdul basit": 2,
        "abdulbasit": 2,
        "sudais": 3,
        "saud ash shuraim": 4,
        "shuraim": 4,
        "al ghamdi": 10,
        "ghamdi": 10,
    ]

    static func recitationID(for artist: String) -> Int {
        let lowered = artist.lowercased()
        for (alias, id) in aliases where lowered.contains(alias) {
            return id
        }
        return 7
    }
}
