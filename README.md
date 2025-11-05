# custom-gpt-1

This is a project to create a RAG chatbot reference for Dungeons & Dragons.  The 2018 Basic Rules (publicly available, so no copyright was violated) were converted into a database of embeddings.  A Shiny application was created to provide a user interface for the chatbot.  The chatbot preserves conversational context for a truly interactive chat experience, and there is a button to enable the user to preserve a transcript of the chat session as a PDF.

Note that the application depends on the presence of a file called dnd_rules_emb.rds, an R dataset that contains the embeddings generated for the 180-page 2018 Basic Rules PDF.  Due to file size (~180 MB), this dataset cannot be pushed to GitHub.  I have not decided how I want to host the file for public live app use.  In the meantime, you may grab a copy of the file from my Google Drive for your local use by using the following link: https://drive.google.com/file/d/1AvfbUk1TDE5JLg_USH1S_HYUxXGc4PWi/view?usp=sharing

