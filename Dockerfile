# Use Node Debian image as the builder stage
FROM node:16.17.0 as builder

WORKDIR /app

# Copy package.json and yarn.lock to the working directory
COPY  ./package.json .
COPY  ./yarn.lock .

# Install dependencies
RUN yarn install

# Show files in directory (optional)
RUN ls -alt

# Copy project files to the working directory
COPY . .

# Set build arguments and environment variables
ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"

# Build the application
RUN yarn build

# Change ownership of files in the app directory
ls -alt

# Use Nginx Debian image as the production stage
FROM nginx:stable

WORKDIR /usr/share/nginx/html

# Remove existing files
RUN rm -rf ./*

# Copy built files from the builder stage to Nginx HTML directory
COPY --from=builder --chown=101:101 /app/dist .

# Show files in directory (optional)
RUN ls -alt

# Install necessary packages, set permissions, and capabilities for Nginx
RUN apt-get update && apt-get install -y libcap2-bin \
    && touch /var/run/nginx.pid \
    && chown -R 101:101 /var/run/nginx.pid /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
    && chmod -R 777 /var/cache/ /var/run /var/run/nginx.pid \
    && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx 

# Change ownership of files in the Nginx HTML directory
RUN chown -R 101:101 /usr/share/nginx/html

# Switch to the 'nginx' user
USER nginx

# Expose port 80
EXPOSE 80

# Set the entry point for the container
ENTRYPOINT ["nginx", "-g", "daemon off;"]
