import SwiftUI

/// A form row that pushes a checklist for choosing several values.
struct MultiSelectPicker: View {
    let title: String
    let sections: [PickerSection]
    @Binding var selection: Set<String>
    var displayName: (String) -> String = { $0 }
    var searchable = false

    private var summary: String {
        selection.isEmpty ? "Any" : selection.sorted().map(displayName).joined(separator: ", ")
    }

    var body: some View {
        NavigationLink {
            MultiSelectList(title: title, sections: sections, selection: $selection, searchable: searchable)
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.appLight)
                Spacer()
                Text(summary)
                    .foregroundStyle(selection.isEmpty ? Color.appMuted : Color.appAccent)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 180, alignment: .trailing)
            }
        }
    }
}

private struct MultiSelectList: View {
    let title: String
    let sections: [PickerSection]
    @Binding var selection: Set<String>
    let searchable: Bool

    @State private var searchText = ""

    private var visibleSections: [PickerSection] {
        let needle = SearchIndex.fold(searchText)
        guard !needle.isEmpty else { return sections }
        return sections.compactMap { section in
            let options = section.options.filter { SearchIndex.fold($0.label).contains(needle) }
            return options.isEmpty ? nil : PickerSection(title: section.title, options: options)
        }
    }

    var body: some View {
        list
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !selection.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") { selection.removeAll() }
                    }
                }
            }
    }

    @ViewBuilder
    private var list: some View {
        if searchable {
            optionList.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        } else {
            optionList
        }
    }

    private var optionList: some View {
        List {
            ForEach(visibleSections) { section in
                Section {
                    ForEach(section.options) { option in
                        Button {
                            toggle(option.value)
                        } label: {
                            HStack(spacing: 12) {
                                if let url = option.imageURL {
                                    RemoteImage(url: url, contentMode: .fill) { Color.appMuted.opacity(0.3) }
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                }
                                Text(option.label)
                                    .foregroundStyle(.appLight)
                                    .fontWeight(selection.contains(option.value) ? .semibold : .regular)
                                Spacer()
                                if selection.contains(option.value) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.appAccent)
                                }
                            }
                        }
                        .listRowBackground(Color.appCard)
                    }
                } header: {
                    if let header = section.title {
                        Text(header)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .screenBackground()
    }

    private func toggle(_ value: String) {
        if selection.contains(value) {
            selection.remove(value)
        } else {
            selection.insert(value)
        }
    }
}
