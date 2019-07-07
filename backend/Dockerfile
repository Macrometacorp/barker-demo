FROM node
LABEL maintainer="jarle.aase@macrometa.co"
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
COPY . .
ENV TENANT unset
ENV FABRIC unset
ENV JWT unset
ENV APIURL unset
ENV PORT 8080
USER nobody
CMD [ "npm", "start" ]
