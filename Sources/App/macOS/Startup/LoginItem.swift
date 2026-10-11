import ServiceManagement
import SwiftUI

@MainActor
final class LoginItem: ObservableObject {
    @Published private(set) var status: SMAppService.Status
    @Published private(set) var errorMessage: String?
    private let readStatus: () -> SMAppService.Status
    private let register: () throws -> Void
    private let unregister: () throws -> Void

    init(
        readStatus: @escaping () -> SMAppService.Status = { SMAppService.mainApp.status },
        register: @escaping () throws -> Void = { try SMAppService.mainApp.register() },
        unregister: @escaping () throws -> Void = { try SMAppService.mainApp.unregister() }
    ) {
        self.readStatus = readStatus
        self.register = register
        self.unregister = unregister
        status = readStatus()
    }

    var isRegistered: Bool { status == .enabled || status == .requiresApproval }

    func refresh() {
        status = readStatus()
    }

    /// Apply the request, then read back the OS state even when registration fails.
    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled { try register() } else { try unregister() }
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
