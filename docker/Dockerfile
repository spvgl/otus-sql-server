FROM mcr.microsoft.com/mssql/server:2019-latest

ENV SA_PASSWORD=P@ssw0rd
ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

ENV APP_DIR=/opt/app

USER root

RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR
COPY . .

RUN chmod +x ./init-db-run.sh

EXPOSE 1433

USER mssql
CMD /bin/bash $APP_DIR/entrypoint.sh