local ui = require("./uidsl")

ui.styles = {
    body = { background = "#000", color = "#fff" },
    title = { font_size = "32px", font_weight = "bold" },
    btn = {
        padding = "10px 20px",
        background = "#007BFF",
        color = "#fff",
        border = "none",
        border_radius = "5px",
        cursor = "pointer"
    }
}

local page = ui.page {
    title = "My Lua Page",
    children = {
        ui.section {
            id = "main",
            children = {
                ui.center { id = "center-div" },
                ui.h1 { text = "Welcome to My Lua Page", class = "title", master = "center-div" },
                ui.text { text = "This is a simple page built with Lua." master = "center-div" },
                ui.button { text = "Click Me", class = "btn", on_click = "alert('Button clicked!')" master = "center-div" }
            }
        }
    }
}

ui.build("index.html", page)
