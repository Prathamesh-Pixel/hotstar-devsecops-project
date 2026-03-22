# Use the latest Alpine for the best chance at pre-patched packages
FROM alpine:latest 

# 1. Update the package index
# 2. Add nodejs and npm (so we can run the app)
# 3. Upgrade vulnerable libraries from your Trivy report
RUN apk update && \
    apk add --no-cache nodejs npm libcrypto3 libssl3 openssl && \
    apk upgrade --no-cache libcrypto3 libssl3

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Build the Hotstar clone
RUN CI=false npm run build

EXPOSE 3000
CMD ["npm", "start"]
