server <- function(input, output, session) {
  
  # Reactive chat history
  rv <- reactiveValues(history = chat_history)
  
  output$chat_ui <- renderUI({
    msgs <- rv$history
    if (length(msgs) <= 1) return(NULL)
    
    # Exclude system message
    msgs <- msgs[-1]
    
    lapply(msgs, function(m) {
      if (m$role == "user") {
        div(style = "text-align: right; margin: 8px;",
            tags$b("You:"), br(), m$content)
      } else {
        div(style = "text-align: left; margin: 8px; background: #eef; padding: 5px; border-radius: 5px;",
            tags$b("Assistant:"), br(), m$content)
      }
    })
    
  })

    
    
  # Handle Send button
  observeEvent(input$submit, {
    req(input$chat)
    
    showModal(modalDialog(paste("Waiting for", gpt_model, "..."), footer=NULL))
    on.exit(removeModal())
    
    question <- input$chat
    updateTextAreaInput(session, "chat", value = "")
    
    # --- Append user message ---
    rv$history <- append(rv$history, list(list(role = "user", content = question)))
    
    # --- Retrieve relevant context ---
    q_emb <- get_embedding(question)
    
    rag_data$similarity <- sapply(rag_data$embedding, cosine_sim, b = q_emb)
    
    top_chunks <- rag_data |> 
      arrange(desc(similarity)) |> 
      head(3)
    
    context_text <- paste(top_chunks$chunk, collapse = "\n---\n")
    
    # --- Build messages list for API ---
    messages <- append(rv$history, list(
      list(role = "user", content = paste("Context:\n", context_text, "\n\nQuestion:", question))
    ))
    
    # --- Query model ---
    res <- POST(
      "https://api.openai.com/v1/chat/completions",
      add_headers(Authorization = paste("Bearer", api_key),
                  "Content-Type" = "application/json"),
      body = toJSON(list(
        model = "gpt-4o-mini",
        messages = messages
      ), auto_unbox = TRUE)
    )
    
    answer <- content(res, as = "parsed")$choices[[1]]$message$content
    
    # --- Append assistant response ---
    rv$history <- append(rv$history, list(list(role = "assistant", content = answer)))

 })

  # ---- Download Chat as PDF ----
  output$download_pdf <- downloadHandler(
    filename = function() {
      paste0("Chat_History_", Sys.Date(), ".pdf")
    },
    content = function(file) {
      # Convert chat history to formatted text
      msgs <- rv$history[-1]  # skip system prompt
      
      chat_text <- paste0(
        sapply(msgs, function(m) {
          if (m$role == "user") {
            paste0("You: ", m$content, "\n\n")
          } else {
            paste0("Assistant: ", m$content, "\n\n")
          }
        }),
        collapse = ""
      )
      
      # Write to a temporary markdown file
      tmp_md <- tempfile(fileext = ".Rmd")
      writeLines(c(
        "---",
        "title: \"Chat Transcript\"",
        paste0("date: \"", Sys.Date(), "\""),
        "output: pdf_document",
        "---",
        "",
        chat_text
      ), tmp_md)
      
      # Render to PDF
      rmarkdown::render(tmp_md, output_file = file, quiet = TRUE)
    }
  )

}
