#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <ESP8266mDNS.h>

#ifndef STASSID
#define STASSID "LOC"
#define STAPSK  "flogisto"
#endif

const char* ssid = STASSID;
const char* password = STAPSK;
String stringa;

ESP8266WebServer server(80);

const int led = 2;

void handleRoot() {
   boolean memorizza=false;
   stringa="PIC response: ";
   while (Serial.available()) {
      delay(3);  //delay to allow buffer to fill
      if (Serial.available() >0) {
        char c = Serial.read();  //gets one byte from serial buffer
        if ( c == 'H') {
          memorizza=true;
        }
        if (memorizza==true) {
          stringa += c; //makes the string readString
        }
        if (( c == 'B')&&(memorizza==true)) {
          boolean memorizza=false;
          break;
        }
      }
    } 
    digitalWrite(led, 1);
    server.send(200, "text/plain", stringa);
    Serial.println(stringa);
}

void handleNotFound() {
  digitalWrite(led, 1);
  String message = "File Not Found\n\n";
  message += "URI: ";
  message += server.uri();
  message += "\nMethod: ";
  message += (server.method() == HTTP_GET) ? "GET" : "POST";
  message += "\nArguments: ";
  message += server.args();
  message += "\n";
  for (uint8_t i = 0; i < server.args(); i++) {
    message += " " + server.argName(i) + ": " + server.arg(i) + "\n";
  }
  server.send(404, "text/plain", message);
  digitalWrite(led, 0);
}

void setup(void) {
  pinMode(led, OUTPUT);
  digitalWrite(led, 0);
  Serial.begin(2400);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);
  Serial.println("");

  Serial.println("");
  Serial.print("Created AP: ");
  Serial.println(ssid);
  Serial.println("IP address is (hardcoded): 192.168.4.1");

  if (MDNS.begin("esp8266")) {
    Serial.println("MDNS responder started");
  }

  server.on("/", handleRoot);

  server.on("/on", []() {
    server.send(200, "text/plain", "this works as well: ON");
    digitalWrite(led, 0);
  });
  server.on("/off", []() {
    server.send(200, "text/plain", "this works as well: OFF");
    digitalWrite(led, 1);
  });

  server.onNotFound(handleNotFound);

  server.begin();
  Serial.println("HTTP server started");
}

void loop(void) {
  server.handleClient();
  MDNS.update();
}
