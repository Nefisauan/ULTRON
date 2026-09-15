import Foundation

/// Accept only an invocation at the start of an utterance, never a phrase quoted midway through it.
public enum WakePhrase {
    public static func command(in transcript: String) -> String? {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = text.range(of: #"^hey[\s,]+ultron\b[\s,.!?:-]*"#,
                                     options: [.regularExpression, .caseInsensitive]) else { return nil }
        let command = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return command.isEmpty ? "Hey Ultron" : command
    }
}
