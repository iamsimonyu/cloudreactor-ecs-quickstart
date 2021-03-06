# Alpine base image can lead to long compilation times and errors.
# https://pythonspeed.com/articles/base-image-python-docker-images/
FROM python:3.8.3-slim-buster

LABEL maintainer="jeff@cloudreactor.io"

# For the web-server task example only.
# If you are not deploying the web-server task you can delete this line.
EXPOSE 7070

WORKDIR /usr/src/app

# Install any OS libraries required to build python libraries
# For example, libpq-dev is required to build psycopg2
#RUN apt-get update && apt-get install -y libpq-dev

RUN pip install --no-cache-dir --upgrade pip==20.1.1

COPY requirements.txt .

# Install dependencies
# https://stackoverflow.com/questions/45594707/what-is-pips-no-cache-dir-good-for
RUN pip install --no-cache-dir -r requirements.txt

# Run as non-root user for better security
RUN groupadd appuser && useradd -g appuser --create-home appuser
USER appuser
WORKDIR /home/appuser

# Pre-create this directory so that it has the correct permission
# when ECS mounts a volume, otherwise it will be owned by root.
RUN mkdir scratch

# Output directly to the terminal to prevent logs from being lost
# https://stackoverflow.com/questions/59812009/what-is-the-use-of-pythonunbuffered-in-docker-file
ENV PYTHONUNBUFFERED 1

# Don't write *.pyc files
ENV PYTHONDONTWRITEBYTECODE 1

# Enable the fault handler for segfaults
# https://docs.python.org/3/library/faulthandler.html
ENV PYTHONFAULTHANDLER 1

ENV PYTHONPATH /home/appuser/src

COPY deploy/files/proc_wrapper_1.3.0.py proc_wrapper.py

COPY src ./src

ARG ENV_FILE_PATH=deploy/files/.env.dev

# copy deployment environment settings
COPY ${ENV_FILE_PATH} .env

CMD python proc_wrapper.py $TASK_COMMAND
