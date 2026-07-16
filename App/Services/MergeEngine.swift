import Foundation

enum MergeResult: Equatable, Sendable {
    case merged(String)
    case conflict
}

enum MergeEngine {
    static func merge(base: String, local: String, remote: String) -> MergeResult {
        if local == remote { return .merged(local) }
        if local == base { return .merged(remote) }
        if remote == base { return .merged(local) }

        let baseLines = lines(base)
        guard let localChange = contiguousChange(from: baseLines, to: lines(local)),
              let remoteChange = contiguousChange(from: baseLines, to: lines(remote)) else {
            return .conflict
        }

        if changesOverlap(localChange, remoteChange) { return .conflict }
        var merged = baseLines
        for change in [localChange, remoteChange].sorted(by: { $0.start > $1.start }) {
            merged.replaceSubrange(change.start..<change.end, with: change.replacement)
        }
        return .merged(merged.joined(separator: "\n"))
    }

    private struct Change {
        let start: Int
        let end: Int
        let replacement: [String]
    }

    private static func lines(_ value: String) -> [String] {
        value.components(separatedBy: "\n")
    }

    private static func contiguousChange(from base: [String], to changed: [String]) -> Change? {
        var prefix = 0
        while prefix < min(base.count, changed.count), base[prefix] == changed[prefix] { prefix += 1 }

        var baseSuffix = base.count
        var changedSuffix = changed.count
        while baseSuffix > prefix, changedSuffix > prefix,
              base[baseSuffix - 1] == changed[changedSuffix - 1] {
            baseSuffix -= 1
            changedSuffix -= 1
        }
        return Change(start: prefix, end: baseSuffix, replacement: Array(changed[prefix..<changedSuffix]))
    }

    private static func changesOverlap(_ lhs: Change, _ rhs: Change) -> Bool {
        if lhs.start == lhs.end, rhs.start == rhs.end { return lhs.start == rhs.start }
        return max(lhs.start, rhs.start) < min(lhs.end, rhs.end)
            || (lhs.start == lhs.end && lhs.start >= rhs.start && lhs.start <= rhs.end)
            || (rhs.start == rhs.end && rhs.start >= lhs.start && rhs.start <= lhs.end)
    }
}

