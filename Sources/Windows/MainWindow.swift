import Luminare
import SwiftUI

final class MainWindowController: NSWindowController {
    var luminareWindow: LuminareWindow?

    public init() {
        let window = LuminareWindow(blurRadius: 20) { MainWindowContentView() }
        super.init(window: window)
        self.luminareWindow = window
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func show() {
        self.showWindow(nil)
        self.luminareWindow?.show()
        self.luminareWindow?.title = String(localized: "app.name")
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.orderFrontRegardless()
        self.window?.center()
    }
}
