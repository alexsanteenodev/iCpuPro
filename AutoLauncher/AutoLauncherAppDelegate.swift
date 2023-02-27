//
//  AppDelegate.swift
//  AutoLauncher
//
//  Created by Oleksandr Hanhaliuk on 22.02.2023.
//

import Cocoa

@NSApplicationMain
class AutoLauncherAppDelegate: NSObject, NSApplicationDelegate {
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == "com.alexsanteeno.iCpu"
        }
        print("Is running")
        print(isRunning)

        if !isRunning {
            var path = Bundle.main.bundlePath as NSString
            for _ in 1...4 {
                path = path.deletingLastPathComponent as NSString
            }
            print("path")
            print(path)
            NSWorkspace.shared.launchApplication(path as String)
        }
    }
    
}
