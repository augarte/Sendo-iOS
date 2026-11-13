//
//  ExerciseDetailView.swift
//  Sendo
//
//  Created by Aimar Ugarte on 8/5/22.
//

import SwiftUI

final class ExerciseDetailViewController: SendoViewController, UIGestureRecognizerDelegate {
    private let exercise: Exercise
    private weak var previousPopDelegate: UIGestureRecognizerDelegate?

    private init(exercise: Exercise) {
        self.exercise = exercise
        super.init(title: exercise.title)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    static func create(exercise: Exercise) -> ExerciseDetailViewController {
        ExerciseDetailViewController(exercise: exercise)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedSendoScreen(UIHostingController(rootView: ExerciseDetailScreen(exercise: exercise) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // Hiding the navigation bar turns off the edge-swipe back gesture, so it is switched back on while this screen shows.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let gesture = navigationController?.interactivePopGestureRecognizer
        previousPopDelegate = gesture?.delegate
        gesture?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = previousPopDelegate
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}

private struct ExerciseDetailScreen: View {
    let exercise: Exercise
    let onBack: () -> Void
    @ObservedObject private var favorites = FavoriteExercises.shared

    var body: some View {
        let secondary = exercise.secondaryTitles
        let equipment = exercise.equipmentTitles
        SendoPage(title: exercise.title, back: ("Exercises", onBack), backIcon: "chevron.left", titleSize: 46, titleLines: 3) {
            hero
            if !exercise.description.isEmpty {
                Text(exercise.description).font(.body).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 12) {
                header("Muscles")
                tags("Primary", exercise.primaryTitles, filled: true)
                if !secondary.isEmpty { tags("Secondary", secondary, filled: false) }
            }
            if !equipment.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    header("Equipment")
                    SendoFlowLayout { ForEach(equipment, id: \.self) { SendoTag(text: $0) } }
                }
            }
            if !exercise.steps.isEmpty { steps }
            if !exercise.tips.isEmpty { tips }
        }
        .overlay(alignment: .topTrailing) { starButton }
    }

    private var starButton: some View {
        let starred = favorites.contains(exercise.id)
        return Button { favorites.toggle(exercise.id) } label: {
            Image(systemName: starred ? "star.fill" : "star")
                .font(.title2)
                .foregroundStyle(starred ? SendoPalette.ink : SendoPalette.subdued)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: starred)
        .padding(.trailing, 12)
        .accessibilityLabel(starred ? "Remove from favourites" : "Add to favourites")
        .accessibilityIdentifier("exercise.favorite")
    }

    private var hero: some View {
        let urls = exercise.images.prefix(2).compactMap { URL(string: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            if urls.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    SendoEyebrow(text: "Primary muscle", color: SendoPalette.heroSubdued)
                    SendoDisplayText(exercise.primaryTitles.joined(separator: " · "), size: 40, relativeTo: .largeTitle)
                        .minimumScaleFactor(0.5)
                        .lineLimit(2)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        figure(url, label: urls.count == 2 ? (index == 0 ? "Relaxation" : "Tension") : nil)
                    }
                }
            }
            HStack(spacing: 10) {
                if !exercise.typeTitle.isEmpty {
                    SendoDisplayText(exercise.typeTitle, size: 15, weight: .heavy, relativeTo: .footnote)
                        .tracking(0.8)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 28)
                        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(SendoPalette.heroInk, lineWidth: 1.5) }
                }
                Text(meta).font(.footnote).foregroundStyle(SendoPalette.heroSubdued)
            }
        }
        .modifier(SendoHero())
    }

    private func figure(_ url: URL, label: String?) -> some View {
        VStack(spacing: 6) {
            // The tile's size comes from the clear base, never from the image, so every exercise shows the same
            // portrait tile whatever the picture's shape or whether it has loaded yet.
            Color(red: 0.984, green: 0.976, blue: 0.957)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .overlay {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit().padding(8)
                        case .failure:
                            Image(systemName: "photo").font(.title2).foregroundStyle(SendoPalette.plateInk.opacity(0.5))
                        default:
                            ProgressView().tint(SendoPalette.plateInk)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 12))
            if let label {
                SendoDisplayText(label, size: 16, weight: .heavy, relativeTo: .footnote).tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.map { "\($0) position" } ?? "Exercise image")
    }

    private var meta: String {
        var parts: [String] = []
        if !exercise.steps.isEmpty { parts.append(exercise.steps.count == 1 ? "1 step" : "\(exercise.steps.count) steps") }
        if !exercise.tips.isEmpty { parts.append(exercise.tips.count == 1 ? "1 tip" : "\(exercise.tips.count) tips") }
        return parts.joined(separator: " · ")
    }

    private func header(_ title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            SendoDisplayText(title, size: 26, weight: .heavy, relativeTo: .title3)
                .accessibilityAddTraits(.isHeader)
            SwiftUI.Spacer()
            if let detail { Text(detail).font(.footnote).foregroundStyle(SendoPalette.subdued) }
        }
    }

    private func tags(_ label: String, _ names: [String], filled: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label).font(.footnote).foregroundStyle(SendoPalette.subdued).frame(width: 74, alignment: .leading)
            SendoFlowLayout { ForEach(names, id: \.self) { SendoTag(text: $0, filled: filled) } }
        }
    }

    private var steps: some View {
        VStack(spacing: 0) {
            header("How to", detail: exercise.steps.count == 1 ? "1 step" : "\(exercise.steps.count) steps")
                .padding(.bottom, 6)
            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                Divider().overlay(SendoPalette.line)
                HStack(alignment: .top, spacing: 14) {
                    SendoDisplayText((index + 1).formatted(), size: 32, weight: .black, relativeTo: .title)
                        .foregroundStyle(SendoPalette.subdued)
                        .frame(width: 30, alignment: .leading)
                        .accessibilityHidden(true)
                    Text(step).font(.body).fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(step)")
            }
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 8) {
            SendoEyebrow(text: exercise.tips.count == 1 ? "Tip" : "Tips")
            ForEach(exercise.tips, id: \.self) { tip in
                Text(tip).font(.body).fixedSize(horizontal: false, vertical: true)
            }
        }
        .modifier(SendoPanel())
    }
}
