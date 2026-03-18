library(shiny)
library(bslib)
library(ellmer)
library(shinychat)
library(httr2)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
API_BASE <- Sys.getenv("LUXJOB_API_URL", "http://localhost:8080")

SYSTEM_PROMPT <- paste(
  "You are a helpful Luxembourg job-market assistant.",
  "You help users explore job vacancies, companies, skills,",
  "learning tracks and book recommendations available in Luxembourg.",
  "Use the tools provided to look up real data — never invent job listings.",
  "When presenting results, use proper markdown formatting:",
  "use `- ` (dash + space) for bullet lists with each item on its own line,",
  "use markdown tables when comparing items, and use **bold** for job titles.",
  "NEVER use the bullet character (U+2022). Always use markdown dash lists.",
  "If a query returns no results, say so and suggest broadening the search.",
  "Always reply in the same language the user writes in."
)

# ---------------------------------------------------------------------------
# Helper: call the Plumber API
# ---------------------------------------------------------------------------
api_get <- function(path, query = list()) {
  query <- Filter(Negate(is.null), query)
  resp <- request(API_BASE) |>
    req_url_path_append(path) |>
    req_url_query(!!!query) |>
    req_perform()
  resp_body_json(resp)
}

# ---------------------------------------------------------------------------
# Tool definitions
# ---------------------------------------------------------------------------
tool_search_vacancies <- tool(
  function(skill = NULL, company = NULL, canton = NULL, limit = 20) {
    api_get("/vacancies", list(
      skill   = skill,
      company = company,
      canton  = canton,
      limit   = limit
    ))
  },
  name = "search_vacancies",
  description = paste(
    "Search for job vacancies in Luxembourg.",
    "Can filter by skill ID, company ID, and/or canton name.",
    "Returns a list of matching vacancies with job title, company, location, etc."
  ),
  arguments = list(
    skill   = type_string("ESCO skill URI to filter by (e.g. 'http://data.europa.eu/esco/skill/...')", required = FALSE),
    company = type_integer("Company ID to filter by", required = FALSE),
    canton  = type_string("Canton name to filter by (e.g. 'Luxembourg', 'Esch-sur-Alzette')", required = FALSE),
    limit   = type_integer("Max results to return (default 20)", required = FALSE)
  )
)

tool_get_skills <- tool(
  function(limit = 50) {
    api_get("/skills", list(limit = limit))
  },
  name = "get_skills",
  description = "List available skills. Useful for discovering skill IDs to use in vacancy searches.",
  arguments = list(
    limit = type_integer("Max number of skills to return (default 50)", required = FALSE)
  )
)

tool_get_skill_by_id <- tool(
  function(skill_id) {
    api_get(paste0("/skills/", URLencode(skill_id, reserved = TRUE)))
  },
  name = "get_skill_by_id",
  description = "Get details for a specific skill by its ESCO URI.",
  arguments = list(
    skill_id = type_string("The ESCO skill URI")
  )
)

tool_get_companies <- tool(
  function(limit = 50) {
    api_get("/companies", list(limit = limit))
  },
  name = "get_companies",
  description = "List companies that have job vacancies in Luxembourg.",
  arguments = list(
    limit = type_integer("Max number of companies to return (default 50)", required = FALSE)
  )
)

tool_get_company_details <- tool(
  function(company_id) {
    api_get(paste0("/companies/", company_id))
  },
  name = "get_company_details",
  description = "Get detailed information about a specific company.",
  arguments = list(
    company_id = type_integer("The company ID")
  )
)

tool_get_vacancy_details <- tool(
  function(vacancy_id) {
    api_get(paste0("/vacancies/", vacancy_id))
  },
  name = "get_vacancy_details",
  description = "Get full details of a specific job vacancy.",
  arguments = list(
    vacancy_id = type_integer("The vacancy ID")
  )
)

tool_get_learning_tracks <- tool(
  function(skill_id = NULL) {
    api_get("/learning_tracks", list(skill_id = skill_id))
  },
  name = "get_learning_tracks",
  description = "Get learning tracks (training / upskilling paths). Optionally filter by skill.",
  arguments = list(
    skill_id = type_string("ESCO skill URI to filter by", required = FALSE)
  )
)

tool_get_learning_track_by_id <- tool(
  function(track_id) {
    api_get(paste0("/learning_tracks/", track_id))
  },
  name = "get_learning_track_by_id",
  description = "Get details of a specific learning track.",
  arguments = list(
    track_id = type_integer("The learning track ID")
  )
)

tool_get_books <- tool(
  function(skill = NULL) {
    api_get("/books", list(skill = skill))
  },
  name = "get_books",
  description = "Get book recommendations, optionally filtered by skill.",
  arguments = list(
    skill = type_string("ESCO skill URI to filter by", required = FALSE)
  )
)

tool_get_book_by_id <- tool(
  function(book_id) {
    api_get(paste0("/books/", book_id))
  },
  name = "get_book_by_id",
  description = "Get details of a specific book.",
  arguments = list(
    book_id = type_integer("The book ID")
  )
)

ALL_TOOLS <- list(
  tool_search_vacancies,
  tool_get_skills,
  tool_get_skill_by_id,
  tool_get_companies,
  tool_get_company_details,
  tool_get_vacancy_details,
  tool_get_learning_tracks,
  tool_get_learning_track_by_id,
  tool_get_books,
  tool_get_book_by_id
)

# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------
ui <- page_fillable(
  title = "luxJob Agent",
  theme = bs_theme(
    version = 5,
    preset = "shiny",
    primary = "#6C63FF",
    secondary = "#44D7B6",
    success = "#44D7B6",
    "font-size-base" = "0.95rem",
    "border-radius" = "0.75rem",
    "card-border-radius" = "0.75rem"
  ),
  padding = 0,

  tags$head(tags$style(HTML("
    .navbar-brand-container {
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .sidebar-content {
      display: flex;
      flex-direction: column;
      height: 100%;
    }
    .sidebar-footer {
      margin-top: auto;
      padding-top: 1rem;
    }
    .feature-item {
      display: flex;
      align-items: flex-start;
      gap: 0.6rem;
      margin-bottom: 0.75rem;
    }
    .feature-icon {
      font-size: 1.15rem;
      line-height: 1.5;
      flex-shrink: 0;
      opacity: 0.8;
    }
    .feature-text {
      font-size: 0.88rem;
      line-height: 1.5;
    }
    .example-chip {
      display: inline-block;
      font-size: 0.78rem;
      padding: 0.25rem 0.65rem;
      border-radius: 999px;
      border: 1px solid var(--bs-border-color);
      margin: 0.2rem 0.15rem;
      cursor: default;
      opacity: 0.85;
    }
    .chat-message ul, .chat-message ol {
      padding-left: 1.4rem;
      margin-bottom: 0.75rem;
    }
    .chat-message li {
      margin-bottom: 0.35rem;
      line-height: 1.55;
    }
    .chat-message table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 0.75rem;
      font-size: 0.9rem;
    }
    .chat-message th, .chat-message td {
      padding: 0.45rem 0.65rem;
      border: 1px solid var(--bs-border-color);
      text-align: left;
    }
    .chat-message th {
      font-weight: 600;
      opacity: 0.85;
    }
    .chat-message h1, .chat-message h2, .chat-message h3 {
      font-size: 1.1rem;
      font-weight: 600;
      margin-top: 1rem;
      margin-bottom: 0.5rem;
    }
    .chat-message h1 { font-size: 1.25rem; }
    .chat-message p {
      margin-bottom: 0.6rem;
      line-height: 1.6;
    }
    .usage-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 0.5rem;
    }
    .usage-card {
      border-radius: 0.6rem;
      padding: 0.55rem 0.7rem;
      border: 1px solid var(--bs-border-color);
    }
    .usage-card .usage-value {
      font-size: 1.05rem;
      font-weight: 700;
      line-height: 1.2;
    }
    .usage-card .usage-label {
      font-size: 0.7rem;
      opacity: 0.55;
      text-transform: uppercase;
      letter-spacing: 0.04em;
    }
  "))),

  page_navbar(
    id = "nav",
    title = tags$span(
      tags$span(style = "font-size:1.3rem; margin-right:0.3rem;", "\U0001F1F1\U0001F1FA"),
      tags$strong("luxJob"),
      tags$span(style = "opacity:0.6; font-weight:300;", "Agent")
    ),
    window_title = "luxJob Agent",
    theme = bs_theme(
      version = 5,
      preset = "shiny",
      primary = "#6C63FF",
      secondary = "#44D7B6",
      success = "#44D7B6",
      "font-size-base" = "0.95rem",
      "border-radius" = "0.75rem",
      "card-border-radius" = "0.75rem"
    ),
    fillable = TRUE,
    header = NULL,

    nav_spacer(),
    nav_item(input_dark_mode(id = "dark_mode", mode = "dark")),

    nav_panel(
      title = "Chat",
      icon = icon("comments"),
      layout_sidebar(
        sidebar = sidebar(
          width = 300,
          open = "desktop",
          tags$div(
            class = "sidebar-content",
            tags$div(
              tags$h6(
                class = "text-uppercase fw-bold mb-3",
                style = "letter-spacing:0.05em; font-size:0.75rem; opacity:0.6;",
                "What can I help with?"
              ),
              tags$div(
                class = "feature-item",
                tags$span(class = "feature-icon", "\U0001F4BC"),
                tags$span(class = "feature-text", "Search job vacancies by skill, company or location")
              ),
              tags$div(
                class = "feature-item",
                tags$span(class = "feature-icon", "\U0001F3E2"),
                tags$span(class = "feature-text", "Explore companies hiring in Luxembourg")
              ),
              tags$div(
                class = "feature-item",
                tags$span(class = "feature-icon", "\U0001F393"),
                tags$span(class = "feature-text", "Find learning tracks and training paths")
              ),
              tags$div(
                class = "feature-item",
                tags$span(class = "feature-icon", "\U0001F4DA"),
                tags$span(class = "feature-text", "Get book recommendations by skill")
              )
            ),
            tags$hr(),
            tags$h6(
              class = "text-uppercase fw-bold mb-2",
              style = "letter-spacing:0.05em; font-size:0.75rem; opacity:0.6;",
              "Try asking"
            ),
            tags$div(
              tags$span(class = "example-chip", "IT jobs in Luxembourg"),
              tags$span(class = "example-chip", "Companies hiring now"),
              tags$span(class = "example-chip", "Learn data analysis"),
              tags$span(class = "example-chip", "Books about Python"),
              tags$span(class = "example-chip", "Jobs in Esch-sur-Alzette")
            ),
            tags$div(
              class = "sidebar-footer",
              tags$hr(),
              tags$h6(
                class = "text-uppercase fw-bold mb-2",
                style = "letter-spacing:0.05em; font-size:0.75rem; opacity:0.6;",
                "API Usage"
              ),
              uiOutput("usage_stats"),
              tags$hr(),
              tags$div(
                class = "d-flex align-items-center gap-2",
                style = "font-size:0.78rem; opacity:0.5;",
                tags$span("Powered by"),
                tags$strong("Claude"),
                tags$span("+"),
                tags$strong("ellmer")
              )
            )
          )
        ),
        chat_ui("chat", placeholder = "Ask me about jobs, companies, skills...")
      )
    )
  )
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------
server <- function(input, output, session) {
  chat_client <- chat_anthropic(
    system_prompt = SYSTEM_PROMPT,
    model = "claude-sonnet-4-20250514"
  )

  for (t in ALL_TOOLS) {
    chat_client$register_tool(t)
  }

  usage <- reactiveValues(input = 0, output = 0, cost = 0, turns = 0)

  observeEvent(input$chat_user_input, {
    stream <- chat_client$stream_async(
      input$chat_user_input,
      stream = "content"
    )
    prom <- chat_append("chat", stream)

    promises::then(prom,
      onFulfilled = function(value) {
        tokens <- chat_client$get_tokens()
        usage$input  <- sum(tokens$input,  na.rm = TRUE)
        usage$output <- sum(tokens$output, na.rm = TRUE)
        usage$cost   <- chat_client$get_cost()
        usage$turns  <- nrow(tokens)
      },
      onRejected = function(err) {}
    )
  })

  output$usage_stats <- renderUI({
    cost_str <- if (is.null(usage$cost) || is.na(usage$cost)) {
      "$0.00"
    } else {
      sprintf("$%.4f", usage$cost)
    }
    tags$div(
      class = "usage-grid",
      tags$div(class = "usage-card",
        tags$div(class = "usage-value", format(usage$input, big.mark = ",")),
        tags$div(class = "usage-label", "Input tokens")
      ),
      tags$div(class = "usage-card",
        tags$div(class = "usage-value", format(usage$output, big.mark = ",")),
        tags$div(class = "usage-label", "Output tokens")
      ),
      tags$div(class = "usage-card",
        tags$div(class = "usage-value", cost_str),
        tags$div(class = "usage-label", "Session cost")
      ),
      tags$div(class = "usage-card",
        tags$div(class = "usage-value", usage$turns),
        tags$div(class = "usage-label", "Turns")
      )
    )
  })
}

shinyApp(ui, server)
