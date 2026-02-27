/************************************************************
 SMART AGRIVAULT

#define TINY_GSM_MODEM_SIM800
#define SerialMon Serial
#define SerialAT Serial1
#define GSM_PIN ""

#include <TinyGsmClient.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

/************************************************************
                    SERVER CONFIGURATION
************************************************************/
const char* THINGSPEAK_SERVER = "api.thingspeak.com";
const char* THINGSPEAK_API_KEY = "GB0URGQ4BC3784LQ";

/************************************************************
                    GSM CONFIGURATION
************************************************************/
#define MODEM_RST 5
#define MODEM_PWKEY 4
#define MODEM_POWER_ON 23
#define MODEM_TX 27
#define MODEM_RX 26
#define SMS_NUMBER "7028014660"

/************************************************************
                    OLED CONFIGURATION
************************************************************/
#define I2C_SDA 21
#define I2C_SCL 22
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define SCREEN_ADDRESS 0x3C

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

/************************************************************
                    SENSOR CONFIGURATION
************************************************************/
#define DHTPIN 13
#define DHTTYPE DHT22
#define FIRE_SENSOR_PIN 25
#define MQ137_PIN 35
#define MG811_PIN 34
#define SW420_PIN 32
#define VENT_RELAY_PIN 14

/************************************************************
                    OBJECT INITIALIZATION
************************************************************/
DHT dht(DHTPIN, DHTTYPE);
TinyGsm modem(SerialAT);
TinyGsmClient client(modem);

/************************************************************
                    GLOBAL VARIABLES
************************************************************/
float temperature = 0;
float humidity = 0;
int fireStatus = 0;
int vibrationStatus = 0;
int nh3Value = 0;
int co2Value = 0;

String tempStatus = "SAFE";
String humStatus = "SAFE";
String nh3Status = "SAFE";
String co2Status = "SAFE";
String overallStatus = "SAFE";

bool ventilationON = false;
bool networkConnected = false;

unsigned long lastSMS = 0;
unsigned long lastCloud = 0;
unsigned long lastSensorRead = 0;

const unsigned long SMS_INTERVAL = 15000;
const unsigned long CLOUD_INTERVAL = 15000;
const unsigned long SENSOR_INTERVAL = 3000;

/************************************************************
                    STATUS CHECK FUNCTIONS
************************************************************/
String checkTemperature(float t){
  if(t >= 15 && t <= 25) return "SAFE";
  else if(t <= 30) return "WARNING";
  else return "DANGER";
}

String checkHumidity(float h){
  if(h <= 70) return "SAFE";
  else if(h <= 80) return "WARNING";
  else return "DANGER";
}

String checkNH3(int v){
  if(v <= 5) return "SAFE";
  else if(v <= 15) return "WARNING";
  else return "DANGER";
}

String checkCO2(int v){
  if(v <= 1500) return "SAFE";
  else if(v <= 3000) return "WARNING";
  else return "DANGER";
}

/************************************************************
                    SENSOR READING FUNCTION
************************************************************/
void readSensors(){

  temperature = dht.readTemperature();
  humidity = dht.readHumidity();

  if(isnan(temperature) || isnan(humidity)){
    temperature = 0;
    humidity = 0;
  }

  fireStatus = (digitalRead(FIRE_SENSOR_PIN)==LOW)?1:0;
  vibrationStatus = (digitalRead(SW420_PIN)==HIGH)?1:0;

  nh3Value = analogRead(MQ137_PIN);
  co2Value = analogRead(MG811_PIN);

  tempStatus = checkTemperature(temperature);
  humStatus  = checkHumidity(humidity);
  nh3Status  = checkNH3(nh3Value);
  co2Status  = checkCO2(co2Value);

  evaluateOverallStatus();
}

/************************************************************
                OVERALL DECISION LOGIC
************************************************************/
void evaluateOverallStatus(){

  if(fireStatus == 1){
    overallStatus = "DANGER";
  }
  else if(tempStatus=="DANGER" || humStatus=="DANGER" || 
          nh3Status=="DANGER" || co2Status=="DANGER"){
    overallStatus = "DANGER";
  }
  else if(tempStatus=="WARNING" || humStatus=="WARNING" || 
          nh3Status=="WARNING" || co2Status=="WARNING"){
    overallStatus = "WARNING";
  }
  else{
    overallStatus = "SAFE";
  }

  controlVentilation();
}

/************************************************************
                VENTILATION CONTROL
************************************************************/
void controlVentilation(){

  if(co2Status!="SAFE" || nh3Status!="SAFE"){
    ventilationON = true;
    digitalWrite(VENT_RELAY_PIN, HIGH);
  }
  else{
    ventilationON = false;
    digitalWrite(VENT_RELAY_PIN, LOW);
  }
}

/************************************************************
                OLED DISPLAY FUNCTION
************************************************************/
void updateDisplay(){

  display.clearDisplay();
  display.setCursor(0,0);
  display.setTextSize(1);
  display.println("SMART AGRIVAULT");

  display.print("Temp: ");
  display.print(temperature);
  display.println(" C");

  display.print("Hum: ");
  display.print(humidity);
  display.println(" %");

  display.print("CO2: ");
  display.println(co2Value);

  display.print("NH3: ");
  display.println(nh3Value);

  display.print("Fire: ");
  display.println(fireStatus?"YES":"NO");

  display.print("Vent: ");
  display.println(ventilationON?"ON":"OFF");

  display.print("Status: ");
  display.println(overallStatus);

  display.display();
}

/************************************************************
                SMS GENERATION
************************************************************/
String generateSMS(){

  String sms = "SMART AGRIVAULT\n";
  sms += "Temp:" + String(temperature) + "C\n";
  sms += "Hum:" + String(humidity) + "%\n";
  sms += "CO2:" + String(co2Value) + "\n";
  sms += "NH3:" + String(nh3Value) + "\n";
  sms += "Fire:" + String(fireStatus?"YES":"NO") + "\n";
  sms += "Vib:" + String(vibrationStatus?"YES":"NO") + "\n";
  sms += "Vent:" + String(ventilationON?"ON":"OFF") + "\n";
  sms += "Status:" + overallStatus;

  return sms;
}

/************************************************************
                SEND SMS FUNCTION
************************************************************/
void sendSMS(){

  if(millis() - lastSMS >= SMS_INTERVAL){

    lastSMS = millis();

    String message = generateSMS();

    modem.sendSMS(SMS_NUMBER, message);
  }
}

/************************************************************
                CLOUD UPLOAD FUNCTION
************************************************************/
int statusToNumber(String s){
  if(s=="SAFE") return 0;
  if(s=="WARNING") return 1;
  return 2;
}

void sendToThingSpeak(){

  if(!client.connect(THINGSPEAK_SERVER,80)) return;

  String url="/update?api_key="+String(THINGSPEAK_API_KEY)+
  "&field1="+String(temperature)+
  "&field2="+String(humidity)+
  "&field3="+String(co2Value)+
  "&field4="+String(nh3Value)+
  "&field5="+String(fireStatus)+
  "&field6="+String(vibrationStatus)+
  "&field7="+String(statusToNumber(overallStatus));

  client.print(String("GET ")+url+" HTTP/1.1\r\n");
  client.print("Host: api.thingspeak.com\r\nConnection: close\r\n\r\n");
  client.stop();
}

/************************************************************
                GSM NETWORK CHECK
************************************************************/
void checkNetwork(){

  if(!modem.isNetworkConnected()){
    modem.restart();
    modem.waitForNetwork();
    modem.gprsConnect("www","","");
  }
}

/************************************************************
                    SETUP FUNCTION
************************************************************/
void setup(){

  SerialMon.begin(115200);

  pinMode(FIRE_SENSOR_PIN, INPUT_PULLUP);
  pinMode(SW420_PIN, INPUT_PULLDOWN);
  pinMode(VENT_RELAY_PIN, OUTPUT);

  dht.begin();
  analogSetAttenuation(ADC_11db);

  Wire.begin(I2C_SDA, I2C_SCL);
  display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS);
  display.setTextColor(SSD1306_WHITE);

  SerialAT.begin(9600,SERIAL_8N1,MODEM_RX,MODEM_TX);
  delay(3000);

  modem.restart();
  modem.waitForNetwork();
  modem.gprsConnect("www","","");
}