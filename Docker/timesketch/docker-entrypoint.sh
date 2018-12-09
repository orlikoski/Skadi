#!/bin/bash

# Set up web credentials
if [ -z ${TIMESKETCH_USER+x} ]; then
  TIMESKETCH_USER="admin"
  echo "TIMESKETCH_USER set to default: ${TIMESKETCH_USER}";
fi
if [ -z ${TIMESKETCH_PASSWORD+x} ]; then
  TIMESKETCH_PASSWORD="$(openssl rand -base64 32)"
  echo "TIMESKETCH_PASSWORD set randomly to: ${TIMESKETCH_PASSWORD}";
fi

# Sleep to allow the other processes to start
sleep 5
tsctl add_user -u "$TIMESKETCH_USER" -p "$TIMESKETCH_PASSWORD"

# Run the Timesketch server (without SSL)
exec `bash -c "/usr/local/bin/celery -A timesketch.lib.tasks worker --uid nobody --loglevel info &\
gunicorn -b 0.0.0.0:5000 --access-logfile - --error-logfile - --log-level info --timeout 600 timesketch.wsgi:application"`
