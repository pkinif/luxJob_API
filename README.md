# luxJob_API

Small HTTP API built with **R [`plumber`](https://www.rplumber.io/)**. Route handlers live in `plumber.R` and delegate most work to the `luxJob` R package.

## Requirements

- R (see `renv.lock` for the expected version)
- Packages restored with `renv`

## Install dependencies

In an R session (RStudio or console):

```r
renv::restore()
```

## Run the API

### Option A (R console / RStudio)

```r
source("run_plumber.R")
```

### Option B (set a custom port)

`run_plumber.R` reads `PORT` from the environment (default: `8008`).

On Windows PowerShell:

```powershell
$env:PORT="8008"
```

Then in R:

```r
source("run_plumber.R")
```

## Quick check

- `GET /health` should return `{"status":"ok"}`.

