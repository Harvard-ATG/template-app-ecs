# Multi-stage build for Next.js frontend
FROM node:22-slim AS builder

WORKDIR /build

# Copy package files
COPY frontend/package.json frontend/package-lock.json* ./

# Install dependencies
RUN npm ci || npm install

# Copy source
COPY frontend .

# Build standalone
RUN npm run build

# Production stage
FROM node:22-slim

WORKDIR /app

# Set production env
ENV NODE_ENV=production
ENV PORT=3000

# Copy standalone build
COPY --from=builder /build/.next/standalone ./
COPY --from=builder /build/.next/static ./.next/static
COPY --from=builder /build/public ./public

# Non-root user (node user already exists in node:22-slim with UID 1000)
RUN chown -R node:node /app
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD node -e "import('http').then(http => http.get('http://localhost:3000/', (r) => process.exit(r.statusCode === 200 ? 0 : 1)))"

EXPOSE 3000

# Use Next.js standalone server directly
CMD ["node", "server.js"]
