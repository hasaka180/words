import Foundation

/// Seeded on first launch so the list — and the widget — are never empty.
enum SampleData {
    static let words: [Word] = [
        Word(english: "Ephemeral",
             definition: "Lasting for a very short time.",
             sinhala: "ක්ෂණිකව නැතිවන; තාවකාලික",
             example: "Fame in the age of social media is often ephemeral."),
        Word(english: "Resilient",
             definition: "Able to recover quickly from difficulties.",
             sinhala: "ඔරොත්තු දෙන; යළි නැගිටින",
             example: "She stayed resilient through a very hard year."),
        Word(english: "Meticulous",
             definition: "Showing great attention to detail; very careful.",
             sinhala: "ඉතා සුපරීක්ෂාකාරී; සියුම් ලෙස සැලකිලිමත්",
             example: "He keeps meticulous notes of every experiment."),
        Word(english: "Serendipity",
             definition: "Finding something good without looking for it.",
             sinhala: "අහම්බෙන් හොඳ දෙයක් සොයාගැනීම",
             example: "Meeting my co-founder in that queue was pure serendipity."),
        Word(english: "Candid",
             definition: "Truthful and straightforward; frank.",
             sinhala: "අවංක; කෙළින්ම කියන",
             example: "Thanks for being candid about the risks.")
    ]
}
