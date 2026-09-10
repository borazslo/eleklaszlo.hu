# Multi-stage build: Jekyll build stage
FROM ruby:3.0-alpine AS builder

WORKDIR /app

# Install dependencies required for Jekyll and gem compilation on Alpine
RUN apk add --no-cache \
    build-base \
    git \
    libffi-dev \
    yaml-dev \
    zlib-dev

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems
RUN bundle install

# Copy source code
COPY . .

# Build Jekyll site
RUN JEKYLL_ENV=production bundle exec jekyll build

# Final stage: nginx
FROM nginx:alpine

# Install wget for healthcheck
RUN apk add --no-cache wget

# Copy built site from builder
COPY --from=builder /app/_site /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
