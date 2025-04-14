# Dockerfile
FROM plumber_image_base:latest

# Copy the application code and .Renviron
COPY app /app/
COPY .Renviron /app/.Renviron

WORKDIR /app

# Expose the port the API runs on
EXPOSE 8080

# Set the entrypoint for the container
ENTRYPOINT ["Rscript", "run_plumber.R"]
