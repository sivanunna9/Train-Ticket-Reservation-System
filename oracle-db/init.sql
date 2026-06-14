FROM gvenzl/oracle-xe:21-slim

# Set database admin password
ENV ORACLE_PASSWORD=MANAGER

# Application user (optional, but helpful)
ENV APP_USER=RESERVATION
ENV APP_USER_PASSWORD=MANAGER

# Copy SQL init script
COPY init.sql /container-entrypoint-initdb.d/
