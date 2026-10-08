import Foundation

/// Whether Podium can use a given firmware as an emulator target, and why.
enum FirmwareCompatibility: Codable, Hashable {
    case compatible
    /// The IPSW parsed fine, but none of its supported devices are ones
    /// Podium knows about.
    case unsupportedDevice
    /// The device is recognized, but this exact iOS version/build hasn't
    /// been validated against Podium's firmware parser and emulator work.
    case unsupportedVersion

    var isCompatible: Bool { self == .compatible }

    var summary: String {
        switch self {
        case .compatible: return "Compatible"
        case .unsupportedDevice: return "Unsupported device"
        case .unsupportedVersion: return "Unsupported version"
        }
    }
}

/// Decides compatibility for parsed firmware metadata.
///
/// Podium now supports multiple iOS versions across multiple iPod touch
/// generations. This checker validates that:
/// 1. The device is recognized (iPod touch 2nd-5th generation)
/// 2. The iOS version/build combination is in the supported list for that device
enum FirmwareCompatibilityChecker {
    static func evaluate(_ metadata: FirmwareMetadata) -> FirmwareCompatibility {
        // Check if device is recognized
        guard metadata.supportedDeviceIdentifiers.contains(where: { deviceId in
            DeviceCatalog.device(for: deviceId) != nil
        }) else {
            return .unsupportedDevice
        }
        
        // Find the first recognized device in the firmware
        guard let deviceId = metadata.supportedDeviceIdentifiers.first(where: { deviceId in
            DeviceCatalog.device(for: deviceId) != nil
        }) else {
            return .unsupportedDevice
        }
        
        // Check if this iOS version is supported for the device
        let supportedVersions = DeviceFirmwareSupport.versions(for: deviceId)
        let isSupported = supportedVersions.contains { version in
            version.productVersion == metadata.productVersion &&
            version.buildVersion == metadata.buildVersion
        }
        
        return isSupported ? .compatible : .unsupportedVersion
    }
}
