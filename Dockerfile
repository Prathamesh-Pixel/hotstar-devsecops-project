FROM node:18-alpine
WORKDIR /app

# Copy the modules you just installed locally
COPY node_modules ./node_modules
COPY package*.json ./
COPY . .

# Build the app (Offline - no internet needed!)
RUN CI=false npm run build

EXPOSE 3000
CMD ["npm", "start"]
