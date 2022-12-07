import os
import uuid
import requests
import json
import asyncio
from azure.storage.blob import BlobServiceClient
from flask import Flask, request, redirect
from azure.cosmos.aio import CosmosClient as cosmos_client
from azure.cosmos import PartitionKey, exceptions
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential
from datetime import datetime

# ------------------------------------------------------------------------------ cosmos

# <add_uri_and_key>
endpoint = "https://receiptcosmos5412.documents.azure.com:443/"
key = "vccB3x0Ug0xF1i20td7Xu5NtU4DjlWKTnWh2oipgHk1J2y0rJPOeh79m5cuET6ILBjixfIZROp435UgwrcRagw=="
# </add_uri_and_key>

# <define_database_and_container_name>
receipt_info_database_name = 'AzureReceiptInfoDatabase'
receipt_info_cosmos_container_name = 'ReceiptInfoContainer'
# </define_database_and_container_name>

# <define_database_and_container_name>
user_info_database_name = 'AzureUserInfoDatabase'
user_info_cosmos_container_name = 'UserInfoContainer'
# </define_database_and_container_name>

# <create_database_if_not_exists>
async def get_or_create_db(client, database_name):
    try:
        database_obj  = client.get_database_client(database_name)
        await database_obj.read()
        return database_obj
    except exceptions.CosmosResourceNotFoundError:
        print("Creating database")
        return await client.create_database(database_name)
# </create_database_if_not_exists>
    
# Create a container
# Using a good partition key improves the performance of database operations.
# <create_container_if_not_exists>
async def get_or_create_container(database_obj, cosmos_container_name):
    try:        
        todo_items_container = database_obj.get_container_client(cosmos_container_name)
        await todo_items_container.read()   
        return todo_items_container
    except exceptions.CosmosResourceNotFoundError:
        print("Creating container with lastName as partition key")
        return await database_obj.create_container(
            id=cosmos_container_name,
            partition_key=PartitionKey(path="/user"),
            offer_throughput=400)
    except exceptions.CosmosHttpResponseError:
        raise
# </create_container_if_not_exists>
    
# <method_populate_container_items>
async def populate_container_items(container_obj, items_to_create):
    # Add items to the container
    receipt_items_to_create = items_to_create
    # <create_item>
    for receipt_item in receipt_items_to_create:
        inserted_item = await container_obj.create_item(body=receipt_item)
        print("Inserted receipt item for %s user. Item Id: %s" %(inserted_item['user'], inserted_item['id']))
    # </create_item>
# </method_populate_container_items>

# <method_read_items>
async def read_items(container_obj, items_to_read):
    # Read items (key value lookups by partition key and id, aka point reads)
    # <read_item>
    for receipt in items_to_read:
        item_response = await container_obj.read_item(item=receipt['id'], partition_key=receipt['user'])
        request_charge = container_obj.client_connection.last_response_headers['x-ms-request-charge']
        print('Read item with id {0}. Operation consumed {1} request units'.format(item_response['id'], (request_charge)))
    # </read_item>
# </method_read_items>

# <method_query_items>
async def query_items(container_obj, query_text):
    # enable_cross_partition_query should be set to True as the container is partitioned
    # In this case, we do have to await the asynchronous iterator object since logic
    # within the query_items() method makes network calls to verify the partition key
    # definition in the container
    # <query_items>
    query_items_response = container_obj.query_items(
        query=query_text,
        enable_cross_partition_query=True
    )
    request_charge = container_obj.client_connection.last_response_headers['x-ms-request-charge']
    items = [item async for item in query_items_response]
    print('Query returned {0} items. Operation consumed {1} request units'.format(len(items), request_charge))
    # </query_items>
# </method_query_items>

# <run_sample>
async def add_receipt_items(receipt_items_to_create):
    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, receipt_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, receipt_info_cosmos_container_name)
            # populate the family items in container
            await populate_container_items(container_obj, receipt_items_to_create)  
            # # read the just populated items using their id and partition key
            # await read_items(container_obj, receipt_items_to_create)
            # # Query these items using the SQL query syntax. 
            # # Specifying the partition key value in the query allows Cosmos DB to retrieve data only from the relevant partitions, which improves performance
            # query = "SELECT * FROM c WHERE c.user in ('Bob')"   #TODO: replace user with actual user id
            # await query_items(container_obj, query)                 
        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nReceipt successfully added")
# </run_sample>


async def create_user(user_id):
    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, user_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, user_info_cosmos_container_name)

            curr_month = datetime.now().month
            curr_year = datetime.now().year

            prev_month = -1
            prev_year = curr_year
            if curr_month == 1:
                prev_month = 12
                prev_year -= 1
            else:
                prev_month = curr_month - 1

            curr_user_trends = {
                'id': user_id,
                'money_spent': 0,
                'receipts_scanned': 0,
                'money_growth': 0,
                'scan_growth': 0,
                'sorted_items': [],
                'current_month': curr_month,
                'current_year': curr_year
            }
            prev_user_trends = {
                'id': user_id,
                'money_spent': 0,
                'receipts_scanned': 0,
                'money_growth': 0,
                'scan_growth': 0,
                'sorted_items': [],
                'current_month': prev_month,
                'current_year': prev_year
            }
            container_obj.create_item(body=prev_user_trends) 
            container_obj.create_item(body=curr_user_trends) 
        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nUser trends successfully created")


# <run_sample>
async def update_user_trends(user_id, receipt_item):
    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, user_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, user_info_cosmos_container_name)

            curr_year = datetime.now().year
            curr_month = datetime.now().month

            print('curr_year', curr_year)
            print('curr_month', curr_month)

            # query by user_id and curr year and curr month
            QUERY = "SELECT * FROM c WHERE c.user = @user_id and c.current_year = @curr_year and c.current_month = @curr_month"
            params = [dict(name="@user_id", value=user_id), 
                    dict(name="@curr_year", value=curr_year), 
                    dict(name="@curr_month", value=curr_month)]
            # params = [dict(name=["@user_id", "@curr_year", "@curr_month"], value=[user_id, curr_year, curr_month])]    


            curr_user_trends = container_obj.query_items(
                query=QUERY, parameters=params, enable_cross_partition_query=False
            )

            # query by user_id and prev year and prev month
            QUERY = "SELECT * FROM c WHERE c.user = @user_id and c.current_year = @prev_year and c.current_month = @prev_month"

            prev_month = -1
            prev_year = curr_year
            if curr_month == 1:
                prev_month = 12
                prev_year -= 1
            else:
                prev_month = curr_month - 1

            print('prev_year', prev_year)
            print('prev_month', prev_month)
            
            params = [dict(name="@user_id", value=user_id), 
                    dict(name="@prev_year", value=prev_year), 
                    dict(name="@prev_month", value=prev_month)]    
            # params = [dict(name=["@user_id", "@prev_year", "@prev_month"], value=[user_id, prev_year, prev_month])]

            prev_user_trends = container_obj.query_items(
                query=QUERY, parameters=params, enable_cross_partition_query=False
            )


            curr_trends = []
            async for trend in curr_user_trends:
                curr_trends.append(trend)

            print('currtrends', curr_trends)

            prev_trends = []
            async for trend in prev_user_trends:
                prev_trends.append(trend)

            print('prevtrends', prev_trends)
            
            # receipt_item = {
            #     'id': 'receipt_' + filename,
            #     'image_url': receipt_link,
            #     'user': user_id,
            #     "items": items,
            #     "total_price": total_price,
            #     "subtotal": subtotal,
            #     "tax": tax,
            #     "purchase_date": purchase_date
            # }

            curr_trends[0]['money_spent'] = curr_trends[0]['money_spent'] + receipt_item['total_price']
            curr_trends[0]['receipts_scanned'] = curr_trends[0]['receipts_scanned'] + 1
            curr_trends[0]['money_growth'] = curr_trends[0]['money_spent'] - prev_trends[0]['money_spent']
            curr_trends[0]['scan_growth'] = curr_trends[0]['receipts_scanned'] - prev_trends[0]['receipts_scanned']
            print('money spent', curr_trends[0]['money_spent'])
            print('receipts scanned', curr_trends[0]['receipts_scanned'])
            print('money growth', curr_trends[0]['money_growth'])
            print('scan growth', curr_trends[0]['scan_growth'])
            curr_trends[0]['sorted_items'].extend(receipt_item['items'])
            print('old sorted items', curr_trends[0]['sorted_items'])
            print('items to add', receipt_item['items'])
            print('new sorted items', curr_trends[0]['sorted_items'])
            sorted(curr_trends[0]['sorted_items'], key=curr_trends[0]['sorted_items'].count, reverse=True)
            print('new sorted items properly?', curr_trends[0]['sorted_items'])

            await container_obj.replace_item(item=curr_trends[0], body=curr_trends[0])

            # # populate the family items in container
            # await populate_container_items(container_obj, receipt_items_to_create)  
            # # read the just populated items using their id and partition key
            # await read_items(container_obj, receipt_items_to_create)
            # # Query these items using the SQL query syntax. 
            # # Specifying the partition key value in the query allows Cosmos DB to retrieve data only from the relevant partitions, which improves performance
            # query = "SELECT * FROM c WHERE c.user in ('Bob')"   #TODO: replace user with actual user id
            # await query_items(container_obj, query)                 
        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nReceipt successfully added")
# </run_sample>


# ---------------------------------------------------------------------------------- blob + flask app

app = Flask(__name__)

connect_str = "DefaultEndpointsProtocol=https;AccountName=receiptstorage5412;AccountKey=N050SWo8B1uEdaJ0n53wWXwj7fhsPrznWzLSnLaLkB2BcOFXCffIRLgLsaNwTu5WoYKhTFyLQG17+AStfZ8wjQ==;EndpointSuffix=core.windows.net"
#os.getenv('AZURE_STORAGE_CONNECTION_STRING') # retrieve the connection string from the environment variable
container_name = "receipts" # container name in which images will be store in the storage account

blob_service_client = BlobServiceClient.from_connection_string(conn_str=connect_str) # create a blob service client to interact with the storage account
try:
    print(connect_str)
    container_client = blob_service_client.get_container_client(container=container_name) # get container client to interact with the container in which images will be stored
    container_client.get_container_properties() # get properties of the container to force exception to be thrown if container does not exist
except Exception as e:
    print(e)
    print("Creating container...")
    container_client = blob_service_client.create_container(container_name) # create a container in the storage account if it does not exist

@app.route("/")
def view_receipts():
    blob_items = container_client.list_blobs() # list all the blobs in the container

    img_html = "<div style='display: flex; justify-content: space-between; flex-wrap: wrap;'>"

    for blob in blob_items:
        blob_client = container_client.get_blob_client(blob=blob.name) # get blob client to interact with the blob and get blob url
        img_html += "<img src='{}' width='auto' height='200' style='margin: 0.5em 0;'/>".format(blob_client.url) # get the blob url and append it to the html
    
    img_html += "</div>"

    # return the html with the images
    return """
    <head>
    <!-- CSS only -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
    </head>
    <body>
        <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
            <div class="container">
                <a class="navbar-brand" href="/">Receipt Interpreter App</a>
            </div>
        </nav>
        <div class="container">
            <div class="card" style="margin: 1em 0; padding: 1em 0 0 0; align-items: center;">
                <h3>Upload new receipt</h3>
                <div class="form-group">
                    <form method="post" action="/upload-receipts" 
                        enctype="multipart/form-data">
                        <div style="display: flex;">
                            <input type="file" accept=".png, .jpeg, .jpg, .gif" name="receipts" multiple class="form-control" style="margin-right: 1em;">
                            <input type="submit" class="btn btn-dark">
                        </div>
                    </form>
                </div> 
            </div>
    """ + img_html + "</div></body>"


ml_endpoint = "https://receiptparser5412.cognitiveservices.azure.com/"
ml_credential = AzureKeyCredential("bc47c289ba524ad5a95a911da7dec573")

document_analysis_client = DocumentAnalysisClient(ml_endpoint, ml_credential)

receipt_link_prefix = "https://receiptstorage5412.blob.core.windows.net/receipts/"
walmart_api_key = "2366937BE2C545AAB92ABB7D0DCE42B1"

# flask endpoint to upload a photo
@app.route("/upload-receipts", methods=["POST"])
async def upload_receipts():
    receipt_items_to_create = []
    filenames = ""
    #args = request.args 
    user_id = 'Bob' #args.get('user_id') #TODO: change back

    for file in request.files.getlist("receipts"):
        try:
            filename = file.filename + str(uuid.uuid4())
            container_client.upload_blob(filename, file) # upload the file to the container using the filename as the blob name
            filenames += file.filename + "<br /> "

            ### ----------------------- perform ml on the receipt ----------------------- ###
            
            # testing
            print('start analyzing')

            # option 1: somehow download receipt as jpg?
            # with open("testreceipt.jpg", "rb") as fd:
            #     receipt = fd.read()
            # poller = document_analysis_client.begin_analyze_document("prebuilt-receipt", receipt)

            # testing
            print('orig filename', file.filename)
            print('new filename', filename)
            print(file)

            # option 2: use the url of the receipt stored in the blob
            receipt_link = receipt_link_prefix + filename

            # testing
            print('link to receipt', receipt_link)

            poller = document_analysis_client.begin_analyze_document_from_url("prebuilt-receipt", receipt_link)
            result = poller.result()
            purchase_date = "undetermined" #transaction date
            items = [] #array of item tuple (name, price, quantity, related_item_name), name and related_item_name is from walmart api
            total_price = "undetermined"
            subtotal = "undetermined"
            tax = "undetermined"

            print('analysis finished, starting to parse')
            
            for receipt in result.documents:
                for name, field in receipt.fields.items():
                    if name == "Items":
                        for idx, item in enumerate(field.value):
                            product_name = "undetermined"
                            product_price = "undetermined"
                            related_product = "undetermined"
                            related_product_link = "undetermined"
                            for item_field_name, item_field in item.value.items():
                                if item_field_name == 'Description':
                                    product_name = item_field.value
                                    params = {
                                        'api_key': walmart_api_key,
                                        'search_term': product_name,
                                        'type': 'search'
                                    }
                                    print('starting request')
                                    api_result = requests.get('https://api.bluecartapi.com/request', params)
                                    print('request ended')
                                    json_result = api_result.json()
                                    print('jsonres', json_result)
                                    if len(json_result['search_results']) >= 2:
                                        related_product = json_result["search_results"][-1]["product"]["title"]
                                        related_product_link = json_result["search_results"][-1]["product"]["link"]
                                elif item_field_name == 'TotalPrice':
                                    product_price = item_field.value
                            items.append({"product_name": product_name, 
                            "product_price": product_price, 
                            "related_product": related_product,
                            "related_product_link": related_product_link})
                    elif name == "Total":
                        total_price = field.value
                    elif name == "Subtotal":
                        subtotal = field.value
                    elif name == "TotalTax":
                        tax = field.value
                    elif name == "TransactionDate":
                        purchase_date = str(field.value)

            # testing
            print('items', items)
            print('total', total_price)
            print('subtot', subtotal)
            print('totaltax', tax)
            print('transactdate', purchase_date)
            
            receipt_item = {
                'id': 'receipt_' + filename,
                'image_url': receipt_link,
                'user': user_id,
                "items": items,
                "total_price": total_price,
                "subtotal": subtotal,
                "tax": tax,
                "purchase_date": purchase_date,
                "upload_date": str(datetime.now())
            }

            receipt_items_to_create.append(receipt_item)

            await update_user_trends(user_id, receipt_item)

        except Exception as e:
            print(e)

    ### ----------------------- post to cosmos with the analysis after performing ml----------------------- ###
    await add_receipt_items(receipt_items_to_create)
        
    return receipt_items_to_create

# flask endpoint to view receipt items of a user by query parameter
@app.route("/view-user-receipt-items", methods=["GET"])
async def view_receipt_items():
    
    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, receipt_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, receipt_info_cosmos_container_name)

            args = request.args 
            user_id = args.get('user_id')

            QUERY = "SELECT * FROM c WHERE c.user = @user_id"
            params = [dict(name="@user_id", value=user_id)]    

            items = container_obj.query_items(
                query=QUERY, parameters=params, enable_cross_partition_query=False
            )

            receipt_items = []

            async for item in items:
                receipt_items.append(item)

            return receipt_items

        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nReceipt items successfully returned")


# flask endpoint to create user
@app.route("/create-user", methods=["GET"])
async def create_trends():

    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, user_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, user_info_cosmos_container_name)

            curr_month = datetime.now().month
            curr_year = datetime.now().year

            prev_month = -1
            prev_year = curr_year
            if curr_month == 1:
                prev_month = 12
                prev_year -= 1
            else:
                prev_month = curr_month - 1

            args = request.args 
            user_id = args.get('user_id')

            curr_user_trends = {
                'id': 'trend' + str(uuid.uuid4()),
                'user': user_id,
                'money_spent': 0,
                'receipts_scanned': 0,
                'money_growth': 0,
                'scan_growth': 0,
                'sorted_items': [],
                'current_month': curr_month,
                'current_year': curr_year
            }
            prev_user_trends = {
                'id': 'trend' + str(uuid.uuid4()),
                'user': user_id,
                'money_spent': 0,
                'receipts_scanned': 0,
                'money_growth': 0,
                'scan_growth': 0,
                'sorted_items': [],
                'current_month': prev_month,
                'current_year': prev_year
            }

            await container_obj.create_item(body=prev_user_trends) 
            await container_obj.create_item(body=curr_user_trends) 

            return curr_user_trends

        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nUser trends successfully created")

        

# flask endpoint to get shopping trends of a user by query parameter
@app.route("/view-user-trends", methods=["GET"])
async def view_trends():
    
    # <create_cosmos_client>
    async with cosmos_client(endpoint, credential = key) as client:
    # </create_cosmos_client>
        try:
            # create a database
            database_obj = await get_or_create_db(client, user_info_database_name)
            # create a container
            container_obj = await get_or_create_container(database_obj, user_info_cosmos_container_name)

            args = request.args 
            user_id = args.get('user_id')

            QUERY = "SELECT * FROM c WHERE c.user = @user_id"
            params = [dict(name="@user_id", value=user_id)]    

            user_trends = container_obj.query_items(
                query=QUERY, parameters=params, enable_cross_partition_query=False
            )

            trends = []
            async for trend in user_trends:
                trends.append(trend)
            return trends

        except exceptions.CosmosHttpResponseError as e:
            print('\nrun_sample has caught an error. {0}'.format(e.message))
        finally:
            print("\nReceipt items successfully returned")