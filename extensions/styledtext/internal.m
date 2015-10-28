// TODO: Review hs.drawing docs
// TODO: wiki writeup on hs.styledtext

#import <Cocoa/Cocoa.h>
// #import <Carbon/Carbon.h>
#import <LuaSkin/LuaSkin.h>
#import "../hammerspoon.h"

#define USERDATA_TAG        "hs.styledtext"
int refTable ;

#define get_objectFromUserdata(objType, L, idx) (objType*)*((void**)luaL_checkudata(L, idx, USERDATA_TAG))

#pragma mark - NSAttributedString Constructors

/// hs.styledtext.new(string, [attributes]) -> styledText object
/// Constructor
/// Create an `hs.styledtext` object from the string or table representation provided.  Attributes to apply to the resulting string may also be optionally provided.
///
/// Parameters:
///  * string     - a string, table, or `hs.styledtext` object to create a new `hs.styledtext` object from.
///  * attributes - an optional table containing attribute key-value pairs to apply to the entire `hs.styledtext` object to be returned.
///
/// Returns:
///  * an `hs.styledtext` object
///
/// Notes:
///  * See `hs.styledtext:asTable` for a description of the table representation of an `hs.styledtext` object
///  * See ... for a description of the attributes table format which can be provided for the optional second argument.
///
///  * Passing an `hs.styledtext` object as the first parameter without specifying an `attributes` table is the equivalent of invoking `hs.styledtext:copy`.
static int string_new(__unused lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING | LS_TNUMBER | LS_TTABLE,
                                LS_TTABLE  | LS_TOPTIONAL,
                                LS_TBREAK] ;
    NSMutableAttributedString *newString = [[[LuaSkin shared] luaObjectAtIndex:1 toClass:"NSAttributedString"] mutableCopy] ;
    if (lua_gettop(L) == 2) {
        NSDictionary *attributes = [[LuaSkin shared] luaObjectAtIndex:2 toClass:"hs.styledtext.AttributesDictionary"] ;
        NSRange theRange = NSMakeRange(0, [newString length]) ;
        if (attributes) [newString addAttributes:attributes range:theRange] ;
    }

    [[LuaSkin shared] pushNSObject:newString] ;
    return 1 ;
}

/// hs.styledtext.getStyledTextFromData(data, [type]) -> styledText object
/// Constructor
/// Converts the provided data into a styled text string.
///
/// Parameters:
///  * data          - the data, as a lua string, which contains the raw data to be converted to a styledText object
///  * type          - a string indicating the format of the contents in `data`.  Defaults to "html".  The string may be one of the following (not all formats may be fully representable as a simple string container - see also `hs.styledtext.setTextFromFile`):
///    * "text"      - Plain text document.
///    * "rtf"        - Rich text format document.
///    * "rtfd"       - Rich text format with attachments document.
///    * "simpleText" - Macintosh SimpleText document.
///    * "html"       - Hypertext Markup Language (HTML) document.
///    * "word"       - Microsoft Word document.
///    * "wordXML"    - Microsoft Word XML (WordML schema) document.
///    * "webArchive" - Web Kit WebArchive document.
///    * "openXML"    - ECMA Office Open XML text document format.
///    * "open"       - OASIS Open Document text document format.
///
/// Returns:
///  * the styledText object
///
/// Notes:
///  * See also `hs.styledtext.getStyledTextFromFile`
static int getStyledTextFromData(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING,
                                LS_TSTRING | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSString *dataType = NSHTMLTextDocumentType ;
    if (lua_type(L, 2) != LUA_TNONE) {
        NSString *requestType = [[LuaSkin shared] toNSObjectAtIndex:2] ;
        if      ([requestType isEqualToString:@"text"])       dataType = NSPlainTextDocumentType ;
        else if ([requestType isEqualToString:@"rtf"])        dataType = NSRTFTextDocumentType ;
        else if ([requestType isEqualToString:@"rtfd"])       dataType = NSRTFDTextDocumentType ;
        else if ([requestType isEqualToString:@"simpleText"]) dataType = NSMacSimpleTextDocumentType ;
        else if ([requestType isEqualToString:@"html"])       dataType = NSHTMLTextDocumentType ;
        else if ([requestType isEqualToString:@"word"])       dataType = NSDocFormatTextDocumentType ;
        else if ([requestType isEqualToString:@"wordXML"])    dataType = NSWordMLTextDocumentType ;
        else if ([requestType isEqualToString:@"openXML"])    dataType = NSOfficeOpenXMLTextDocumentType ;
        else if ([requestType isEqualToString:@"webArchive"]) dataType = NSWebArchiveTextDocumentType ;
        else if ([requestType isEqualToString:@"open"])       dataType = NSOpenDocumentTextDocumentType ;
        else return luaL_argerror(L, 2, "unrecognized encoding type") ;
    }

    id      theInput = [[LuaSkin shared] toNSObjectAtIndex:1] ;
    NSData  *dataToPresent ;

    if ([theInput isKindOfClass:[NSString class]])
        dataToPresent = [theInput dataUsingEncoding:NSUTF8StringEncoding] ;
    else
        dataToPresent = (NSData *)theInput ;

    NSError *theError ;
    NSAttributedString* newString = [[NSAttributedString alloc] initWithData:dataToPresent
                                                                     options:@{NSDocumentTypeDocumentAttribute : dataType}
                                                          documentAttributes:nil
                                                                       error:&theError];
    if (theError)
        return luaL_error(L, "setTextFromData: conversion error: %s", [[theError localizedDescription] UTF8String]) ;
    else
        [[LuaSkin shared] pushNSObject:newString] ;

    return 1 ;
}

/// hs.styledtext.getStyledTextFromFile(file, [type]) -> styledText object
/// Constructor
/// Converts the data in the specified file into a styled text string.
///
/// Parameters:
///  * file          - the path to the file to use as the source for the data to convert into a styledText object
///  * type          - a string indicating the format of the contents in `data`.  Defaults to "html".  The string may be one of the following (not all formats may be fully representable as a simple string container - see also `hs.styledtext.setTextFromFile`):
///    * "text"      - Plain text document.
///    * "rtf"        - Rich text format document.
///    * "rtfd"       - Rich text format with attachments document.
///    * "simpleText" - Macintosh SimpleText document.
///    * "html"       - Hypertext Markup Language (HTML) document.
///    * "word"       - Microsoft Word document.
///    * "wordXML"    - Microsoft Word XML (WordML schema) document.
///    * "webArchive" - Web Kit WebArchive document.
///    * "openXML"    - ECMA Office Open XML text document format.
///    * "open"       - OASIS Open Document text document format.
///
/// Returns:
///  * the styledText object
///
/// Notes:
///  * See also `hs.styledtext.getStyledTextFromData`
static int getStyledTextFromFile(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TSTRING,
                                LS_TSTRING | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSString *dataType = NSHTMLTextDocumentType ;
    if (lua_type(L, 2) != LUA_TNONE) {
        NSString *requestType = [[LuaSkin shared] toNSObjectAtIndex:2] ;
        if      ([requestType isEqualToString:@"text"])       dataType = NSPlainTextDocumentType ;
        else if ([requestType isEqualToString:@"rtf"])        dataType = NSRTFTextDocumentType ;
        else if ([requestType isEqualToString:@"rtfd"])       dataType = NSRTFDTextDocumentType ;
        else if ([requestType isEqualToString:@"simpleText"]) dataType = NSMacSimpleTextDocumentType ;
        else if ([requestType isEqualToString:@"html"])       dataType = NSHTMLTextDocumentType ;
        else if ([requestType isEqualToString:@"word"])       dataType = NSDocFormatTextDocumentType ;
        else if ([requestType isEqualToString:@"wordXML"])    dataType = NSWordMLTextDocumentType ;
        else if ([requestType isEqualToString:@"openXML"])    dataType = NSOfficeOpenXMLTextDocumentType ;
        else if ([requestType isEqualToString:@"webArchive"]) dataType = NSWebArchiveTextDocumentType ;
        else if ([requestType isEqualToString:@"open"])       dataType = NSOpenDocumentTextDocumentType ;
        else return luaL_argerror(L, 2, "unrecognized encoding type") ;
    }

    NSError *theError ;
    NSAttributedString* newString = [[NSAttributedString alloc] initWithURL:[NSURL fileURLWithPath:[[[LuaSkin shared] toNSObjectAtIndex:1] stringByExpandingTildeInPath]]
                                                                    options:@{NSDocumentTypeDocumentAttribute : dataType}
                                                         documentAttributes:nil
                                                                      error:&theError];
    if (theError)
        return luaL_error(L, "setTextFromFile: conversion error: %s", [[theError localizedDescription] UTF8String]) ;
    else
        [[LuaSkin shared] pushNSObject:newString] ;

    return 1 ;
}

#pragma mark - Font Information Functions

/// hs.styledtext.fontNames() -> table
/// Function
/// Returns the names of all installed fonts for the system.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a table containing the names of every font installed for the system.  The individual names are strings which can be used in the `hs.drawing:setTextFont(fontname)` method.
static int fontNames(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TBREAK] ;

    NSArray *fontNames = [[NSFontManager sharedFontManager] availableFonts];

    lua_newtable(L) ;
    for (unsigned long indFont=0; indFont<[fontNames count]; ++indFont)
    {
        lua_pushstring(L, [[fontNames objectAtIndex:indFont] UTF8String]) ; lua_rawseti(L, -2, (lua_Integer)indFont + 1);
    }
    return 1 ;
}

/// hs.styledtext.convertFont(fontTable, trait) -> table
/// Function
/// Returns the font which most closely matches the given font and the trait change requested.
///
/// Parameters:
///  * font - a string or a table which specifies a font.  If a string is given, the default system font size is assumed.  If a table is provided, it should contain the following keys:
///    * name - the name of the font (defaults to the system font)
///    * size - the point size of the font (defaults to the default system font size)
///  * trait - a number corresponding to a trait listed in `hs.styledtext.fontTraits` you wish to add or remove (unboldFont and unitalicFont) from the given font, or a boolean indicating whether you want a heavier version (true) or a lighter version (false).
///
/// Returns:
///  * a table containing the name and size of the font which most closely matches the specified font and the trait change requested.  If no such font is available, then the original font is returned unchanged.
static int font_convertFont(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TTABLE | LS_TSTRING, LS_TNUMBER | LS_TBOOLEAN, LS_TBREAK] ;

    NSFont *theFont = [[LuaSkin shared] luaObjectAtIndex:1 toClass:"NSFont"] ;
    if (!theFont)
        return luaL_argerror(L, 1, "does not specify a font") ;

    if (lua_type(L, 2) == LUA_TNUMBER)
        [[LuaSkin shared] pushNSObject:[[NSFontManager sharedFontManager] convertFont:theFont
                                                                          toHaveTrait:(NSFontTraitMask)luaL_checkinteger(L, 2)]] ;
    else
        [[LuaSkin shared] pushNSObject:[[NSFontManager sharedFontManager] convertWeight:(BOOL)lua_toboolean(L, 2)
                                                                                 ofFont:theFont]] ;

    return 1 ;
}

/// hs.styledtext.fontNamesWithTraits(fontTraitMask) -> table
/// Function
/// Returns the names of all installed fonts for the system with the specified traits.
///
/// Parameters:
///  * traits - a number, specifying the fontTraitMask, or a table containing traits listed in `hs.styledtext.fontTraits` which are logically 'OR'ed together to create the fontTraitMask used.
///
/// Returns:
///  * a table containing the names of every font installed for the system which matches the fontTraitMask specified.  The individual names are strings which can be used in the `hs.drawing:setTextFont(fontname)` method.
///
/// Notes:
///  * specifying 0 or an empty table will match all fonts that are neither italic nor bold.  This would be the same list as you'd get with { hs.styledtext.fontTraits.unBold, hs.styledtext.fontTraits.unItalic } as the parameter.
static int fontNamesWithTraits(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TNUMBER | LS_TTABLE | LS_TOPTIONAL, LS_TBREAK] ;

    NSFontTraitMask theTraits = 0 ;

    switch (lua_type(L, 1)) {
        case LUA_TNIL:
        case LUA_TNONE:
            break ;
        case LUA_TNUMBER:
            theTraits = (enum NSFontTraitMask)luaL_checkinteger(L, 1) ;
            break ;
        case LUA_TTABLE:
            for (lua_pushnil(L); lua_next(L, 1); lua_pop(L, 1)) {
               theTraits |= (enum NSFontTraitMask)lua_tointeger(L, -1) ;
            }
            break ;
        default: // shouldn't happen with the checkArgs above...
            return luaL_argerror(L, 1, "expected integer or table");
            break ;
    }

    NSArray *fontNames = [[NSFontManager sharedFontManager] availableFontNamesWithTraits:theTraits];

    lua_newtable(L) ;
    for (unsigned long indFont=0; indFont<[fontNames count]; ++indFont)
    {
        lua_pushstring(L, [[fontNames objectAtIndex:indFont] UTF8String]) ; lua_rawseti(L, -2, (lua_Integer)indFont + 1);
    }
    return 1 ;
}

/// hs.styledtext.fontTraits -> table
/// Constant
/// A table for containing Font Trait masks for use with `hs.styledtext.fontNamesWithTraits(...)`
///
///    boldFont                    - fonts with the 'Bold' attribute set
///    compressedFont              - fonts with the 'Compressed' attribute set
///    condensedFont               - fonts with the 'Condensed' attribute set
///    expandedFont                - fonts with the 'Expanded' attribute set
///    fixedPitchFont              - fonts with the 'FixedPitch' attribute set
///    italicFont                  - fonts with the 'Italic' attribute set
///    narrowFont                  - fonts with the 'Narrow' attribute set
///    posterFont                  - fonts with the 'Poster' attribute set
///    smallCapsFont               - fonts with the 'SmallCaps' attribute set
///    nonStandardCharacterSetFont - fonts with the 'NonStandardCharacterSet' attribute set
///    unboldFont                  - fonts that do not have the 'Bold' attribute set
///    unitalicFont                - fonts that do not have the 'Italic' attribute set
static int fontTraits(lua_State* L) {
    lua_newtable(L);
      lua_pushinteger(L, NSBoldFontMask);                    lua_setfield(L, -2, "boldFont");
      lua_pushinteger(L, NSCompressedFontMask);              lua_setfield(L, -2, "compressedFont");
      lua_pushinteger(L, NSCondensedFontMask);               lua_setfield(L, -2, "condensedFont");
      lua_pushinteger(L, NSExpandedFontMask);                lua_setfield(L, -2, "expandedFont");
      lua_pushinteger(L, NSFixedPitchFontMask);              lua_setfield(L, -2, "fixedPitchFont");
      lua_pushinteger(L, NSItalicFontMask);                  lua_setfield(L, -2, "italicFont");
      lua_pushinteger(L, NSNarrowFontMask);                  lua_setfield(L, -2, "narrowFont");
      lua_pushinteger(L, NSPosterFontMask);                  lua_setfield(L, -2, "posterFont");
      lua_pushinteger(L, NSSmallCapsFontMask);               lua_setfield(L, -2, "smallCapsFont");
      lua_pushinteger(L, NSNonStandardCharacterSetFontMask); lua_setfield(L, -2, "nonStandardCharacterSetFont");
      lua_pushinteger(L, NSUnboldFontMask);                  lua_setfield(L, -2, "unboldFont");
      lua_pushinteger(L, NSUnitalicFontMask);                lua_setfield(L, -2, "unitalicFont");
    return 1 ;
}

/// hs.styledtext.fontInfo(font) -> table
/// Function
/// Get information about the font Specified in the attributes table.
///
/// Paramters:
///  * font - a string or a table which specifies a font.  If a string is given, the default system font size is assumed.  If a table is provided, it should contain the following keys:
///    * name - the name of the font (defaults to the system font)
///    * size - the point size of the font (defaults to the default system font size)
///
/// Returns:
///  * a table containing the following keys:
///    * fontName           - The font's internally recognized name.
///    * familyName         - The font's family name.
///    * displayName        - The font’s display name is typically localized for the user’s language.
///    * fixedPitch         - A boolean value indicating whether all glyphs in the font have the same advancement.
///    * ascender           - The top y-coordinate, offset from the baseline, of the font’s longest ascender.
///    * boundingRect       - A table containing the font’s bounding rectangle, scaled to the font’s size.  This rectangle is the union of the bounding rectangles of every glyph in the font.
///    * capHeight          - The cap height of the font.
///    * descender          - The bottom y-coordinate, offset from the baseline, of the font’s longest descender.
///    * italicAngle        - The number of degrees that the font is slanted counterclockwise from the vertical. (read-only)
///    * leading            - The leading value of the font.
///    * maximumAdvancement - A table containing the maximum advance of any of the font’s glyphs.
///    * numberOfGlyphs     - The number of glyphs in the font.
///    * pointSize          - The point size of the font.
///    * underlinePosition  - The baseline offset to use when drawing underlines with the font.
///    * underlineThickness - The thickness to use when drawing underlines with the font.
///    * xHeight            - The x-height of the font.
static int fontInformation(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TTABLE | LS_TSTRING, LS_TBREAK] ;

    NSFont *theFont = [[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSFont"] ;

    lua_newtable(L) ;
      [[LuaSkin shared] pushNSObject:[theFont fontName]] ;        lua_setfield(L, -2, "fontName") ;
      [[LuaSkin shared] pushNSObject:[theFont familyName]] ;      lua_setfield(L, -2, "familyName") ;
      [[LuaSkin shared] pushNSObject:[theFont displayName]] ;     lua_setfield(L, -2, "displayName") ;
      lua_pushboolean(L, [theFont isFixedPitch]) ;                lua_setfield(L, -2, "fixedPitch") ;
      lua_pushnumber(L, [theFont ascender]) ;                     lua_setfield(L, -2, "ascender") ;
      NSRect boundingRect = [theFont boundingRectForFont] ;
      lua_newtable(L) ;
        lua_pushnumber(L, boundingRect.origin.x) ;    lua_setfield(L, -2, "x") ;
        lua_pushnumber(L, boundingRect.origin.y) ;    lua_setfield(L, -2, "y") ;
        lua_pushnumber(L, boundingRect.size.height) ; lua_setfield(L, -2, "h") ;
        lua_pushnumber(L, boundingRect.size.width) ;  lua_setfield(L, -2, "w") ;
                                                                  lua_setfield(L, -2, "boundingRect") ;
      lua_pushnumber(L, [theFont capHeight]) ;                    lua_setfield(L, -2, "capHeight") ;
      lua_pushnumber(L, [theFont descender]) ;                    lua_setfield(L, -2, "descender") ;
      lua_pushnumber(L, [theFont italicAngle]) ;                  lua_setfield(L, -2, "italicAngle") ;
      lua_pushnumber(L, [theFont leading]) ;                      lua_setfield(L, -2, "leading") ;
      NSSize maxAdvance = [theFont maximumAdvancement] ;
      lua_newtable(L) ;
        lua_pushnumber(L, maxAdvance.height) ;  lua_setfield(L, -2, "h") ;
        lua_pushnumber(L, maxAdvance.width) ;   lua_setfield(L, -2, "w") ;
                                                                  lua_setfield(L, -2, "maximumAdvancement") ;
      lua_pushinteger(L, (lua_Integer)[theFont numberOfGlyphs]) ; lua_setfield(L, -2, "numberOfGlyphs") ;
      lua_pushnumber(L, [theFont pointSize]) ;                    lua_setfield(L, -2, "pointSize") ;
      lua_pushnumber(L, [theFont underlinePosition]) ;            lua_setfield(L, -2, "underlinePosition") ;
      lua_pushnumber(L, [theFont underlineThickness]) ;           lua_setfield(L, -2, "underlineThickness") ;
      lua_pushnumber(L, [theFont xHeight]) ;                      lua_setfield(L, -2, "xHeight") ;
    return 1 ;
}

/// hs.styledtext.lineStyles
/// Constant
/// A table of styles which apply to the line for underlining or strike-through.
///
/// Notes:
///  * Valid line style keys are as follows:
///    * none   - no line style
///    * single - a single thin line
///    * thick  - a single thick line (usually double the single line's thickness)
///    * double - double think lines
///
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs.styledtext.lineStyles
///    * hs.styledtext.linePatterns
///    * hs.styledtext.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs.styledtext.lineStyles.single | hs.styledtext.linePatterns.dash | hs.styledtext.lineAppliesToWord
static int defineLineStyles(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, NSUnderlineStyleNone) ;    lua_setfield(L, -2, "none") ;
      lua_pushinteger(L, NSUnderlineStyleSingle) ;  lua_setfield(L, -2, "single") ;
      lua_pushinteger(L, NSUnderlineStyleThick) ;   lua_setfield(L, -2, "thick") ;
      lua_pushinteger(L, NSUnderlineStyleDouble) ;  lua_setfield(L, -2, "double") ;
    return 1 ;
}

/// hs.styledtext.linePatterns
/// Constant
/// A table of patterns which apply to the line for underlining or strike-through.
///
/// Notes:
///  * Valid line pattern keys are as follows:
///    * solid      - a solid line
///    * dot        - a dotted line
///    * dash       - a dashed line
///    * dashDot    - a pattern of a dash followed by a dot
///    * dashDotDot - a pattern of a dash followed by two dots
///
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs.styledtext.lineStyles
///    * hs.styledtext.linePatterns
///    * hs.styledtext.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs.styledtext.lineStyles.single | hs.styledtext.linePatterns.dash | hs.styledtext.lineAppliesToWord
static int defineLinePatterns(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, NSUnderlinePatternSolid) ;       lua_setfield(L, -2, "solid") ;
      lua_pushinteger(L, NSUnderlinePatternDot) ;         lua_setfield(L, -2, "dot") ;
      lua_pushinteger(L, NSUnderlinePatternDash) ;        lua_setfield(L, -2, "dash") ;
      lua_pushinteger(L, NSUnderlinePatternDashDot) ;     lua_setfield(L, -2, "dashDot") ;
      lua_pushinteger(L, NSUnderlinePatternDashDotDot) ;  lua_setfield(L, -2, "dashDotDot") ;
    return 1 ;
}

/// hs.styledtext.lineAppliesTo
/// Constant
/// A table of values indicating how the line for underlining or strike-through are applied to the text.
///
/// Notes:
///  * Valid keys are as follows:
///    * line - the underline or strike-through is applied to an entire line of text
///    * word - the underline or strike-through is only applied to words and not the spaces in a line of text
///
///  * When specifying a line type for underlining or strike-through, you can combine one entry from each of the following tables:
///    * hs.styledtext.lineStyles
///    * hs.styledtext.linePatterns
///    * hs.styledtext.lineAppliesTo
///  * The entries chosen should be combined with the `or` operator to provide a single value. for example:
///    * hs.styledtext.lineStyles.single | hs.styledtext.linePatterns.dash | hs.styledtext.lineAppliesToWord
static int defineLineAppliesTo(lua_State *L) {
    lua_newtable(L) ;
      lua_pushinteger(L, 0) ;                                  lua_setfield(L, -2, "line") ;
      lua_pushinteger(L, (lua_Integer)NSUnderlineByWordMask) ; lua_setfield(L, -2, "word") ; // deprecated in 10.11 with Xcode 7.1 update
//       lua_pushinteger(L, (lua_Integer)NSUnderlineByWord) ;     lua_setfield(L, -2, "word") ;
    return 1 ;
}

#pragma mark - Methods unique to hs.styledtext objects

/// hs.styledtext:copy(styledText) -> styledText object
/// Method
/// Create a copy of the `hs.styledtext` object.
///
/// Parameters:
///  * styledText - an `hs.styledtext` object
///
/// Returns:
///  * a copy of the styledText object
static int string_copy(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    [[LuaSkin shared] pushNSObject:[theString copy]] ;
    return 1 ;
}

/// hs.styledtext:isIdentical(styledText) -> boolean
/// Method
/// Determine if the `styledText` object is identical to the one specified.
///
/// Parameters:
///  * styledText - an `hs.styledtext` object
///
/// Returns:
///  * a boolean value indicating whether or not the styled text objects are identical, both in text content and attributes specified.
///
/// Notes:
///  * comparing two `hs.styledtext` objects with the `==` operator only compares whether or not the string values are identical.  This method also compares their attributes.
static int string_identical(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSAttributedString *theString1 = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    NSAttributedString *theString2 = get_objectFromUserdata(__bridge NSAttributedString, L, 2) ;
    lua_pushboolean(L, [theString1 isEqualToAttributedString:theString2]) ;
    return 1 ;
}

/// hs.styledtext:asTable([starts], [ends]) -> table
/// Method
/// Returns the table representation of the `hs.styledtext` object or its specified substring.
///
/// Parameters:
///  * starts - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the substring to return the table for.  Defaults to 1, the beginning of the objects text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends   - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to return the table for.  Defaults to the length of the objects text.  If this number is negative, it is counted backwards from the end of the object's text.
///
/// Returns:
///  * a table representing the `hs.styledtext` object.  The table will be an array with the following structure:
///    * index 1             - the text of the `hs.styledtext` object as a Lua String.
///    * index 2+            - a table with the following keys:
///      * starts            - the index position in the string where this list of attributes is first applied
///      * ends              - the index position in the string where the application of this list of attributes ends
///      * attributes        - a table of attribute key-value pairs that apply to the string between the positions of `starts` and `ends`
///      * unsupportedFields - this field only exists, and will be set to `true` when an attribute that was included in the attributes table that this module cannot modify.  A best effort will be made to render the attributes assigned value in the attributes table, but modifying the attribute and re-applying it with `hs.styledtext:setStyle` will be silently ignored.
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function.
///  * The attribute which contains an attachment (image) for a converted RTFD or other document is known to set the `unsupportedFields` flag.
///
///  * See ... for a description of the attributes table format
static int string_totable(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;

// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = lua_isnoneornil(L, 2) ?   1 : luaL_checkinteger(L, 2) ;
    lua_Integer j = lua_isnoneornil(L, 3) ? len : luaL_checkinteger(L, 3) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)   i = len + 1 + i ; // if i is negative, then it is indexed from the end of the string
    if (j < 0)   j = len + 1 + j ; // if j is negative, then it is indexed from the end of the string
    if (i < 1)   i = 1 ;           // if i is still < 1, then silently coerce to beginning of string
    if (j > len) j = len ;         // if j is > length,  then silently coerce to string length (end)
    lua_newtable(L) ;
    if (i > j) {
        lua_pushstring(L, "") ;
        lua_rawseti(L, -2, 1) ;
    } else {
// finally convert to Objective-C's practice of 0 indexing and j as length, not index
        NSRange theRange = NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;
        lua_pushstring(L, [[[theString attributedSubstringFromRange:theRange] string] UTF8String]) ;
        lua_rawseti(L, -2, 1) ;

        if (theString) {
            NSRange            limitRange = theRange ;
            NSRange            effectiveRange = NSMakeRange(0, 0);

            while (limitRange.length > 0) {
                lua_newtable(L) ;
                  NSDictionary *attributes = [theString attributesAtIndex:limitRange.location
                                                    longestEffectiveRange:&effectiveRange
                                                                  inRange:limitRange] ;
                  lua_pushinteger(L, (lua_Integer)(effectiveRange.location + 1)) ; lua_setfield(L, -2, "starts") ;
                  lua_pushinteger(L, (lua_Integer)NSMaxRange(effectiveRange)) ;    lua_setfield(L, -2, "ends") ;

// NSLog(@"From %lu with a length of %lu", effectiveRange.location, effectiveRange.length) ;
                  BOOL containsUnsupportedFields = NO ;
                  lua_newtable(L) ;
                    for (id key in attributes) {
// NSLog(@"NAS: %@ = %@", key, [attributes objectForKey:key]) ;
                        [[LuaSkin shared] pushNSObject:[attributes objectForKey:key]] ;
                        if ([(NSString *)key isEqualToString:NSFontAttributeName])                    { lua_setfield(L, -2, "font") ; }
                        else if ([(NSString *)key isEqualToString:NSUnderlineStyleAttributeName])     { lua_setfield(L, -2, "underlineStyle") ; }
                        else if ([(NSString *)key isEqualToString:NSSuperscriptAttributeName])        { lua_setfield(L, -2, "superscript") ; }
                        else if ([(NSString *)key isEqualToString:NSLigatureAttributeName])           { lua_setfield(L, -2, "ligature") ; }
                        else if ([(NSString *)key isEqualToString:NSBaselineOffsetAttributeName])     { lua_setfield(L, -2, "baselineOffset") ; }
                        else if ([(NSString *)key isEqualToString:NSKernAttributeName])               { lua_setfield(L, -2, "kerning") ; }
                        else if ([(NSString *)key isEqualToString:NSStrokeWidthAttributeName])        { lua_setfield(L, -2, "strokeWidth") ; }
                        else if ([(NSString *)key isEqualToString:NSStrikethroughStyleAttributeName]) { lua_setfield(L, -2, "strikethroughStyle") ; }
                        else if ([(NSString *)key isEqualToString:NSObliquenessAttributeName])        { lua_setfield(L, -2, "obliqueness") ; }
                        else if ([(NSString *)key isEqualToString:NSExpansionAttributeName])          { lua_setfield(L, -2, "expansion") ; }
                        else if ([(NSString *)key isEqualToString:NSLinkAttributeName])               { lua_setfield(L, -2, "link") ; }
                        else if ([(NSString *)key isEqualToString:NSToolTipAttributeName])            { lua_setfield(L, -2, "tooltip") ; }
                        else if ([(NSString *)key isEqualToString:NSForegroundColorAttributeName])    { lua_setfield(L, -2, "color") ; }
                        else if ([(NSString *)key isEqualToString:NSBackgroundColorAttributeName])    { lua_setfield(L, -2, "backgroundColor") ; }
                        else if ([(NSString *)key isEqualToString:NSStrokeColorAttributeName])        { lua_setfield(L, -2, "strokeColor") ; }
                        else if ([(NSString *)key isEqualToString:NSUnderlineColorAttributeName])     { lua_setfield(L, -2, "underlineColor") ; }
                        else if ([(NSString *)key isEqualToString:NSStrikethroughColorAttributeName]) { lua_setfield(L, -2, "strikethroughColor") ; }
                        else if ([(NSString *)key isEqualToString:NSShadowAttributeName])             { lua_setfield(L, -2, "shadow") ; }
                        else if ([(NSString *)key isEqualToString:NSParagraphStyleAttributeName])     { lua_setfield(L, -2, "paragraphStyle") ; }
                        else { containsUnsupportedFields = YES ; lua_setfield(L, -2, [(NSString *)key UTF8String]) ; }
                    }
                  lua_setfield(L, -2, "attributes") ;
                  if (containsUnsupportedFields) { lua_pushboolean(L, containsUnsupportedFields) ; lua_setfield(L, -2, "unsupportedFields") ; }
                lua_rawseti(L, -2, luaL_len(L, -2) + 1) ;
                limitRange = NSMakeRange(NSMaxRange(effectiveRange), NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
            }
        }
    }
    return 1 ;
}

/// hs.styledtext:asString([starts], [ends]) -> string
/// Method
/// Returns the text of the `hs.styledtext` object as a Lua String
///
/// Parameters:
///  * starts - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the substring to return the string for.  Defaults to 1, the beginning of the objects text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends   - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to return the string for.  Defaults to the length of the objects text.  If this number is negative, it is counted backwards from the end of the object's text.
///
/// Returns:
///  * a string containing the text of the `hs.styledtext` object specified
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function.
static int string_tostring(lua_State* L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;

// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = lua_isnoneornil(L, 2) ?   1 : luaL_checkinteger(L, 2) ;
    lua_Integer j = lua_isnoneornil(L, 3) ? len : luaL_checkinteger(L, 3) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)   i = len + 1 + i ; // if i is negative, then it is indexed from the end of the string
    if (j < 0)   j = len + 1 + j ; // if j is negative, then it is indexed from the end of the string
    if (i < 1)   i = 1 ;           // if i is still < 1, then silently coerce to beginning of string
    if (j > len) j = len ;         // if j is > length,  then silently coerce to string length (end)
    if (i > j)
        lua_pushstring(L, "") ;
    else {
// finally convert to Objective-C's practice of 0 indexing and j as length, not index
        NSRange theRange = NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;
        lua_pushstring(L, [[[theString attributedSubstringFromRange:theRange] string] UTF8String]) ;
    }

    return 1 ;
}

/// hs.styledtext:setStyle(attributes, [starts], [ends], [clear]) -> styledText object
/// Method
/// Return a copy of the `hs.styledtext` object containing the changes to its attributes specified in the `attributes` table.
///
/// Parameters:
///  * attributes - a table of attribute key-value pairs to apply to the object between the positions of `starts` and `ends`
///  * starts     - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the substring to set attributes for.  Defaults to 1, the beginning of the objects text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends       - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to set attributes for.  Defaults to the length of the objects text.  If this number is negative, it is counted backwards from the end of the object's text.
///  * clear      - an optional boolean indicating whether or not the attributes specified should completely replace the existing attributes (true) or be added to/modify them (false).  Defaults to false.
///
/// Returns:
///  * a copy of the `hs.styledtext` object with the attributes specified applied to the given range of the original object.
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function except that `starts` must refer to an index preceding or equal to `ends`, even after negative and out-of-bounds indices are adjusted for.
///
///  * See ... for a description of the attributes table format
static int string_setStyleForRange(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TTABLE,
                                LS_TNUMBER  | LS_TOPTIONAL,
                                LS_TNUMBER  | LS_TOPTIONAL,
                                LS_TBOOLEAN | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString  = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    NSDictionary       *attributes = [[LuaSkin shared] luaObjectAtIndex:2 toClass:"hs.styledtext.AttributesDictionary"] ;
    BOOL replaceAttributes = lua_isboolean(L, lua_gettop(L)) ? (BOOL)lua_toboolean(L, lua_gettop(L)) : NO ;

// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = lua_isnoneornil(L, 3) ?   1 : luaL_checkinteger(L, 3) ;
    lua_Integer j = lua_isnoneornil(L, 4) ? len : luaL_checkinteger(L, 4) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)   i = len + 1 + i ; // if i is negative, then it is indexed from the end of the string
    if (j < 0)   j = len + 1 + j ; // if j is negative, then it is indexed from the end of the string
    if (i < 1)   i = 1 ;           // if i is still < 1, then silently coerce to beginning of string
    if (j > len) j = len ;         // if j is > length,  then silently coerce to string length (end)
    if (i > j)
        return luaL_argerror(L, 3, "starts index must be < ends index") ;

// finally convert to Objective-C's practice of 0 indexing and j as length, not index
    NSRange theRange = NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;

    NSMutableAttributedString *newString = [theString mutableCopy] ;
    if (attributes) {
        if (replaceAttributes)
            [newString setAttributes:attributes range:theRange] ;
        else
            [newString addAttributes:attributes range:theRange] ;
    }

    [[LuaSkin shared] pushNSObject:newString] ;
    return 1 ;
}

/// hs.styledtext:removeStyle(attributes, [starts], [ends]) -> styledText object
/// Method
/// Return a copy of the `hs.styledtext` object containing the changes to its attributes specified in the `attributes` table.
///
/// Parameters:
///  * attributes - an array of attribute labels to remove (set to `nil`) from the `hs.styledtext` object.
///  * starts     - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the substring to remove attributes for.  Defaults to 1, the beginning of the object's text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends       - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to remove attributes for.  Defaults to the length of the object's text.  If this number is negative, it is counted backwards from the end of the object's text.
///
/// Returns:
///  * a copy of the `hs.styledtext` object with the attributes specified removed from the given range of the original object.
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function.
///
///  * See ... for a list of officially recognized attribute label names.
///  * The officially recognized attribute labels were chosen for brevity or for consistency with conventions used in Hammerspoon's other modules.  If you know the Objective-C name for an attribute, you can list it instead of an officially recognized label, allowing the removal of attributes which this module cannot manipulate in other ways.
static int string_removeStyleForRange(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TTABLE  | LS_TOPTIONAL,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TNUMBER | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString  = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    NSMutableArray *attributes = [[NSMutableArray alloc] init] ;
    int nextArg = 2 ;
    if (lua_type(L, 2) == LUA_TTABLE) {
        lua_Integer i = 1 ;
        while (lua_rawgeti(L, 2, i) != LUA_TNIL) {
            NSString *value = [NSString stringWithUTF8String:lua_tostring(L, -1)] ;
            if ([value isEqualToString:@"font"])               [attributes addObject:NSFontAttributeName] ;
            else if ([value isEqualToString:@"paragraphStyle"])     [attributes addObject:NSParagraphStyleAttributeName] ;
            else if ([value isEqualToString:@"underlineStyle"])     [attributes addObject:NSUnderlineStyleAttributeName] ;
            else if ([value isEqualToString:@"superscript"])        [attributes addObject:NSSuperscriptAttributeName] ;
            else if ([value isEqualToString:@"ligature"])           [attributes addObject:NSLigatureAttributeName] ;
            else if ([value isEqualToString:@"strikethroughStyle"]) [attributes addObject:NSStrikethroughStyleAttributeName] ;
            else if ([value isEqualToString:@"baselineOffset"])     [attributes addObject:NSBaselineOffsetAttributeName] ;
            else if ([value isEqualToString:@"kerning"])            [attributes addObject:NSKernAttributeName] ;
            else if ([value isEqualToString:@"strokeWidth"])        [attributes addObject:NSStrokeWidthAttributeName] ;
            else if ([value isEqualToString:@"obliqueness"])        [attributes addObject:NSObliquenessAttributeName] ;
            else if ([value isEqualToString:@"expansion"])          [attributes addObject:NSExpansionAttributeName] ;
            else if ([value isEqualToString:@"color"])              [attributes addObject:NSForegroundColorAttributeName] ;
            else if ([value isEqualToString:@"backgroundColor"])    [attributes addObject:NSBackgroundColorAttributeName] ;
            else if ([value isEqualToString:@"strokeColor"])        [attributes addObject:NSStrokeColorAttributeName] ;
            else if ([value isEqualToString:@"underlineColor"])     [attributes addObject:NSUnderlineColorAttributeName] ;
            else if ([value isEqualToString:@"strikethroughColor"]) [attributes addObject:NSStrikethroughColorAttributeName] ;
            else if ([value isEqualToString:@"shadow"])             [attributes addObject:NSShadowAttributeName] ;
// if you know the actual Obj-C name, this will allow removal of attributes the module doesn't know about
            else [attributes addObject:value] ;
            lua_pop(L, 1) ;
            i++ ;
        }
        lua_pop(L, 1) ; // the terminating nil
        nextArg++ ;
    }

// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = lua_isnoneornil(L, nextArg) ?       1 : luaL_checkinteger(L, nextArg) ;
    lua_Integer j = lua_isnoneornil(L, nextArg + 1) ? len : luaL_checkinteger(L, nextArg + 1) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)   i = len + 1 + i ; // if i is negative, then it is indexed from the end of the string
    if (j < 0)   j = len + 1 + j ; // if j is negative, then it is indexed from the end of the string
    if (i < 1)   i = 1 ;           // if i is still < 1, then silently coerce to beginning of string
    if (j > len) j = len ;         // if j is > length,  then silently coerce to string length (end)
    if (i > j)
        return luaL_argerror(L, 3, "starts index must be < ends index") ;

// finally convert to Objective-C's practice of 0 indexing and j as length, not index
    NSRange theRange = NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;

    NSMutableAttributedString *newString = [theString mutableCopy] ;

    for (NSString *key in attributes)  [newString removeAttribute:key range:theRange] ;

    [[LuaSkin shared] pushNSObject:newString] ;
    return 1 ;
}

/// hs.styledtext:replaceSubstring(string, [starts], [ends], [clear]) -> styledText object
/// Method
/// Return a copy of the `hs.styledtext` object containing the changes to its attributes specified in the `attributes` table.
///
/// Parameters:
///  * string     - a string, table, or `hs.styledtext` object to insert or replace the substring specified.
///  * starts     - an optional index position within the text of the `hs.styledtext` object indicating the beginning of the destination for the specified string.  Defaults to 1, the beginning of the objects text.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends       - an optional index position within the text of the `hs.styledtext` object indicating the end of destination for the specified string.  Defaults to the length of the objects text.  If this number is negative, it is counted backwards from the end of the object's text.  If this number is 0, then the substring is inserted at the index specified by `starts` rather than replacing it.
///  * clear      - an optional boolean indicating whether or not the attributes of the new string should be included (true) or whether the new substring should inherit the attributes of the first character replaced (false).  Defaults to false if `string` is a Lua String or number; otherwise defaults to true.
///
/// Returns:
///  * a copy of the `hs.styledtext` object with the specified substring replacement to the original object.
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function except that `starts` must refer to an index preceding or equal to `ends`, even after negative and out-of-bounds indices are adjusted for.
///  * If `starts` and `ends` are equal, the substring is inserted at the specified location.
///
///  * See ... for a description of the attributes table format
static int string_replaceSubstringForRange(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TANY,
                                LS_TNUMBER  | LS_TOPTIONAL,
                                LS_TNUMBER  | LS_TOPTIONAL,
                                LS_TBOOLEAN | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString  = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    BOOL withAttributes = ((lua_type(L, 2) == LUA_TSTRING) || (lua_type(L, 2) == LUA_TNUMBER)) ?  NO : YES ;
    if (lua_isboolean(L, lua_gettop(L))) withAttributes = (BOOL)lua_toboolean(L, lua_gettop(L)) ;

    NSAttributedString *subString = [[LuaSkin shared] luaObjectAtIndex:2 toClass:"NSAttributedString"] ;

// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = lua_isnumber(L, 3) ? luaL_checkinteger(L, 3) : 1 ;
    lua_Integer j = lua_isnumber(L, 4) ? luaL_checkinteger(L, 4) : len ;
    BOOL insert = (j == 0) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)              i = len + 1 + i ;  // if i is negative, then it is indexed from the end of the string
    if (!insert && (j < 0)) j = len + 1 + j ;  // if j is negative, then it is indexed from the end of the string
    if (i < 1)              i = 1 ;            // if i is still < 1, then silently coerce to beginning of string
    if (j > len)            j = len ;          // if j is > length,  then silently coerce to string length (end)
// because we allow inserting, the normal check of i > j will be skipped... silently correct i in that case...
    if (insert && (i > len + 1)) i = len + 1 ; // if i> length, then silently coerce to string length (end)
    if (!insert && (i > j))
        return luaL_argerror(L, 3, "starts index must be < ends index") ;

// finally convert to Objective-C's practice of 0 indexing and j as length, not index
    NSRange theRange = insert ? NSMakeRange((NSUInteger)(i - 1), 0) : NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;

    NSMutableAttributedString *newString = [theString mutableCopy] ;

    if (withAttributes)
// will this copy keep Lua from thinking a userdata has been changed after __gc, thus causing a crash?  If it does, I don't know why...
        [newString replaceCharactersInRange:theRange withAttributedString:[subString copy]] ;
    else
        [newString replaceCharactersInRange:theRange withString:[subString string]] ;

    [[LuaSkin shared] pushNSObject:newString] ;

    return 1 ;
}

/// hs.styledtext:convert([type]) -> string
/// Method
/// Converts the styledtext object into the data format specified.
///
/// Parameters:
///  * type          - a string indicating the format to convert the styletext object into.  Defaults to "html".  The string may be one of the following:
///    * "text"      - Plain text document.
///    * "rtf"        - Rich text format document.
///    * "rtfd"       - Rich text format with attachments document.
///    * "html"       - Hypertext Markup Language (HTML) document.
///    * "word"       - Microsoft Word document.
///    * "wordXML"    - Microsoft Word XML (WordML schema) document.
///    * "webArchive" - Web Kit WebArchive document.
///    * "openXML"    - ECMA Office Open XML text document format.
///    * "open"       - OASIS Open Document text document format.
///
/// Returns:
///  * a string containing the converted data
static int string_convert(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TSTRING | LS_TOPTIONAL,
                                LS_TBREAK] ;

    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;

    NSString *dataType = NSHTMLTextDocumentType ;
    if (lua_type(L, 2) != LUA_TNONE) {
        NSString *requestType = [[LuaSkin shared] toNSObjectAtIndex:2] ;
        if      ([requestType isEqualToString:@"text"])       dataType = NSPlainTextDocumentType ;
        else if ([requestType isEqualToString:@"rtf"])        dataType = NSRTFTextDocumentType ;
        else if ([requestType isEqualToString:@"rtfd"])       dataType = NSRTFDTextDocumentType ;
// The MacSimpleText format requires a resource fork... returns "Cocoa error 66062" if we attempt it here.
// I don't have any examples to test with reading one in, so I'll leave it in the constructor methods for now...
//        else if ([requestType isEqualToString:@"simpleText"]) dataType = NSMacSimpleTextDocumentType ;
        else if ([requestType isEqualToString:@"html"])       dataType = NSHTMLTextDocumentType ;
        else if ([requestType isEqualToString:@"word"])       dataType = NSDocFormatTextDocumentType ;
        else if ([requestType isEqualToString:@"wordXML"])    dataType = NSWordMLTextDocumentType ;
        else if ([requestType isEqualToString:@"openXML"])    dataType = NSOfficeOpenXMLTextDocumentType ;
        else if ([requestType isEqualToString:@"webArchive"]) dataType = NSWebArchiveTextDocumentType ;
        else if ([requestType isEqualToString:@"open"])       dataType = NSOpenDocumentTextDocumentType ;
        else return luaL_argerror(L, 2, "unrecognized encoding type") ;
    }

    NSError *theError ;
    NSData *theResult = [theString dataFromRange:NSMakeRange(0, [theString length])
                              documentAttributes:@{NSDocumentTypeDocumentAttribute : dataType}
                                           error:&theError] ;

    if (theError)
        return luaL_error(L, "convert: conversion error: %s", [[theError localizedDescription] UTF8String]) ;
    else
        [[LuaSkin shared] pushNSObject:theResult] ;

    return 1 ;
}

#pragma mark - Methods to mimic Lua's string type as closely as possible

/// hs.styledtext:len() -> integer
/// Method
/// Returns the length of the text of the `hs.styledtext` object.  Mimics the Lua `string.len` function.
///
/// Parameters:
///  * None
///
/// Returns:
///  * an integer which is the length of the text of the `hs.styledtext` object.
static int string_len(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    lua_pushinteger(L, (lua_Integer)[theString length]) ;
    return 1 ;
}

/// hs.styledtext:upper() -> styledText object
/// Method
/// Returns a copy of the `hs.styledtext` object with all alpha characters converted to upper case.  Mimics the Lua `string.upper` function.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a copy of the `hs.styledtext` object with all alpha characters converted to upper case
static int string_upper(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    NSMutableAttributedString *newString = [theString mutableCopy] ;
    if ([newString length] > 0) {
        NSRange stringRange = NSMakeRange(0, [theString length]) ;
        [newString replaceCharactersInRange:stringRange withString:[[theString string] uppercaseString]] ;
        [[LuaSkin shared] pushNSObject:newString] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs.styledtext:lower() -> styledText object
/// Method
/// Returns a copy of the `hs.styledtext` object with all alpha characters converted to lower case.  Mimics the Lua `string.lower` function.
///
/// Parameters:
///  * None
///
/// Returns:
///  * a copy of the `hs.styledtext` object with all alpha characters converted to lower case
static int string_lower(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG, LS_TBREAK] ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    NSMutableAttributedString *newString = [theString mutableCopy] ;
    if ([newString length] > 0) {
        NSRange stringRange = NSMakeRange(0, [theString length]) ;
        [newString replaceCharactersInRange:stringRange withString:[[theString string] lowercaseString]] ;
        [[LuaSkin shared] pushNSObject:newString] ;
    } else {
        lua_pushnil(L) ;
    }
    return 1 ;
}

/// hs.styledtext:sub(starts, [ends]) -> styledText object
/// Method
/// Returns a substring, including the style attributes, specified by the given indicies from the `hs.styledtext` object.  Mimics the Lua `string.sub` function.
///
/// Parameters:
///  * starts - the index position within the text of the `hs.styledtext` object indicating the beginning of the substring to return.  If this number is negative, it is counted backwards from the end of the object's text (i.e. -1 would be the last character position).
///  * ends   - an optional index position within the text of the `hs.styledtext` object indicating the end of the substring to return.  Defaults to the length of the objects text.  If this number is negative, it is counted backwards from the end of the object's text.
///
/// Returns:
///  * an `hs.styledtext` object containing the specified substring.
///
/// Notes:
///  * `starts` and `ends` follow the conventions of `i` and `j` for Lua's `string.sub` function.
static int string_sub(lua_State *L) {
    [[LuaSkin shared] checkArgs:LS_TUSERDATA, USERDATA_TAG,
                                LS_TNUMBER,
                                LS_TNUMBER | LS_TOPTIONAL, LS_TBREAK] ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
// cleaner with one cast, rather than for all references to it...
    lua_Integer len = (lua_Integer)[theString length] ;

    lua_Integer i = luaL_checkinteger(L, 2) ;
    lua_Integer j = len ; // in lua, j is an index, but length happens to be the lua index of the last char
    if (lua_type(L, 3) == LUA_TNUMBER) j = luaL_checkinteger(L, 3) ;

// keep lua indexing and method of specifying range (index starts at 1, j is also an index, not the length
    if (i < 0)   i = len + 1 + i ; // if i is negative, then it is indexed from the end of the string
    if (j < 0)   j = len + 1 + j ; // if j is negative, then it is indexed from the end of the string
    if (i < 1)   i = 1 ;           // if i is still < 1, then silently coerce to beginning of string
    if (j > len) j = len ;         // if j is > length,  then silently coerce to string length (end)
    if (i > j)
        [[LuaSkin shared] pushNSObject:[[NSAttributedString alloc] initWithString:@""]] ;
    else {
// finally convert to Objective-C's practice of 0 indexing and j as length, not index
        NSRange theRange = NSMakeRange((NSUInteger)(i - 1), (NSUInteger)(j - (i - 1))) ;
        [[LuaSkin shared] pushNSObject:[theString attributedSubstringFromRange:theRange]] ;
    }
    return 1 ;
}

#pragma mark - LuaSkin conversion helpers

// NSAttributedString *theString = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"NSAttributedString"] ;
// C-API
// Create an NSAttributedString from the userdata, table, or string/number at the specified index in the Lua Stack.
//
// If the item on the stack is a string, this returns an NSAttributedString with no attributes.
// If the item is a userdata object, it must be an "hs.styledtext" userdata object.
// If the item is a table, the table should have the following layout:
// {
//   "full text of the string",
//   {
//     starts     = index indicating where in the string this attribute definition starts,
//     ends       = index indicating where in the string this attribute definition ends,
//     attributes = {... attribute definition as described elsewhere ...}
//   },
//   ... additional attribute definitions as necessary for this string ...
// }
static id lua_toNSAttributedString(lua_State* L, int idx) {
    NSMutableAttributedString *theString ;
    if ((lua_type(L, idx) == LUA_TSTRING) || (lua_type(L, idx) == LUA_TNUMBER)) {
        theString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:lua_tostring(L, idx)]] ;
    } else if (lua_type(L, idx == LUA_TUSERDATA)) {
        theString = [get_objectFromUserdata(__bridge NSAttributedString, L, idx) mutableCopy];
    } else {
        luaL_checktype(L, idx, LUA_TTABLE) ;

        lua_rawgeti(L, idx, 1) ;
        theString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:lua_tostring(L, -1)]] ;
        lua_pop(L, 1) ; // the string on the stack

        lua_Integer locInTable = 2 ;
        while (lua_rawgeti(L, idx, locInTable) != LUA_TNIL) {
            luaL_checktype(L, -1, LUA_TTABLE) ;

            NSUInteger loc = (lua_getfield(L, -1, "starts") == LUA_TNUMBER)  ? ((NSUInteger)luaL_checkinteger(L, -1) - 1) : 0 ;
            lua_pop(L, 1) ;
            NSUInteger len = ((lua_getfield(L, -1, "ends") == LUA_TNUMBER) ? ((NSUInteger)luaL_checkinteger(L, -1)) : ([theString length])) - loc ;
            lua_pop(L, 1) ;

            lua_getfield(L, -1, "attributes") ;
            @try {
                [theString setAttributes:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"hs.styledtext.AttributesDictionary"]
                                   range:NSMakeRange(loc, len)] ;
            }
            @catch (NSException *theException) {
                luaL_error(L, "error creating NSAttributedString from table: %s", [[theException name] UTF8String]) ;
                return nil ;
            }
            locInTable++ ;
            lua_pop(L, 1) ;
        }
        lua_pop(L, 1); // the loop terminating nil
    }

    return theString ;
}

// NSDictionary *attrDict = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"hs.styledtext.AttributesDictionary"] ;
// C-API
// A helper function for the "Pseudo class" AttributesDictionary.
//
// This is a Pseudo class because it is in reality just an NSDictionary; however, the key names used in the
// lua version of the table differ from the keys needed for use with NSAttributedString, so a straight
// NSDictionary conversion would require going through it again anyways.  This is used in multiple places
// within this module but isn't expected to have much use outside of it; however leveraging the lua object
// conversion support in LuaSkin makes the code cleaner than it might otherwise be.
static id table_toAttributesDictionary(lua_State* L, int idx) {
    luaL_checktype(L, idx, LUA_TTABLE) ;
    NSMutableDictionary *theAttributes = [[NSMutableDictionary alloc] init] ;

    if (lua_getfield(L, idx, "font") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSFont"] forKey:NSFontAttributeName] ;
    else if (lua_type(L, -1) == LUA_TSTRING)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSFont"] forKey:NSFontAttributeName] ;
    lua_pop(L, 1) ;
    if (lua_getfield(L, idx, "paragraphStyle") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSParagraphStyle"] forKey:NSParagraphStyleAttributeName] ;
    lua_pop(L, 1) ;

    if (lua_getfield(L, idx, "underlineStyle") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSUnderlineStyleAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "superscript") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSSuperscriptAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "ligature") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSLigatureAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "strikethroughStyle") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tointeger(L, -1)) forKey:NSStrikethroughStyleAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "baselineOffset") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSBaselineOffsetAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "kerning") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSKernAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "strokeWidth") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSStrokeWidthAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "obliqueness") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSObliquenessAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "expansion") == LUA_TNUMBER)
        [theAttributes setObject:@(lua_tonumber(L, -1)) forKey:NSExpansionAttributeName] ;
    lua_pop(L, 1);

    if (lua_getfield(L, idx, "color") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"] forKey:NSForegroundColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "backgroundColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"] forKey:NSBackgroundColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "strokeColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"] forKey:NSStrokeColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "underlineColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"] forKey:NSUnderlineColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "strikethroughColor") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"] forKey:NSStrikethroughColorAttributeName] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "shadow") == LUA_TTABLE)
        [theAttributes setObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSShadow"] forKey:NSShadowAttributeName] ;
    lua_pop(L, 1);

    return theAttributes ;
}

static int NSAttributedString_toLua(lua_State *L, id obj) {
// [[LuaSkin shared] pushNSObject:NSFont] ;
// C-API
// Creates a userdata object representing the NSAttributedString
    NSAttributedString *theString = obj ;

    void** stringPtr = lua_newuserdata(L, sizeof(NSAttributedString *)) ;
    *stringPtr = (__bridge_retained void *)theString ;
    luaL_getmetatable(L, USERDATA_TAG) ;
    lua_setmetatable(L, -2) ;

    return 1 ;
}

static int NSFont_toLua(lua_State *L, id obj) {
// [[LuaSkin shared] pushNSObject:NSFont] ;
// C-API
// Creates a table representing the NSFont for Lua
//
// The table will have the following layout:
// {
//   name = the font name,
//   size = the font size in points as a floating point number
// }
    NSFont *theFont = obj ;

    lua_newtable(L) ;
        [[LuaSkin shared] pushNSObject:[theFont fontName]] ;  lua_setfield(L, -2, "name") ;
        lua_pushnumber(L, [theFont pointSize]) ;              lua_setfield(L, -2, "size") ;

    return 1 ;
}

static id table_toNSFont(lua_State* L, int idx) {
// NSFont *theFont = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"NSFont"] ;
// [[LuaSkin shared] pushNSObject:NSFont] ;
// C-API
// Returns the NSFont described by the string or table at the specific index on the Lua Stack.
//
// If the value at the stack location is a string, the font will be at the default system font size.
// If the value at the stack location is a table, the table should have the following layout:
// {
//   name = the font name,
//   size = the font size in points as a floating point number
// }
    NSString *theName = [[NSFont systemFontOfSize:0] fontName] ;
    CGFloat  theSize = [NSFont systemFontSize] ;

    if (lua_type(L, idx) == LUA_TSTRING) {
        theName = [[LuaSkin shared] toNSObjectAtIndex:idx] ;
    } else {
        luaL_checktype(L, idx, LUA_TTABLE) ;

        if (lua_getfield(L, idx, "name") == LUA_TSTRING)
            theName = [[LuaSkin shared] toNSObjectAtIndex:-1] ;
        lua_pop(L, 1);

        if (lua_getfield(L, idx, "size") == LUA_TNUMBER)
            theSize = lua_tonumber(L, -1);
        lua_pop(L, 1);
    }

    return [NSFont fontWithName:theName size:theSize] ;
}

static int NSShadow_toLua(lua_State *L, id obj) {
// [[LuaSkin shared] pushNSObject:NSShadow] ;
// C-API
// Pushes an NSShadow object onto the Lua Stack.
//
// The table will have the following layout:
// {
//   offset     = { h = float, w = float },
//   blurRadius = float,
//   color      = { NSColor table representation described in hs.drawing.color },
// }
    NSShadow *theShadow = obj ;
    NSSize   offset = [theShadow shadowOffset] ;

    lua_newtable(L) ;
        lua_newtable(L) ;
          lua_pushnumber(L, offset.height) ; lua_setfield(L, -2, "h") ;
          lua_pushnumber(L, offset.width) ;  lua_setfield(L, -2, "w") ;
        lua_setfield(L, -2, "offset") ;
        lua_pushnumber(L, [theShadow shadowBlurRadius]) ;         lua_setfield(L, -2, "blurRadius") ;
        [[LuaSkin shared] pushNSObject:[theShadow shadowColor]] ; lua_setfield(L, -2, "color") ;

    return 1 ;
}

static id table_toNSShadow(lua_State* L, int idx) {
// NSShadow *theShadow = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"NSShadow"] ;
// C-API
// Returns an NSShadow object as described in the table on the Lua Stack at idx.
//
// The table should have the following layout:
// {
//   offset     = { h = float, w = float },
//   blurRadius = float,
//   color      = { NSColor table representation described in hs.drawing.color },
// }
    luaL_checktype(L, idx, LUA_TTABLE) ;
    NSShadow *theShadow = [[NSShadow alloc] init] ;
    if (lua_getfield(L, idx, "offset") == LUA_TTABLE)
        [theShadow setShadowOffset:[[LuaSkin shared] tableToSizeAtIndex:-1]] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "blurRadius") == LUA_TNUMBER)
        [theShadow setShadowBlurRadius:luaL_checknumber(L, -1)] ;
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "color") == LUA_TTABLE)
        [theShadow setShadowColor:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSColor"]] ;
    lua_pop(L, 1);
    return theShadow ;
}

static int NSParagraphStyle_toLua(lua_State *L, id obj) {
// [[LuaSkin shared] pushNSObject:NSParagraphStyle] ;
// C-API
// Pushes an NSParagraphStyle object onto the Lua Stack.
//
// The table will have the following layout:
// {
//   alignment                     = string,
//   lineBreak                     = string,
//   baseWritingDirection          = string,
//   defaultTabInterval            = float,
//   firstLineHeadIndent           = float,
//   headIndent                    = float,
//   tailIndent                    = float,
//   maximumLineHeight             = float,
//   minimumLineHeight             = float,
//   lineSpacing                   = float,
//   paragraphSpacing              = float,
//   paragraphSpacingBefore        = float,
//   lineHeightMultiple            = float,
//   hyphenationFactor             = float,
//   tighteningFactorForTruncation = float,
//   headerLevel                   = int,
//   tabStops                      = array,
// }
    NSParagraphStyle *thePS = obj ;

    lua_newtable(L) ;

    switch([thePS alignment]) {
        case NSLeftTextAlignment:      lua_pushstring(L, "left") ;      break ;
        case NSRightTextAlignment:     lua_pushstring(L, "right") ;     break ;
        case NSCenterTextAlignment:    lua_pushstring(L, "center") ;    break ;
        case NSJustifiedTextAlignment: lua_pushstring(L, "justified") ; break ;
        case NSNaturalTextAlignment:   lua_pushstring(L, "natural") ;   break ;
        default:                       lua_pushstring(L, "unknown") ;   break ;
    }
    lua_setfield(L, -2, "alignment") ;

    switch([thePS lineBreakMode]) {
        case NSLineBreakByWordWrapping:     lua_pushstring(L, "wordWrap") ;       break ;
        case NSLineBreakByCharWrapping:     lua_pushstring(L, "charWrap") ;       break ;
        case NSLineBreakByClipping:         lua_pushstring(L, "clip") ;           break ;
        case NSLineBreakByTruncatingHead:   lua_pushstring(L, "truncateHead") ;   break ;
        case NSLineBreakByTruncatingTail:   lua_pushstring(L, "truncateTail") ;   break ;
        case NSLineBreakByTruncatingMiddle: lua_pushstring(L, "truncateMiddle") ; break ;
        default:                            lua_pushstring(L, "unknown") ;        break ;
    }
    lua_setfield(L, -2, "lineBreak") ;

    switch([thePS baseWritingDirection]) {
        case NSWritingDirectionNatural:     lua_pushstring(L, "natural") ;     break ;
        case NSWritingDirectionLeftToRight: lua_pushstring(L, "leftToRight") ; break ;
        case NSWritingDirectionRightToLeft: lua_pushstring(L, "rightToLeft") ; break ;
        default:                            lua_pushstring(L, "unknown") ;     break ;
    }
    lua_setfield(L, -2, "baseWritingDirection") ;

    lua_pushnumber(L, [thePS defaultTabInterval]) ;             lua_setfield(L, -2, "defaultTabInterval") ;

    lua_pushnumber(L, [thePS firstLineHeadIndent]) ;            lua_setfield(L, -2, "firstLineHeadIndent") ;
    lua_pushnumber(L, [thePS headIndent]) ;                     lua_setfield(L, -2, "headIndent") ;
    lua_pushnumber(L, [thePS tailIndent]) ;                     lua_setfield(L, -2, "tailIndent") ;
    lua_pushnumber(L, [thePS maximumLineHeight]) ;              lua_setfield(L, -2, "maximumLineHeight") ;
    lua_pushnumber(L, [thePS minimumLineHeight]) ;              lua_setfield(L, -2, "minimumLineHeight") ;
    lua_pushnumber(L, [thePS lineSpacing]) ;                    lua_setfield(L, -2, "lineSpacing") ;
    lua_pushnumber(L, [thePS paragraphSpacing]) ;               lua_setfield(L, -2, "paragraphSpacing") ;
    lua_pushnumber(L, [thePS paragraphSpacingBefore]) ;         lua_setfield(L, -2, "paragraphSpacingBefore") ;
    lua_pushnumber(L, [thePS lineHeightMultiple]) ;             lua_setfield(L, -2, "lineHeightMultiple") ;
    lua_pushnumber(L, [thePS hyphenationFactor]) ;              lua_setfield(L, -2, "hyphenationFactor") ;
    lua_pushnumber(L, [thePS tighteningFactorForTruncation]) ;  lua_setfield(L, -2, "tighteningFactorForTruncation") ;
// Doesn't seem to actually be in the API yet...
//     if ([thePS respondsToSelector:@selector(allowsDefaultTighteningForTruncation)]) {
//         lua_pushboolean(L, [thePS allowsDefaultTighteningForTruncation]) ;
//         lua_setfield(L, -2, "allowsDefaultTighteningForTruncation") ;
//     }

    [[LuaSkin shared] pushNSObject:[thePS tabStops]] ;          lua_setfield(L, -2, "tabStops") ;
    lua_pushinteger(L, [thePS headerLevel]) ;                   lua_setfield(L, -2, "headerLevel") ;
    return 1 ;
}

static id table_toNSParagraphStyle(lua_State* L, int idx) {
// NSParagraphStyle *theParagraphStyle = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"NSParagraphStyle"] ;
// C-API
// Returns an NSParagraphStyle object as described in the table on the Lua Stack at idx.
//
// The table should have the following layout:
// {
//   alignment                     = "left"|"right"|"center"|"justified"|"natural",
//   lineBreak                     = "wordWrap"|"charWrap"|"clip"|"truncateHead"|"truncateTail"|"truncateMiddle",
//   baseWritingDirection          = "natural"|"leftToRight"|"rightToLeft",
//   defaultTabInterval            = float > 0.0,
//   firstLineHeadIndent           = float > 0.0,
//   headIndent                    = float > 0.0,
//   tailIndent                    = float,
//   maximumLineHeight             = float > 0.0,
//   minimumLineHeight             = float > 0.0,
//   lineSpacing                   = float > 0.0,
//   paragraphSpacing              = float > 0.0,
//   paragraphSpacingBefore        = float > 0.0,
//   lineHeightMultiple            = float > 0.0,
//   hyphenationFactor             = float [0.0, 1.0],
//   tighteningFactorForTruncation = float,
//   headerLevel                   = int [0, 6],
//   tabStops                      = array of tabStop tables
// }
    luaL_checktype(L, idx, LUA_TTABLE) ;
    NSMutableParagraphStyle *thePS = [[NSParagraphStyle defaultParagraphStyle] mutableCopy] ;

    if (lua_getfield(L, idx, "alignment") == LUA_TSTRING) {
        NSString *theString = [[LuaSkin shared] toNSObjectAtIndex:-1] ;
        if ([theString isEqualToString:@"left"])      { thePS.alignment = NSLeftTextAlignment ;      } else
        if ([theString isEqualToString:@"right"])     { thePS.alignment = NSRightTextAlignment ;     } else
        if ([theString isEqualToString:@"center"])    { thePS.alignment = NSCenterTextAlignment ;    } else
        if ([theString isEqualToString:@"justified"]) { thePS.alignment = NSJustifiedTextAlignment ; } else
        if ([theString isEqualToString:@"natural"])   { thePS.alignment = NSNaturalTextAlignment ;   }
        else {
            luaL_error(L, [[NSString stringWithFormat:@"invalid alignment: %@", theString] UTF8String]) ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "lineBreak") == LUA_TSTRING) {
        NSString *theString = [[LuaSkin shared] toNSObjectAtIndex:-1] ;
        if ([theString isEqualToString:@"wordWrap"])       { thePS.lineBreakMode = NSLineBreakByWordWrapping ;     } else
        if ([theString isEqualToString:@"charWrap"])       { thePS.lineBreakMode = NSLineBreakByCharWrapping ;     } else
        if ([theString isEqualToString:@"clip"])           { thePS.lineBreakMode = NSLineBreakByClipping ;         } else
        if ([theString isEqualToString:@"truncateHead"])   { thePS.lineBreakMode = NSLineBreakByTruncatingHead ;   } else
        if ([theString isEqualToString:@"truncateTail"])   { thePS.lineBreakMode = NSLineBreakByTruncatingTail ;   } else
        if ([theString isEqualToString:@"truncateMiddle"]) { thePS.lineBreakMode = NSLineBreakByTruncatingMiddle ; }
        else {
            luaL_error(L, [[NSString stringWithFormat:@"invalid lineBreakMode: %@", theString] UTF8String]) ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "baseWritingDirection") == LUA_TSTRING) {
        NSString *theString = [[LuaSkin shared] toNSObjectAtIndex:-1] ;
        if ([theString isEqualToString:@"natural"])     { thePS.baseWritingDirection = NSWritingDirectionNatural ;     } else
        if ([theString isEqualToString:@"leftToRight"]) { thePS.baseWritingDirection = NSWritingDirectionLeftToRight ; } else
        if ([theString isEqualToString:@"rightToLeft"]) { thePS.baseWritingDirection = NSWritingDirectionRightToLeft ; }
        else {
            luaL_error(L, [[NSString stringWithFormat:@"invalid baseWritingDirection: %@", theString] UTF8String]) ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "defaultTabInterval") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.defaultTabInterval = theNumber ;
        } else {
            luaL_error(L, "defaultTabInterval must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "firstLineHeadIndent") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.firstLineHeadIndent = theNumber ;
        } else {
            luaL_error(L, "firstLineHeadIndent must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);

    if (lua_getfield(L, idx, "headIndent") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.headIndent = theNumber ;
        } else {
            luaL_error(L, "headIndent must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "tailIndent") == LUA_TNUMBER) {
        thePS.tailIndent = lua_tonumber(L, -1) ;
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "maximumLineHeight") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.maximumLineHeight = theNumber ;
        } else {
            luaL_error(L, "maximumLineHeight must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "minimumLineHeight") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.minimumLineHeight = theNumber ;
        } else {
            luaL_error(L, "minimumLineHeight must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "lineSpacing") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.lineSpacing = theNumber ;
        } else {
            luaL_error(L, "lineSpacing must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "paragraphSpacing") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.paragraphSpacing = theNumber ;
        } else {
            luaL_error(L, "paragraphSpacing must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "paragraphSpacingBefore") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.paragraphSpacingBefore = theNumber ;
        } else {
            luaL_error(L, "paragraphSpacingBefore must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "lineHeightMultiple") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0) {
            thePS.lineHeightMultiple = theNumber ;
        } else {
            luaL_error(L, "lineHeightMultiple must be non-negative") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "hyphenationFactor") == LUA_TNUMBER) {
        lua_Number theNumber = lua_tonumber(L, -1) ;
        if (theNumber >= 0.0 && theNumber <= 1.0) {
            thePS.hyphenationFactor = (float) theNumber ;
        } else {
            luaL_error(L, "hyphenationFactor must be between 0.0 and 1.0 inclusive") ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "tighteningFactorForTruncation") == LUA_TNUMBER) {
        thePS.tighteningFactorForTruncation = (float) lua_tonumber(L, -1) ;
    }
    lua_pop(L, 1);
// Doesn't seem to actually be in the API yet...
//     if ([thePS respondsToSelector:@selector(allowsDefaultTighteningForTruncation)]) {
//         if(lua_getfield(L, -1, "allowsDefaultTighteningForTruncation") == LUA_TBOOLEAN) {
//             thePS.allowsDefaultTighteningForTruncation = lua_toboolean(L, -1) ;
//         }
//         lua_pop(L, 1) ;
//     }

    if (lua_getfield(L, idx, "headerLevel") == LUA_TNUMBER) {
        lua_Integer theNumber = luaL_checkinteger(L, -1) ;
        if (theNumber >= 0 && theNumber <= 6) {
            thePS.headerLevel = theNumber ;
        } else {
            luaL_error(L, "headerNumber must be between 0 and 6 inclusive") ;
            return nil ;
        }
    }
    lua_pop(L, 1);

    if (lua_getfield(L, idx, "tabStops") == LUA_TTABLE) {
        NSMutableArray *theTabStops = [[NSMutableArray alloc] init] ;
        lua_Integer pos = 1 ;

        while(lua_rawgeti(L, -1, pos) != LUA_TNIL) {
            luaL_checktype(L, -1, LUA_TTABLE) ;
            [theTabStops addObject:[[LuaSkin shared] luaObjectAtIndex:-1 toClass:"NSTextTab"]] ;
            lua_pop(L, 1) ; // the tabStop table we just looked at
            pos++ ;
        }
        lua_pop(L, 1) ; // loop terminating nil
        thePS.tabStops = theTabStops ;
    }
    lua_pop(L, 1) ;

    return thePS ;
}

static int NSTextTab_toLua(lua_State *L, id obj) {
// [[LuaSkin shared] pushNSObject:NSTextTab] ;
// C-API
// Pushes an NSTextTab object onto the Lua Stack.
//
// The table will have the following layout:
// {
//   location    = float,
//   tabStopType = string,    // deprecated
// }
    NSTextTab *theTabStop = obj ;
    lua_newtable(L) ;

    lua_pushnumber(L, [theTabStop location]) ; lua_setfield(L, -2, "location") ;

    switch([theTabStop tabStopType]) {
        case NSLeftTabStopType:    lua_pushstring(L, "left") ;    break ;
        case NSRightTabStopType:   lua_pushstring(L, "right") ;   break ;
        case NSCenterTabStopType:  lua_pushstring(L, "center") ;  break ;
        case NSDecimalTabStopType: lua_pushstring(L, "decimal") ; break ;
        default:                   lua_pushstring(L, "unknown") ; break ;
    }
    lua_setfield(L, -2, "tabStopType") ;

//     switch([theTabStop alignment]) {
//         case NSLeftTextAlignment:       lua_pushstring(L, "left") ;      break ;
//         case NSRightTextAlignment:      lua_pushstring(L, "right") ;     break ;
//         case NSCenterTextAlignment:     lua_pushstring(L, "center") ;    break ;
//         case NSJustifiedTextAlignment:  lua_pushstring(L, "justified") ; break ;
//         case NSNaturalTextAlignment:    lua_pushstring(L, "natural") ;   break ;
//         default:                        lua_pushstring(L, "unknown") ;   break ;
//     }
//     lua_setfield(L, -2, "alignment") ;

//     [[LuaSkin shared] pushNSObject:[theTabStop options]] ; lua_setfield(L, -2, "options") ;

// NSTextTab Notes:
//
// alignment with an options dictionary is preferred, but see notes below for why we're skipping it for now.
//
// tabStopType has been deprecated in 10.11, but the "correct" method of using alignment=natural with an options dictionary
// containing @{NSTabColumnTerminatorsAttributeName: NSTextTab.columnTerminatorsForLocale(NSLocale.currentLocale())} doesn't
// seem to be in the OS X headers yet...
//
// So, stick we with the tabStopType approach until it breaks -- I'd rather rely on OS X knowing what
// tabStopType NSDecimalTabStopType means for a given locale instead of naively assuming creating a single
// element NSCharacterSet with just a "." is valid outside of my locale
//
// FWIW, I used the following to determine that a single element character set is in fact what its doing behind the scenes:
//    > inspect(hs.styledtext.testTabStops(3,10))
//    {
//      alignment = "natural",
//      location = 10.0,
//      options = {
//        NSTabColumnTerminatorsAttributeName = { "." }
//      },
//      tabStopType = "decimal"
//    }
//
// static int NSCharacterSet_toLua(lua_State __unused *L, id obj) {
// // tweaked from http://stackoverflow.com/questions/26610931/list-of-characters-in-an-nscharacterset
//     NSCharacterSet *charset = obj ;
//     NSMutableArray *array = [NSMutableArray array];
//     for (unsigned int plane = 0; plane <= 16; plane++) {
//         if ([charset hasMemberInPlane:(uint8_t)plane]) {
//             UTF32Char c;
//             for (c = plane << 16; c < (plane+1) << 16; c++) {
//                 if ([charset longCharacterIsMember:c]) {
//                     UTF32Char c1 = OSSwapHostToLittleInt32(c); // To make it byte-order safe
//                     NSString *s = [[NSString alloc] initWithBytes:&c1 length:4 encoding:NSUTF32LittleEndianStringEncoding];
//                     [array addObject:s];
//                 }
//             }
//         }
//     }
//     [[LuaSkin shared] pushNSObject:array] ;
//     return 1 ;
// }
//
// static int testTabStops(lua_State *L) {
//     [[LuaSkin shared] checkArgs:LS_TNUMBER, LS_TNUMBER, LS_TBREAK] ;
//     [[LuaSkin shared] pushNSObject:[[NSTextTab alloc] initWithType:(enum NSTextTabType)lua_tointeger(L, 1) location:lua_tonumber(L, 2)]] ;
//
//     return 1 ;
// }

    return 1 ;
}

static id table_toNSTextTab(lua_State *L, int idx) {
// NSTextTab *tabStop = [[LuaSkin shared] luaObjectAtIndex:idx toClass:"NSTextTab"] ;
// C-API
// Returns an NSTextTab object as described in the table on the Lua Stack at idx.
//
// The table should have the following layout:
// {
//   location    = float,
//   tabStopType = string
// }
    luaL_checktype(L, idx, LUA_TTABLE) ;

    NSTextTabType tabStopType     = NSLeftTabStopType ;
    CGFloat       tabStopLocation = 0.0 ;

    if (lua_getfield(L, idx, "tabStopType") == LUA_TSTRING) {
        NSString *theString = [[LuaSkin shared] toNSObjectAtIndex:-1] ;
        if ([theString isEqualToString:@"left"])    { tabStopType = NSLeftTabStopType ;    } else
        if ([theString isEqualToString:@"right"])   { tabStopType = NSRightTabStopType ;   } else
        if ([theString isEqualToString:@"center"])  { tabStopType = NSCenterTabStopType ;  } else
        if ([theString isEqualToString:@"decimal"]) { tabStopType = NSDecimalTabStopType ; }
        else {
            luaL_error(L, [[NSString stringWithFormat:@"invalid tabStopType: %@", theString] UTF8String]) ;
            return nil ;
        }
    }
    lua_pop(L, 1);
    if (lua_getfield(L, idx, "location") == LUA_TNUMBER)
        tabStopLocation = lua_tonumber(L, -1) ;
    lua_pop(L, 1);

    return [[NSTextTab alloc] initWithType:tabStopType location:tabStopLocation] ;
}

#pragma mark - Lua Infrastructure

static int userdata_tostring(lua_State* L) {
    NSString *title = [get_objectFromUserdata(__bridge NSAttributedString, L, 1) string] ;
    if ([title length] > 20) // arbitrary cutoff to keep it readable
        lua_pushstring(L, [[NSString stringWithFormat:@"%s: %@... (%p)", USERDATA_TAG, [title substringToIndex:20], lua_topointer(L, 1)] UTF8String]) ;
    else
        lua_pushstring(L, [[NSString stringWithFormat:@"%s: %@ (%p)", USERDATA_TAG, title, lua_topointer(L, 1)] UTF8String]) ;
    return 1 ;
}

static int userdata_concat(lua_State* L) {
    if (lua_type(L, 1) == LUA_TSTRING) {
// if the type of first argument is string, then we'd only get called if the second was one of us
        NSString *theString1 = [NSString stringWithUTF8String: lua_tostring(L, 1)] ;
        NSString *theString2 = [get_objectFromUserdata(__bridge NSAttributedString, L, 2) string] ;
        NSMutableString *newString = [theString1 mutableCopy] ;
        [newString appendString:theString2] ;
        [[LuaSkin shared] pushNSObject:newString] ;

    } else {
        NSAttributedString *theString1 = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
// however, if the first argument is one of us, we still don't know what the second one is...
        NSAttributedString *theString2 = (lua_type(L, 2) == LUA_TUSERDATA) ?
                                          get_objectFromUserdata(__bridge NSAttributedString, L, 2) :
                                          [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String: lua_tostring(L, 2)]];
        NSMutableAttributedString *newString = [theString1 mutableCopy] ;
        [newString appendAttributedString:theString2] ;
        [[LuaSkin shared] pushNSObject:newString] ;
    }
    return 1 ;
}

// For reasons unclear to me, Lua will only call __eq when *both* arguments are userdata or *both* are tables.
// However __lt and __le are called if *both* arguments are *not* strings or *not* numbers...
// I'll go ahead and leave the type check in __eq anyways in case this changes in the future, though I'm not holding my breath.
static int userdata_eq(lua_State* L) {
    NSString *theString1 = (lua_type(L, 1) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 1) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 1)] ;
    NSString *theString2 = (lua_type(L, 2) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 2) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 2)] ;
    lua_pushboolean(L, [theString1 isEqualToString:theString2]) ;
    return 1 ;
}

static int userdata_lt(lua_State* L) {
    NSString *theString1 = (lua_type(L, 1) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 1) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 1)] ;
    NSString *theString2 = (lua_type(L, 2) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 2) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 2)] ;
    lua_pushboolean(L, [theString1 compare:theString2] == NSOrderedAscending) ;
    return 1 ;
}

static int userdata_le(lua_State* L) {
    NSString *theString1 = (lua_type(L, 1) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 1) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 1)] ;
    NSString *theString2 = (lua_type(L, 2) == LUA_TUSERDATA) ?  [get_objectFromUserdata(__bridge NSAttributedString, L, 2) string] :
                                                                [NSString stringWithUTF8String: lua_tostring(L, 2)] ;
    lua_pushboolean(L, [theString1 compare:theString2] != NSOrderedDescending) ;
    return 1 ;
}

static int userdata_len(lua_State *L) {
// Oddly, lua passes the userdata object as argument 1 *AND* argument 2 to this metamethod, so simply using
// the duplication of the string.length method above which checks for 1 and only 1 argument won't work.  I
// suppose we could point "len" to this one, since it ignores arguments other than the first, but I prefer
// proper data validation in functions/methods which get called by the user explicitly.
//     int x = lua_gettop(L) ;
//     lua_getglobal(L, "print") ;
//     for (int i = 1 ; i <= x ; i++) { lua_pushvalue(L, i) ; }
//     lua_call(L, x, 0) ;
    NSAttributedString *theString = get_objectFromUserdata(__bridge NSAttributedString, L, 1) ;
    lua_pushinteger(L, (lua_Integer)[theString length]) ;
    return 1 ;
}

static int userdata_gc(lua_State* L) {
// transfer it to an Objective-C object so ARC can clear it
    NSAttributedString __unused *theString = get_objectFromUserdata(__bridge_transfer NSAttributedString, L, 1) ;

// Remove the Metatable so future use of the variable in Lua won't think its valid
    lua_pushnil(L) ;
    lua_setmetatable(L, 1) ;

    return 0 ;
}

// static int meta_gc(lua_State* __unused L) {
//     return 0 ;
// }

// Metatable for userdata objects
static const luaL_Reg userdata_metaLib[] = {
    {"isIdentical",      string_identical},
    {"copy",             string_copy},
    {"asTable",          string_totable},
    {"asString",         string_tostring},
    {"setStyle",         string_setStyleForRange},
    {"removeStyle",      string_removeStyleForRange},
    {"replaceSubstring", string_replaceSubstringForRange},
    {"convert",          string_convert},

    {"len",              string_len},
    {"upper",            string_upper},
    {"lower",            string_lower},
    {"sub",              string_sub},

    {"__tostring",       userdata_tostring},
    {"__concat",         userdata_concat},
    {"__len",            userdata_len},
    {"__eq",             userdata_eq},
    {"__lt",             userdata_lt},
    {"__le",             userdata_le},
    {"__gc",             userdata_gc},
    {NULL,               NULL}
};

// Functions for returned object when module loads
static luaL_Reg moduleLib[] = {
    {"new",                   string_new},
    {"getStyledTextFromFile", getStyledTextFromFile},
    {"getStyledTextFromData", getStyledTextFromData},

    {"convertFont",           font_convertFont},
    {"fontInfo",              fontInformation},
    {"fontNames",             fontNames},
    {"fontNamesWithTraits",   fontNamesWithTraits},

    {NULL,                  NULL}
};

// // Metatable for module, if needed
// static const luaL_Reg module_metaLib[] = {
//     {"__gc", meta_gc},
//     {NULL,   NULL}
// };

int luaopen_hs_styledtext_internal(lua_State* __unused L) {
    refTable = [[LuaSkin shared] registerLibraryWithObject:USERDATA_TAG
                                                 functions:moduleLib
                                             metaFunctions:nil    // or module_metaLib
                                           objectFunctions:userdata_metaLib];

    fontTraits(L) ;          lua_setfield(L, -2, "fontTraits") ;

    defineLinePatterns(L) ;  lua_setfield(L, -2, "linePatterns") ;
    defineLineStyles(L) ;    lua_setfield(L, -2, "lineStyles") ;
    defineLineAppliesTo(L) ; lua_setfield(L, -2, "lineAppliesTo") ;

    [[LuaSkin shared] registerPushNSHelper:NSShadow_toLua                  forClass:"NSShadow"] ;
    [[LuaSkin shared] registerLuaObjectHelper:table_toNSShadow             forClass:"NSShadow"] ;

    [[LuaSkin shared] registerPushNSHelper:NSParagraphStyle_toLua          forClass:"NSParagraphStyle"] ;
    [[LuaSkin shared] registerLuaObjectHelper:table_toNSParagraphStyle     forClass:"NSParagraphStyle"] ;

    [[LuaSkin shared] registerPushNSHelper:NSTextTab_toLua                 forClass:"NSTextTab"] ;
    [[LuaSkin shared] registerLuaObjectHelper:table_toNSTextTab            forClass:"NSTextTab"] ;

    [[LuaSkin shared] registerPushNSHelper:NSFont_toLua                    forClass:"NSFont"] ;
    [[LuaSkin shared] registerLuaObjectHelper:table_toNSFont               forClass:"NSFont"] ;

    [[LuaSkin shared] registerPushNSHelper:NSAttributedString_toLua        forClass:"NSAttributedString"] ;
    [[LuaSkin shared] registerLuaObjectHelper:lua_toNSAttributedString     forClass:"NSAttributedString"] ;

    [[LuaSkin shared] registerLuaObjectHelper:table_toAttributesDictionary forClass:"hs.styledtext.AttributesDictionary"] ;

    return 1;
}

// + TODO: all the hs.drawing integration
// TODO: - way to register defaults for specific uses of styleText objects?
//         sorta... new can accept a table now... should it actually be registered here?
