# Dockerfile
FROM myapp/base:latest

# Copy the app folder
COPY app /app/

# Expose the port the app runs on
EXPOSE 8080

# Set the entrypoint for the container
ENTRYPOINT ["Rscript", "app.R"]