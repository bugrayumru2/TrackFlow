import Foundation
import Combine

@MainActor
final class TrackFlowPreferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var configuration: GestureConfiguration {
        didSet {
            let validated = configuration.normalized
            if configuration != validated {
                configuration = validated
                return
            }
            save(configuration, key: "gestureConfiguration")
        }
    }
    @Published var excludedApplications: [ExcludedApplication] {
        didSet { save(excludedApplications, key: "excludedApplications") }
    }
    @Published var startMonitoringOnLaunch: Bool {
        didSet { defaults.set(startMonitoringOnLaunch, forKey: "startMonitoringOnLaunch") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        configuration = defaults.data(forKey: "gestureConfiguration")
            .flatMap { try? JSONDecoder().decode(GestureConfiguration.self, from: $0) }?.normalized ?? .default
        excludedApplications = defaults.data(forKey: "excludedApplications")
            .flatMap { try? JSONDecoder().decode([ExcludedApplication].self, from: $0) } ?? []
        startMonitoringOnLaunch = defaults.bool(forKey: "startMonitoringOnLaunch")
    }

    func addExclusion(id: String, name: String) {
        guard !id.isEmpty, !excludedApplications.contains(where: { $0.id == id }) else { return }
        excludedApplications.append(.init(id: id, name: name))
    }

    func excludedName(for bundleID: String?) -> String? {
        excludedApplications.first { $0.id == bundleID }?.name
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
