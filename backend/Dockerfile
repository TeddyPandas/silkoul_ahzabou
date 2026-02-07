# Use Node.js 18 Alpine for a small footprint
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm install --production

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start command
CMD ["node", "server.js"]
