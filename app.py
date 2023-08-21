import flask
import logging
from flask import Flask, Response

from download_SRA import download_accession, setup_custom_logger, _find_processed
import gcloud_storage
import os
app = flask.Flask(__name__)


@app.route("/")
def index():
    return """
    <form action="/download" method="get">
        <label for="sra">Enter SRA ID:</label>
        <input type="text" id="sra" name="sra">
        <br>
        <label for="bucket">Enter Bucket Name:</label>
        <input type="text" id="bucket" name="bucket_name">
        <br>
        <label for="cores">Enter Cores:</label>
        <input type="text" id="cores" name="cores">
        <br>        
        <input type="submit" value="Download">
    </form>
    <div id="log-output"></div>
    <script>
        const logOutput = document.getElementById('log-output');
        const eventSource = new EventSource('/log_stream');
        eventSource.onmessage = function(event) {
            logOutput.innerHTML += event.data + '<br>';
        };
    </script>
    """

@app.route("/download")
def download():
    sra_id = flask.request.args.get("sra", "empty")
    bucket_name = flask.request.args.get("bucket_name", "empty")
    cores = flask.request.args.get("cores", "empty")
    print(f"Using: {sra_id}")
    save_folder="./SRA_data"
    if{sra_id != "empty"}:
        my_logger = setup_custom_logger('download_SRA', log_level=logging.DEBUG, log_file=os.path.join(save_folder,sra_id, "test.log"))

        
        my_logger.info("Currently processing: " + sra_id + " ({0}/{1})".format(sra_id, '{0}/{1}'.format(save_folder, sra_id)))
        
        res = download_accession(sra_id, cores=cores, logger=my_logger, save_folder=save_folder)
        
        bucket_name="ncbi-ccle-data"
        bucket_folder_name = "SRA_Downloads"
        gcloud_storage.upload_folder_to_gcs(bucket_name=bucket_name,  
                                            source_folder=os.path.join(save_folder, sra_id), 
                                            destination_folder=os.path.join(bucket_folder_name, sra_id))
        

        # log_contents = get_log_contents(os.path.join(save_folder, sra_id, "test.log"))

        return "Download complete. Further input is disabled."
    else:
        return "Please enter a valid SRA ID."

@app.route("/log_stream")
def log_stream():
    sra_id = flask.request.args.get("sra", "empty")
    log_file_path = os.path.join("./SRA_data", sra_id, "test.log")

    def generate():
        with open(log_file_path, "r") as log_file:
            for line in log_file:
                yield f"data: {line}<br>\n"
    
    return Response(generate(), mimetype="text/event-stream")

if __name__ == "__main__":
    app.run()
