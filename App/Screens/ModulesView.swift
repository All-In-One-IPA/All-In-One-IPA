import SwiftUI

struct ModulesView: View {
    @State private var search = ""
    @State private var selectedCategory: ModuleCategory?

    private var filtered: [ModuleInfo] {
        ModuleCatalog.all.filter { module in
            (selectedCategory == nil || module.category == selectedCategory) &&
            (search.isEmpty || module.title.localizedCaseInsensitiveContains(search) ||
             module.subtitle.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 7) {
                        Eyebrow(text: "КАТАЛОГ")
                        Text("Модули")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text("Инструменты, которые будут жить здесь.")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.secondary)
                    }
                    searchField
                    categoryFilters
                    HStack {
                        Text("Найдено: \(filtered.count)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.secondary)
                        Spacer()
                        Text("0 готовы к работе")
                            .font(.system(size: 12))
                            .foregroundStyle(Palette.secondary)
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { module in
                            ModuleListRow(module: module)
                        }
                    }
                    if filtered.isEmpty {
                        QuietEmptyState(symbol: "magnifyingglass", title: "Ничего не нашлось",
                                        message: "Попробуй другое название или сбрось фильтр.")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 17)
                .padding(.bottom, 30)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var searchField: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.secondary)
            TextField("Найти модуль", text: $search)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button {
                    search = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.secondary)
                }
                .accessibilityLabel("Очистить поиск")
            }
        }
        .padding(15)
        .surfaceCard(radius: 18)
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("Все", category: nil)
                ForEach(ModuleCategory.allCases) { category in
                    filterChip(category.title, category: category)
                }
            }
        }
        .contentMargins(.trailing, 20)
        .padding(.trailing, -20)
    }

    private func filterChip(_ title: String, category: ModuleCategory?) -> some View {
        let active = selectedCategory == category
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedCategory = category
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? Palette.background : Palette.secondary)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(active ? Palette.cyan : Palette.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(active ? Color.clear : Palette.hairline, lineWidth: 0.7))
        }
        .buttonStyle(.plain)
    }
}
