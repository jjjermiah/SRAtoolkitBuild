FROM northamerica-northeast2-docker.pkg.dev/orcestra-388613/bhklab-docker-repo/sra_toolkit_gcp_mount:latest

RUN apk add --no-cache python3 py3-pip
# Copy application dependency manifests to the container image.
# Copying this separately prevents re-running pip install on every code change.
COPY requirements.txt ./

# Install production dependencies.
RUN pip3 install -r requirements.txt
RUN pip3 install gunicorn

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY . ./

# Run the web service on container startup.
# Use gunicorn webserver with one worker process and 8 threads.
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 app:app