FROM node:12 as build

WORKDIR /home/node/app

ADD ./package.json /home/node/app/package.json
ADD ./yarn.lock /home/node/app/yarn.lock

RUN yarn install

COPY ./src /home/node/app/src
COPY ./tsconfig.json /home/node/app/tsconfig.json

RUN yarn build-es

FROM node:12-alpine as deps

WORKDIR /home/node/app

ADD ./package.json /home/node/app/package.json
ADD ./yarn.lock /home/node/app/yarn.lock

RUN LDFLAGS='-static-libgcc -static-libstdc++' yarn install --production --no-interactive --frozen-lockfile

FROM node:12-alpine

LABEL org.opencontainers.image.source='https://github.com/digirati-co-uk/storage-api'
LABEL org.opencontainers.image.documentation='https://docs.madoc.io/'
LABEL org.opencontainers.image.vendor='Digirati'
LABEL org.opencontainers.image.licenses='MIT'

WORKDIR /home/node/app

COPY --from=deps /home/node/app/package.json /home/node/app/package.json
COPY --from=deps /home/node/app/yarn.lock /home/node/app/yarn.lock
COPY --from=deps /home/node/app/node_modules /home/node/app/node_modules
COPY --from=build /home/node/app/dist /home/node/app/dist
COPY ./ecosystem.config.js /home/node/app/ecosystem.config.js

ENV SERVER_PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

USER node

CMD ["node_modules/.bin/pm2-runtime", "start", "./ecosystem.config.js"]
