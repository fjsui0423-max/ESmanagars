import Foundation
import Security

/// Keychain を使用してパスワードを安全に保存・取得・削除するシングルトン。
/// アカウントキーには Company.id.uuidString を使用する。
final class KeychainManager: @unchecked Sendable {

    static let shared = KeychainManager()
    private init() {}

    private let service: String = Bundle.main.bundleIdentifier ?? "com.esmanagers.app"

    // MARK: - Public API

    func savePassword(_ password: String, for account: String) {
        let data = Data(password.utf8)
        // 既存エントリを削除してから追加（upsert 相当）
        SecItemDelete(baseQuery(for: account) as CFDictionary)
        var query = baseQuery(for: account)
        query[kSecValueData as String] = data
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("⚠️ Keychain save failed: \(status)")
        }
    }

    func loadPassword(for account: String) -> String? {
        var query = baseQuery(for: account)
        query[kSecReturnData  as String] = true
        query[kSecMatchLimit  as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deletePassword(for account: String) {
        SecItemDelete(baseQuery(for: account) as CFDictionary)
    }

    // MARK: - Private

    private func baseQuery(for account: String) -> [String: Any] {
        [kSecClass       as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }
}
