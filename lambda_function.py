import os
import json
import urllib.request

def lambda_function(event, context):

    WEBHOOK = os.environ.get('DISCORD_WEBHOOK_URL')
    
    if not WEBHOOK:
        print("Błąd: Zmienna DISCORD_WEBHOOK_URL nie istnieje bądź jest pusta.")
        return{
            "statusCode": 500,
            "body": json.dumps("brak konfiguracji webhooka w zmiennych środowiskowych.")
        }

    aws_region = event.get("region")
    detale = event.get("detail") or {}
    user_identity = event.get('detail', {}).get('userIdentity', {})
    user_name = (
        user_identity.get('userName') or 
        user_identity.get('principalId', 'Nieznany / Konsola AWS')
    )
    event_detail = detale.get("eventName", "Nieznane zdarzenie")

    message_content = {
        "content": f"**AWS Security Alert!**\n"
                   f"**Zdarzenie:** `{event_detail}`\n"
                   f"**Użytkownik:** `{user_name}`\n"
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
            print(f"Powiadomienie wysłane! Status: {response.status}")
    except Exception as e:
        print(f"Błąd podczas wysyłania do Discorda: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps(str(e))
        }

    return {
        "statusCode": 200,
        "body": json.dumps("Pomyślnie przetworzono zdarzenie!")
    }