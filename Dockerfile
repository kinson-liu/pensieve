FROM jfrog.kinson.fun/registry/node:lts-buster as builder
WORKDIR /pensieve
COPY . .
RUN npm config set registry https://registry.npm.taobao.org/
# RUN npm config set registry https://jfrog.kinson.fun/artifactory/api/npm/npm-ali
RUN npm install
RUN npm install hexo-cli -g
RUN hexo generate
FROM nginx as server
COPY --from=builder /pensieve/public/ /usr/share/nginx/html/
