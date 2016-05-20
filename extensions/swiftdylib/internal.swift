//
//  File.swift
//  Hammerspoon
//
//  Created by Michael Bujol on 5/11/16.
//  Copyright © 2016 Hammerspoon. All rights reserved.
//
import Foundation
import LuaSkin

typealias LuaState = UnsafeMutablePointer<lua_State>
//protocol CFormatFunction {
//    func checkArgs(firstArg: Int32, _ args: CVarArgType...)
//}

//protocol CFormatFunction {
//    static func checkArguments(firstArg: Int32, _ args: CVarArgType...) -> Void
//}
extension LuaSkin {
    func checkArgs(firstArg: Int32, _ args: CVarArgType...) {
        self.checkArgs(firstArg, args: getVaList(args))
    }
}

// functions
func thing(L: LuaState) -> Int32 {
    let skin = LuaSkin.shared()
    let msg = skin.toNSObjectAtIndex(1) as! String
    skin.pushNSObject(msg+"!!!")
    return 1;
}

func stuff(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin:LuaSkin = LuaSkin.shared() as! LuaSkin
    skin.checkArgs(LS_TSTRING,LS_TNUMBER,LS_TBREAK)
    let msg = skin.toNSObjectAtIndex(1) as! String
//    let msg = skin.toNSObjectAtIndex(1) as! String
    skin.pushNSObject(msg+"???")
    return 1;
}

// automatically gives hs.image object using its helper
func image(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    let path: String = skin.toNSObjectAtIndex(1) as! String
    skin.pushNSObject(NSImage.init(byReferencingFile: path))
    return 1;
}

// userdata objects
class Note {
    var contents: String = ""
    var author: String = "default"
}


func new(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    let note = Note()
    let contents = skin.toNSObjectAtIndex(1) as! String
    note.contents = contents
    
    let ptr = UnsafeMutablePointer<Note>(lua_newuserdata(skin.L, sizeof(Note)))
    ptr.initialize(note)
    lua_getfield(L, -LUAI_MAXSTACK-1000, "note") // aka luaL_getmetatable(L, "note"), macros not available in swift, could be defined in LuaSkin
    lua_setmetatable(L, -2);
    
    return 1;
}

func getAuthor(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    let note = UnsafeMutablePointer<Note>(lua_touserdata(L, 1)).memory
    skin.pushNSObject(note.author)
    return 1;
}

func setAuthor(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    let note = UnsafeMutablePointer<Note>(lua_touserdata(L, 1)).memory
    let author = skin.toNSObjectAtIndex(2) as! String
    note.author = author
    lua_pushvalue(L, 1);
    return 1;
}

func tostring(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let note = UnsafeMutablePointer<Note>(lua_touserdata(L, 1)).memory
    lua_pushstring(L, String(format: "%@: (%p)\n\n%@", "note", lua_topointer(L, 1), note.contents))
    return 1;
}

//func mods() -> [luaL_Reg] {
//    return [
//        luaL_Reg(name: ("thing" as NSString).UTF8String, func: thing),
//        luaL_Reg(name: ("stuff" as NSString).UTF8String, func: stuff),
//        luaL_Reg(name: ("image" as NSString).UTF8String, func: image),
//    ]
//}


var funcs: [luaL_Reg] = ([
    ("thing", thing),
    ("stuff", stuff),
    ("image", image),
    ("new", new),
    ] as [(String, lua_CFunction)]).map { luaL_Reg(name: strdup($0.0), func: $0.1) }

var metafuncs: [luaL_Reg] = [
    luaL_Reg(name: strdup("getAuthor"), func: getAuthor),
    luaL_Reg(name: strdup("setAuthor"), func: setAuthor),
    luaL_Reg(name: strdup("__tostring"), func: tostring),
    luaL_Reg(name: nil, func: nil),
]

func luaopen_hs_swiftdylib_internal(L: UnsafeMutablePointer<lua_State>) -> Int32 {
    let skin = LuaSkin.shared()
    funcs.append(luaL_Reg(name: nil, func: nil))
    
    skin.registerLibrary(funcs, metaFunctions: nil)
    skin.registerObject("note", objectFunctions: metafuncs)
    return 1;
}
