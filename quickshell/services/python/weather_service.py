#!/usr/bin/env python3
import urllib.request
import json
import sys

def fetch_weather():
    city = "Local"
    temp = 22.0
    code = 0
    is_day = 1
    
    try:
        # 1. Geolocation Lookup via ip-api
        req = urllib.request.Request("http://ip-api.com/json/", headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=4) as response:
            loc = json.loads(response.read().decode())
            city = loc.get("city", "Local")
            lat = loc.get("lat", 0.0)
            lon = loc.get("lon", 0.0)

        # 2. Weather Data via Open-Meteo API
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true"
        req_weather = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req_weather, timeout=4) as resp_w:
            weather_data = json.loads(resp_w.read().decode())
            cw = weather_data.get("current_weather", {})
            temp = cw.get("temperature", temp)
            code = cw.get("weathercode", code)
            is_day = cw.get("is_day", is_day)

    except Exception:
        pass

    # Print delimited result string: City|||Temp|||WeatherCode|||IsDay
    print(f"{city}|||{temp}|||{code}|||{is_day}", flush=True)

if __name__ == "__main__":
    fetch_weather()
