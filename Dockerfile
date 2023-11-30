FROM node:16.17.0-alpine as builder
WORKDIR /app
COPY --chown=101:101 ./package.json .
COPY --chown=101:101 ./yarn.lock .
RUN yarn install
RUN ls -alt
COPY --chown=101:101 . .
RUN ls -alt
ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"
RUN yarn build
RUN --chown -R 101:101 /app 
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --chown=101:101 --from=builder /app/dist .
RUN ls -alt
RUN    apk add --no-cache libcap \
        && touch /var/run/nginx.pid \
        && chown -R 101:101 /var/run/nginx.pid /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
        && chmod -R 777 /var/cache/ /var/run /var/run/nginx.pid \
        && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx 
RUN chown -R 101:101 /usr/share/nginx/html
RUN ls -alt 
USER nginx
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
