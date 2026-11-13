import Combine
import SimpleLineChart
import SwiftUI

final class ProgressViewController: BaseTabViewController {
    private let viewModel: ProgressViewModel
    private var screen: UIHostingController<MeasurementsScreen>?
    private var subscription: AnyCancellable?

    init(viewModel: ProgressViewModel) {
        self.viewModel = viewModel
        super.init(title: "Progress", image: "MeasurementWhite")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscription = viewModel.$state.sink { [weak self] in self?.render($0) }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        Task { await viewModel.load() }
    }

    private func render(_ state: ProgressViewModel.State) {
        let revision = viewModel.revision
        let content = MeasurementsScreen(
            state: state,
            onRefresh: { [viewModel] in await viewModel.load() },
            onEdit: { [weak self] measurement in
                guard let self, self.viewModel.revision == revision else { return }
                self.showEditor(for: measurement)
            },
            onDelete: { [weak self] measurement in self?.delete(measurement, revision: revision) }
        )
        if let screen {
            screen.rootView = content
        } else {
            let screen = UIHostingController(rootView: content)
            embedSendoScreen(screen)
            self.screen = screen
        }
    }

    private func delete(_ measurement: BodyMeasurement, revision: UUID) {
        Task {
            do {
                try await viewModel.delete(id: measurement.id, revision: revision)
            } catch {
                let alert = UIAlertController(title: "Couldn’t delete weight", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func showEditor(for measurement: BodyMeasurement?) {
        let revision = viewModel.revision
        let editor = NewEntryDialog(measurement: measurement) { [viewModel] draft in
            try await viewModel.save(draft, isEditing: measurement != nil, revision: revision)
        }
        showModalView(viewController: editor)
    }
}

private struct MeasurementsScreen: View {
    let state: ProgressViewModel.State
    let onRefresh: () async -> Void
    let onEdit: (BodyMeasurement?) -> Void
    let onDelete: (BodyMeasurement) -> Void

    var body: some View {
        SendoPage(title: "Progress", context: "Measurements") {
            if let latest = state.measurements.first {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            SendoEyebrow(text: "Latest weight", color: SendoPalette.heroSubdued)
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                SendoDisplayText(latest.value.clean, size: 92, relativeTo: .largeTitle)
                                    .monospacedDigit()
                                if let unit = latest.unit {
                                    SendoDisplayText(unit.rawValue, size: 30, weight: .heavy, relativeTo: .title2)
                                        .foregroundStyle(SendoPalette.heroSubdued)
                                }
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(weight(latest))
                        }
                        SwiftUI.Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 6) {
                            if let change = change(at: 0) {
                                Text("\(change.clean)%")
                                    .font(.subheadline.weight(.bold)).monospacedDigit()
                                    .foregroundStyle(SendoPalette.hero)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(SendoPalette.heroInk, in: .rect(cornerRadius: 6))
                            }
                            Text(latest.measuredAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.footnote).foregroundStyle(SendoPalette.heroSubdued)
                        }
                        .padding(.bottom, 8)
                    }
                    if state.measurements.count > 1 {
                        MeasurementChart(measurements: state.measurements).frame(height: 110)
                            .accessibilityLabel("Weight history chart")
                    }
                }
                .modifier(SendoHero())
            } else if state.isLoading {
                ProgressView("Loading measurements…").frame(minHeight: 44)
            } else if let error = state.loadError {
                SendoEmptyState(icon: "exclamationmark.circle", title: "Couldn’t load measurements", detail: error)
                Button("Retry") { Task { await onRefresh() } }.buttonStyle(SendoButtonStyle(.secondary))
            } else {
                SendoEmptyState(icon: "chart.xyaxis.line", title: "No measurements yet",
                                detail: "Log your first weight to start a history.")
            }
            Button("Log weight") { onEdit(nil) }
                .buttonStyle(SendoButtonStyle(.primary))
                .accessibilityIdentifier("progress.addMeasurement")

            if !state.measurements.isEmpty {
                VStack(spacing: 0) {
                    SendoDisplayText("History", size: 26, weight: .heavy, relativeTo: .title3)
                        .accessibilityAddTraits(.isHeader)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)
                    ForEach(Array(state.measurements.enumerated()), id: \.element.id) { index, measurement in
                        Divider().overlay(SendoPalette.line)
                        HStack(spacing: 0) {
                            Button { onEdit(measurement) } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(weight(measurement)).font(.body.weight(.semibold)).monospacedDigit()
                                    if let change = change(at: index) {
                                        Text("\(change.clean)%")
                                            .font(.footnote).monospacedDigit()
                                            .foregroundStyle(SendoPalette.subdued)
                                    }
                                    SwiftUI.Spacer()
                                    Text(measurement.measuredAt.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline).foregroundStyle(SendoPalette.subdued)
                                }
                                .frame(minHeight: 54)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            Menu {
                                Button("Delete weight", systemImage: "trash", role: .destructive) { onDelete(measurement) }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(SendoPalette.subdued)
                                    .frame(width: 44, height: 44, alignment: .trailing).contentShape(.rect)
                            }
                            .accessibilityLabel("Measurement actions")
                        }
                    }
                }
            }
        }
        .refreshable { await onRefresh() }
    }

    private func change(at index: Int) -> Double? {
        guard index + 1 < state.measurements.count else { return nil }
        let current = state.measurements[index]
        let previous = state.measurements[index + 1]
        guard previous.value > 0, current.unit == previous.unit else { return nil }
        let percentage = 100 * (current.value - previous.value) / previous.value
        guard percentage.isFinite else { return nil }
        let rounded = percentage.round(to: 1)
        return rounded == 0 ? nil : rounded
    }

    private func weight(_ measurement: BodyMeasurement) -> String {
        measurement.value.clean + (measurement.unit.map { " \($0.rawValue)" } ?? "")
    }
}

private struct MeasurementChart: UIViewRepresentable {
    let measurements: [BodyMeasurement]

    func makeUIView(context: Context) -> SimpleLineChart {
        let chart = SimpleLineChart()
        chart.setChartStyle(chartStyle: SLCChartStyle(backgroundGradient: false, solidBackgroundColor: .clear))
        chart.backgroundColor = .clear
        return chart
    }

    func updateUIView(_ chart: SimpleLineChart, context: Context) {
        var plottedSeconds = Set<Int>()
        var points = measurements.compactMap { measurement -> SLCData? in
            let seconds = measurement.measuredAt.timeIntervalSince1970.rounded(.towardZero)
            guard let timestamp = Int(exactly: seconds), plottedSeconds.insert(timestamp).inserted else { return nil }
            return SLCData(x: timestamp, y: measurement.value)
        }
        let now = Int(Date().timeIntervalSince1970)
        if let latest = points.first, latest.x < now {
            points.insert(SLCData(x: now, y: latest.y), at: 0)
        }
        let dataSet = SLCDataSet(graphPoints: points)
        dataSet.setLineStyle(SLCLineStyle(
            lineColor: UIColor(SendoPalette.heroInk), lineStroke: 3, circleDiameter: 8, lineShadow: false
        ))
        chart.loadPoints(dataSet: dataSet)
    }
}
