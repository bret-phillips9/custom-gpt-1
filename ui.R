# theme definition
appTheme <- bs_theme(
  version = 5,
  bootswatch = "cerulean"
)

# sidebar for user input and explain button
appSidebar <- sidebar(
  h4("Functions"),
  downloadButton("download_pdf", "📄 Save Chat to PDF")
)

# main body 
appMain <- mainPanel(
  fluidPage(
    fluidRow(
      column(12,
             includeMarkdown("instructions.md"))
    ),
    fluidRow(
      column(
        6,
        textAreaInput(inputId = "chat",
                  label = "Enter your question below.",
                  height = "400px"),
        actionButton("submit", "Submit Chat"),
        ),
        column(
          6,
          p("Chat History"),
          tags$div(
            id = "chat_window",
            style = "height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: 10px; background: #f9f9f9;",
            uiOutput("chat_ui")
          )
      )
    )
  )
)

# main page code
page_sidebar(
  title = "ChatDND: Rules Assistant for Dungeons & Dragons",
  sidebar = appSidebar,
  theme = appTheme,
  appMain
)

