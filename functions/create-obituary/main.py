# add your create-obituary function here
import boto3
import json
import requests
from requests_toolbelt.multipart import decoder
import base64
import os
import time
import hashlib

def upload_to_cloudinary(api_secret,filename,resource_type = "image", extra_field = {}): 
    client = boto3.client('ssm', region_name = "ca-central-1")
    response = client.get_parameters_by_path(
        Path='/the-last-show/',
        Recursive=True,
        WithDecryption=True,
    )

    params = {key["Name"]: key["Value"] for key in response["Parameters"]}

    api_key = str(params["/the-last-show/cloudinary-key"])

    cloud_name = str(params["/the-last-show/cloud-name"])

    body = {
        "api_key": api_key, 
    }

    #with open(filename, "rb") as f:
        #file_info = f.read()
    files ={
        "file": open(filename,"rb")
    }

    body.update(extra_field)
    body["signature"] = create_signature(body,api_secret)
    


    url = f"https://api.cloudinary.com/v1_1/{cloud_name}/{resource_type}/upload"
    res = requests.post(url, files= files, data= body)
    print(filename)
    print(res.json())


    return res.json()



def create_signature(body, api_secret):
    exclude = ["api_key","resource_type","cloud_name"]
    timestamp = int(time.time())
    body["timestamp"] = timestamp

    sorted = sort_dictionary(dictionary = body,exclude = exclude)
    query_string = create_query_string( body = sorted)
    query_string_addended = f"{query_string}{api_secret}"
    hashed = hashlib.sha1(query_string_addended.encode())
    signature = hashed.hexdigest()
    print(signature)
    return signature

def sort_dictionary(dictionary,exclude):
    return{k:v for k,v in sorted(dictionary.items(), key= lambda item:item[0]) if k not in exclude}

def create_query_string(body):
    query_string = ""
    for idx, (k,v) in enumerate(body.items()):
        query_string = f"{k}={v}" if idx == 0 else f"{query_string}&{k}={v}"
    
    return query_string


def get_gpt_response(gpt_secret, prompt):
    print(gpt_secret)
    print(prompt)

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {gpt_secret}",
    }

    data = {
        "prompt": prompt,
        "max_tokens": 600,
        "n": 1,
    }
    url = "https://api.openai.com/v1/engines/text-curie-001/completions"
    response = requests.post(url, headers=headers, data=json.dumps(data))
    if response.status_code != 200:
        raise ValueError(f'Request failed with status code {response.status_code}')
    response_data = json.loads(response.text)
    return response_data["choices"][0]["text"]


def text_to_speech(gpt_res):
    polly_client = boto3.client('polly')
    response = polly_client.synthesize_speech(
        Engine='standard',
        LanguageCode='en-US',
        OutputFormat='mp3',
        Text= gpt_res,
        TextType='text',
        VoiceId='Joanna'
    )
    print(response)

    filename = os.path.join("/tmp","polly.mp3")
    with open(filename,"wb") as f:
        f.write(response["AudioStream"].read())

    return filename


def lambda_handler(event, context):

    client = boto3.client('ssm', region_name = "ca-central-1")

    response = client.get_parameters_by_path(
        Path='/the-last-show/',
        Recursive=True,
        WithDecryption=True,
    )

    params = {key["Name"]: key["Value"] for key in response["Parameters"]}

    cloudinary_secret = str(params["/the-last-show/cloudinary-secret"])

    gpt_secret = str(params["/the-last-show/gpt-key"])

    image_body = event["body"]

    if event["isBase64Encoded"]:
        image_body = base64.b64decode(image_body)

    content_type= event["headers"]["content-type"]
    data = decoder.MultipartDecoder(image_body,content_type)

    binary_data = [part.content for part in data.parts]
    name = binary_data[1].decode()
    born = binary_data[2].decode()
    death = binary_data[3].decode()


    file_name = os.path.join("/tmp","obituary.png")
    with open(file_name,"wb") as f:
        f.write(binary_data[0])
    
    res = upload_to_cloudinary(api_secret=cloudinary_secret,filename=file_name, extra_field={"eager": "e_art:zorro,e_grayscale,w_150,h_150,c_fill,g_face,r_max"}) #extra_field={"eager": "e_art:zorro"}
    cloudinary_url = res["eager"][0]["secure_url"]
    print(cloudinary_url)

    gpt_prompt = f"write an obituary about a fictional character named {name} who was born on {born} and died on {death}."

    gpt_res = get_gpt_response(gpt_secret,prompt=gpt_prompt)
    print(gpt_res)

    polly_res = text_to_speech(gpt_res)
    print(polly_res)
    polly_upload = upload_to_cloudinary(api_secret = cloudinary_secret,filename=polly_res,resource_type="raw")
    polly_url= polly_upload["secure_url"]
    print(polly_url)

    dynamodb = boto3.resource('dynamodb')
    print(event["headers"]["id"])
    
    response = dynamodb.Table("the-last-show-30141162").put_item(
        Item={
        'id': str(event["headers"]["id"]),
        'Name': str(name),
        'Born': str(born),
        "Death": str(death),
        "Image": str(cloudinary_url),
        "Text": str(gpt_res),
        "mp3": str(polly_url)
        }

    
 
    )




    
    