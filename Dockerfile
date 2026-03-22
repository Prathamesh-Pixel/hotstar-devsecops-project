FROM alpine:latest
# Or specifically target a fixed version:
RUN apk upgrade --no-cache libcrypto3 libssl3
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN CI=false npm run build
EXPOSE 3000
CMD ["npm","start"]
