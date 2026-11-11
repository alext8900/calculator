import SwiftUI

struct ContentView: View {
    // See CalculatorState for why this is @AppStorage rather than @State.
    @AppStorage("calculator") private var state = CalculatorState()

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            Text(state.display)
                .font(.system(size: 72, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 24)

            keypad
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var keypad: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                CalculatorButton("AC", style: .function) { state.clear() }
                CalculatorButton("±", style: .function) { state.toggleSign() }
                CalculatorButton("%", style: .function) { state.percent() }
                operationButton(.divide)
            }
            HStack(spacing: 12) {
                digitButton(7)
                digitButton(8)
                digitButton(9)
                operationButton(.multiply)
            }
            HStack(spacing: 12) {
                digitButton(4)
                digitButton(5)
                digitButton(6)
                operationButton(.subtract)
            }
            HStack(spacing: 12) {
                digitButton(1)
                digitButton(2)
                digitButton(3)
                operationButton(.add)
            }
            HStack(spacing: 12) {
                // Two nested HStacks split the row in half, so "0" spans two columns.
                HStack(spacing: 12) {
                    digitButton(0)
                }
                .frame(maxWidth: .infinity)
                HStack(spacing: 12) {
                    CalculatorButton(".", style: .digit) { state.inputDecimalPoint() }
                    CalculatorButton("=", style: .operation(active: false)) { state.equals() }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func digitButton(_ digit: Int) -> CalculatorButton {
        CalculatorButton(String(digit), style: .digit) { state.inputDigit(digit) }
    }

    private func operationButton(_ operation: Operation) -> CalculatorButton {
        let active = state.pendingOperation == operation && !state.isTyping
        return CalculatorButton(operation.rawValue, style: .operation(active: active)) {
            state.choose(operation)
        }
    }
}

struct CalculatorButton: View {
    enum Style {
        case digit
        case function
        case operation(active: Bool)

        var background: Color {
            switch self {
            case .digit: return Color(white: 0.2)
            case .function: return Color(white: 0.65)
            case .operation(let active): return active ? .white : .orange
            }
        }

        var foreground: Color {
            switch self {
            case .digit: return .white
            case .function: return .black
            case .operation(let active): return active ? .orange : .white
            }
        }
    }

    let label: String
    let style: Style
    let action: () -> Void

    init(_ label: String, style: Style, action: @escaping () -> Void) {
        self.label = label
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(style.background, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// PreviewProvider rather than #Preview, for the same no-macros reason.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
