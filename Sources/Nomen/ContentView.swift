import SwiftUI
import NomenCore

extension Color {
    static let nomen = Color(red: 0.42, green: 0.33, blue: 0.95)
    static let nomenPink = Color(red: 0.98, green: 0.42, blue: 0.62)
    static let nomenViolet = Color(red: 0.55, green: 0.33, blue: 0.98)
    static let nomenBlue = Color(red: 0.27, green: 0.36, blue: 0.96)
}

extension LinearGradient {
    /// The app icon's pink → violet → blue.
    static let nomen = LinearGradient(
        colors: [.nomenPink, .nomenViolet, .nomenBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// "3 fájl" / "3 files".
func fileCount(_ n: Int) -> String {
    L("\(n) fájl", n == 1 ? "1 file" : "\(n) files")
}

extension RenameMode {
    var shortTitle: String {
        switch self {
        case .replaceFirst: L("Első csere", "Replace First")
        case .replaceLast: L("Utolsó csere", "Replace Last")
        case .replaceAll: L("Összes csere", "Replace All")
        case .wildcard: L("Helyettesítő", "Wildcard")
        case .append: L("Végére", "Append")
        case .prepend: L("Elejére", "Prepend")
        case .removeCharacters: L("Törlés", "Remove")
        case .insertCharacters: L("Beszúrás", "Insert")
        case .changeCase: L("Kis/Nagy", "Case")
        case .sequence: L("Sorszám", "Sequence")
        case .date: L("Dátum", "Date")
        case .regex: "Regex"
        }
    }

    var symbol: String {
        switch self {
        case .replaceFirst: "arrow.forward.to.line"
        case .replaceLast: "arrow.backward.to.line"
        case .replaceAll: "arrow.left.arrow.right"
        case .wildcard: "asterisk"
        case .append: "text.append"
        case .prepend: "text.insert"
        case .removeCharacters: "delete.left"
        case .insertCharacters: "character.cursor.ibeam"
        case .changeCase: "textformat"
        case .sequence: "number"
        case .date: "calendar"
        case .regex: "chevron.left.forwardslash.chevron.right"
        }
    }

    var hint: String {
        switch self {
        case .replaceFirst: L("Az első találatot cseréli le.", "Replaces the first match.")
        case .replaceLast: L("Az utolsó találatot cseréli le.", "Replaces the last match.")
        case .replaceAll: L("Minden találatot lecserél.", "Replaces every match.")
        case .wildcard: L("* = bármennyi karakter, ? = pontosan egy karakter.", "* = any number of characters, ? = exactly one character.")
        case .append: L("A szöveg a név végére kerül.", "Adds the text to the end of the name.")
        case .prepend: L("A szöveg a név elejére kerül.", "Adds the text to the start of the name.")
        case .removeCharacters: L("Megadott számú karaktert töröl.", "Removes the given number of characters.")
        case .insertCharacters: L("A szöveget a megadott pozícióba szúrja be.", "Inserts the text at the given position.")
        case .changeCase: L("Átalakítja a kis- és nagybetűket.", "Changes upper and lower case.")
        case .sequence: L("Sorszámot ad a lista sorrendjében.", "Numbers the files in list order.")
        case .date: L("Dátumot tesz a névbe.", "Puts a date into the name.")
        case .regex: L("Csoportokra $1, $2 … hivatkozhatsz.", "Refer to groups with $1, $2 …")
        }
    }
}

struct ContentView: View {
    @Bindable var model: NomenModel
    @State private var isDropTargeted = false

    var body: some View {
        let previews = model.previews

        VStack(spacing: 0) {
            RuleCard(settings: $model.settings)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            Group {
                if model.items.isEmpty {
                    DropZone(isTargeted: isDropTargeted) { model.showOpenPanel() }
                        .padding([.horizontal, .bottom], 16)
                } else {
                    fileTable(previews)
                        .overlay {
                            if isDropTargeted {
                                Rectangle().strokeBorder(Color.nomen, lineWidth: 3)
                            }
                        }
                }
            }
            .frame(maxHeight: .infinity)

            footer(previews)
        }
        .background {
            ZStack(alignment: .top) {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient.nomen
                    .opacity(0.14)
                    .frame(height: 320)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            if let toast = model.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 78)
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                    .task(id: toast.id) {
                        try? await Task.sleep(for: .seconds(2.2))
                        if model.toast?.id == toast.id { model.toast = nil }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: model.toast)
        .tint(.nomen)
        .navigationTitle("Nomen")
        .navigationSubtitle(model.items.isEmpty ? L("Tömeges átnevezés", "Batch rename") : fileCount(model.items.count))
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .toolbar { toolbar }
        .alert(
            L("Hiba", "Error"),
            isPresented: Binding(get: { model.alertMessage != nil }, set: { if !$0 { model.alertMessage = nil } }),
            presenting: model.alertMessage
        ) { _ in
            Button("OK") {}
        } message: { Text($0) }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button { model.showOpenPanel() } label: { Label(L("Hozzáadás", "Add"), systemImage: "plus") }
                .help(L("Fájlok hozzáadása (⌘O)", "Add files (⌘O)"))
            Button { model.removeSelected() } label: { Label(L("Eltávolítás", "Remove"), systemImage: "minus") }
                .help(L("Kijelöltek eltávolítása a listából (⌫)", "Remove selected from the list (⌫)"))
                .disabled(model.selection.isEmpty)
            Button { model.clear() } label: { Label(L("Ürítés", "Clear"), systemImage: "trash") }
                .help(L("Lista ürítése (⇧⌘⌫)", "Clear the list (⇧⌘⌫)"))
                .disabled(model.items.isEmpty)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            ControlGroup {
                Button { model.moveSelected(by: -1) } label: { Label(L("Fel", "Up"), systemImage: "chevron.up") }
                    .help(L("Kijelöltek feljebb (⌥⌘↑) – a sorszámozás a lista sorrendjét követi", "Move selected up (⌥⌘↑) – sequence numbers follow the list order"))
                Button { model.moveSelected(by: 1) } label: { Label(L("Le", "Down"), systemImage: "chevron.down") }
                    .help(L("Kijelöltek lejjebb (⌥⌘↓)", "Move selected down (⌥⌘↓)"))
            }
            .disabled(model.selection.isEmpty)

            Menu {
                Picker(L("Nyelv", "Language"), selection: $model.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.inline)
            } label: {
                Label(L("Nyelv", "Language"), systemImage: "globe")
            }
            .help(L("Nyelv", "Language"))
        }
    }

    private func fileTable(_ previews: (byID: [FileItem.ID: Preview], error: String?)) -> some View {
        Table(model.items, selection: $model.selection, sortOrder: $model.sortOrder) {
            TableColumn(L("Eredeti név", "Original Name"), value: \.name) { item in
                HStack(spacing: 8) {
                    Image(nsImage: item.icon)
                        .resizable()
                        .frame(width: 18, height: 18)
                    Text(item.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .width(min: 160, ideal: 280)

            TableColumn("") { item in
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(previews.byID[item.id]?.isChange == true ? Color.nomen : Color.secondary.opacity(0.4))
            }
            .width(18)

            TableColumn(L("Új név", "New Name")) { item in
                if let preview = previews.byID[item.id] {
                    HStack(spacing: 6) {
                        if preview.issue != nil {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                        Text(highlighted(old: item.name, new: preview.newName, issue: preview.issue != nil))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .help(preview.issue?.message ?? "")
                }
            }
            .width(min: 160, ideal: 300)

            TableColumn(L("Módosítva", "Modified"), value: \.modified) { item in
                Text(item.modified, format: .dateTime.year().month(.abbreviated).day().hour().minute())
                    .foregroundStyle(.secondary)
            }
            .width(min: 110, ideal: 150, max: 190)
        }
        .scrollContentBackground(.hidden)
        .onDeleteCommand { model.removeSelected() }
    }

    /// Unchanged start and end of the name stay plain; the part that changes is coloured.
    private func highlighted(old: String, new: String, issue: Bool) -> AttributedString {
        var result = AttributedString(new)
        if issue {
            result.foregroundColor = .red
            return result
        }
        guard old != new else {
            result.foregroundColor = .secondary
            return result
        }
        let oldChars = Array(old), newChars = Array(new)
        var prefix = 0
        while prefix < min(oldChars.count, newChars.count), oldChars[prefix] == newChars[prefix] { prefix += 1 }
        var suffix = 0
        while suffix < min(oldChars.count, newChars.count) - prefix,
              oldChars[oldChars.count - 1 - suffix] == newChars[newChars.count - 1 - suffix] { suffix += 1 }

        let start = result.index(result.startIndex, offsetByCharacters: prefix)
        let end = result.index(result.endIndex, offsetByCharacters: -suffix)
        if start < end {
            result[start..<end].foregroundColor = .nomen
            result[start..<end].font = .body.weight(.semibold)
        }
        return result
    }

    private func footer(_ previews: (byID: [FileItem.ID: Preview], error: String?)) -> some View {
        let changes = previews.byID.values.filter(\.isChange).count
        let issues = previews.byID.values.filter { $0.issue != nil }.count

        return HStack(spacing: 8) {
            StatPill(symbol: "doc.on.doc", text: fileCount(model.items.count), color: .secondary)
            if changes > 0 {
                StatPill(symbol: "pencil", text: L("\(changes) változik", "\(changes) changing"), color: .nomen)
            }
            if issues > 0 {
                StatPill(symbol: "exclamationmark.triangle.fill", text: L("\(issues) ütközés", "\(issues) \(issues == 1 ? "conflict" : "conflicts")"), color: .red)
                    .help(L("Vidd az egeret a piros névre a részletekért", "Hover over a red name for details"))
            }
            if let error = previews.error {
                StatPill(symbol: "exclamationmark.triangle.fill", text: error, color: .red)
            }

            Spacer()

            if !model.lastRename.isEmpty {
                Button { model.undo() } label: {
                    Label(L("Visszavonás", "Undo"), systemImage: "arrow.uturn.backward")
                }
                .controlSize(.large)
                .help(L("Utolsó átnevezés visszavonása (⌥⌘Z)", "Undo the last rename (⌥⌘Z)"))
            }
            Button { model.rename() } label: {
                Label(changes > 0 ? L("\(changes) fájl átnevezése", "Rename \(fileCount(changes))") : L("Átnevezés", "Rename"), systemImage: "sparkles")
                    .contentTransition(.numericText())
            }
            .buttonStyle(GlowButtonStyle())
            .disabled(!model.canRename)
            .animation(.snappy, value: changes)
            .help(L("Átnevezés (⌘R)", "Rename (⌘R)"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Rule card

struct RuleCard: View {
    @Binding var settings: RenameSettings

    private var mode: RenameMode { settings.mode }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ModeChips(selection: $settings.mode)

            HStack(alignment: .bottom, spacing: 10) {
                Captioned(mode == .regex ? L("Minta", "Pattern") : L("Keresett szöveg", "Find")) {
                    TextField(mode.usesFind ? (mode == .regex ? L("pl. (\\d+)", "e.g. (\\d+)") : L("Eredeti szöveg", "Original text")) : "—", text: $settings.find)
                        .disabled(!mode.usesFind)
                }
                .opacity(mode.usesFind ? 1 : 0.45)

                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 7)

                Captioned(textCaption) {
                    TextField(mode.usesText ? textPlaceholder : "—", text: $settings.text)
                        .disabled(!mode.usesText)
                }
                .opacity(mode.usesText ? 1 : 0.45)
            }
            .textFieldStyle(.roundedBorder)
            .controlSize(.large)

            Divider()

            OptionsBar(settings: $settings)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .nomenViolet.opacity(0.18), radius: 18, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LinearGradient.nomen.opacity(0.45), lineWidth: 1)
        }
        .animation(.snappy(duration: 0.2), value: settings.mode)
    }

    private var textCaption: String {
        switch mode {
        case .sequence: L("Név", "Name")
        case .append, .prepend, .insertCharacters: L("Szöveg", "Text")
        default: L("Új szöveg", "New text")
        }
    }

    private var textPlaceholder: String {
        switch mode {
        case .sequence: L("Üresen csak a szám", "Leave empty for number only")
        case .regex: L("Csere ($1, $2 …)", "Replace with ($1, $2 …)")
        case .append, .prepend, .insertCharacters: L("Beszúrandó szöveg", "Text to add")
        default: L("Új szöveg", "New text")
        }
    }
}

struct Captioned<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            content
        }
    }
}

/// Settings that only some modes need, plus the extension toggle.
struct OptionsBar: View {
    @Binding var settings: RenameSettings

    var body: some View {
        HStack(spacing: 16) {
            switch settings.mode {
            case .replaceFirst, .replaceLast, .replaceAll, .wildcard, .regex:
                Toggle(L("Kis-/nagybetű érzékeny", "Case sensitive"), isOn: $settings.caseSensitive)
                hint

            case .removeCharacters:
                NumberField(title: L("Darab", "Count"), value: $settings.removeCount, range: 0...999)
                NumberField(title: L("Kihagy", "Skip"), value: $settings.removeOffset, range: 0...999)
                anchorPicker($settings.removeFrom)

            case .insertCharacters:
                NumberField(title: L("Pozíció", "Position"), value: $settings.insertOffset, range: 0...999)
                anchorPicker($settings.insertFrom)

            case .changeCase:
                Picker(L("Forma", "Style"), selection: $settings.caseStyle) {
                    ForEach(CaseStyle.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()

            case .sequence:
                NumberField(title: L("Kezdő", "Start"), value: $settings.sequenceStart, range: -99999...99999)
                NumberField(title: L("Lépés", "Step"), value: $settings.sequenceStep, range: -999...999)
                NumberField(title: L("Számjegy", "Digits"), value: $settings.sequenceDigits, range: 1...10)
                SmallTextField(title: L("Elválasztó", "Separator"), text: $settings.sequenceSeparator, width: 40)
                Picker(L("Szám", "Number"), selection: $settings.sequenceNumberFirst) {
                    Text(L("Név után", "After name")).tag(false)
                    Text(L("Név előtt", "Before name")).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Toggle(L("Eredeti név marad", "Keep original name"), isOn: $settings.sequenceKeepName)

            case .date:
                Picker(L("Dátum", "Date"), selection: $settings.dateSource) {
                    ForEach(DateSource.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                SmallTextField(title: L("Formátum", "Format"), text: $settings.dateFormat, width: 120)
                Picker(L("Hova", "Where"), selection: $settings.datePlacement) {
                    ForEach(DatePlacement.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                SmallTextField(title: L("Elválasztó", "Separator"), text: $settings.dateSeparator, width: 40)

            case .append, .prepend:
                hint
            }

            Spacer(minLength: 0)

            Toggle(isOn: $settings.keepExtension) {
                Text(L("Kiterjesztés marad", "Keep extension"))
            }
            .toggleStyle(.switch)
            .help(L("Bekapcsolva a szabály csak a névre hat, a kiterjesztés (.jpg, .pdf …) változatlan marad", "When on, the rule only changes the name; the extension (.jpg, .pdf …) stays as it is"))
        }
        .controlSize(.small)
        .frame(minHeight: 24)
    }

    private var hint: some View {
        Label(settings.mode.hint, systemImage: "info.circle")
            .foregroundStyle(.secondary)
            .font(.callout)
    }

    private func anchorPicker(_ selection: Binding<TextAnchor>) -> some View {
        Picker(L("Honnan", "From"), selection: selection) {
            Text(L("Elejétől", "From start")).tag(TextAnchor.start)
            Text(L("Végétől", "From end")).tag(TextAnchor.end)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }
}

struct NumberField: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            TextField("", value: $value, format: .number.grouping(.never))
                .textFieldStyle(.roundedBorder)
                .frame(width: 48)
                .multilineTextAlignment(.trailing)
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}

struct SmallTextField: View {
    let title: String
    @Binding var text: String
    let width: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: width)
        }
    }
}

// MARK: - Empty state and footer bits

struct DropZone: View {
    let isTargeted: Bool
    let onChoose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray.and.arrow.down")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(isTargeted ? Color.nomen : .secondary)
                .symbolEffect(.bounce, value: isTargeted)
            VStack(spacing: 4) {
                Text(L("Húzd ide a fájlokat vagy mappákat", "Drop files or folders here"))
                    .font(.title3.weight(.semibold))
                Text(L("Az új nevek azonnal megjelennek, semmi sem változik, amíg rá nem kattintasz az Átnevezésre.", "New names show up instantly; nothing changes until you click Rename."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(L("Fájlok kiválasztása…", "Choose Files…"), action: onChoose)
                .controlSize(.large)
                .keyboardShortcut("o")
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isTargeted ? Color.nomen.opacity(0.08) : .clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                .foregroundStyle(isTargeted ? Color.nomen : Color.secondary.opacity(0.35))
        }
        .animation(.easeOut(duration: 0.15), value: isTargeted)
    }
}

/// The twelve modes as tappable chips; the selected one glows in the brand gradient.
struct ModeChips: View {
    @Binding var selection: RenameMode
    @Namespace private var namespace

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(RenameMode.allCases) { mode in
                let isSelected = mode == selection
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selection = mode }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 18)
                            .symbolEffect(.bounce, value: isSelected)
                        Text(mode.shortTitle)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(isSelected ? .white : .primary)
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient.nomen)
                                .shadow(color: .nomenViolet.opacity(0.5), radius: 8, y: 3)
                                .matchedGeometryEffect(id: "selected", in: namespace)
                        } else {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ChipPressStyle())
                .help("\(mode.title) (⌃⌘\(String(mode.shortcut).uppercased()))")
            }
        }
    }
}

struct ChipPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Big gradient capsule with a soft glow, for the main action.
struct GlowButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 38)
            .background {
                Capsule()
                    .fill(isEnabled ? AnyShapeStyle(LinearGradient.nomen) : AnyShapeStyle(Color.gray.opacity(0.45)))
                    .shadow(color: isEnabled ? .nomenViolet.opacity(configuration.isPressed ? 0.3 : 0.55) : .clear, radius: 12, y: 4)
            }
            .overlay {
                Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        Label(toast.text, systemImage: toast.symbol)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .symbolEffect(.bounce, value: toast.id)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(LinearGradient.nomen)
                    .shadow(color: .nomenViolet.opacity(0.5), radius: 16, y: 6)
            }
    }
}

struct StatPill: View {
    let symbol: String
    let text: String
    let color: Color

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.callout.weight(.medium))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
