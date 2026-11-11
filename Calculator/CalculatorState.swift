import Foundation

enum Operation: String, CaseIterable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"

    func apply(_ lhs: Double, _ rhs: Double) -> Double {
        switch self {
        case .add: return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide: return lhs / rhs
        }
    }
}

/// The whole calculator state, kept as a value type so the view can hold it in @AppStorage.
///
/// @AppStorage rather than @State on purpose: in the Xcode 27 SDK @State is a Swift macro,
/// and the Borrowed Hands build sandbox cannot run macro plugins. RawRepresentable (as a String)
/// is what @AppStorage needs, and the calculator survives a relaunch as a bonus.
struct CalculatorState: Equatable, RawRepresentable {
    /// What the display shows.
    var display: String = "0"
    /// The left operand waiting for a pending operation.
    var accumulator: Double? = nil
    /// The operation chosen but not yet applied.
    var pendingOperation: Operation? = nil
    /// True while the user is typing the current number (next digit appends instead of replacing).
    var isTyping: Bool = false

    init() {}

    // MARK: RawRepresentable (manual, no Codable, so there is no recursion through rawValue)

    private static let separator: Character = "|"

    var rawValue: String {
        [
            display,
            accumulator.map { String($0) } ?? "",
            pendingOperation?.rawValue ?? "",
            isTyping ? "1" : "0",
        ].joined(separator: String(Self.separator))
    }

    init?(rawValue: String) {
        let parts = rawValue.split(separator: Self.separator, omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4 else { return nil }
        display = parts[0].isEmpty ? "0" : parts[0]
        accumulator = parts[1].isEmpty ? nil : Double(parts[1])
        pendingOperation = parts[2].isEmpty ? nil : Operation(rawValue: parts[2])
        isTyping = parts[3] == "1"
    }

    // MARK: Input

    private var displayValue: Double { Double(display) ?? 0 }

    mutating func inputDigit(_ digit: Int) {
        let text = String(digit)
        if isTyping {
            if display == "0" {
                display = text
            } else if display.count < 12 {
                display += text
            }
        } else {
            display = text
            isTyping = true
        }
    }

    mutating func inputDecimalPoint() {
        if !isTyping {
            display = "0."
            isTyping = true
        } else if !display.contains(".") {
            display += "."
        }
    }

    mutating func toggleSign() {
        if display.hasPrefix("-") {
            display.removeFirst()
        } else if display != "0" {
            display = "-" + display
        }
    }

    mutating func percent() {
        display = Self.format(displayValue / 100)
        isTyping = false
    }

    mutating func clear() {
        self = CalculatorState()
    }

    mutating func choose(_ operation: Operation) {
        if isTyping || pendingOperation == nil {
            commitPending()
        }
        accumulator = displayValue
        pendingOperation = operation
        isTyping = false
    }

    mutating func equals() {
        commitPending()
        accumulator = nil
        pendingOperation = nil
        isTyping = false
    }

    /// Applies the pending operation to the accumulator and the display value, if there is one.
    private mutating func commitPending() {
        guard let operation = pendingOperation, let lhs = accumulator else { return }
        display = Self.format(operation.apply(lhs, displayValue))
        accumulator = nil
        pendingOperation = nil
    }

    // MARK: Formatting

    static func format(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return "Error" }
        if value == value.rounded(.towardZero), abs(value) < 1e15 {
            return String(Int64(value))
        }
        return String(format: "%.10g", value)
    }
}
