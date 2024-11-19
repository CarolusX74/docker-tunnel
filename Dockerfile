FROM nginx:alpine

RUN apk add --no-cache bash autossh

COPY nginx.conf.template /
COPY start.sh /
#COPY --chmod=400 ssh.key / (Better mount your ssh.key, we'll fix the permission inside)

RUN chmod +x /start.sh
#RUN chmod 400 /srv/ssh.key

ENV PORTS="80:3000,443:3001"
ENV PROXY_HOST="ssh.yourhost.com"
ENV PROXY_SSH_PORT="22"
ENV PROXY_SSH_USER="root"
ENV APP_IP=""
ENV MODE="app"

RUN echo 'LA IMAGEN FUE COMPILADA EXITOSAMENTE \n'

ENTRYPOINT ["/start.sh"]
