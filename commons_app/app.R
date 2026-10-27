# ADSL Review -- {commons} chat app (CDISCPILOT01)
# Run from the project root: shiny::runApp("commons_app")

root <- if (dir.exists("trusted")) "." else ".."

adam <- commons::data_source(
  adsl = readRDS(file.path(root, "data/adsl.rds")),
  adsl_ref = readRDS(file.path(root, "data/adsl_ref.rds")),
  dictionary = file.path(root, "commons_app/dictionaries/adam.yaml")
)

build_agent <- function() {
  commons::commons(
    client = ellmer::chat_aws_bedrock(
      model = getOption("adsl_review.model", "us.anthropic.claude-sonnet-4-6"),
      echo = "none"
    ),
    data_sources = list(adam = adam),
    semantic_layer = commons::semantic_layer(file.path(root, "trusted")),
    context_layer = commons::context_layer(
      list.files(file.path(root, "commons_app/context"), pattern = "[.]md$", full.names = TRUE)
    ),
    instructions = file.path(root, "commons_app/instructions.md")
  )
}

greeting <- paste(
  "Ask me about the ADSL converted from SAS to R.",
  "Answers that run approved company code show a **green shield**.",
  "",
  "* <span class=\"suggestion\">How many subjects are in the safety population by treatment?</span>",
  "* <span class=\"suggestion\">Which subjects differ from the reference ADSL on TRTEDT?</span>",
  "* <span class=\"suggestion\">What is the median age of women in the high dose arm?</span>",
  sep = "\n"
)

ui <- shinychat::page_chat(
  "ADSL Review -- CDISCPILOT01 (SAS to R conversion)",
  id = "chat",
  greeting = greeting,
  theme = commons::commons_theme()
)

server <- function(input, output, session) {
  commons::commons_server("chat", build_agent())
}

shiny::shinyApp(ui, server)
