//
//  File.swift
//  Hammerspoon
//
//  Created by Michael Bujol on 5/11/16.
//  Copyright © 2016 Hammerspoon. All rights reserved.
//
import AppKit
import Foundation
import LuaSkin

func thing(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    let msg:String = skin.toNSObjectAtIndex(1) as! String
    skin.pushNSObject(msg+"!!!")
    return 1;
}

// func untitled(L: UnsafeMutablePointer<lua_State>) -> Int32 {
//     let skin = LuaSkin.shared()
//     skin.pushNSObject(NSImage.init(byReferencingFile: "/Users/michael/Desktop/Untitled.png"))
//     return 1;
// }


 var moduleLib: [luaL_Reg] = [
    luaL_Reg(name: ("fiere" as NSString).UTF8String, func: thing),
    luaL_Reg(name: nil, func: nil)
]
//    luaL_Reg(name: nil, func: nil)



 func luaopen_hs_swiftmodule_internal(L: UnsafeMutablePointer<lua_State>) -> Int32 {
     let skin = LuaSkin.shared()
    withUnsafePointer(&moduleLib) {
     skin.registerLibrary(UnsafePointer($0), metaFunctions: nil)
    }
     return 1;
 }