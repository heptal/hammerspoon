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



//  build/docs.json: build
// -       find . -type f \( -name '*.lua' -o -name '*.m' \) -not -path '*/sample-extensions/*' -not -path './build/*' -not -path './extensions/.build/*' -not -path './Pods/*' -exec cat {} + | scripts/docs/bin/gencomments | scripts/docs/bin/genjson > $@
// +       find . -type f \( -name '*.lua' -o -name '*.m' \) -not -path '*/sample-extensions/*' -not -path './build/*' -not -path './extensions/.build/*' -not -path './extensions/sss/*' -not -path './Pods/*' -exec cat {} + | scripts/docs/bin/gencomments | scripts/docs/bin/genjson > $@

//let skin = LuaSkin.shared()
//
//func sayHi(person: String) -> String{
//    return "HI" + person;
//}
//let t = skin.L
//skin.logInfo("sadfsadf");


//skin.pushNSObject(NSImage.init(byReferencingFile: "/Users/michael/Desktop/Untitled.png"));
//skin.pushNSObject(NSImage.init(byReferencingFile: "/Users/michael/Desktop/Untitled.png"));
//
//skin.toNSObjectAtIndex(1);
//print(skin.toNSObjectAtIndex(1));
//let str = lua_getglobal(skin.L, "string")
//print(str)
//lua_pushnumber(skin.L, 43)
//lua_setglobal(skin.L, "qq")
//lua_pushnumber(skin.L, 95)
//lua_setglobal(skin.L, "ww")
//lua_pushnumber(skin.L, 11)
//lua_setglobal(skin.L, "zz")
//
//
//lua_getglobal(skin.L, "qq")
//print(skin.toNSObjectAtIndex(-1))

//func runswift() -> Iant32 {
//    let d = lua_tointegerx(L, 1, <#T##isnum: UnsafeMutablePointer<Int32>##UnsafeMutablePointer<Int32>#>);  /* get argument */
//    lua_pushnumber(L, sin(d));  /* push result */
//    return 1;  /* number of results */
//}
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


 var moduleLib: [luaL_Reg] = [luaL_Reg(name: ("fiere" as NSString).UTF8String, func: thing)]
//    luaL_Reg(name: nil, func: nil)



 func luaopen_hs_swiftmodule_internal(L: UnsafeMutablePointer<lua_State>) -> Int32 {
     let skin = LuaSkin.shared()
    withUnsafePointer(&moduleLib) {
     skin.registerLibrary(UnsafePointer($0), metaFunctions: nil)
    }
     return 1;
 }