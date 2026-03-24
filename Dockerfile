# 1. Use an image that ALREADY has Node and NPM installed
FROM node:18-alpine

# 2. Set the working directory
WORKDIR /app

# 3. Copy only the package files first (to optimize build cache)
COPY package*.json ./

# 4. Run install with a massive timeout to handle the network flickering
RUN npm install --network-timeout=1000000

# 5. Copy the rest of the source code
COPY . .

# 6. Build the Hotstar clone (CI=false avoids failing on minor warnings)
RUN CI=false npm run build

EXPOSE 3000
CMD ["npm", "start"]
