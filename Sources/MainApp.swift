import Luminare
import SwiftUI

final class MainApp: NSObject, NSApplicationDelegate {
    static let shared = MainApp()
    let mainWindow = MainWindowController()
    let settingsWindow = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        mainWindow.show()
        setupMenuBar()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        if !flag {
            mainWindow.show()
        }
        return true
    }

    @objc func showSettingsWindow() {
        settingsWindow.show()
    }

    func setupMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(
            withTitle: String(
                format: String(localized: "menuBar.app.aboutApp"), String(localized: "app.name")),
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )

        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(
            withTitle: String(localized: "menuBar.app.settings"),
            action: #selector(self.showSettingsWindow),
            keyEquivalent: ","
        )

        appMenu.addItem(NSMenuItem.separator())

        // Services menu
        let servicesItem = NSMenuItem(
            title: String(localized: "menuBar.app.services"), action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        servicesItem.submenu = servicesMenu
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(servicesItem)

        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(
            withTitle: String(
                format: String(localized: "menuBar.app.hideApp"), String(localized: "app.name")),
            action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h"
        )

        appMenu.addItem(
            withTitle: String(localized: "menuBar.app.hideOthers"),
            action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h",
        ).keyEquivalentModifierMask = [.command, .option]

        appMenu.addItem(
            withTitle: String(localized: "menuBar.app.showAll"),
            action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: ""
        )

        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(
            withTitle: String(
                format: String(localized: "menuBar.app.quitApp"), String(localized: "app.name")),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        // Edit menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: String(localized: "menuBar.edit"))
        editMenuItem.submenu = editMenu

        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.undo"), action: Selector(("undo:")),
            keyEquivalent: "z")
        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.redo"), action: Selector(("redo:")),
            keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.cut"), action: #selector(NSText.cut(_:)),
            keyEquivalent: "x")
        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.copy"), action: #selector(NSText.copy(_:)),
            keyEquivalent: "c")
        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.paste"), action: #selector(NSText.paste(_:)),
            keyEquivalent: "v")
        editMenu.addItem(
            withTitle: String(localized: "menuBar.edit.paste"),
            action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)

        let helpMenu = NSMenu(title: String(localized: "menuBar.help"))
        helpMenuItem.submenu = helpMenu

        helpMenu.addItem(
            withTitle: String(
                format: String(localized: "menuBar.help.appHelp"), String(localized: "app.name")),
            action: #selector(NSApplication.showHelp(_:)),
            keyEquivalent: "?"
        )

        NSApp.mainMenu = mainMenu
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up resources if needed
    }
}
