import SwiftUI

/// The filter form shared by the Ratings and Random screens.
struct FiltersSheet: View {
    let options: FilterTypes
    let showScore: Bool
    let onApply: (MovieListQuery) -> Void

    @State private var draft: FilterDraft
    @Environment(\.dismiss) private var dismiss

    init(options: FilterTypes, query: MovieListQuery, showScore: Bool = true, onApply: @escaping (MovieListQuery) -> Void) {
        self.options = options
        self.showScore = showScore
        self.onApply = onApply
        _draft = State(initialValue: FilterDraft(query: query, runtimeBounds: options.runtimeBounds))
    }

    var body: some View {
        NavigationStack {
            Form {
                if showScore {
                    Section("Score") {
                        RangeRow(range: $draft.score, bounds: FilterDraft.scoreBounds) { "\(Int($0))" }
                    }
                }
                Section {
                    pickers
                }
                Section {
                    Toggle("Free to Watch", isOn: $draft.free)
                    Toggle("Dani Approved", isOn: $draft.daniApproved)
                }
                Section("Runtime") {
                    RangeRow(range: $draft.runtime, bounds: draft.runtimeBounds) { "\(Int($0)) min" }
                }
                Section {
                    Button("Reset all filters", role: .destructive) {
                        draft.reset()
                    }
                }
            }
            .listRowBackground(Color.appCard)
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft.query)
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var pickers: some View {
        MultiSelectPicker(title: "Genre",
                          sections: FilterOptions.genres(options.genre),
                          selection: $draft.genres)
        MultiSelectPicker(title: "Universe",
                          sections: FilterOptions.universes(options.universes),
                          selection: $draft.universes)
        MultiSelectPicker(title: "Director",
                          sections: [PickerSection(values: FilterOptions.directors(options.director))],
                          selection: $draft.directors,
                          searchable: true)
        MultiSelectPicker(title: "Studio",
                          sections: [PickerSection(values: options.studio)],
                          selection: $draft.studios,
                          searchable: true)
        MultiSelectPicker(title: "Year",
                          sections: [PickerSection(values: FilterOptions.years(options.year))],
                          selection: $draft.years,
                          searchable: true)
        MultiSelectPicker(title: "Streaming Provider",
                          sections: [PickerSection(options: FilterOptions.providers(options.provider))],
                          selection: $draft.providers,
                          displayName: { FilterOptions.providerName(for: $0, in: options.provider) })
        MultiSelectPicker(title: "Holiday",
                          sections: [PickerSection(values: options.holiday)],
                          selection: $draft.holidays)
        MultiSelectPicker(title: "Decade",
                          sections: [PickerSection(values: FilterOptions.decades(fromYears: options.year))],
                          selection: $draft.decades)
    }
}

/// A labelled range slider row.
private struct RangeRow: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let format: (Double) -> String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(format(range.lowerBound))
                Spacer()
                Text(format(range.upperBound))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.appAccent)
            RangeSlider(range: $range, bounds: bounds)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    FiltersSheet(options: .fixture(), query: MovieListQuery(genre: ["Action"])) { _ in }
        .preferredColorScheme(.dark)
}
#endif
