import Foundation
import CommonCrypto

// ─────────────────────────────────────────────
// MARK: - PasswordHasher
// ─────────────────────────────────────────────

/// Salted PBKDF2-SHA256 password hashing via CommonCrypto (no external dependency).
///
/// Stored format: `"<saltHex>:<hashHex>"`.
enum PasswordHasher {

    private static let iterations    = 100_000
    private static let saltByteCount = 16   // 128-bit salt
    private static let keyLength     = 32   // 256-bit derived key

    /// Produce a salted hash ready to store in `Usuario.passwordHash`.
    static func hash(_ password: String) -> String {
        let salt   = randomSalt()
        let digest = derive(password: password, salt: salt)
        return hex(salt) + ":" + hex(digest)
    }

    /// Verify a plaintext password against a stored `"saltHex:hashHex"` value.
    static func verify(_ password: String, against stored: String) -> Bool {
        guard let separator = stored.firstIndex(of: ":") else { return false }
        let saltHex   = String(stored[..<separator])
        let digestHex = String(stored[stored.index(after: separator)...])
        guard let salt = data(fromHex: saltHex) else { return false }
        return constantTimeEquals(hex(derive(password: password, salt: salt)), digestHex)
    }

    // MARK: - Private

    private static func derive(password: String, salt: Data) -> Data {
        let passBytes = Array(password.utf8)
        let saltBytes = Array(salt)
        var derived   = Data(count: keyLength)
        derived.withUnsafeMutableBytes { ptr in
            _ = CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passBytes, passBytes.count,
                saltBytes, saltBytes.count,
                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                UInt32(iterations),
                ptr.baseAddress?.assumingMemoryBound(to: UInt8.self), keyLength
            )
        }
        return derived
    }

    private static func randomSalt() -> Data {
        var bytes = Data(count: saltByteCount)
        bytes.withUnsafeMutableBytes {
            _ = SecRandomCopyBytes(kSecRandomDefault, saltByteCount, $0.baseAddress!)
        }
        return bytes
    }

    private static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static func data(fromHex string: String) -> Data? {
        guard string.count % 2 == 0 else { return nil }
        var bytes = Data(capacity: string.count / 2)
        var index = string.startIndex
        while index < string.endIndex {
            let next = string.index(index, offsetBy: 2)
            guard let byte = UInt8(string[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        return bytes
    }

    private static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let lhs = Array(a.utf8), rhs = Array(b.utf8)
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<lhs.count { diff |= lhs[i] ^ rhs[i] }
        return diff == 0
    }
}
