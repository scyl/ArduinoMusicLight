ArduinoMusicLight
=============

Play and analyse music to control NeoPixel LED lights through an Arduino
 
Description
-----------
Play music on a processing sketch and using FFT to get the amplitude to each spectrum band, then base on the amplitude in specific bands, adjust the brightness of LEDs on a NeoPixel strip that in connected via an Arduino.

Files
-----
* ArduinoMusicLight.pde - The processing sketch that play the music, calculate the spectrum and output the brightness to the Arduino
* ArduinoMusicLightClient.ino - Arduino code that take the data from the processing sketch and control the NeoPixel with it

Dependencies
------------
* Minim
* Adafruit_NeoPixel library

Install/Setup
-------------
1. Download and install the Adafruit_NeoPixel library
2. Connect the NeoPixel according to Adafruit's guide, using pin 6 as data
3. Create a "data" folder and put the music you want to use in it
4. Edit the processing sketch section "Load the music file" with the file name of your music
5. Connect the Arduino to the computer
6. Run the processing sketch to see which device device number is the Arduino, then update the "arduinoNum" variable with that number
7. Upload the Arduino sketch and Run the processing sketch
