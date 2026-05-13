import SwiftUI

struct DrillsView: View {
    let onStartDrill: () -> Void
    @State private var searchText: String = ""
    @State private var selectedSkills: Set<String> = []
    private let tabBarClearance: CGFloat = 118

    private var filteredTemplates: [DrillTemplate] {
        DrillLibrary.templates.filter { template in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchable = ([template.title, template.description] + template.primarySkills + template.secondarySkills)
                .joined(separator: " ")
            let matchesSearch = query.isEmpty || searchable.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            let allSkills = Set((template.primarySkills + template.secondarySkills).map { $0.lowercased() })
            let matchesSkills = selectedSkills.allSatisfy { skill in allSkills.contains(skill.lowercased()) }
            return matchesSearch && matchesSkills
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Drills")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                    .padding(.top, 4)

                searchAndFilters

                VStack(spacing: 10) {
                    if filteredTemplates.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredTemplates) { template in
                            NavigationLink {
                                DrillDetailView(template: template, onStartDrill: onStartDrill)
                            } label: {
                                DrillTemplateRow(template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, Layout.pagePadding)
            .padding(.bottom, tabBarClearance)
        }
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .appBackSwipeEnabled()
    }

    private var searchAndFilters: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Theme.muted)
                TextField("Search drills", text: $searchText)
                    .foregroundColor(Theme.text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundColor(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Theme.panel2.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DrillLibrary.fargoSkills, id: \.self) { skill in
                        FilterSkillButton(skill: skill, isOn: selectedSkills.contains(skill)) {
                            if selectedSkills.contains(skill) { selectedSkills.remove(skill) } else { selectedSkills.insert(skill) }
                        }
                    }
                    if !selectedSkills.isEmpty {
                        Button("Clear") { selectedSkills.removeAll() }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.muted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Theme.panel2.opacity(0.65))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("No drills match that filter")
                .font(.headline.weight(.semibold))
                .foregroundColor(Theme.text)
            Text("Try clearing one skill or searching a broader term.")
                .font(.caption)
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.panel2.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))
    }
}

private struct DrillTemplateRow: View {
    let template: DrillTemplate

    var body: some View {
        HStack(spacing: 12) {
            DrillThumbnail(template: template)
                .frame(width: 96, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.6))

            VStack(alignment: .leading, spacing: 6) {
                Text(template.title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Theme.text)
                    .lineLimit(2)
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(Theme.muted)
                    .lineLimit(2)
                HStack(spacing: 7) {
                    ForEach(Array(template.primarySkills.prefix(2)), id: \.self) { skill in
                        drillBadge(skill, color: drillColor(skill))
                    }
                    drillBadge(template.difficultyRangeText, color: Theme.text2)
                }
            }

            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Theme.muted)
        }
        .padding(12)
        .background(Theme.panel2.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 0.6))
    }
}
