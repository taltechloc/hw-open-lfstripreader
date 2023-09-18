/*********
Wifi moduile firmware
*********/

// Including the ESP8266 WiFi library
#include <ESP8266WiFi.h>



// Replace with your network details
const char* ssid = "LOTR0";
const char* password = "flogisto";

// Web Server on port 80
WiFiServer server(80);


// only runs once on boot
void setup() {
  // Initializing serial port for debugging purposes
  Serial.begin(2400);
  delay(10);


  // Connecting to WiFi network
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.println("WiFi connected");
  
  // Starting the web server
  server.begin();
  Serial.println("Web server running. Waiting for the ESP IP...");
  delay(10000);
  
  // Printing the ESP IP address
  Serial.println(WiFi.localIP());
}

// runs over and over again
void loop() {
  // Listenning for new clients
  WiFiClient client = server.available();
  
  if (client) {
    Serial.println("New client");
    // bolean to locate when the http request ends
    boolean blank_line = true;
    while (client.connected()) {
      if (client.available()) {
           boolean scrivi=false;
           while (true)
           { char lettura = Serial.read();
              if (lettura= "H") {boolean scrivi=true;}
              if (scrivi=true) {
                Serial.print(lettura);
                client.print(lettura);
                if (lettura='B'){
                 Serial.println("closing connection");
                 client.stop();
                }
   
              }   
          }
     }
    }
  }
