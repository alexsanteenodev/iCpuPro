//
//  AppDelegate.swift
//  iCpu
//
//  Created by Oleksandr Hanhaliuk on 20.02.2023.
//
import Cocoa
import SwiftUI
import ServiceManagement
import LaunchAtLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var timer: Timer!
    var eventMonitor: EventMonitor?
    var isFarenheit: Bool = false

    private struct Constants {
        // Helper Application Bundle Identifier
        static let helperBundleID = "com.alexsanteeno.AutoLauncher"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        isFarenheit = UserDefaults.standard.bool(forKey: "isFarenheit")

        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 1400, height: 400)
        popover.behavior = .transient
        self.popover = popover
        
        // Create the status item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        let tempsensor = TempSensor()
        
        
        if let button = self.statusBarItem.button {
            let celsiusTemperature = tempsensor.getTemperature()

            button.title = self.convertTemperature(fromCelsius: celsiusTemperature)
            button.action = #selector(togglePopover(_:))
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                let celsiusTemperature = tempsensor.getTemperature()
                button.title = self.convertTemperature(fromCelsius: celsiusTemperature)
            }

        }
        
        constructMenu()

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
          if let strongSelf = self, strongSelf.popover.isShown {
            strongSelf.closePopover(sender: event)
          }
        }
        
        
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
        
        let menu = NSMenu()
        menu.addItem(self.toggleMenuItem())
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(self.tempMenuItem())
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusBarItem.menu = menu
    }
    
    
    @objc func toggleMenuItem()->NSMenuItem {
        
        let toggleMenuItem = NSMenuItem()

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 50, height: 22))
        textField.stringValue = "Launch on startup"
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = NSColor.clear

        let switchView = NSSwitch(frame: NSRect(x: 0, y: 0, width: 25, height: 22) )
        switchView.target = self
        switchView.action = #selector(toggleSwitchClicked(_:))
        switchView.state = LaunchAtLogin.isEnabled ? .on : .off
        
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

        return toggleMenuItem
    }
    
    @objc func tempMenuItem()->NSMenuItem {
        let celsiusMenuItem = NSMenuItem(title: "Celsius", action: #selector(toggleTemperatureUnit(_:)), keyEquivalent: "")
        celsiusMenuItem.tag = 0 // Tag the menu item to identify the selected unit later
        celsiusMenuItem.state =  isFarenheit ? .off : .on // Set the initial state to on, since Celsius is the default

        let fahrenheitMenuItem = NSMenuItem(title: "Fahrenheit", action: #selector(toggleTemperatureUnit(_:)), keyEquivalent: "")
        fahrenheitMenuItem.tag = 1 // Tag the menu item to identify the selected unit later
        fahrenheitMenuItem.state =  isFarenheit ? .on : .off // Set the initial state to on, since Celsius is the default

        let temperatureUnitMenu = NSMenu(title: "Temperature Unit")
        temperatureUnitMenu.addItem(celsiusMenuItem)
        temperatureUnitMenu.addItem(fahrenheitMenuItem)

        let temperatureUnitMenuItem = NSMenuItem(title: "Temperature Unit", action: nil, keyEquivalent: "")
        temperatureUnitMenuItem.submenu = temperatureUnitMenu
        return temperatureUnitMenuItem

    }
    
    
    @objc func toggleSwitchClicked(_ sender: NSMenuItem) {
        let isAuto = sender.state == .on ? true : false
        LaunchAtLogin.isEnabled = isAuto
    }
    
    @objc func convertTemperature(fromCelsius celsiusTemperature: Int)-> String {
        if(isFarenheit){
            let value =  (celsiusTemperature * 9/5) + 32
            return "\(value)°F"
        }
        return "\(celsiusTemperature)°C"
    }
    
    func convertToFahrenheit(fromCelsius celsiusTemperature: String) -> String? {
        guard let celsiusValue = Int(celsiusTemperature) else {
            return nil
        }
        let fahrenheitTemperature = (celsiusValue * 9/5) + 32
        return "\(fahrenheitTemperature)°F"
    }

    @objc func toggleTemperatureUnit(_ sender: NSMenuItem) {
        // Uncheck the other menu item
        for item in sender.menu!.items where item != sender {
            item.state = .off
        }
        sender.state = .on

        if sender.tag == 0 {
            // Celsius selected
            isFarenheit = false
        } else if sender.tag == 1 {
            // Fahrenheit selected
            isFarenheit = true
        }
        UserDefaults.standard.set(isFarenheit, forKey: "isFarenheit")
    }


    
    func closePopover(sender: Any?) {
        self.popover.performClose(sender)
        eventMonitor?.stop()
    }
}


