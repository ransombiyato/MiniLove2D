-- minilove2d by ribi
-- a tiny love2d editor/sandbox
-- bugs? discord me lol
-- come say hi im cool

local Editor = {
    currentTab = "code",
    lines = {
        "-- welcome to minilove2d by ribi(me), made to make people's life easier",
        "-- if you want to support me then go to the discord server mentioned in my repo and tell people that i am very great and not evil and is very very nice and helpful or smth like that lol. (im being for real.)",
        "-- if you encounter any bugs pls tell me in the discord(im DISABLED SPEED?)",
        "function love.draw()",
        "    love.graphics.setColor(0, 0.47, 0.8)",
        "    love.graphics.circle('fill', 150, 150, 60)",
        "end"
    },
    cursorX = 1, 
    cursorY = 1,
    fontSize = 15, 
    font = nil,
    lineHeight = 22, 
    charWidth = 9,
    
    scrollX = 0, 
    targetScrollX = 0,
    scrollY = 0, 
    targetScrollY = 0,
    isDragging = false, 
    lastMouseX = 0, 
    lastMouseY = 0,
    cursorTimer = 0, 
    ignoreTextInputTimer = 0,
    
    sidebarWidth = 40, 
    tabHeight = 35,
    suggestActive = false, 
    suggestions = {}, 
    suggestIndex = 1,
    localSymbols = {},
    
    keywords = {
        "function", "end", "if", "then", "else", "elseif", "for", "while", "return", "local", "break", "true", "false", "nil",
        "assert", "error", "ipairs", "pairs", "pcall", "tonumber", "tostring", "type", "unpack", "xpcall", "require",
        "math", "table", "string", "coroutine", "package", "io", "os", "debug",
        "abs", "acos", "asin", "atan", "atan2", "ceil", "cos", "cosh", "deg", "exp", "floor", "fmod", "log", "log10", "max", "min", "pow", "rad", "random", "randomseed", "sin", "sinh", "sqrt", "tan", "tanh",
        "insert", "remove", "concat", "sort", "maxn", "byte", "char", "find", "format", "gmatch", "gsub", "len", "lower", "match", "rep", "reverse", "sub", "upper",
        "love", "graphics", "draw", "update", "load", "audio", "event", "filesystem", "font", "image", "joystick", "keyboard", "mouse", "physics", "sound", "system", "thread", "timer", "touch", "video", "window",
        "circle", "rectangle", "setColor", "clear", "print", "printf", "line", "polygon", "arc", "ellipse", "points", "newImage", "newFont", "newQuad", "newCanvas", "setCanvas", "getWidth", "getHeight", "push", "pop", "translate", "scale", "rotate", "shear",
        "isDown", "setKeyRepeat", "getPosition", "isPressed", "getFPS", "getDelta", "getTime", "sleep", "step", "vibrate", "openURL", "getOS",
        "newSource", "play", "pause", "stop", "setVolume", "getVolume", "setPitch", "getPitch", "isLooping", "setLooping",
        "newBody", "newWorld", "newFixture", "newCircleShape", "newRectangleShape", "applyForce", "applyTorque", "setGravity", "getGravity",
        "setBackgroundColor", "origin", "getDimensions", "getDPIScale", "newText", "drawLayer", "setLineWidth", "setPointSize", "getMousePosition", "setMode", "getMode"
    },

    theme = {
        bg = {0.11, 0.11, 0.11},
        sidebarBg = {0.13, 0.13, 0.13},
        tabBg = {0.14, 0.14, 0.14},
        tabActive = {0.11, 0.11, 0.11},
        accent = {0.0, 0.47, 0.8},
        gutterText = {0.35, 0.35, 0.35},
        cursor = {0.7, 0.7, 0.7},
        toolbarBg = {0.15, 0.15, 0.15},
        errorText = {0.9, 0.3, 0.3},
        plainColor = {0.85, 0.85, 0.85}
    },
    
    consoleLogs = {}, 
    autosaveTimer = 0, 
    autosaveInterval = 120, 
    sandboxActive = false, 
    sandboxError = nil,
    sandboxCallbacks = { load = nil, update = nil, draw = nil, textinput = nil, keypressed = nil }
}

local luaKeywords = {["function"]=true, ["end"]=true, ["if"]=true, ["then"]=true, ["else"]=true, ["elseif"]=true, ["for"]=true, ["while"]=true, ["return"]=true, ["local"]=true, ["break"]=true, ["true"]=true, ["false"]=true, ["nil"]=true}
local loveKeywords = {["love"]=true, ["graphics"]=true, ["draw"]=true, ["update"]=true, ["load"]=true, ["print"]=true, ["circle"]=true, ["rectangle"]=true, ["setColor"]=true, ["clear"]=true}

local History = { undoStack = {}, redoStack = {} }

function Editor.log(msg, isError)
    table.insert(Editor.consoleLogs, {text = tostring(msg), isError = isError or false})
    if #Editor.consoleLogs > 100 then 
        table.remove(Editor.consoleLogs, 1) 
    end
end

function Editor.saveState()
    local snapshot = {}
    for i, v in ipairs(Editor.lines) do 
        snapshot[i] = v 
    end
    
    table.insert(History.undoStack, {
        lines = snapshot, 
        cx = Editor.cursorX, 
        cy = Editor.cursorY
    })
    
    History.redoStack = {}
    if #History.undoStack > 40 then 
        table.remove(History.undoStack, 1) 
    end
end

function Editor.undo()
    if #History.undoStack == 0 then return end
    
    local snapshot = {}
    for i, v in ipairs(Editor.lines) do 
        snapshot[i] = v 
    end
    
    table.insert(History.redoStack, {lines = snapshot, cx = Editor.cursorX, cy = Editor.cursorY})
    
    local prev = table.remove(History.undoStack)
    Editor.lines = prev.lines
    Editor.cursorX = prev.cx
    Editor.cursorY = prev.cy
end

function Editor.redo()
    if #History.redoStack == 0 then return end
    
    local snapshot = {}
    for i, v in ipairs(Editor.lines) do 
        snapshot[i] = v 
    end
    
    table.insert(History.undoStack, {lines = snapshot, cx = Editor.cursorX, cy = Editor.cursorY})
    
    local next = table.remove(History.redoStack)
    Editor.lines = next.lines
    Editor.cursorX = next.cx
    Editor.cursorY = next.cy
end

function Editor.exportCode()
    if not love.filesystem.getInfo("saves", "directory") then 
        love.filesystem.createDirectory("saves") 
    end
    
    local files = love.filesystem.getDirectoryItems("saves")
    local name = "saves/project_" .. (#files + 1) .. ".lua"
    local code = table.concat(Editor.lines, "\n")
    
    if love.filesystem.write(name, code) then
        Editor.log("Exported: " .. name)
    else
        Editor.log("Export failed", true)
    end
    
    love.filesystem.write("saved_code.lua", code)
end

function Editor.importCode()
    if not love.filesystem.getInfo("saved_code.lua") then 
        Editor.log("No saved file.", true) 
        return 
    end
    
    local content = love.filesystem.read("saved_code.lua")
    if content then
        Editor.lines = {}
        for line in string.gmatch(content .. "\n", "(.-)\r?\n") do 
            table.insert(Editor.lines, line) 
        end
        
        Editor.cursorX = 1
        Editor.cursorY = 1
        Editor.log("Imported!", false)
    end
end

function Editor.scanLocals()
    Editor.localSymbols = {}

    for _, line in ipairs(Editor.lines) do
        for var in line:gmatch("local%s+([%w_]+)") do
            Editor.localSymbols[var] = true
        end

        for func in line:gmatch("local%s+function%s+([%w_]+)") do
            Editor.localSymbols[func] = true
        end

        for func in line:gmatch("function%s+([%w_%.:]+)") do
            local name = func:match("([%w_]+)$")
            if name then
                Editor.localSymbols[name] = true
            end
        end
    end
end

local function fuzzyMatch(word, cand)
    local i = 1
    for c in cand:gmatch(".") do
        if c:lower() == word:sub(i,i):lower() then
            i = i + 1
        end
        if i > #word then return true end
    end
    return false
end

function Editor.updateAutocomplete()
    local line = Editor.lines[Editor.cursorY] or ""
    local before = line:sub(1, Editor.cursorX - 1)
    local word = before:match("([%a_][%w_%.%:]*)$")
    
    if not word or word == "" then 
        Editor.suggestActive = false
        return 
    end
    
    if word:find("%.") then 
        word = word:match("([^%.]+)$") or "" 
    end
    
    if word == "" then 
        Editor.suggestActive = false
        return 
    end
    
    Editor.scanLocals()

    local prefix = {}
    local fuzzy = {}
    local lower = word:lower()
    
    for name in pairs(Editor.localSymbols or {}) do
        local ln = name:lower()
        if ln ~= lower and ln:find("^" .. lower) then
            table.insert(prefix, name)
        end
    end

    for _, kw in ipairs(Editor.keywords) do
        local lkw = kw:lower()
        if lkw ~= lower then
            if lkw:find("^" .. lower) then
                table.insert(prefix, kw)
            elseif fuzzyMatch(word, kw) then
                table.insert(fuzzy, kw)
            end
        end
    end

    Editor.suggestions = #prefix > 0 and prefix or fuzzy
    Editor.suggestActive = #Editor.suggestions > 0
    Editor.suggestIndex = 1
end

function Editor.acceptSuggestion()
    if not Editor.suggestActive or #Editor.suggestions == 0 then return end
    
    local line = Editor.lines[Editor.cursorY]
    local before = line:sub(1, Editor.cursorX - 1)
    local after = line:sub(Editor.cursorX)
    local word = before:match("([%a_][%w_]*)$") or ""
    local pre = before:sub(1, #before - #word)
    local chosen = Editor.suggestions[Editor.suggestIndex]
    
    Editor.lines[Editor.cursorY] = pre .. chosen .. after
    Editor.cursorX = #pre + #chosen + 1
    Editor.suggestActive = false
end

function Editor.runSandbox()
    Editor.consoleLogs = {}
    Editor.sandboxActive = false

    for k in pairs(Editor.sandboxCallbacks) do 
        Editor.sandboxCallbacks[k] = nil 
    end

    local env = {}
    for k, v in pairs(_G) do 
        env[k] = v 
    end

    env.print = function(...)
        local args = {}
        for i = 1, select("#", ...) do 
            table.insert(args, tostring(select(i, ...))) 
        end
        Editor.log(table.concat(args, "\t"), false)
    end

    env.love = {}
    for k, v in pairs(love) do 
        env.love[k] = v 
    end

    local code = table.concat(Editor.lines, "\n")
    local chunk, err = load(code, "Sandbox", "t", env)

    if not chunk then 
        Editor.log("Compile Error: " .. err, true)
        Editor.currentTab = "console"
        return 
    end

    local ok, runErr = pcall(chunk)
    if not ok then 
        Editor.log("Runtime Error: " .. runErr, true)
        Editor.currentTab = "console"
        return 
    end

    for _, hook in ipairs({"load", "update", "draw", "textinput", "keypressed"}) do
        if env.love and type(env.love[hook]) == "function" then 
            Editor.sandboxCallbacks[hook] = env.love[hook] 
        end
    end

    Editor.sandboxActive = true

    if Editor.sandboxCallbacks.load then
        local ok2, err2 = pcall(Editor.sandboxCallbacks.load)
        if not ok2 then
            Editor.log("Load Error: " .. err2, true)
        end
    end
end

function love.load()
    Editor.font = love.graphics.newFont(Editor.fontSize)
    love.graphics.setFont(Editor.font)
    Editor.charWidth = Editor.font:getWidth(" ")
    Editor.lineHeight = Editor.font:getHeight() + 4
    love.keyboard.setTextInput(true)
    Editor.scanLocals()
end

function love.update(dt)
    Editor.scrollY = Editor.scrollY + (Editor.targetScrollY - Editor.scrollY) * 18 * dt
    Editor.scrollX = Editor.scrollX + (Editor.targetScrollX - Editor.scrollX) * 18 * dt
    Editor.cursorTimer = (Editor.cursorTimer + dt) % 1.0
    
    if Editor.ignoreTextInputTimer > 0 then 
        Editor.ignoreTextInputTimer = Editor.ignoreTextInputTimer - dt 
    end
    
    Editor.autosaveTimer = Editor.autosaveTimer + dt
    if Editor.autosaveTimer >= Editor.autosaveInterval then
        Editor.autosaveTimer = 0
        love.filesystem.write("backup_code.lua", table.concat(Editor.lines, "\n"))
    end
    
    if Editor.sandboxActive and Editor.currentTab == "game" and Editor.sandboxCallbacks.update then 
        pcall(Editor.sandboxCallbacks.update, dt) 
    end
end

local function drawLine(line, x, y)
    local kw = {0.77, 0.52, 0.75, 1}
    local api = {0.31, 0.76, 1, 1}
    local str = {0.81, 0.57, 0.47, 1}
    local num = {0.71, 0.81, 0.66, 1}
    local cmt = {0.41, 0.6, 0.33, 1}
    local txt = {0.84, 0.84, 0.84, 1}
    local sym = {0.65, 0.65, 0.65, 1}
    
    if line:match("^%s*%-%-") then 
        love.graphics.setColor(cmt)
        love.graphics.print(line, x, y)
        return 
    end
    
    local i = 1
    local len = #line
    local cx = x
    
    while i <= len do
        local c = line:sub(i, i)
        
        if c == "-" and line:sub(i + 1, i + 1) == "-" then
            love.graphics.setColor(cmt)
            love.graphics.print(line:sub(i), cx, y)
            break
        elseif c == '"' or c == "'" then
            local q = c
            local start = i
            i = i + 1
            while i <= len and line:sub(i, i) ~= q do i = i + 1 end
            
            local text = line:sub(start, i)
            love.graphics.setColor(str)
            love.graphics.print(text, cx, y)
            cx = cx + Editor.font:getWidth(text)
            i = i + 1
        elseif c:match("%d") then
            local start = i
            while i <= len and line:sub(i, i):match("[%d%.]") do i = i + 1 end
            
            local text = line:sub(start, i - 1)
            love.graphics.setColor(num)
            love.graphics.print(text, cx, y)
            cx = cx + Editor.font:getWidth(text)
        elseif c:match("[%a_]") then
            local start = i
            while i <= len and line:sub(i, i):match("[%w_]") do i = i + 1 end
            
            local text = line:sub(start, i - 1)
            
            if luaKeywords[text] then 
                love.graphics.setColor(kw) 
            elseif loveKeywords[text] then 
                love.graphics.setColor(api) 
            else 
                love.graphics.setColor(txt) 
            end
            
            love.graphics.print(text, cx, y)
            cx = cx + Editor.font:getWidth(text)
        else
            if c:match("[%+%-%*%/%=<>~&|%.%(%)%{%}%[%],;]") then 
                love.graphics.setColor(sym) 
            else 
                love.graphics.setColor(txt) 
            end
            
            love.graphics.print(c, cx, y)
            cx = cx + Editor.font:getWidth(c)
            i = i + 1
        end
    end
end

function love.textinput(t)
    if Editor.currentTab ~= "code" or Editor.ignoreTextInputTimer > 0 then return end
    
    Editor.saveState()
    Editor.cursorTimer = 0
    
    local line = Editor.lines[Editor.cursorY] or ""
    local before = line:sub(1, Editor.cursorX - 1)
    local after = line:sub(Editor.cursorX)
    
    local pairs = {["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'"}
    
    if pairs[t] then
        Editor.lines[Editor.cursorY] = before .. t .. pairs[t] .. after
        Editor.cursorX = Editor.cursorX + 1
    elseif (t == ")" or t == "]" or t == "}" or t == '"' or t == "'") and after:sub(1, 1) == t then
        Editor.cursorX = Editor.cursorX + 1
    else
        Editor.lines[Editor.cursorY] = before .. t .. after
        Editor.cursorX = Editor.cursorX + 1
    end
    
    Editor.updateAutocomplete()
end

local function killSuggest()
    Editor.suggestActive = false
    Editor.suggestions = {}
    Editor.suggestIndex = 1
end

function love.keypressed(key)
    if Editor.currentTab ~= "code" then return end
    
    Editor.cursorTimer = 0
    
    if Editor.suggestActive then
        if key == "return" then
            Editor.acceptSuggestion()
            return
        elseif key == "down" then
            Editor.suggestIndex = (Editor.suggestIndex % #Editor.suggestions) + 1
            return
        elseif key == "up" then
            Editor.suggestIndex = Editor.suggestIndex - 1
            if Editor.suggestIndex < 1 then
                Editor.suggestIndex = #Editor.suggestions
            end
            return
        end
    end

    local line = Editor.lines[Editor.cursorY] or ""

    if key == "backspace" then
        Editor.ignoreTextInputTimer = 0.12

        if Editor.cursorX > 1 then
            local before = line:sub(1, Editor.cursorX - 1)
            local after = line:sub(Editor.cursorX)
            local pair = before:sub(-1) .. after:sub(1, 1)

            if pair == "()" or pair == "[]" or pair == "{}" or pair == '""' or pair == "''" then
                Editor.lines[Editor.cursorY] = before:sub(1, -2) .. after:sub(2)
            else
                Editor.lines[Editor.cursorY] = before:sub(1, -2) .. after
            end

            Editor.cursorX = Editor.cursorX - 1

        elseif Editor.cursorY > 1 then
            Editor.cursorX = #Editor.lines[Editor.cursorY - 1] + 1
            Editor.lines[Editor.cursorY - 1] = Editor.lines[Editor.cursorY - 1] .. line
            table.remove(Editor.lines, Editor.cursorY)
            Editor.cursorY = Editor.cursorY - 1
        end

    elseif key == "return" then
        local before = line:sub(1, Editor.cursorX - 1)
        local after = line:sub(Editor.cursorX)
        local indent = before:match("^(%s*)") or ""
        local trimmed = before:gsub("%s+$", "")

        local needsEnd =
            trimmed:match("^%s*function[%s%(]") or
            trimmed:match("^%s*if.+then$") or
            trimmed:match("^%s*for.+do$") or
            trimmed:match("^%s*while.+do$") or
            trimmed:match("^%s*repeat$") or
            trimmed:match("^%s*do$")

        if needsEnd then
            Editor.lines[Editor.cursorY] = before
            table.insert(Editor.lines, Editor.cursorY + 1, indent .. "    ")
            table.insert(Editor.lines, Editor.cursorY + 2, indent .. "end")
            Editor.cursorY = Editor.cursorY + 1
            Editor.cursorX = #indent + 5
        else
            Editor.lines[Editor.cursorY] = before
            table.insert(Editor.lines, Editor.cursorY + 1, indent .. after)
            Editor.cursorY = Editor.cursorY + 1
            Editor.cursorX = #indent + 1
        end
    end

    killSuggest()
    if key == "left" or key == "right" or key == "up" or key == "down" then
        killSuggest()
    end
end

function love.mousepressed(x, y, button)
    killSuggest()
    
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local rem = w - Editor.sidebarWidth
    
    if x <= Editor.sidebarWidth then
        local tab = math.floor(y / (h / 3)) + 1
        if tab == 1 then Editor.currentTab = "code"
        elseif tab == 2 then Editor.currentTab = "console"
        elseif tab == 3 then
            Editor.currentTab = "game"
            Editor.runSandbox()
        end
        return
    end
    
    if y <= Editor.tabHeight and x > Editor.sidebarWidth then
        local tabArea = rem * 0.65
        
        if x <= Editor.sidebarWidth + tabArea then
            local tw = tabArea / 3
            local tab = math.floor((x - Editor.sidebarWidth) / tw) + 1
            
            if tab == 1 then Editor.currentTab = "code"
            elseif tab == 2 then Editor.currentTab = "console"
            elseif tab == 3 then
                Editor.currentTab = "game"
                Editor.runSandbox()
            end
            return
        else
            local off = x - (Editor.sidebarWidth + tabArea)
            local tw = (rem * 0.35) / 4
            local act = math.floor(off / tw) + 1
            
            if act == 1 then Editor.undo()
            elseif act == 2 then Editor.redo()
            elseif act == 3 then Editor.exportCode()
            elseif act == 4 then Editor.importCode()
            end
            return
        end
    end
    
    Editor.isDragging = true
    Editor.lastMouseX = x
    Editor.lastMouseY = y
    
    if Editor.currentTab == "code" then
        local clickLine = math.floor((y - Editor.tabHeight - Editor.scrollY) / Editor.lineHeight) + 1
        
        if clickLine >= 1 and clickLine <= #Editor.lines then
            love.keyboard.setTextInput(true)
            Editor.cursorY = clickLine
            
            local localX = x - Editor.sidebarWidth - 45 - Editor.scrollX
            local target = 1
            local dist = math.abs(localX)
            local str = Editor.lines[Editor.cursorY] or ""
            
            for idx = 1, #str do
                local w = Editor.font:getWidth(str:sub(1, idx))
                local d = math.abs(localX - w)
                
                if d < dist then 
                    dist = d
                    target = idx + 1 
                end
            end
            
            Editor.cursorX = target
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if not Editor.isDragging then return end
    
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local rem = w - Editor.sidebarWidth
    local cH = h - Editor.tabHeight
    local tH = #Editor.lines * Editor.lineHeight
    
    if tH > cH then
        Editor.targetScrollY = math.min(0, math.max(
            -(tH - cH + 20), 
            Editor.targetScrollY + dy
        ))
    else
        Editor.targetScrollY = 0
    end
    
    local mW = 0
    for _, line in ipairs(Editor.lines) do
        local w = Editor.font:getWidth(line) + 60
        if w > mW then mW = w end
    end
    
    if mW > rem then
        Editor.targetScrollX = math.min(0, math.max(
            -(mW - rem), 
            Editor.targetScrollX + dx
        ))
    else
        Editor.targetScrollX = 0
    end
end

function love.mousereleased()
    Editor.isDragging = false
end

function love.resize()
    Editor.targetScrollY = 0
    Editor.targetScrollX = 0
end

function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    local rem = w - Editor.sidebarWidth
    local t = Editor.theme
    
    love.graphics.setColor(t.bg)
    love.graphics.rectangle("fill", Editor.sidebarWidth, Editor.tabHeight, rem, h - Editor.tabHeight)
    
    love.graphics.push("all")
    love.graphics.intersectScissor(Editor.sidebarWidth, Editor.tabHeight, rem, h - Editor.tabHeight)
    
    if Editor.currentTab == "code" then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight + Editor.scrollY)
        
        for i, line in ipairs(Editor.lines) do
            local y = (i - 1) * Editor.lineHeight
            
            if i == Editor.cursorY then
                love.graphics.setColor(0.16, 0.16, 0.16, 0.8)
                love.graphics.rectangle("fill", 0, y, rem, Editor.lineHeight)
            end
            
            love.graphics.setColor(t.gutterText)
            love.graphics.printf(tostring(i), 5, y + 2, 25, "right")
            
            love.graphics.push()
            love.graphics.translate(Editor.scrollX, 0)
            
            local ok = pcall(function() drawLine(line, 45, y + 2) end)
            
            if not ok then
                love.graphics.setColor(t.plainColor)
                love.graphics.print(line, 45, y + 2)
            end
            
            if i == Editor.cursorY and Editor.cursorTimer < 0.5 then
                love.graphics.setColor(t.cursor)
                local cx = 45 + Editor.font:getWidth(line:sub(1, Editor.cursorX - 1))
                love.graphics.rectangle("fill", cx, y + 2, 2, Editor.lineHeight - 4)
            end
            
            love.graphics.pop()
        end
        
        if Editor.suggestActive and #Editor.suggestions > 0 then
            local line = Editor.lines[Editor.cursorY] or ""
            local sx = 45 + Editor.scrollX + Editor.font:getWidth(line:sub(1, Editor.cursorX - 1))
            local sy = Editor.cursorY * Editor.lineHeight
            local sw = 140
            
            love.graphics.setColor(0.18, 0.18, 0.22, 0.95)
            love.graphics.rectangle("fill", sx, sy, sw, #Editor.suggestions * Editor.lineHeight)
            
            for i, s in ipairs(Editor.suggestions) do
                if i == Editor.suggestIndex then
                    love.graphics.setColor(0.2, 0.45, 0.8)
                    love.graphics.rectangle("fill", sx + 2, sy + (i - 1) * Editor.lineHeight + 2, sw - 4, Editor.lineHeight - 4)
                end
                
                love.graphics.setColor(0.9, 0.9, 0.9)
                love.graphics.print(s, sx + 6, sy + (i - 1) * Editor.lineHeight + 2)
            end
        end
    elseif Editor.currentTab == "console" then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight + Editor.scrollY)
        
        local y = 10
        for _, log in ipairs(Editor.consoleLogs) do
            love.graphics.setColor(log.isError and t.errorText or t.plainColor)
            love.graphics.print(log.text, 15, y)
            y = y + Editor.lineHeight
        end
    elseif Editor.currentTab == "game" and Editor.sandboxActive then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight)
        love.graphics.setColor(1, 1, 1, 1)
        pcall(Editor.sandboxCallbacks.draw)
    end
    
    love.graphics.pop()
    
    love.graphics.setColor(t.toolbarBg)
    love.graphics.rectangle("fill", Editor.sidebarWidth, 0, rem, Editor.tabHeight)
    
    local tabArea = rem * 0.65
    local tw = tabArea / 3
    local tabs = {
        {id = "code", label = "main.lua"},
        {id = "console", label = "debug.log"},
        {id = "game", label = "play.exe"}
    }
    
    for i, tab in ipairs(tabs) do
        local tx = Editor.sidebarWidth + (i - 1) * tw
        local act = Editor.currentTab == tab.id
        local col = act and t.tabActive or t.tabBg
        
        love.graphics.setColor(col, col, col)
        love.graphics.rectangle("fill", tx, 0, tw - 1, Editor.tabHeight)
        
        if act then
            love.graphics.setColor(t.accent, t.accent, t.accent)
            love.graphics.rectangle("fill", tx, 0, tw - 1, 2)
        end
        
        love.graphics.setColor(t.plainColor, t.plainColor, t.plainColor)
        love.graphics.printf(tab.label, tx, 8, tw, "center")
    end
    
    local toolStart = Editor.sidebarWidth + tabArea
    local toolW = (rem * 0.35) / 4
    local tools = {"Un", "Re", "Ex", "Im"}
    
    for i, label in ipairs(tools) do
        love.graphics.setColor(t.plainColor)
        love.graphics.printf(label, toolStart + (i - 1) * toolW, 8, toolW, "center")
    end
    
    love.graphics.setColor(t.sidebarBg)
    love.graphics.rectangle("fill", 0, 0, Editor.sidebarWidth, h)
    
    local sbH = h / 3
    local sb = {
        {id = "code", label = "[|]"},
        {id = "console", label = "[>]"},
        {id = "game", label = "|>"}
    }
    
    for i, item in ipairs(sb) do
        if Editor.currentTab == item.id then
            love.graphics.setColor(t.accent)
            love.graphics.rectangle("fill", 0, (i - 1) * sbH, 2, sbH)
        end
        
        love.graphics.setColor(t.plainColor)
        love.graphics.printf(item.label, 0, (i - 1) * sbH + (sbH / 2) - 8, Editor.sidebarWidth, "center")
    end
end
