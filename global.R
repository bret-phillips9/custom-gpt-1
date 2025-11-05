# Load required libraries
library(shiny)
library(bslib)
library(dplyr)
library(httr)
library(jsonlite)
library(stringr)
library(readr)
library(rmarkdown)

# Load rules embeddings
rag_data <- readRDS("./embeddings/dnd_rules_emb.rds")

# Sys.setenv(OPENAI_API_KEY = "your_api_key_here")
# API Key set in different file (not shown here for security)
api_key <- Sys.getenv("OPENAI_API_KEY")

# --- Function to get embeddings for text ---
get_embedding <- function(text, model = "text-embedding-3-small") {
  res <- POST(
    "https://api.openai.com/v1/embeddings",
    add_headers(
      Authorization = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ),
    body = toJSON(list(model = model, input = text), auto_unbox = TRUE)
  )
  emb <- content(res, as = "parsed")$data[[1]]$embedding
  unlist(emb)
}

# --- Function to compute cosine similarity ---
cosine_sim <- function(a, b) {
  sum(a * b) / (sqrt(sum(a * a)) * sqrt(sum(b * b)))
}

# --- Initialize history ---
chat_history <- list(
  list(role = "system", content = "You are a helpful assistant that uses the Dungeons & Dragons 2018 Basic Rules information to answer questions accurately.")
)

# Set GPT model
gpt_model = "gpt-4o-mini"

# --- Function to send a new message ---
chat_with_rag <- function(question, top_k = 3) {
  # Step 1: Retrieve relevant context from RAG
  q_emb <- get_embedding(question)
  rag_data$similarity <- sapply(rag_data$embedding, cosine_sim, b = q_emb)
  
  top_chunks <- rag_data |>
    arrange(desc(similarity)) |>
    head(top_k)
  
  context_text <- paste(top_chunks$chunk, collapse = "\n---\n")
  
  # Step 2: Add this turn to chat history
  chat_history <<- append(chat_history, list(
    list(role = "user", content = paste("Context:\n", context_text, "\n\nQuestion:", question))
  ))
  
  # Step 3: Send the full conversation (system + history)
  res <- POST(
    "https://api.openai.com/v1/chat/completions",
    add_headers(
      Authorization = paste("Bearer", api_key),
      "Content-Type" = "application/json"
    ),
    body = toJSON(list(
      model = gpt_model,
      messages = chat_history
    ), auto_unbox = TRUE)
  )
  
  ans <- content(res, as = "parsed")
  answer <- ans$choices[[1]]$message$content
  
  # Step 4: Add assistant’s reply to history
  chat_history <<- append(chat_history, list(list(role = "assistant", content = answer)))
  
}