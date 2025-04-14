# plumber.R

# Load packages
library(plumber)
library(DBI)
library(RPostgres)
library(glue)
library(luxJob)

# ------------------------------------------------------------------------------
# Skills
# ------------------------------------------------------------------------------

#* Get all skills
#* @get /skills
#* @param limit:int Maximum number of skills to return
function(limit = NULL) {
    luxJob::get_skills(as.integer(limit))
}

#* Get all skills
#* @get /skills1
#* @param limit:int Maximum number of skills to return
function(limit = 100) {
    luxJob::get_skills(as.integer(limit))
}

#* Get all skills
#* @get /skills2
#* @param limit:int optionnal Maximum number of skills to return
function(limit) {
    luxJob::get_skills(as.integer(limit))
}

#* Get a skill by ID
#* @get /skills/<skill_id>
#* @param skill_id:string ID of the skill to retrieve
function(skill_id = 'http://data.europa.eu/esco/skill/97965983-0da4-4902-9daf-d5cd2693ef73') {
    skill_id <- utils::URLdecode(skill_id)
    luxJob::get_skill_by_id(as.character(skill_id))
}

# ------------------------------------------------------------------------------
# Companies
# ------------------------------------------------------------------------------

#* Get all companies
#* @get /companies
#* @param limit:int Maximum number of companies to return
function(limit = 100) {
    luxJob::get_companies(as.integer(limit))
}

#* Get a company by ID
#* @get /companies/<company_id>
#* @param company_id:int ID of the company to retrieve
function(company_id) {
    luxJob::get_company_details(as.integer(company_id))
}

# ------------------------------------------------------------------------------
# Vacancies
# ------------------------------------------------------------------------------

#* Get job vacancies
#* @get /vacancies
#* @param skill:string Skill ID to filter by
#* @param company:int Company ID to filter by
#* @param canton:string Canton name to filter by
#* @param limit:int Maximum number of results to return
function(skill = NULL, company = NULL, canton = NULL, limit = 100) {
    luxJob::get_vacancies(
        skill = skill,
        company = if (!is.null(company)) as.integer(company) else NULL,
        canton = canton,
        limit = as.integer(limit)
    )
}

#* Get a vacancy by ID
#* @get /vacancies/<vacancy_id>
#* @param vacancy_id:int ID of the vacancy to retrieve
function(vacancy_id) {
    luxJob::get_vacancy_by_id(as.numeric(vacancy_id))
}

# ------------------------------------------------------------------------------
# Learning Tracks
# ------------------------------------------------------------------------------

#* Get learning tracks
#* @get /learning_tracks
#* @param skill_id:string Optional skill ID to filter learning tracks
function(skill_id = NULL) {
    luxJob::get_learning_tracks(skill_id)
}

#* Get a learning track by ID
#* @get /learning_tracks/<track_id>
#* @param track_id:int ID of the learning track to retrieve
function(track_id) {
    luxJob::get_learning_track_by_id(as.integer(track_id))
}

# ------------------------------------------------------------------------------
# Books
# ------------------------------------------------------------------------------

#* Get book recommendations
#* @get /books
#* @param skill:string Optional skill ID to filter books
function(skill = 'http://data.europa.eu/esco/skill/70198e4e-86ad-4acc-a9eb-e24e2c107d18') {
    luxJob::get_books(skill)
}

#* Get a book by ID
#* @get /books/<book_id>
#* @param book_id:int ID of the book to retrieve
function(book_id) {
    luxJob::get_book_by_id(as.integer(book_id))
}

# ------------------------------------------------------------------------------
# Logs
# ------------------------------------------------------------------------------

#* Log a search query
#* @post /log_search
#* @param user_id:int ID of the user making the search
#* @param query:string Text of the search query
function(user_id, query) {
    luxJob::log_search(as.integer(user_id), query)
}
