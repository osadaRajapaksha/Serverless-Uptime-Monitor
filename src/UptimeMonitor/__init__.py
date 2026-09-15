import datetime
import logging
import os
import requests
import azure.functions as func
from azure.data.tables import TableClient
from azure.core.exceptions import ResourceExistsError

def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function ran at %s', utc_timestamp)

    endpoints_str = os.environ.get('TARGET_ENDPOINTS', '')
    if not endpoints_str:
        logging.warning("No TARGET_ENDPOINTS configured.")
        return
    
    endpoints = [e.strip() for e in endpoints_str.split(',')]
    table_name = os.environ.get('TABLE_NAME', 'UptimeMonitorResults')
    storage_connection_string = os.environ.get('AzureWebJobsStorage', '')

    try:
        table_client = TableClient.from_connection_string(conn_str=storage_connection_string, table_name=table_name)
        try:
            table_client.create_table()
        except ResourceExistsError:
            pass # Table already exists
    except Exception as e:
        logging.error(f"Failed to connect to table storage: {e}")
        return

    for endpoint in endpoints:
        try:
            start_time = datetime.datetime.now()
            response = requests.get(endpoint, timeout=10)
            latency = (datetime.datetime.now() - start_time).total_seconds()
            
            status_code = response.status_code
            
            entity = {
                'PartitionKey': "UptimeCheck",
                'RowKey': str(datetime.datetime.utcnow().timestamp()),
                'Endpoint': endpoint,
                'StatusCode': status_code,
                'LatencySeconds': latency,
                'Timestamp': utc_timestamp
            }
            
            table_client.create_entity(entity=entity)
            
            if status_code != 200:
                logging.error(f"Endpoint {endpoint} returned non-200 status code: {status_code}")
            else:
                logging.info(f"Successfully checked {endpoint} - Status: {status_code}, Latency: {latency}s")
                
        except requests.RequestException as e:
            logging.error(f"Error checking endpoint {endpoint}: {e}")
            entity = {
                'PartitionKey': "UptimeCheck",
                'RowKey': str(datetime.datetime.utcnow().timestamp()),
                'Endpoint': endpoint,
                'StatusCode': 0,
                'LatencySeconds': 0.0,
                'Error': str(e),
                'Timestamp': utc_timestamp
            }
            table_client.create_entity(entity=entity)
