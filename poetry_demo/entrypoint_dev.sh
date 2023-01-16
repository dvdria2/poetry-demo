#!/usr/bin/env bash
source ~/.bash_profile

trap cleanup INT TERM

EXPOSE_PORT=${EXPOSE_PORT:-8030}
SLEEP_AFTER_CRASH=${SLEEP_AFTER_CRASH:-5}
DJANGO_PID=


cleanup () {
    echo "cleanup"
    kill -s SIGTERM $DJANGO_PID
    exit 0
}

start () {
    pip install --user "pip~=22.2.0"
    poetry install
    poetry run ./manage.py migrate --noinput
    if [ ! -f ./docker.code-workspace ]
    then
        cp ./docker/docker.code-workspace.tmpl ./docker.code-workspace
    fi

    while true; do
        poetry run ./manage.py runserver 0.0.0.0:$EXPOSE_PORT &
        DJANGO_PID=$!
        DO_WATCH=true
        while $DO_WATCH; do
            # Monitor change in /app folder (only .env file)
            # Quale devo prendere?
            # filename=$(inotifywait --quiet -e modify -e move -e create -e delete -e attrib --format "%f" -r ~/app/services/psa_onboarding)
            filename=$(inotifywait --quiet -t 3 -e modify -e move -e create -e delete -e attrib --format "%w" .env)
            if [[ $filename == .env ]]; then
                # If .env is changed, then restart
                echo ".env changed, reload"
                DO_WATCH=false
            elif ! kill -0 "$DJANGO_PID"; then
                # If runserver is crashed, then restart
                echo "$DJANGO_PID not found, reload"
                DO_WATCH=false
            fi
        done
        kill -s SIGTERM $DJANGO_PID
        # wait $!
        sleep $SLEEP_AFTER_CRASH
    done
}

start
