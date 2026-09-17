import os
import json
import urllib.request

def lambda_function(event, context):

    WEBHOOK = os.environ.get('DISCORD_WEBHOOK_URL')
    
    if not WEBHOOK:
        print("Error: DISCORD_WEBHOOK_URL environment variable is missing or empty.")
        return{
            "statusCode": 500,
            "body": json.dumps("Discord webhook URL not set in environment variables.")
        }

    aws_region = event.get("region")
    detale = event.get("detail") or {}
    user_identity = event.get('detail', {}).get('userIdentity', {})
    user_name = (
        user_identity.get('userName') or 
        user_identity.get('principalId', 'Unknown / AWS Management Console')
    )
    event_detail = detale.get("eventName", "Unknown event")

    message_content = {
        "content": f"**AWS Security Alert!**\n"
                   f"**Event:** `{event_detail}`\n"
                   f"**User:** `{user_name}`\n"
                   f"**Region:** `{aws_region}`\n"
    }
    
    req = urllib.request.Request(
        WEBHOOK,
        data=json.dumps(message_content).encode('utf-8'),
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) SecurityNotifierBot/1.0'  
        })
    
    try:
        with urllib.request.urlopen(req) as response:
            print(f"Notification sent! Status: {response.status}")
    except Exception as e:
        print(f"Error sending message to Discord: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps(str(e))
        }

    return {
        "statusCode": 200,
        "body": json.dumps("Successfully processed the event!")
    }