import Foundation
import ServiceManagement
import Testing
@testable import pbscreenshotAgent

@Suite("Launch at login")
@MainActor
struct LoginItemTests {
    @Test("Approval pending stays registered and refresh observes external changes")
    func approvalAndRefresh() {
        var state = SMAppService.Status.notRegistered
        let item = LoginItem(readStatus: { state }, register: { state = .requiresApproval }, unregister: { state = .notRegistered })
        item.setEnabled(true)
        #expect(item.isRegistered)
        #expect(item.status == .requiresApproval)
        state = .enabled
        item.refresh()
        #expect(item.status == .enabled)
        item.setEnabled(false)
        #expect(!item.isRegistered)
    }

    @Test("Failure shows the error and keeps the actual OS state")
    func failedRegistration() {
        let item = LoginItem(readStatus: { .notRegistered }, register: { throw CocoaError(.fileWriteNoPermission) }, unregister: {})
        item.setEnabled(true)
        #expect(!item.isRegistered)
        #expect(item.errorMessage != nil)
    }

    @Test("Failed unregister does not pretend the login item is off")
    func failedUnregister() {
        let item = LoginItem(readStatus: { .enabled }, register: {}, unregister: { throw CocoaError(.fileWriteNoPermission) })
        item.setEnabled(false)
        #expect(item.isRegistered)
        #expect(item.errorMessage != nil)
    }
}
