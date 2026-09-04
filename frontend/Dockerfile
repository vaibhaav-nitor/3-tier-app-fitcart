
FROM node:20-alpine AS build
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


FROM nginx:stable-alpine


COPY nginx.conf /etc/nginx/conf.d/default.conf


COPY --from=build /app/dist /usr/share/nginx/html

# Renders config.js from $HERO_HIGHLIGHT_TEXT when it arrives as a container
# env var (Azure App Service). A no-op on AKS, where the value instead arrives
# as a mounted ConfigMap file — see docker-entrypoint.d/10-render-config.sh.
COPY docker-entrypoint.d/10-render-config.sh /docker-entrypoint.d/10-render-config.sh
RUN chmod +x /docker-entrypoint.d/10-render-config.sh

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
