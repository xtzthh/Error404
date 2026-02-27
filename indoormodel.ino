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