import os
from shutil import copy2
import sys
import json
import subprocess, shlex
import logging
import glob
from collections import defaultdict
import csv
from pathlib import Path


# Description:
# This function is used to find processed files in a specified directory based on two patterns: "*.sr*.fast*" and "*.sr*".

# Arguments:
# - directory (str): The target directory where the function searches for processed files.
# - logger (logging.Logger): A logger instance used to log information and messages during the function's execution.

# Return:
# - processed (list): A list of file names (without extensions) that match either pattern "*.sr*.fast*" or "*.sr*".

def _find_processed(directory, logger):
    # Use the 'glob' module to search for files matching the patterns in the target directory.
    processed_fast = glob.glob("{0}/*.sr*.fast*".format(directory))
    processed_sr = glob.glob("{0}/*.sr*".format(directory))

    # Combine the lists of processed files and remove duplicates.
    processed = set()
    for file_path in processed_fast + processed_sr:
        processed.add(os.path.split(file_path)[-1].split(".")[0])

    # Return the list of processed file names.
    return list(processed)

def _call(command, logger):
    res = subprocess.run(command, shell=True, capture_output=True, universal_newlines=True)
    if res.stderr:
        logger.error(res.stderr)
    return res

def setup_custom_logger(logger_name, log_level=logging.DEBUG, log_file=None):
    # Create a logger instance with the given name
    logger = logging.getLogger(logger_name)

    # Set the log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    logger.setLevel(log_level)

    # Optionally, you can configure a specific log format
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

    # Create a console handler and add the formatter
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)

    # Add the console handler to the logger
    logger.addHandler(console_handler)

    if log_file:
        # Ensure the log file directory exists
        log_dir = os.path.dirname(log_file)
        if not os.path.exists(log_dir):
            os.makedirs(log_dir)

        # Create a file handler and add the formatter
        file_handler = logging.FileHandler(log_file)
        file_handler.setFormatter(formatter)

        # Add the file handler to the logger
        logger.addHandler(file_handler)

    return logger


def download_accession(accession, cores, logger, save_folder="./downloaded", compress=False):
    """ Downloads a single accession file to the target directory
    
    Args:
        accession (str): run accession
        save_folder (str): target directory
        compress (bool): if `True`, the file will be in the `fastq.gz` format
    """

    fname = os.path.join(save_folder, accession)
    fname = save_folder
    prefetch = "prefetch \
        --resume yes \
        --max-size u \
        --verify yes \
        --type sra " + accession  + " -O " + fname
    
    results = _call(prefetch, logger)
    if "no data" in str(results.stderr):
        logger.error("Accession {0} not found".format(accession))
        raise FileNotFoundError

    # fasterq_dump = "fasterq-dump {0} -O {1}".format(fname, save_folder)
    # res = _call(fasterq_dump)
    # if 'invalid accession' in res.stderr:
    #     logger.warning('Accession {0} not found'.format(accession))
    #     raise FileNotFoundError 

    # os.remove(fname)
    if compress:
        for fname in glob.glob("{0}/{1}*.fastq".format(save_folder, accession)):
            compress = 'pigz '
            if cores is not None:
                compress += ' -p ' + str(cores)
            compress += ' ' + fname
            _call(compress)
    return results.stdout

# def download_reads(metadata, cores, save_folder, logger, compress=True, skip_absent=True):
#     """ Downloads a list of accessions and puts them into project directories.
    
#     Args:
#         metadata (dict): dictionary with bioproject names as keys and SRA IDs as list of values.
#             The keys don't have to be real bioproject identifiers.
#         save_folder (str): root target directory
#         compress (bool): if `True`, the file will be in the `fastq.gz` format
#         skip_absent (bool): if `True`, skip the files that couldn't be downloaded earlier

#     Returns:
#         dict: info about how many SRAs were downloaded for each project
#     """

#     study_stats = {}
#     processed_no = 1
#     all_accessions = [item for sublist in metadata.values() for item in sublist]

#     for study_name, accessions in metadata.items():
#         study_save_folder = os.path.join(save_folder, study_name)
#         processed = _find_processed(study_save_folder)

#         try:
#             absent = _load_absent(os.path.join(study_save_folder, "absent.txt"))
#         except FileNotFoundError:
#             absent = []
        
#         for sra_id in accessions:
#             fname = os.path.join(save_folder, sra_id)

#             logger.info("Currently processing: " + sra_id + " ({0}/{1})".format(processed_no, len(all_accessions)))
#             processed_no += 1

#             if sra_id in processed:
#                 logger.info("Already present! Skipping.")
#                 continue
#             if skip_absent:
#                 if sra_id in absent:
#                     logger.info("Absent! Skipping.")
#                     continue

#             try:
#                 download_accession(sra_id, cores, '{0}/{1}'.format(save_folder, study_name), compress)
#             except FileNotFoundError:
#                 Path(study_save_folder).mkdir(parents=True, exist_ok=True)

#                 with open(os.path.join(study_save_folder, "absent.txt"), "a") as f:
#                     f.write(sra_id+"\n")

#             if not study_name in study_stats.keys():
#                 study_stats[study_name] = 1
#             else:
#                 study_stats[study_name] += 1

#     return study_stats

