from io import BytesIO

import asyncio
from azure.identity.aio import DefaultAzureCredential
from azure.storage.blob.aio import BlobServiceClient

try:
    account_url = "https://holodelta.blob.core.windows.net"
    default_credential = DefaultAzureCredential()

    # Create the BlobServiceClient object
    blob_service_client = BlobServiceClient(account_url, credential=default_credential)

    card_data_client = blob_service_client.get_blob_client(container="holodelta", blob="cardData.zip")

except Exception as ex:
    print('Exception:')
    print(ex)

async def get_card_data():
    stream = BytesIO()
    card_data_stream = await card_data_client.download_blob()
    await card_data_stream.readinto(stream)
    stream.seek(0) #Thank you Saum
    return stream