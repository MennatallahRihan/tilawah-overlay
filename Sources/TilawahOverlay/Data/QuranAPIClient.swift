import Foundation

enum QuranAPIError: Error, LocalizedError {
    case invalidResponse
    case missingTimings
    case missingAudio

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Unexpected response from Quran.com API"
        case .missingTimings: "No ayah timings available for this reciter/surah"
        case .missingAudio: "No audio file for this reciter/surah"
        }
    }
}

struct ChapterInfo: Identifiable, Equatable, Sendable {
    let id: Int
    let nameSimple: String
    let bismillahPre: Bool
}

struct ReciterInfo: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let style: String?
}

/// Gapless chapter MP3 + matching ayah timestamps from Quran.com / QuranicAudio.
struct QuranAPIClient: Sendable {
    private let baseURL = URL(string: "https://api.quran.com/api/v4")!
    private let session: URLSession

    init(session: URLSession? = nil) {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "TilawahOverlay/0.1",
            "Accept": "application/json",
        ]
        self.session = session ?? URLSession(configuration: configuration)
    }

    func loadSession(surahNumber: Int, recitationID: Int, reciterName: String) async throws -> SurahSession {
        async let ayahs = fetchAyahs(chapter: surahNumber)
        async let recitation = fetchChapterRecitation(chapter: surahNumber, recitationID: recitationID)
        async let chapter = fetchChapter(chapter: surahNumber)

        let ayahList = try await ayahs
        let audio = try await recitation
        let chapterInfo = try await chapter

        guard let audioURL = audio.audioURL else { throw QuranAPIError.missingAudio }

        return SurahSession(
            surahNumber: surahNumber,
            surahName: chapterInfo.nameSimple,
            reciterName: reciterName,
            recitationID: recitationID,
            audioURL: audioURL,
            ayahs: ayahList,
            ayahTimings: audio.timings,
            timingDurationMs: audio.timings.last?.endMs ?? 0
        )
    }

    func fetchChapters() async throws -> [ChapterInfo] {
        let decoded: ChaptersResponse = try await get(url(path: "chapters", query: ["language": "en"]))
        return decoded.chapters.map {
            ChapterInfo(id: $0.id, nameSimple: $0.nameSimple, bismillahPre: $0.bismillahPre)
        }
    }

    func fetchReciters() async throws -> [ReciterInfo] {
        let decoded: RecitationsResponse = try await get(url(path: "resources/recitations"))
        return decoded.recitations.map {
            ReciterInfo(id: $0.id, name: $0.reciterName, style: $0.style)
        }
    }

    private func fetchAyahs(chapter: Int) async throws -> [Ayah] {
        let decoded: UthmaniVersesResponse = try await get(
            url(path: "quran/verses/uthmani", query: ["chapter_number": String(chapter)])
        )
        return decoded.verses.compactMap { verse -> Ayah? in
            guard let number = Int(verse.verseKey.split(separator: ":").last ?? "") else { return nil }
            return Ayah(number: number, text: verse.textUthmani.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        .sorted { $0.number < $1.number }
    }

    private func fetchChapterRecitation(chapter: Int, recitationID: Int) async throws -> ChapterAudio {
        let decoded: ChapterRecitationResponse = try await get(
            url(path: "chapter_recitations/\(recitationID)/\(chapter)", query: ["segments": "true"])
        )
        guard let timestamps = decoded.audioFile.timestamps, !timestamps.isEmpty else {
            throw QuranAPIError.missingTimings
        }

        let timings = timestamps.enumerated().map { index, stamp in
            let nextStart = timestamps.indices.contains(index + 1) ? timestamps[index + 1].timestampFrom : stamp.timestampTo
            return AyahTiming(
                ayahNumber: stamp.verseNumber,
                startMs: stamp.timestampFrom,
                endMs: nextStart ?? (stamp.timestampTo ?? stamp.timestampFrom + 5_000)
            )
        }

        return ChapterAudio(audioURL: decoded.audioFile.audioURL.flatMap(URL.init(string:)), timings: timings)
    }

    private func fetchChapter(chapter: Int) async throws -> ChapterDTO {
        let decoded: ChapterResponse = try await get(url(path: "chapters/\(chapter)"))
        return decoded.chapter
    }

    private func url(path: String, query: [String: String] = [:]) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components.url!
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("TilawahOverlay/0.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw QuranAPIError.invalidResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct ChapterAudio {
    let audioURL: URL?
    let timings: [AyahTiming]
}

private struct UthmaniVersesResponse: Decodable {
    let verses: [UthmaniVerseDTO]
}

private struct UthmaniVerseDTO: Decodable {
    let verseKey: String
    let textUthmani: String

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case textUthmani = "text_uthmani"
    }
}

private struct ChapterRecitationResponse: Decodable {
    let audioFile: AudioFileDTO

    enum CodingKeys: String, CodingKey {
        case audioFile = "audio_file"
    }
}

private struct AudioFileDTO: Decodable {
    let audioURL: String?
    let timestamps: [TimestampDTO]?

    enum CodingKeys: String, CodingKey {
        case audioURL = "audio_url"
        case timestamps
    }
}

private struct TimestampDTO: Decodable {
    let verseNumber: Int
    let timestampFrom: Int
    let timestampTo: Int?

    enum CodingKeys: String, CodingKey {
        case verseKey = "verse_key"
        case timestampFrom = "timestamp_from"
        case timestampTo = "timestamp_to"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let verseKey = try container.decode(String.self, forKey: .verseKey)
        verseNumber = Int(verseKey.split(separator: ":").last ?? "") ?? 0
        timestampFrom = try container.decode(Int.self, forKey: .timestampFrom)
        timestampTo = try container.decodeIfPresent(Int.self, forKey: .timestampTo)
    }
}

private struct ChapterResponse: Decodable {
    let chapter: ChapterDTO
}

private struct ChaptersResponse: Decodable {
    let chapters: [ChapterDTO]
}

private struct ChapterDTO: Decodable {
    let id: Int
    let nameSimple: String
    let bismillahPre: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case nameSimple = "name_simple"
        case bismillahPre = "bismillah_pre"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        nameSimple = try container.decode(String.self, forKey: .nameSimple)
        bismillahPre = try container.decodeIfPresent(Bool.self, forKey: .bismillahPre) ?? false
    }
}

private struct RecitationsResponse: Decodable {
    let recitations: [RecitationDTO]
}

private struct RecitationDTO: Decodable {
    let id: Int
    let reciterName: String
    let style: String?

    enum CodingKeys: String, CodingKey {
        case id
        case reciterName = "reciter_name"
        case style
    }
}
