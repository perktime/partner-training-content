# Use an official Python image
FROM mcr.microsoft.com/azurelinux/base/python:3.12

# Set the working directory inside the container
WORKDIR /app

# Copy only requirements.txt first (for caching)
COPY src/app/requirements.txt .

# Install dependencies
RUN pip install --upgrade --no-cache-dir -r requirements.txt

# Copy the `src/` folder while preserving its structure
COPY src /app/src

# Expose the required port
EXPOSE 8080

# Set the PYTHONPATH to ensure `src` is found
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["python3", "-u", "-m", "uvicorn", "src.app.banking_agents_api:app", "--host", "0.0.0.0", "--port", "8080"]