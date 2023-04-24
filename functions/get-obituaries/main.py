import json
import boto3
import urllib.parse
import urllib.request


dynamodb_resource = boto3.resource("dynamodb", region_name='ca-central-1')
table = dynamodb_resource.Table("the-last-show-30141162")



def lambda_handler(event, context):

        try:
            res = table.scan()

            if res["Count"] == 0:

              return {

                    "statusCode": 200,
                    "body": json.dumps({
                 "message": "Database is empty",
                 "data": res["Items"]
                    })
                    }

            return{
                    "statusCode": 200,
                    "body": json.dumps({
                 "message": "Database has items",
                 "data": res["Items"]
                    })
                    }

        except Exception as exp:
            print(f"exception: {exp}")
            return {
                "statusCode": 500,
                "body": json.dumps({
                    "message": str(exp)
                })
            }