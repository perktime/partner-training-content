# Multi-stage build: compile the Angular app, then serve it with nginx.

# --- Stage 1: build ---
FROM mcr.microsoft.com/azurelinux/base/nodejs:20 AS build
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npx ng build --configuration production

# --- Stage 2: runtime ---
FROM mcr.microsoft.com/azurelinux/base/nginx:1
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist/multi-agent-app/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
