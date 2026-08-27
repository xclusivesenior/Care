# Zero-dependency service, so there is nothing to npm install - the image is
# just Node plus the source. Alpine keeps it small enough to deploy anywhere.
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# Copy source. No package install step: the bridge has no dependencies.
COPY package.json ./
COPY server.js get-chat-id.js test.js ./
COPY lib ./lib

# Run as the unprivileged user that the node image already provides.
USER node

EXPOSE 3000

# The health route is the same one the smoke tests assert on.
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "server.js"]
