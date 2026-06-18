-- minilove2d by ribi
-- a tiny love2d editor/sandbox thing
-- if you find bugs lmk in discord i guess
-- also come say hi, i'm pretty cool

Editor = {
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

luaKeywords = {["function"]=true, ["end"]=true, ["if"]=true, ["then"]=true, ["else"]=true, ["elseif"]=true, ["for"]=true, ["while"]=true, ["return"]=true, ["local"]=true, ["break"]=true, ["true"]=true, ["false"]=true, ["nil"]=true}
loveKeywords = {["love"]=true, ["graphics"]=true, ["draw"]=true, ["update"]=true, ["load"]=true, ["print"]=true, ["circle"]=true, ["rectangle"]=true, ["setColor"]=true, ["clear"]=true}

function Editor.log(msg, isError)
    table.insert(Editor.consoleLogs, {text = tostring(msg), isError = isError or false})
    -- clear old logs so we don't explode memory
    if #Editor.consoleLogs > 100 then 
        table.remove(Editor.consoleLogs, 1) 
    end
end

History = { undoStack = {}, redoStack = {} }

function Editor.saveState()
    -- snapshot the current state for undo
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
    if #History.undoStack == 0 then 
        return 
    end
    
    -- save current state to redo stack
    local snapshot = {}
    for i, v in ipairs(Editor.lines) do 
        snapshot[i] = v 
    end
    
    table.insert(History.redoStack, {
        lines = snapshot, 
        cx = Editor.cursorX, 
        cy = Editor.cursorY
    })
    
    local prev = table.remove(History.undoStack)
    Editor.lines = prev.lines
    Editor.cursorX = prev.cx
    Editor.cursorY = prev.cy
end

function Editor.redo()
    if #History.redoStack == 0 then 
        return 
    end
    
    -- move current to undo
    local snapshot = {}
    for i, v in ipairs(Editor.lines) do 
        snapshot[i] = v 
    end
    
    table.insert(History.undoStack, {
        lines = snapshot, 
        cx = Editor.cursorX, 
        cy = Editor.cursorY
    })
    
    local nextState = table.remove(History.redoStack)
    Editor.lines = nextState.lines
    Editor.cursorX = nextState.cx
    Editor.cursorY = nextState.cy
end

function Editor.exportCode()
    if not love.filesystem.getInfo("saves", "directory") then 
        love.filesystem.createDirectory("saves") 
    end
    
    local files = love.filesystem.getDirectoryItems("saves")
    local newFileName = "saves/project_" .. (#files + 1) .. ".lua"
    local fullText = table.concat(Editor.lines, "\n")
    
    local success, err = love.filesystem.write(newFileName, fullText)
    if success then
        Editor.log("Exported: " .. newFileName)
    else
        Editor.log("Export error: " .. tostring(err), true)
    end
    
    -- also write to main save file
    love.filesystem.write("saved_code.lua", fullText)
end

function Editor.importCode()
    if not love.filesystem.getInfo("saved_code.lua") then 
        Editor.log("No saved file found.", true) 
        return 
    end
    
    local content = love.filesystem.read("saved_code.lua")
    if content then
        Editor.lines = {}
        -- split by lines (handle different line endings)
        for line in string.gmatch(content .. "\n", "(.-)\r?\n") do 
            table.insert(Editor.lines, line) 
        end
        
        Editor.cursorX = 1
        Editor.cursorY = 1
        Editor.log("Code imported successfully.", false)
    end
end

function Editor.scanLocals()
    -- look through all lines and find local vars + functions
    Editor.localSymbols = {}

    for _, line in ipairs(Editor.lines) do
        -- match: local foo
        for var in line:gmatch("local%s+([%w_]+)") do
            Editor.localSymbols[var] = true
        end

        -- match: local function foo()
        for func in line:gmatch("local%s+function%s+([%w_]+)") do
            Editor.localSymbols[func] = true
        end

        -- match: function foo()
        for func in line:gmatch("function%s+([%w_%.:]+)") do
            local name = func:match("([%w_]+)$")
            if name then
                Editor.localSymbols[name] = true
            end
        end
    end
end

function Editor.updateAutocomplete()
    local currentLine = Editor.lines[Editor.cursorY] or ""
    local textBeforeCursor = currentLine:sub(1, Editor.cursorX - 1)
    local lastWord = textBeforeCursor:match("([%a_][%w_%.%:]*)$")
    
    if not lastWord or lastWord == "" then 
        Editor.suggestActive = false
        return 
    end
    
    -- if it has a dot, just get the part after it
    if lastWord:find("%.") then 
        lastWord = lastWord:match("([^%.]+)$") or "" 
    end
    
    if lastWord == "" then 
        Editor.suggestActive = false
        return 
    end
    
    local suggestions = {}
    local queryLower = lastWord:lower()
    
    -- check built-in keywords
    for _, keyword in ipairs(Editor.keywords) do
        if keyword:lower():sub(1, #queryLower) == queryLower and keyword ~= lastWord then
            table.insert(suggestions, keyword)
        end
    end
    
    -- check local symbols
    for symbol, _ in pairs(Editor.localSymbols or {}) do
        if symbol:lower():sub(1, #queryLower) == queryLower and symbol ~= lastWord then
            table.insert(suggestions, symbol)
        end
    end
    
    if #suggestions > 0 then
        Editor.suggestions = suggestions
        Editor.suggestActive = true
        Editor.suggestIndex = math.min(Editor.suggestIndex, #suggestions)
    else
        Editor.suggestActive = false
    end
end

function Editor.acceptSuggestion()
    if not Editor.suggestActive or #Editor.suggestions == 0 then 
        return 
    end
    
    local currentLine = Editor.lines[Editor.cursorY]
    local textBeforeCursor = currentLine:sub(1, Editor.cursorX - 1)
    local textAfterCursor = currentLine:sub(Editor.cursorX)
    local lastWord = textBeforeCursor:match("([%a_][%w_]*)$") or ""
    local prefix = textBeforeCursor:sub(1, #textBeforeCursor - #lastWord)
    local chosen = Editor.suggestions[Editor.suggestIndex]
    
    Editor.lines[Editor.cursorY] = prefix .. chosen .. textAfterCursor
    Editor.cursorX = #prefix + #chosen + 1
    Editor.suggestActive = false
end

function Editor.runSandbox()
    -- reset everything before running
    Debug.log = {}
    Editor.consoleLogs = {}

    Editor.sandboxActive = false
    Editor.sandboxError = nil

    for k in pairs(Editor.sandboxCallbacks) do 
        Editor.sandboxCallbacks[k] = nil 
    end

    -- create sandbox env
    local env = {}
    for k, v in pairs(_G) do 
        env[k] = v 
    end

    -- override print so it goes to console
    env.print = function(...)
        local output = {}
        for i = 1, select("#", ...) do 
            table.insert(output, tostring(select(i, ...))) 
        end
        Editor.log(table.concat(output, "	"), false)
    end

    env.love = {}
    for k, v in pairs(love) do 
        env.love[k] = v 
    end

    local chunk, err = load(table.concat(Editor.lines, "\n"), "Sandbox", "t", env)

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

    -- grab the callbacks the user defined
    for _, hook in ipairs({"load", "update", "draw", "textinput", "keypressed"}) do
        if env.love and type(env.love[hook]) == "function" then 
            Editor.sandboxCallbacks[hook] = env.love[hook] 
        end
    end

    Editor.sandboxActive = true

    -- call load if they defined it
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
    -- smooth scrolling
    Editor.scrollY = Editor.scrollY + (Editor.targetScrollY - Editor.scrollY) * 18 * dt
    Editor.scrollX = Editor.scrollX + (Editor.targetScrollX - Editor.scrollX) * 18 * dt
    Editor.cursorTimer = (Editor.cursorTimer + dt) % 1.0
    
    if Editor.ignoreTextInputTimer > 0 then 
        Editor.ignoreTextInputTimer = Editor.ignoreTextInputTimer - dt 
    end
    
    -- autosave every 2 mins or so
    Editor.autosaveTimer = Editor.autosaveTimer + dt
    if Editor.autosaveTimer >= Editor.autosaveInterval then
        Editor.autosaveTimer = 0
        love.filesystem.write("backup_code.lua", table.concat(Editor.lines, "\n"))
    end
    
    -- update sandbox if game tab is active
    if Editor.sandboxActive and Editor.currentTab == "game" and Editor.sandboxCallbacks.update then 
        pcall(Editor.sandboxCallbacks.update, dt) 
    end
end

local function parseAndDrawLine(line, startX, startY)
    -- syntax highlighting colors
    local kwColor = {0.77, 0.52, 0.75, 1}
    local apiColor = {0.31, 0.76, 1, 1}
    local stringColor = {0.81, 0.57, 0.47, 1}
    local numberColor = {0.71, 0.81, 0.66, 1}
    local commentColor = {0.41, 0.6, 0.33, 1}
    local textColor = {0.84, 0.84, 0.84, 1}
    local symbolColor = {0.65, 0.65, 0.65, 1}
    
    -- if it's a full line comment, just highlight it all
    if line:match("^%s*%-%-") then 
        love.graphics.setColor(commentColor)
        love.graphics.print(line, startX, startY)
        return 
    end
    
    local i = 1
    local len = #line
    local curX = startX
    
    while i <= len do
        local char = line:sub(i, i)
        
        -- inline comment
        if char == "-" and line:sub(i + 1, i + 1) == "-" then
            love.graphics.setColor(commentColor)
            love.graphics.print(line:sub(i), curX, startY)
            break
        -- strings
        elseif char == '"' or char == "'" then
            local quote = char
            local startPos = i
            i = i + 1
            
            while i <= len and line:sub(i, i) ~= quote do 
                i = i + 1 
            end
            
            local text = line:sub(startPos, i)
            love.graphics.setColor(stringColor)
            love.graphics.print(text, curX, startY)
            curX = curX + Editor.font:getWidth(text)
            i = i + 1
        -- numbers
        elseif char:match("%d") then
            local startPos = i
            
            while i <= len and line:sub(i, i):match("[%d%.]") do 
                i = i + 1 
            end
            
            local text = line:sub(startPos, i - 1)
            love.graphics.setColor(numberColor)
            love.graphics.print(text, curX, startY)
            curX = curX + Editor.font:getWidth(text)
        -- identifiers / keywords
        elseif char:match("[%a_]") then
            local startPos = i
            
            while i <= len and line:sub(i, i):match("[%w_]") do 
                i = i + 1 
            end
            
            local text = line:sub(startPos, i - 1)
            
            if luaKeywords[text] then 
                love.graphics.setColor(kwColor) 
            elseif loveKeywords[text] then 
                love.graphics.setColor(apiColor) 
            else 
                love.graphics.setColor(textColor) 
            end
            
            love.graphics.print(text, curX, startY)
            curX = curX + Editor.font:getWidth(text)
        -- everything else
        else
            if char:match("[%+%-%*%/%=<>~&|%.%(%)%{%}%[%],;]") then 
                love.graphics.setColor(symbolColor) 
            else 
                love.graphics.setColor(textColor) 
            end
            
            love.graphics.print(char, curX, startY)
            curX = curX + Editor.font:getWidth(char)
            i = i + 1
        end
    end
end

function love.textinput(t)
    if Editor.currentTab ~= "code" or Editor.ignoreTextInputTimer > 0 then 
        return 
    end
    
    Editor.saveState()
    Editor.cursorTimer = 0
    
    local line = Editor.lines[Editor.cursorY] or ""
    local before = line:sub(1, Editor.cursorX - 1)
    local after = line:sub(Editor.cursorX)
    
    -- auto-pair brackets
    local pairsMap = {
        ["("] = ")",
        ["["] = "]",
        ["{"] = "}",
        ['"'] = '"',
        ["'"] = "'"
    }
    
    if pairsMap[t] then
        Editor.lines[Editor.cursorY] = before .. t .. pairsMap[t] .. after
        Editor.cursorX = Editor.cursorX + 1
    elseif (t == ")" or t == "]" or t == "}" or t == '"' or t == "'") and after:sub(1, 1) == t then
        -- skip closing bracket if one's already there
        Editor.cursorX = Editor.cursorX + 1
    else
        Editor.lines[Editor.cursorY] = before .. t .. after
        Editor.cursorX = Editor.cursorX + 1
    end
    
    Editor.updateAutocomplete()
end

function love.keypressed(key)
    if Editor.currentTab ~= "code" then 
        return 
    end
    
    Editor.cursorTimer = 0
    
    -- handle autocomplete menu
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

            -- delete matched pair
            if pair == "()" or pair == "[]" or pair == "{}" or pair == '""' or pair == "''" then
                Editor.lines[Editor.cursorY] = before:sub(1, -2) .. after:sub(2)
            else
                Editor.lines[Editor.cursorY] = before:sub(1, -2) .. after
            end

            Editor.cursorX = Editor.cursorX - 1

        elseif Editor.cursorY > 1 then
            -- merge with previous line
            Editor.cursorX = #Editor.lines[Editor.cursorY - 1] + 1
            Editor.lines[Editor.cursorY - 1] = Editor.lines[Editor.cursorY - 1] .. line
            table.remove(Editor.lines, Editor.cursorY)
            Editor.cursorY = Editor.cursorY - 1
        end

    elseif key == "return" then
        local before = line:sub(1, Editor.cursorX - 1)
        local after = line:sub(Editor.cursorX)
        local spaces = before:match("^(%s*)") or ""
        local trimmed = before:gsub("%s+$", "")

        -- check if this line opens a block
        local opensBlock =
            trimmed:match("^%s*function[%s%(]") or
            trimmed:match("^%s*if.+then$") or
            trimmed:match("^%s*for.+do$") or
            trimmed:match("^%s*while.+do$") or
            trimmed:match("^%s*repeat$") or
            trimmed:match("^%s*do$")

        if opensBlock then
            -- insert auto-indented block
            Editor.lines[Editor.cursorY] = before
            table.insert(Editor.lines, Editor.cursorY + 1, spaces .. "    ")
            table.insert(Editor.lines, Editor.cursorY + 2, spaces .. "end")
            Editor.cursorY = Editor.cursorY + 1
            Editor.cursorX = #spaces + 5
        else
            Editor.lines[Editor.cursorY] = before
            table.insert(Editor.lines, Editor.cursorY + 1, spaces .. after)
            Editor.cursorY = Editor.cursorY + 1
            Editor.cursorX = #spaces + 1
        end
    end

    Editor.updateAutocomplete()
end

function love.mousepressed(x, y, button)
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local remainingWidth = winW - Editor.sidebarWidth
    
    -- sidebar tab clicks
    if x <= Editor.sidebarWidth then
        local tabIndex = math.floor(y / (winH / 3)) + 1
        if tabIndex == 1 then 
            Editor.currentTab = "code" 
        elseif tabIndex == 2 then 
            Editor.currentTab = "console" 
        elseif tabIndex == 3 then 
            Editor.currentTab = "game"
            Editor.runSandbox() 
        end
        return
    end
    
    -- toolbar area
    if y <= Editor.tabHeight and x > Editor.sidebarWidth then
        if Editor.suggestActive and #Editor.suggestions > 0 then 
            Editor.suggestActive = false 
        end
        
        local tabAreaWidth = remainingWidth * 0.65
        
        -- tab clicks
        if x <= Editor.sidebarWidth + tabAreaWidth then
            local tabWidth = tabAreaWidth / 3
            local clickedTab = math.floor((x - Editor.sidebarWidth) / tabWidth) + 1
            
            if clickedTab == 1 then 
                Editor.currentTab = "code" 
            elseif clickedTab == 2 then 
                Editor.currentTab = "console" 
            elseif clickedTab == 3 then 
                Editor.currentTab = "game"
                Editor.runSandbox() 
            end
            return
        else
            -- tool buttons (undo, redo, export, import)
            local rightOffset = x - (Editor.sidebarWidth + tabAreaWidth)
            local toolWidth = (remainingWidth * 0.35) / 4
            local actionIndex = math.floor(rightOffset / toolWidth) + 1
            
            if actionIndex == 1 then 
                Editor.undo() 
            elseif actionIndex == 2 then 
                Editor.redo() 
            elseif actionIndex == 3 then 
                Editor.exportCode() 
            elseif actionIndex == 4 then 
                Editor.importCode() 
            end
            return
        end
    end
    
    Editor.isDragging = true
    Editor.lastMouseX = x
    Editor.lastMouseY = y
    
    -- handle code editor clicks
    if Editor.currentTab == "code" then
        local clickLine = math.floor((y - Editor.tabHeight - Editor.scrollY) / Editor.lineHeight) + 1
        
        if clickLine >= 1 and clickLine <= #Editor.lines then
            love.keyboard.setTextInput(true)
            Editor.cursorY = clickLine
            
            -- find cursor position from x coordinate
            local localX = x - Editor.sidebarWidth - 45 - Editor.scrollX
            local targetIndex = 1
            local bestDistance = math.abs(localX)
            local currentLineStr = Editor.lines[Editor.cursorY] or ""
            
            for charIndex = 1, #currentLineStr do
                local substringWidth = Editor.font:getWidth(currentLineStr:sub(1, charIndex))
                local distance = math.abs(localX - substringWidth)
                
                if distance < bestDistance then 
                    bestDistance = distance
                    targetIndex = charIndex + 1 
                end
            end
            
            Editor.cursorX = targetIndex
        end
    end
end

function love.mousemoved(x, y, dx, dy)
    if not Editor.isDragging then 
        return 
    end
    
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local remainingWidth = winW - Editor.sidebarWidth
    local remainingHeight = winH - Editor.tabHeight
    local totalContentHeight = #Editor.lines * Editor.lineHeight
    
    -- vertical scroll
    if totalContentHeight > remainingHeight then
        Editor.targetScrollY = math.min(0, math.max(
            -(totalContentHeight - remainingHeight + 20), 
            Editor.targetScrollY + dy
        ))
    else
        Editor.targetScrollY = 0
    end
    
    -- horizontal scroll
    local maxLineWidth = 0
    for _, line in ipairs(Editor.lines) do
        local width = Editor.font:getWidth(line) + 60
        if width > maxLineWidth then 
            maxLineWidth = width 
        end
    end
    
    if maxLineWidth > remainingWidth then
        Editor.targetScrollX = math.min(0, math.max(
            -(maxLineWidth - remainingWidth), 
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
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local remainingWidth = winW - Editor.sidebarWidth
    local theme = Editor.theme
    
    -- main background
    love.graphics.setColor(theme.bg)
    love.graphics.rectangle("fill", Editor.sidebarWidth, Editor.tabHeight, remainingWidth, winH - Editor.tabHeight)
    
    love.graphics.push("all")
    love.graphics.intersectScissor(Editor.sidebarWidth, Editor.tabHeight, remainingWidth, winH - Editor.tabHeight)
    
    if Editor.currentTab == "code" then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight + Editor.scrollY)
        
        for i, line in ipairs(Editor.lines) do
            local y = (i - 1) * Editor.lineHeight
            
            -- highlight current line
            if i == Editor.cursorY then
                love.graphics.setColor(0.16, 0.16, 0.16, 0.8)
                love.graphics.rectangle("fill", 0, y, remainingWidth, Editor.lineHeight)
            end
            
            -- line numbers
            love.graphics.setColor(theme.gutterText)
            love.graphics.printf(tostring(i), 5, y + 2, 25, "right")
            
            love.graphics.push()
            love.graphics.translate(Editor.scrollX, 0)
            
            -- draw the code with syntax highlighting
            local status, err = pcall(function() 
                parseAndDrawLine(line, 45, y + 2) 
            end)
            
            if not status then
                -- fallback if syntax highlighting breaks
                love.graphics.setColor(theme.plainColor)
                love.graphics.print(line, 45, y + 2)
            end
            
            -- draw cursor
            if i == Editor.cursorY and Editor.cursorTimer < 0.5 then
                love.graphics.setColor(theme.cursor)
                local cursorX = 45 + Editor.font:getWidth(line:sub(1, Editor.cursorX - 1))
                love.graphics.rectangle("fill", cursorX, y + 2, 2, Editor.lineHeight - 4)
            end
            
            love.graphics.pop()
        end
        
        -- autocomplete dropdown
        if Editor.suggestActive and #Editor.suggestions > 0 then
            local currentLine = Editor.lines[Editor.cursorY] or ""
            local suggestionX = 45 + Editor.scrollX + Editor.font:getWidth(currentLine:sub(1, Editor.cursorX - 1))
            local suggestionY = Editor.cursorY * Editor.lineHeight
            local suggestionWidth = 140
            
            love.graphics.setColor(0.18, 0.18, 0.22, 0.95)
            love.graphics.rectangle("fill", suggestionX, suggestionY, suggestionWidth, #Editor.suggestions * Editor.lineHeight)
            
            for idx, suggestion in ipairs(Editor.suggestions) do
                if idx == Editor.suggestIndex then
                    love.graphics.setColor(0.2, 0.45, 0.8)
                    love.graphics.rectangle("fill", suggestionX + 2, suggestionY + (idx - 1) * Editor.lineHeight + 2, suggestionWidth - 4, Editor.lineHeight - 4)
                end
                
                love.graphics.setColor(0.9, 0.9, 0.9)
                love.graphics.print(suggestion, suggestionX + 6, suggestionY + (idx - 1) * Editor.lineHeight + 2)
            end
        end
    elseif Editor.currentTab == "console" then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight + Editor.scrollY)
        
        local y = 10
        for _, log in ipairs(Editor.consoleLogs) do
            love.graphics.setColor(log.isError and theme.errorText or theme.plainColor)
            love.graphics.print(log.text, 15, y)
            y = y + Editor.lineHeight
        end
    elseif Editor.currentTab == "game" and Editor.sandboxActive then
        love.graphics.translate(Editor.sidebarWidth, Editor.tabHeight)
        love.graphics.setColor(1, 1, 1, 1)
        pcall(Editor.sandboxCallbacks.draw)
    end
    
    love.graphics.pop()
    
    -- draw toolbar
    love.graphics.setColor(theme.toolbarBg)
    love.graphics.rectangle("fill", Editor.sidebarWidth, 0, remainingWidth, Editor.tabHeight)
    
    local tabAreaWidth = remainingWidth * 0.65
    local tabWidth = tabAreaWidth / 3
    local tabs = {
        {id = "code", label = "main.lua"},
        {id = "console", label = "debug.log"},
        {id = "game", label = "play.exe"}
    }
    
    for i, tabInfo in ipairs(tabs) do
        local tx = Editor.sidebarWidth + (i - 1) * tabWidth
        local isActive = Editor.currentTab == tabInfo.id
        local tabColor = isActive and theme.tabActive or theme.tabBg
        
        love.graphics.setColor(tabColor, tabColor, tabColor)
        love.graphics.rectangle("fill", tx, 0, tabWidth - 1, Editor.tabHeight)
        
        if isActive then
            love.graphics.setColor(theme.accent, theme.accent, theme.accent)
            love.graphics.rectangle("fill", tx, 0, tabWidth - 1, 2)
        end
        
        love.graphics.setColor(theme.plainColor, theme.plainColor, theme.plainColor)
        love.graphics.printf(tabInfo.label, tx, 8, tabWidth, "center")
    end
    
    -- tool buttons (Un/Re/Ex/Im)
    local toolsStartX = Editor.sidebarWidth + tabAreaWidth
    local toolWidth = (remainingWidth * 0.35) / 4
    local toolLabels = {"Un", "Re", "Ex", "Im"}
    
    for i, label in ipairs(toolLabels) do
        love.graphics.setColor(theme.plainColor)
        love.graphics.printf(label, toolsStartX + (i - 1) * toolWidth, 8, toolWidth, "center")
    end
    
    -- draw sidebar
    love.graphics.setColor(theme.sidebarBg)
    love.graphics.rectangle("fill", 0, 0, Editor.sidebarWidth, winH)
    
    local sidebarHeight = winH / 3
    local sidebarLabels = {
        {id = "code", label = "[|]"},
        {id = "console", label = "[>]"},
        {id = "game", label = "|>"}
    }
    
    for i, sidebarInfo in ipairs(sidebarLabels) do
        if Editor.currentTab == sidebarInfo.id then
            love.graphics.setColor(theme.accent)
            love.graphics.rectangle("fill", 0, (i - 1) * sidebarHeight, 2, sidebarHeight)
        end
        
        love.graphics.setColor(theme.plainColor)
        love.graphics.printf(sidebarInfo.label, 0, (i - 1) * sidebarHeight + (sidebarHeight / 2) - 8, Editor.sidebarWidth, "center")
    end
end
