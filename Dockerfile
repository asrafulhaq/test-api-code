# FROM node:24-alpine 

# WORKDIR /app

# COPY package*.json ./

# RUN npm install

# COPY . . 

# RUN npm run build 

# CMD ["node", "dist/main.js"]




# -----------------------------
# 1. Base Image
# -----------------------------
FROM node:20-alpine AS base

# Enable corepack for pnpm
RUN corepack enable

WORKDIR /app

# -----------------------------
# 2. Install Dependencies
# -----------------------------
FROM base AS deps

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

# -----------------------------
# 3. Build Application
# -----------------------------
FROM base AS builder

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build NestJS
RUN pnpm build

# -----------------------------
# 4. Production Image
# -----------------------------
FROM node:20-alpine AS runner

RUN corepack enable

WORKDIR /app

ENV NODE_ENV=production

# Copy only necessary files
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Prisma client (important if using migrations/runtime)
RUN npx prisma generate

EXPOSE 3000

CMD ["node", "dist/main.js"]



