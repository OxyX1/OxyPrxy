-- uidsl.lua (fixed recursive rendering)

local ui = {}
ui.styles = {}
local registry = {}

-- utils -----------------------

local function cssKey(key)
    return key:gsub("_", "-")
end

local function tableToCss(tbl)
    local css = {}
    for k, v in pairs(tbl) do
        table.insert(css, cssKey(k) .. ":" .. v .. ";")
    end
    return table.concat(css, "")
end

local function buildStyles()
    local css = {}
    for class, rules in pairs(ui.styles) do
        table.insert(css, "." .. class .. " {" .. tableToCss(rules) .. "}")
    end
    return table.concat(css, "\n")
end

-- recursive render -----------------------

local function renderChildren(children, indent)
    indent = indent or "  "
    local lines = {}
    for _, child in ipairs(children or {}) do
        if type(child) == "table" then
            table.insert(lines, indent .. child)
        elseif type(child) == "string" and child ~= "" then
            table.insert(lines, indent .. child)
        end
    end
    return table.concat(lines, "\n")
end

local function formatHtml(tag, opts, void, indent)
    indent = indent or ""
    local id    = opts.id and (' id="'..opts.id..'"') or ""
    local class = opts.class and (' class="'..opts.class..'"') or ""
    local style = opts.style and (' style="'..tableToCss(opts.style)..'"') or ""
    local attrs = opts.on_click and (' onclick="'..opts.on_click..'"') or ""

    if void then
        return indent .. string.format("<%s%s%s%s%s />", tag, id, class, style, attrs)
    else
        local text = opts.text or ""
        local children = renderChildren(opts.children, indent .. "  ")
        if children ~= "" then children = "\n" .. children .. "\n" .. indent end
        return indent .. string.format("<%s%s%s%s%s>%s%s</%s>", tag, id, class, style, attrs, text, children, tag)
    end
end

-- master injection -----------------------

local function registerElement(id, html)
    registry[id] = registry[id] or { html = "", children = {} }
    registry[id].html = html
end

local function attachToMaster(master, html)
    registry[master] = registry[master] or { html = "", children = {} }
    table.insert(registry[master].children, html)
end

local function resolveMasters(body)
    for id, data in pairs(registry) do
        if #data.children > 0 and data.html ~= "" then
            local childStr = table.concat(data.children, "\n")
            data.html = data.html:gsub("</%w+>$", childStr .. "\n%1")
        end
    end
    return body
end

-- elements -----------------------

local function element(tag, opts)
    local html = formatHtml(tag, opts, false)
    if opts.id then registerElement(opts.id, html) end
    if opts.master then attachToMaster(opts.master, html) return "" end
    return html
end

local function voidElement(tag, opts)
    local html = formatHtml(tag, opts, true)
    if opts.master then attachToMaster(opts.master, html) return "" end
    return html
end

function ui.h1(opts) return element("h1", opts) end
function ui.text(opts) return element("p", opts) end
function ui.button(opts) return element("button", opts) end
function ui.input(opts) return voidElement("input", opts) end
function ui.img(opts) return voidElement("img", opts) end

function ui.div(opts) return formatHtml("div", opts, false) end
function ui.section(opts) return formatHtml("section", opts, false) end
function ui.center(opts) 
    opts.class = (opts.class or "") .. " center"
    return formatHtml("div", opts, false)
end

-- page wrapper -----------------------

function ui.page(opts)
    local body = renderChildren(opts.children, "  ")
    body = resolveMasters(body)
    return [[
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>]]..(opts.title or "Lua UI Page")..[[</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
]]..body..[[
</body>
</html>
]]
end

-- build -----------------------

function ui.build(filename, html)
    local f = assert(io.open(filename or "index.html", "w"))
    f:write(html)
    f:close()

    local css = buildStyles()
    local s = assert(io.open("style.css", "w"))
    s:write(css)
    s:close()

    print("✅ Built " .. (filename or "index.html") .. " + style.css")
end

return ui
