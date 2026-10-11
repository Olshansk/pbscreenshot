import Testing
import PBScreenshotMacOS

@Suite("Screen Recording permission")
@MainActor
struct PermissionTests {
    @Test("Permission is refreshed from macOS, including revocation")
    func refreshAndRevoke() {
        var granted = false
        let permission = ScreenRecordingPermission(preflight: { granted }, requestAccess: { granted = true; return true })
        #expect(!permission.isGranted)
        permission.request()
        #expect(permission.isGranted)
        granted = false
        permission.refresh()
        #expect(!permission.isGranted)
    }

    @Test("Request result alone is never treated as the current grant")
    func staleRequestResult() {
        let permission = ScreenRecordingPermission(preflight: { false }, requestAccess: { true })
        permission.request()
        #expect(!permission.isGranted)
    }
}
