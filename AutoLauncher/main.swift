//
//  main.swift
//  AutoLauncher
//
//  Created by Oleksandr Hanhaliuk on 22.02.2023.
//

import Cocoa

let delegate = AutoLauncherAppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
