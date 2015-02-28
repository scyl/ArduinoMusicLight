/*
 *  ArduinoMusicLight
 *  Play and analyse music to control NeoPixel LED lights through an Arduino
 *
 *  by Stephen Leung
 */

#include <Adafruit_NeoPixel.h>

int incomingByte = 0;
int led = 13;
int numRead = 0;

int i = 0;

// Setup connection to the NeoPixel
#define PIN 6
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, PIN, NEO_GRB + NEO_KHZ800);

void setup() {
  // Initialise the NeoPixel
  strip.begin();
  strip.setBrightness(255);
  
  for(uint16_t i=0; i<strip.numPixels(); i++) {
      strip.setPixelColor(i, 0, 0, 0);
  }
  
  strip.show();
  
  // Start the commication to the processing sketch
  Serial.begin(9600);
  pinMode(led, OUTPUT);
}

void loop() {
  // Read the data from the processing sketch and adjust the brightness of eatch
  // section of LEDs base on it
  if (Serial.available() > 0) {
    incomingByte = Serial.read();
    if (incomingByte == 0) {
      numRead = 0;
    } else {
      if (numRead == 0) {
        for (i=0; i<10; i++) {
          strip.setPixelColor(i, incomingByte, 0, 0);
        }
        for (i=50; i<60; i++) {
          strip.setPixelColor(i, incomingByte, 0, 0);
        }
      } else if (numRead == 1) {
        for (i=10; i<16; i++) {
          strip.setPixelColor(i, 0, incomingByte, 0);
        }
        for (i=44; i<50; i++) {
          strip.setPixelColor(i, 0, incomingByte, 0);
        }
      } else if (numRead == 2) {
        for (i=16; i<22; i++) {
          strip.setPixelColor(i, 0, 0, incomingByte);
        }
        for (i=38; i<44; i++) {
          strip.setPixelColor(i, 0, 0, incomingByte);
        }
      } else if (numRead == 3) {
        for (i=22; i<27; i++) {
          strip.setPixelColor(i, incomingByte, 0, incomingByte);
        }
        for (i=33; i<38; i++) {
          strip.setPixelColor(i, incomingByte, 0, incomingByte);
        }
      } else if (numRead == 4) {
        for (i=27; i<33; i++) {
          strip.setPixelColor(i, incomingByte, incomingByte, 0);
        }
      }
      
      // Flush the LEDs when all the sections are updated
      digitalWrite(led, LOW);
      if (numRead == 4) {
        strip.show();
        digitalWrite(led, HIGH);
      }
      numRead++;
    }
  }
}

