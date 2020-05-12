#!/usr/local/bin/python
import logging
import os
import signal
import random
import time
from dotenv import load_dotenv

from status_updater import StatusUpdater

def signal_handler(signum, frame):
    # This will cause the exit handler to be executed, if it is registered.
    raise RuntimeError('Caught SIGTERM, exiting.')

load_dotenv()

logging.basicConfig(level=logging.DEBUG, format=f"%(asctime)s %(levelname)s: %(message)s")

signal.signal(signal.SIGTERM, signal_handler)

row_to_fail_at = int(os.environ.get('ROW_TO_FAIL_AT', '-1'))

updater = StatusUpdater()

try:
    updater.send_update(last_status_message='sleeping', expected_count=random.randrange(5, 15))
    success_count = 0
    for i in range(5):
        if i == row_to_fail_at:
            updater.send_update(error_count=1)
            logging.error(f"Failed on row {i}, exiting!")
            exit(1)
        else:
            print(f"sleeping {i} ...")
            time.sleep(2)
            success_count += random.randrange(1, 10)

            try:
                updater.send_update(success_count=success_count)
            except:
                logging.info('Failed to send update')

            print("done sleeping")

    updater.send_update(last_status_message='woken up')
finally:
    try:
        updater.shutdown()
    except:
        logging.exception("Can't shutdown updater")
