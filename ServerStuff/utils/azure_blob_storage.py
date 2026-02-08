from io import BytesIO

from azure.identity.aio import DefaultAzureCredential
from azure.storage.blob.aio import BlobServiceClient

try:
    account_url = "https://holodelta.blob.core.windows.net"
    default_credential = DefaultAzureCredential()

    # Create the BlobServiceClient object
    blob_service_client = BlobServiceClient(account_url, credential=default_credential)

except Exception as ex:
    print('Exception:')
    print(ex)

async def get_stream(data_client):
    stream = BytesIO()
    data_stream = await data_client.download_blob()
    await data_stream.readinto(stream)
    stream.seek(0) #Thank you Saum
    return stream

async def get_file(file_name):
    try:
        return await get_stream(blob_service_client.get_blob_client(container="holodelta", blob=file_name))
    except Exception as ex:
        print('Exception:')
        print(ex)
        return BytesIO()

async def upload_cosmetics(game_id, player_id, cosmetics_type, file_data):
    container_client = blob_service_client.get_container_client(container=game_id)

    if await container_client.exists():
        blob_client = container_client.get_blob_client(player_id + "-" + cosmetics_type + ".webp")
        await blob_client.upload_blob(file_data)

async def download_cosmetics(game_id, player_id, cosmetics_type):
    container_client = blob_service_client.get_container_client(container=game_id)

    if await container_client.exists():
        blob_client = container_client.get_blob_client(player_id + "-" + cosmetics_type + ".webp")
        if await blob_client.exists():
            return await get_stream(blob_client)

async def create_cosmetics(game_id):
    container_client = blob_service_client.get_container_client(container=game_id)
    if not await container_client.exists():
        await container_client.create_container()

async def delete_cosmetics(game_id):
    container_client = blob_service_client.get_container_client(container=game_id)

    if await container_client.exists():
        await container_client.delete_container()