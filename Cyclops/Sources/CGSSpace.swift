import AppKit

// MARK: - Private CoreGraphics SPI

typealias CGSConnectionID = UInt32
typealias CGSSpaceID = UInt64

@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> CGSConnectionID

@_silgen_name("CGSSpaceCreate")
func CGSSpaceCreate(_ cid: CGSConnectionID, _ flag: Int, _ options: NSDictionary?) -> CGSSpaceID

@_silgen_name("CGSSpaceSetAbsoluteLevel")
func CGSSpaceSetAbsoluteLevel(_ cid: CGSConnectionID, _ space: CGSSpaceID, _ level: Int)

@_silgen_name("CGSSpaceDestroy")
func CGSSpaceDestroy(_ cid: CGSConnectionID, _ space: CGSSpaceID)

@_silgen_name("CGSShowSpaces")
func CGSShowSpaces(_ cid: CGSConnectionID, _ spaces: NSArray)

@_silgen_name("CGSHideSpaces")
func CGSHideSpaces(_ cid: CGSConnectionID, _ spaces: NSArray)

@_silgen_name("CGSAddWindowsToSpaces")
func CGSAddWindowsToSpaces(_ cid: CGSConnectionID, _ windowIDs: NSArray, _ spaceIDs: NSArray)

@_silgen_name("CGSRemoveWindowsFromSpaces")
func CGSRemoveWindowsFromSpaces(_ cid: CGSConnectionID, _ windowIDs: NSArray, _ spaceIDs: NSArray)

// MARK: - NotchSpace

class NotchSpace {
    let spaceID: CGSSpaceID
    private let connection: CGSConnectionID
    private var _windows: Set<CGWindowID> = []

    var windows: Set<CGWindowID> {
        get { _windows }
        set {
            let added = newValue.subtracting(_windows)
            let removed = _windows.subtracting(newValue)
            _windows = newValue

            if !added.isEmpty {
                CGSAddWindowsToSpaces(
                    connection,
                    added.map { NSNumber(value: $0) } as NSArray,
                    [NSNumber(value: spaceID)] as NSArray
                )
            }
            if !removed.isEmpty {
                CGSRemoveWindowsFromSpaces(
                    connection,
                    removed.map { NSNumber(value: $0) } as NSArray,
                    [NSNumber(value: spaceID)] as NSArray
                )
            }
        }
    }

    init() {
        connection = _CGSDefaultConnection()
        spaceID = CGSSpaceCreate(connection, 2, nil)  // 2 = fullscreen space type
        CGSSpaceSetAbsoluteLevel(connection, spaceID, 2_147_483_647)  // max Int32
        CGSShowSpaces(connection, [NSNumber(value: spaceID)] as NSArray)
    }

    deinit {
        CGSHideSpaces(connection, [NSNumber(value: spaceID)] as NSArray)
        CGSSpaceDestroy(connection, spaceID)
    }
}

// MARK: - NotchSpaceManager

class NotchSpaceManager {
    static let shared = NotchSpaceManager()
    let notchSpace = NotchSpace()

    private init() {}

    func addWindow(_ windowNumber: Int) {
        notchSpace.windows.insert(CGWindowID(windowNumber))
    }

    func removeWindow(_ windowNumber: Int) {
        notchSpace.windows.remove(CGWindowID(windowNumber))
    }
}
