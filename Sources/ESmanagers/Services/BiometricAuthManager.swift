import LocalAuthentication
import Foundation

/// Face ID / Touch ID による生体認証を提供するシングルトン。
/// 生体認証が利用不可の場合はデバイスパスコードにフォールバックする。
final class BiometricAuthManager: @unchecked Sendable {

    static let shared = BiometricAuthManager()
    private init() {}

    // MARK: - Capability checks

    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// 利用可能な生体認証の種類（FaceID / TouchID / None）
    var biometryType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }

    // MARK: - Authentication

    /// 生体認証を要求する（不可の場合はパスコードにフォールバック）。
    /// - Returns: 認証成功なら `true`、キャンセルや失敗なら `false`
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var canEvalError: NSError?

        let policy: LAPolicy =
            context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &canEvalError)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: nil) else { return false }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
