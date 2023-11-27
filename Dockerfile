FROM node:16.17.0-alpine as builder
WORKDIR /app
COPY ./package.json .
COPY ./yarn.lock .
RUN yarn install
COPY . .
ARG TMDB_V3_API_KEY
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"
RUN yarn build

FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /app/dist .
RUN    apk add --no-cache libcap \
        && touch /var/run/nginx.pid \
        && chown -R 101:101 /var/run/nginx.pid /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d \
        && chmod -R 777 /var/cache/ /var/run /var/run/nginx.pid \
        && setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx
USER nginx
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]
