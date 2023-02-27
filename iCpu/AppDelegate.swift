//
//  AppDelegate.swift
//  iCpu
//
//  Created by Oleksandr Hanhaliuk on 20.02.2023.
//
import Cocoa
import SwiftUI
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var timer: Timer!
    var eventMonitor: EventMonitor?

    @State private var launchAtLogin = false {
        didSet {
            SMLoginItemSetEnabled(Constants.helperBundleID as CFString,
                                  launchAtLogin)
        }
    }
    
    private struct Constants {
        // Helper Application Bundle Identifier
        static let helperBundleID = "com.alexsanteeno.AutoLauncher"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

//        let view  = ContentView()
        
        //        let tempMiner = XRGTemperatureMiner()
//        let keys = tempMiner.locationKeys(includingUnknown: true)
////        let tempData = tempMiner.locationKeys(includingUnknown: true)
//        print(keys)
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 1400, height: 400)
        popover.behavior = .transient
        self.popover = popover
        
        // Create the status item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        let tempsensor = TempSensor()
            
        tempsensor.printValues()
        
        if let button = self.statusBarItem.button {
            button.title=tempsensor.getTemperature()
            button.action = #selector(togglePopover(_:))
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in

                button.title = tempsensor.getTemperature()
            }

        }
        
        constructMenu()

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
          if let strongSelf = self, strongSelf.popover.isShown {
            strongSelf.closePopover(sender: event)
          }
        }
        
        var path = Bundle.allBundles
        print("path")
        NSWorkspace.shared.launchApplication(path as String)
        
        NSApp.activate(ignoringOtherApps: true)
        
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
                eventMonitor?.stop()
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                eventMonitor?.start()
            }
        }
    }
    
    func constructMenu() {
        
        
        let toggleMenuItem = NSMenuItem()

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 50, height: 22))
        textField.stringValue = "Launch on startup"
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear

        let switchView = NSSwitch(frame: NSRect(x: 0, y: 0, width: 25, height: 22) )
        switchView.target = self
        switchView.action = #selector(toggleSwitchClicked(_:))
        
        
        let foundHelper = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == Constants.helperBundleID
        }

        
        switchView.state = foundHelper ? .on : .off
        
//        switchView.state = launchAtLogin==true ? .on : .off
        
        let stackView = NSStackView(views: [textField, switchView])
        stackView.orientation = .horizontal
        stackView.alignment = .centerY
        stackView.spacing = 8

        let toggleMenuItemView = NSView(frame: NSRect(x: 0, y: 0, width: 140, height: 30))
        toggleMenuItemView.addSubview(stackView)

        // Use Auto Layout to center the stack view horizontally within the menu item
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerYAnchor.constraint(equalTo: toggleMenuItemView.centerYAnchor).isActive = true
        stackView.leadingAnchor.constraint(equalTo: toggleMenuItemView.leadingAnchor, constant: 12).isActive = true
        stackView.trailingAnchor.constraint(equalTo: toggleMenuItemView.trailingAnchor, constant: -12).isActive = true

        toggleMenuItem.view = toggleMenuItemView
        toggleMenuItem.indentationLevel = 1 // set the same indentation level as the "Quit" menu item

        
        let menu = NSMenu()
        menu.addItem(toggleMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        

        statusBarItem.menu = menu
    }
    
    @objc func toggleSwitchClicked(_ sender: NSMenuItem) {
        let isAuto = sender.state == .on ? true : false
    
        print("Switch clicked: \(isAuto)")

        
        SMLoginItemSetEnabled(Constants.helperBundleID as CFString, isAuto)

    }

    
    func closePopover(sender: Any?) {
        self.popover.performClose(sender)
        eventMonitor?.stop()
    }
}


