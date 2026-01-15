--!nocheck
--[[

Chalk

A terminal string styling library for Luau, forked from
https://github.com/Roblox/chalk-lua. Provides ANSI color codes for text
modifiers, foreground colors, background colors, and dynamic color functions.

--]]

type StyleFunction = (value: any) -> string

export type Chalk = StyleFunction & {
    level: number,

    -- modifiers
    reset: StyleFunction,
    bold: StyleFunction,
    dim: StyleFunction,
    italic: StyleFunction,
    underline: StyleFunction,
    overline: StyleFunction,
    inverse: StyleFunction,
    hidden: StyleFunction,
    strikethrough: StyleFunction,

    -- foreground colors
    black: StyleFunction,
    red: StyleFunction,
    green: StyleFunction,
    yellow: StyleFunction,
    blue: StyleFunction,
    magenta: StyleFunction,
    cyan: StyleFunction,
    white: StyleFunction,

    -- bright foreground colors
    blackBright: StyleFunction,
    gray: StyleFunction,
    grey: StyleFunction,
    redBright: StyleFunction,
    greenBright: StyleFunction,
    yellowBright: StyleFunction,
    blueBright: StyleFunction,
    magentaBright: StyleFunction,
    cyanBright: StyleFunction,
    whiteBright: StyleFunction,

    -- background colors
    bgBlack: StyleFunction,
    bgRed: StyleFunction,
    bgGreen: StyleFunction,
    bgYellow: StyleFunction,
    bgBlue: StyleFunction,
    bgMagenta: StyleFunction,
    bgCyan: StyleFunction,
    bgWhite: StyleFunction,

    -- bright background colors
    bgBlackBright: StyleFunction,
    bgGray: StyleFunction,
    bgGrey: StyleFunction,
    bgRedBright: StyleFunction,
    bgGreenBright: StyleFunction,
    bgYellowBright: StyleFunction,
    bgBlueBright: StyleFunction,
    bgMagentaBright: StyleFunction,
    bgCyanBright: StyleFunction,
    bgWhiteBright: StyleFunction,

    -- dynamic color functions
    rgb: (red: number, green: number, blue: number) -> StyleFunction,
    bgRgb: (red: number, green: number, blue: number) -> StyleFunction,
    hex: (hex: string) -> StyleFunction,
    bgHex: (hex: string) -> StyleFunction,
    ansi: (ansi: number) -> StyleFunction,
    bgAnsi: (ansi: number) -> StyleFunction,
    ansi256: (ansi: number) -> StyleFunction,
    bgAnsi256: (ansi: number) -> StyleFunction,
}

-- Plain string replacement (actually replaces substring with replacer)
local function stringReplace(string_, substring, replacer)
    local result = {}
    local start = 1
    while true do
        local pos = string.find(string_, substring, start, true)
        if not pos then
            table.insert(result, string.sub(string_, start))
            break
        end
        table.insert(result, string.sub(string_, start, pos - 1))
        table.insert(result, replacer)
        start = pos + #substring
    end
    return table.concat(result)
end

-- ROBLOX NOTE: inline stringReplaceAll to keep ChalkLua as one file
-- NOTE: This function KEEPS substring and APPENDS replacer after it (for style chaining)
local function stringReplaceAll(string_, substring, replacer)
    local index = string.find(string_, substring, 1, true)
    if index == nil then
        return string_
    end
    local substringLength = #substring
    local endIndex = 1
    local returnValue = ""
    repeat
        returnValue ..= string.sub(string_, endIndex, index - 1) .. substring .. replacer
        endIndex = index + substringLength
        index = string.find(string_, substring, endIndex, true)
    until not (index ~= nil)
    returnValue ..= string.sub(string_, endIndex)
    return returnValue
end

-- ROBLOX NOTE: inline stringEncaseCRLFWithFirstIndex to keep ChalkLua as one file
local function stringEncaseCRLFWithFirstIndex(string_, prefix, postfix, index)
    local endIndex = 1
    local returnValue = ""
    repeat
        local gotCR = string.sub(string_, index - 1, index - 1) == "\r"
        returnValue ..= string.sub(string_, endIndex, if gotCR then index - 2 else index - 1) .. prefix .. (if gotCR
            then "\r\n"
            else "\n") .. postfix
        endIndex = index + 1
        index = string.find(string_, "\n", endIndex)
    until not (index ~= nil)
    returnValue ..= string.sub(string_, endIndex)
    return returnValue
end

local ansiStyles = {
    modifier = {
        reset = { 0, 0 },
        bold = { 1, 22 },
        dim = { 2, 22 },
        italic = { 3, 23 },
        underline = { 4, 24 },
        overline = { 53, 55 },
        inverse = { 7, 27 },
        hidden = { 8, 28 },
        strikethrough = { 9, 29 },
    },

    color = {
        black = { 30, 39 },
        red = { 31, 39 },
        green = { 32, 39 },
        yellow = { 33, 39 },
        blue = { 34, 39 },
        magenta = { 35, 39 },
        cyan = { 36, 39 },
        white = { 37, 39 },

        -- bright color
        blackBright = { 90, 39 },
        gray = { 90, 39 },
        grey = { 90, 39 },
        redBright = { 91, 39 },
        greenBright = { 92, 39 },
        yellowBright = { 93, 39 },
        blueBright = { 94, 39 },
        magentaBright = { 95, 39 },
        cyanBright = { 96, 39 },
        whiteBright = { 97, 39 },
    },

    bgColor = {
        bgBlack = { 40, 49 },
        bgRed = { 41, 49 },
        bgGreen = { 42, 49 },
        bgYellow = { 43, 49 },
        bgBlue = { 44, 49 },
        bgMagenta = { 45, 49 },
        bgCyan = { 46, 49 },
        bgWhite = { 47, 49 },

        -- bright color
        bgBlackBright = { 100, 49 },
        bgGray = { 100, 49 },
        bgGrey = { 100, 49 },
        bgRedBright = { 101, 49 },
        bgGreenBright = { 102, 49 },
        bgYellowBright = { 103, 49 },
        bgBlueBright = { 104, 49 },
        bgMagentaBright = { 105, 49 },
        bgCyanBright = { 106, 49 },
        bgWhiteBright = { 107, 49 },
    },
}

local ansi16 = "%c[%dm"
local ansi256 = "%c[%d;5;%dm"
local ESC = 27
local ANSI_SET_FOREGROUND = 38
local ANSI_SET_BACKGROUND = 48

-- Marker to indicate where outer styles should resume after reset text.
-- Uses an invalid ANSI code that terminals will ignore.
local RESUME_MARKER = string.format(ansi16, ESC, 999)

local styles = {}

for groupName, group in pairs(ansiStyles) do
    for styleName, style in pairs(group) do
        styles[styleName] = {
            open = string.format(ansi16, ESC, style[1]),
            close = string.format(ansi16, ESC, style[2]),
        }
    end
end

local createStyler
local applyStyle

local function compositeStyler(style, otherStyle)
    return createStyler(style.open .. otherStyle.open, otherStyle.close .. style.close)
end

local function environmentSupported()
    -- checks if running in a roblox environment
    local success1, RunService = pcall(function()
        return game:GetService("RunService")
    end)
    if not success1 then
        return true
    end

    -- checks if running in roblox-cli
    local success2, processServiceExists = pcall(function()
        return game:GetService("ProcessService")
    end)
    if success2 and processServiceExists then
        return true
    end

    -- checks if running in ocale
    if RunService:IsServer() and not RunService:IsStudio() then
        return true
    end

    return false
end

local Chalk = { level = 2 }
if _G.NOCOLOR or not environmentSupported() then
    Chalk.level = 0
end

setmetatable(Chalk, {
    __call = function(_, str)
        if str == nil or type(str) == "string" and #str == 0 then
            return ""
        end
        return tostring(str)
    end,
})

function createStyler(open, close)
    local styler = {
        open = open,
        close = close,
    }

    setmetatable(styler, {
        __call = function(self, str)
            return applyStyle(self, str)
        end,
        __concat = function(self, other)
            return compositeStyler(self, other)
        end,
    })

    return styler
end

function applyStyle(self, str)
    if str == nil or type(str) == "string" and #str == 0 then
        return ""
    end
    if Chalk.level == 0 then
        return tostring(str)
    end

    local styler = self

    local openAll, closeAll = styler.open, styler.close
    if string.match(str, "\u{001B}") then
        -- Replace any instances already present with a re-opening code
        -- otherwise only the part of the string until said closing code
        -- will be colored, and the rest will simply be 'plain'.
        str = stringReplaceAll(str, styler.close, styler.open)

        -- Handle RESUME_MARKER from nested Chalk.reset() calls.
        -- Replace the marker with this style's open code to resume styling
        -- after the reset text.
        str = stringReplace(str, RESUME_MARKER, styler.open)
    end

    -- We can move both next actions out of loop, because remaining actions in loop won't have
    -- any/visible effect on parts we add here. Close the styling before a linebreak and reopen
    -- after next line to fix a bleed issue on macOS: https://github.com/chalk/chalk/pull/92
    local lfIndex = string.find(str, "\n")
    if lfIndex ~= nil then
        str = stringEncaseCRLFWithFirstIndex(str, closeAll, openAll, lfIndex)
    end

    return self.open .. tostring(str) .. self.close
end

local function noStyle()
    return createStyler("", "")
end

local close = string.format(ansi16, ESC, 39)
local bgClose = string.format(ansi16, ESC, 49)
local reset = string.format(ansi16, ESC, 0)

for styleName, style in pairs(styles) do
    Chalk[styleName] = createStyler(style.open, style.close)
end

-- reset uses RESUME_MARKER as close so outer styles know where to resume
Chalk["reset"] = createStyler(reset, RESUME_MARKER)

local function rgbToAnsi256(red, green, blue)
    if red == green and green == blue then
        if red < 8 then
            return 16
        end
        if red > 248 then
            return 231
        end

        return math.round((((red - 8) / 247) * 24) + 232)
    end

    local ansi = 16 + (36 * math.round(red / 255 * 5)) + (6 * math.round(green / 255 * 5)) + math.round(blue / 255 * 5)
    return ansi
end

Chalk["rgb"] = function(red, green, blue)
    if
        type(red) ~= "number"
        or type(green) ~= "number"
        or type(blue) ~= "number"
        or red > 255
        or red < 0
        or green > 255
        or green < 0
        or blue > 255
        or blue < 0
    then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_FOREGROUND, rgbToAnsi256(red, green, blue))
    return createStyler(open, close)
end

Chalk["bgRgb"] = function(red, green, blue)
    if
        type(red) ~= "number"
        or type(green) ~= "number"
        or type(blue) ~= "number"
        or red > 255
        or red < 0
        or green > 255
        or green < 0
        or blue > 255
        or blue < 0
    then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_BACKGROUND, rgbToAnsi256(red, green, blue))
    return createStyler(open, bgClose)
end

local function hexToRgb(hex)
    local red = tonumber(string.sub(hex, 2, 3), 16)
    local blue = tonumber(string.sub(hex, 4, 5), 16)
    local green = tonumber(string.sub(hex, 6, 7), 16)

    return rgbToAnsi256(red, blue, green)
end

Chalk["hex"] = function(hex)
    if type(hex) ~= "string" or string.find(hex, "#%X") ~= nil or #hex ~= 7 then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_FOREGROUND, hexToRgb(hex))
    return createStyler(open, close)
end

Chalk["bgHex"] = function(hex)
    if type(hex) ~= "string" or string.find(hex, "#%X") ~= nil or #hex ~= 7 then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_BACKGROUND, hexToRgb(hex))
    return createStyler(open, bgClose)
end

Chalk["ansi"] = function(ansi)
    if type(ansi) ~= "number" or ansi < 30 or (ansi > 37 and ansi < 90) or ansi > 97 then
        return noStyle()
    end
    local open = string.format(ansi16, ESC, ansi)
    return createStyler(open, close)
end

Chalk["bgAnsi"] = function(ansi)
    if type(ansi) ~= "number" or ansi < 40 or (ansi > 47 and ansi < 100) or ansi > 107 then
        return noStyle()
    end
    local open = string.format(ansi16, ESC, ansi)
    return createStyler(open, bgClose)
end

Chalk["ansi256"] = function(ansi)
    if type(ansi) ~= "number" or ansi < 0 or ansi > 255 then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_FOREGROUND, ansi)
    return createStyler(open, close)
end

Chalk["bgAnsi256"] = function(ansi)
    if type(ansi) ~= "number" or ansi < 0 or ansi > 255 then
        return noStyle()
    end
    local open = string.format(ansi256, ESC, ANSI_SET_BACKGROUND, ansi)
    return createStyler(open, bgClose)
end

return Chalk :: Chalk
