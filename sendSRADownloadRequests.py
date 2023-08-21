import requests

# List of parameters
parameters = [
    {
        'sra': 'SRR8615052',
        'bucket_name': 'ncbi-ccle-data',
        'cores': '2'
    },
    {
        'sra': 'SRR8615087',
        'bucket_name': 'ncbi-ccle-data',
        'cores': '2'
    },
]

base_url = 'https://download-sra-a74brwai6q-pd.a.run.app/download'

# Iterate through the parameters and send requests
for param in parameters:
    url = f"{base_url}?sra={param['sra']}&bucket_name={param['bucket_name']}&cores={param['cores']}"
    response = requests.get(url)
    
    if response.status_code == 200:
        print(f"Request for {param['sra']} successful.")
        print(f"Content: {response.text}")
    else:
        print(f"Request for {param['sra']} failed. Status code: {response.status_code}")