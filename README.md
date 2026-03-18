# luxJob API & AI Agent

A two-service stack for exploring the **Luxembourg job market**:

1. **Plumber API** — RESTful HTTP API built with R [`plumber`](https://www.rplumber.io/), backed by the [`luxJob`](https://github.com/pkinif/luxJob) R package.
2. **AI Agent** — A Shiny chat app powered by [Anthropic Claude](https://www.anthropic.com/) that understands natural language queries and calls the API automatically using [tool calling](https://ellmer.tidyverse.org/articles/tool-calling.html).

```
User (browser)
      │
      ▼
┌─────────────┐         ┌──────────────┐         ┌──────────────┐
│  Shiny Chat │──tools──▶  Claude API  │         │  PostgreSQL  │
│  Agent :3838│◀─answer──│  (Anthropic) │         │   (AWS RDS)  │
└──────┬──────┘         └──────────────┘         └──────▲───────┘
       │ HTTP                                           │
       ▼                                                │
┌──────────────┐                                        │
│ Plumber API  │────────────────────────────────────────┘
│     :8080    │
└──────────────┘
```

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Running with Docker (recommended)](#running-with-docker-recommended)
- [Running Locally (without Docker)](#running-locally-without-docker)
- [API Reference](#api-reference)
- [AI Agent](#ai-agent)
- [Deployment](#deployment)

## Features

- **12 REST endpoints** covering skills, companies, vacancies, learning tracks, books and search logging
- **AI-powered chat interface** — ask questions in natural language (English, French, etc.) and get formatted answers drawn from real data
- **Dockerized** — both services run in containers orchestrated by Docker Compose
- **Environment-aware** — a single env var (`LUXJOB_API_URL`) switches between local and production deployments

## Project Structure

```
luxJob_API/
├── plumber.R            # API route definitions
├── run_plumber.R        # API entry point (reads PORT env var)
├── agent/
│   └── app.R            # Shiny chat agent (ellmer + shinychat)
├── dockerfile.base      # Base image: R 4.4.3 + system libs + renv
├── dockerfile.api       # Plumber API image
├── dockerfile.agent     # Shiny agent image
├── docker-compose.yml   # Orchestrates api + agent services
├── docker_command.txt   # Quick-reference Docker commands
├── renv.lock            # Reproducible R package versions
├── .Renviron            # Environment variables (DB creds, API keys) — git-ignored
└── .gitignore
```

## Prerequisites

- **Docker Desktop** (recommended) — [Install Docker](https://docs.docker.com/get-docker/)
- OR **R >= 4.4.3** + [`renv`](https://rstudio.github.io/renv/) for running locally
- An **Anthropic API key** for the AI agent — [Get one here](https://console.anthropic.com/)

## Configuration

All secrets live in the `.Renviron` file at the project root (git-ignored). Create it with the following variables:

```env
PG_DB = 'postgres'
PG_HOST = '<your-rds-host>'
PG_USER = 'postgres'
PG_PASSWORD = '<your-password>'
sql_schema = 'adem'
ANTHROPIC_API_KEY = '<your-anthropic-api-key>'
```

| Variable | Used by | Description |
|---|---|---|
| `PG_DB` | API | PostgreSQL database name |
| `PG_HOST` | API | PostgreSQL host (e.g. AWS RDS endpoint) |
| `PG_USER` | API | PostgreSQL user |
| `PG_PASSWORD` | API | PostgreSQL password |
| `sql_schema` | API | Database schema name |
| `ANTHROPIC_API_KEY` | Agent | Anthropic API key for Claude |

## Running with Docker (recommended)

### 1. Build the base image

This installs system libraries and all R packages. Only needed once (or when `renv.lock` changes):

```bash
docker build -f dockerfile.base -t luxjob_base .
```

### 2. Start both services

```bash
docker compose up -d --build
```

This builds the API and agent images on top of the base, then starts both containers:

| Service | URL | Description |
|---|---|---|
| **API** | http://localhost:8080 | REST API (Swagger docs at `/__docs__/`) |
| **Agent** | http://localhost:3838 | AI chat interface |

### 3. Check logs

```bash
docker compose logs -f          # all services
docker compose logs api --tail 20   # API only
docker compose logs agent --tail 20 # Agent only
```

### 4. Stop

```bash
docker compose down
```

### Rebuild after code changes

No need to rebuild the base image unless `renv.lock` changed:

```bash
docker compose up -d --build
```

## Running Locally (without Docker)

### Install R dependencies

```r
# install.packages("renv")
renv::restore()
```

### Start the API

In an R console or RStudio:

```r
source("run_plumber.R")
```

The API starts on port **8080** by default. Override with the `PORT` environment variable:

```r
Sys.setenv(PORT = "9090")
source("run_plumber.R")
```

### Start the AI Agent

In a **separate** R session:

```r
shiny::runApp("agent")
```

The agent reads `LUXJOB_API_URL` to know where the API is. It defaults to `http://localhost:8080`. If your API runs on a different port:

```r
Sys.setenv(LUXJOB_API_URL = "http://localhost:9090")
shiny::runApp("agent")
```

## API Reference

Base URL: `http://localhost:8080`

### Health

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Returns `{"status": "ok"}` |

### Skills

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| GET | `/skills` | `limit` (int, default 100) | List all skills |
| GET | `/skills/<skill_id>` | `skill_id` (ESCO URI) | Get a skill by ID |

### Companies

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| GET | `/companies` | `limit` (int, default 100) | List all companies |
| GET | `/companies/<company_id>` | `company_id` (int) | Get company details |

### Vacancies

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| GET | `/vacancies` | `skill` (string), `company` (int), `canton` (string), `limit` (int) | Search vacancies with optional filters |
| GET | `/vacancies/<vacancy_id>` | `vacancy_id` (int) | Get vacancy details |

### Learning Tracks

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| GET | `/learning_tracks` | `skill_id` (string, optional) | List learning tracks |
| GET | `/learning_tracks/<track_id>` | `track_id` (int) | Get learning track details |

### Books

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| GET | `/books` | `skill` (string, optional) | Get book recommendations |
| GET | `/books/<book_id>` | `book_id` (int) | Get book details |

### Logs

| Method | Endpoint | Parameters | Description |
|---|---|---|---|
| POST | `/log_search` | `user_id` (int), `query` (string) | Log a search query |

### Example requests

```bash
# Health check
curl http://localhost:8080/health

# List 10 skills
curl "http://localhost:8080/skills?limit=10"

# Search vacancies in a specific canton
curl "http://localhost:8080/vacancies?canton=Luxembourg&limit=5"

# Get a specific company
curl http://localhost:8080/companies/1
```

## AI Agent

The agent (`agent/app.R`) is a Shiny app that provides a conversational interface to the API. It uses:

- [**ellmer**](https://ellmer.tidyverse.org/) — R package for LLM interaction with tool/function calling
- [**shinychat**](https://posit-dev.github.io/shinychat/) — Chat UI component for Shiny
- [**Anthropic Claude**](https://www.anthropic.com/) — The LLM that powers the conversation

### How it works

1. The user types a natural language question (e.g. "Find me IT jobs in Luxembourg city")
2. The question is sent to Claude along with descriptions of 10 available tools
3. Claude decides which API endpoint(s) to call and with what parameters
4. The agent executes the API calls via HTTP and returns the results to Claude
5. Claude formulates a natural language answer using the real data
6. The answer (and collapsible tool-call cards) are rendered in the chat UI

### Available tools

The agent exposes 10 tools to Claude, each mapped to an API endpoint:

| Tool | API Endpoint | Description |
|---|---|---|
| `search_vacancies` | GET /vacancies | Search jobs by skill, company, canton |
| `get_skills` | GET /skills | List available skills |
| `get_skill_by_id` | GET /skills/:id | Get skill details |
| `get_companies` | GET /companies | List companies |
| `get_company_details` | GET /companies/:id | Get company details |
| `get_vacancy_details` | GET /vacancies/:id | Get full job details |
| `get_learning_tracks` | GET /learning_tracks | List training paths |
| `get_learning_track_by_id` | GET /learning_tracks/:id | Get track details |
| `get_books` | GET /books | Get book recommendations |
| `get_book_by_id` | GET /books/:id | Get book details |

### Usage dashboard

The sidebar displays a real-time **API Usage** panel that tracks your Anthropic API consumption for the current session:

| Metric | Description |
|---|---|
| **Input tokens** | Total tokens sent to Claude (questions + tool results) |
| **Output tokens** | Total tokens received from Claude (answers + tool calls) |
| **Session cost** | Estimated cost in USD based on the model's pricing |
| **Turns** | Number of assistant responses so far |

These counters reset when the page is refreshed (new session). Use them to monitor costs, especially on pay-per-token Anthropic plans.

### Example questions you can ask

- "Show me job vacancies in Luxembourg city"
- "What companies are hiring?"
- "Find learning tracks for data analysis skills"
- "Recommend books about programming"
- "How many jobs require Python?"

## Deployment

### Local (Docker Compose)

```bash
docker compose up -d
```

The agent container automatically connects to the API container via Docker's internal network (`http://api:8080`).

### Production server

Set `LUXJOB_API_URL` to the production API URL:

```yaml
# docker-compose.override.yml
services:
  agent:
    environment:
      - LUXJOB_API_URL=https://api.your-domain.com
```

Or pass it as an environment variable:

```bash
LUXJOB_API_URL=https://api.your-domain.com docker compose up -d
```

### Port configuration

Default ports can be overridden via environment variables:

```bash
API_PORT=9090 AGENT_PORT=4000 docker compose up -d
```
