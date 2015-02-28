/*
 *  ArduinoMusicLight
 *  Play and analyse music to control NeoPixel LED lights through an Arduino
 *
 *  by Stephen Leung
 */

import java.util.ArrayList;
import java.util.LinkedList;
import ddf.minim.analysis.*;
import ddf.minim.*;
import processing.serial.*;

Minim minim;  
AudioPlayer music;
FFT fftLog;

int arduinoNum = 1; // The position of the arduino printed in the output
float spectrumScale = 5; // Default to 5 times
float FixedSpectrumScale = 2; // Always scale the spectrum by this
boolean filled = false;
ArrayList<Float> spectrumOrg = new ArrayList<Float>(60);
LinkedList<ArrayList<Float>> history = new LinkedList<ArrayList<Float>>();
ArrayList<Short> colors = new ArrayList<Short>(5);

Serial arduino;

void setup() {
  // Setup the window
  size(60*8, 512);
  frameRate(60);
  
  // Fill in history array
  ArrayList<Float> empty = new ArrayList<Float>(60);
  for(int i = 0; i < 60; i++) {
    empty.add(0.0);
  }
  history.addFirst(empty);
  history.addFirst(empty);
  
  // Load the file
  minim = new Minim(this);
  music = minim.loadFile("moy.mp3", 1024);
  
  // loop the file
  music.loop();
  
  // create an FFT object for calculating logarithmically spaced averages
  fftLog = new FFT( music.bufferSize(), music.sampleRate() );
  
  // calculate averages based on a miminum octave width
  fftLog.logAverages( 88, 8 );
  
  rectMode(CORNERS);
  
  // Connect to the arduino
  println(Serial.list());
  arduino = new Serial(this, Serial.list()[arduinoNum], 9600);
  
  // Set the LEDs to off
  for(int i = 0; i < 5; i++) {
    colors.add((short)0);
  }
}

void draw() {
  // Start a new blank screen
  background(0);
  fill(255);
  
  // Calculate the scpectrum from the music
  fftLog.forward( music.mix );
  
  int w = int( width/60 );
  
  // Get the scpectrum data and scale it up
  for(int i = 0; i < 60; i++) {
    float averageWidth = fftLog.getAverageBandWidth(i);
    spectrumScale = map(averageWidth, 14, 1400, 2, 12);
    spectrumOrg.add(i, fftLog.getAvg(i)*spectrumScale*FixedSpectrumScale);
  }
    
  // Smooth data
  ArrayList<Float> spectrumSmoothed =  smooth(smoothTime(spectrumOrg));
  
  
  // Simulate effects on screen
  
  // Red
  fill(255, 0, 0, map(spectrumSmoothed.get(0), 50, 512, 0, 255));
  rect(0, 0, 100, 30);
  rect(width, 0, width-100, 30);
  
  // Green
  fill(0, 255, 0, map(spectrumSmoothed.get(10), 30, 300, 0, 255));
  rect(100, 0, 130, 30);
  rect(width-100, 0, width-130, 30);
  
  // Blue
  fill(0, 0, 255, map(spectrumSmoothed.get(22), 50, 200, 0, 255));
  rect(130, 0, 180, 30);
  rect(width-130, 0, width-180, 30);
  
  // Purple
  int fourth = 0;
  for (int i = 26; i < 32; i++) {
    fourth += spectrumSmoothed.get(i);
  }
  fill(255, 0, 255, map(fourth, 130, 350, 0, 255));
  rect(180, 0, 220, 30);
  rect(width-180, 0, width-220, 30);
  
  // Yellow
  int fifth = 0;
  for (int i = 33; i < 50; i++) {
    fifth += spectrumSmoothed.get(i);
  }
  fill(255, 255, 0, map(fifth, 50, 600, 0, 255));
  rect(220, 0, 260, 30);
  
  // Set the LEDs to the desire brightness and color
  colors.set(0, (short)map(spectrumSmoothed.get(0), 50, 512, 1, 255));
  colors.set(1, (short)map(spectrumSmoothed.get(10), 30, 300, 1, 127));
  colors.set(2, (short)map(spectrumSmoothed.get(22), 50, 200, 1, 127));
  colors.set(3, (short)map(fourth, 130, 350, 1, 127));
  colors.set(4, (short)map(fifth, 50, 600, 1, 127));
  
  // If the spectrum is overflowing, cap it off at 0 and 255
  for (int i = 0; i < 5; i++) {
    if (colors.get(i) < 1) {
      colors.set(i, (short)1);
    }
    if (colors.get(i) > 255) {
      colors.set(i, (short)255);
    }
  }
  
  // Sent the color data to the arduino
  arduino.write(0);
  arduino.write(colors.get(0));
  arduino.write(colors.get(1));
  arduino.write(colors.get(2));
  arduino.write(colors.get(3));
  arduino.write(colors.get(4));

  
  // Draw graph
  fill(255);
  for(int i = 0; i < 60; i++) {
    if (i == 60) {
      fill(255,0,0);
    }
    rect( i*w, height, i*w+w, height - spectrumSmoothed.get(i) );
    fill(255);
  }
}

ArrayList smoothTime(ArrayList<Float> newData) {
  // Smooth the spectrum base on what each band's value was in the last few frames
  ArrayList<Float> timeSmooth = new ArrayList<Float>(newData.size());
  
  for(int i = 0; i < 60; i++) {
    timeSmooth.add(i, historySmooth(i, newData.get(i)));
  }
  history.remove(1);
  history.addFirst(timeSmooth);
  
  return history.get(0);
}

float historySmooth(int index, float num) {
  history.get(0).get(index);
  return (num+(history.get(0).get(index)/2)+(history.get(1).get(index)/4)) / 1.75;
}

ArrayList smooth(ArrayList<Float> org) {
  // Smooth the spectrum base on the value of the neighbouring bands
  ArrayList<Float> spectrumSmooth = new ArrayList<Float>(org.size());
  
  spectrumSmooth.add(0, weightAverage(org.get(0), org.get(0), org.get(1)));
  
  for(int i = 1; i < 59; i++) {
    spectrumSmooth.add(i, weightAverage(org.get(i-1), org.get(i), org.get(i+1)));
  }
  
  spectrumSmooth.add(59, weightAverage(org.get(58), org.get(59), org.get(59)));
  
  return spectrumSmooth;
}

float weightAverage(float num1, float num2, float num3) {
  // Calculate the weighted average of 3 numbers with num2 having 50% weight and num1 & num3 have 25% each
  return (num2+((num1+num3)/2))/2;
}
