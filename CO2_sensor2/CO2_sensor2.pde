import processing.serial.*;
import cc.arduino.*;
import grafica.*;
import controlP5.*;
import java.io.BufferedWriter;
import java.io.FileWriter;
Arduino arduino;
//PrintWriter foutput;
String fname;
boolean logData = true;
ControlP5 cp5;

PFont fontLight, fontBold, fontBig, fontCp5;
color colorDark, colorGray;
int dia;
int mes;
int ano;
int hora;
int min;
int sec;
String sData, sHora, sDataHora;

color off = color(4, 79, 111);
color on = color(84, 145, 158);

GPlot plot2;
color plotColor[] = new color[6];
color baseColor[] = new color[6];

int px, py, pw, ph, pd, p5x, p5y;
int numSensors =6;
int numPoints =0;

float lastX =0.0;
float fator[][] = new float[numSensors][3];

int storedValues_length =10;
float[][] storedValues = new float[storedValues_length][6];
int[] count = new int[6];
float[] sum = new float[6];
float readAverage;
/*
millis = 1/1000 seconds
 1 hora = 60 min
 1 dia = 60 * 24 = 1440
 */
int numHours = 24*4;
int xTicks = numHours * 1;
int interval = 10; //in seconds
int millis_interval = interval * 1000;

int pointsHour = 60 * 60  /1;
//int millis_interval = 1000 *5; //1sec
//int millis_interval = 1000 * 60 *1; //1min
float limX = numHours * 60 * 60 / interval;

int millis_old = 0;

int countPoints = 0;

//http://forum.arduino.cc/index.php/topic,55780.0.html
//VARIABLES
float Ro = 41763.0;    // this has to be tuned 10K Ohm
//int sensorPin = 0;  // select the input pin for the sensor
//int ledPin = 13;    // select the pin for the LED
int val = 0;        // variable to store the value coming from the sensor
float Vrl = 0.0;
float Rs = 0.0;
float ratio = 0.0;
float CO2 = 0.0;
float MQ135_SCALINGFACTOR = 116.6020682; //CO2 gas value
float MQ135_EXPONENT = -2.769034857; //CO2 gas value

void setup() {
  size(900, 650);
  noStroke();
  smooth();
  //println(Arduino.list());
  //arduino = new Arduino(this, Arduino.list()[0], 57600);
  //arduino = new Arduino(this, "/dev/ttyUSB0", 57600);
  arduino = new Arduino(this, "/dev/ttyACM0", 57600);

  // Set the Arduino digital pins as inputs.
  for (int i = 0; i <= 13; i++) {
    arduino.pinMode(i, Arduino.INPUT);
  }

  dia = day();
  mes = month();
  ano = year();
  hora = hour();
  min = minute();
  sec = second();
  sData = nf(dia, 2) +"/"+ nf(mes, 2) +"/"+ ano;
  sHora = nf(hora, 2)  +":"+ nf(min, 2) +":"+ nf(sec, 2);

  fname ="dados_"
    + ano + nf(mes, 2)+ nf(dia, 2) + 
    nf(hora, 2) + nf(min, 2) + nf(sec, 2)
    +".csv";
  // foutput = createWriter(fname);
  // First batch of data
  String data1 =     "i,time,A0,A1,A2,A4";
  appendToFile(fname, data1);

  fontLight = loadFont("OpenSans-CondensedLight-24.vlw"); 
  fontBold = loadFont("OpenSans-CondensedBold-24.vlw");
  fontBig = loadFont("OpenSans-CondensedBold-48.vlw");
  fontCp5 = loadFont("OpenSans-CondensedBold-12.vlw");
  colorDark= color(#000000);
  colorGray= color(#CCCCCC);
  cp5 = new ControlP5(this);
  cp5.setControlFont(fontCp5);
  // change the original colors
  cp5.setColorForeground(color(150, 150, 255));
  cp5.setColorBackground(color(199, 199, 199));
  cp5.setColorLabel(color(0, 0, 0));
  cp5.setColorValue(color(0, 0, 0));
  cp5.setColorActive(color(100, 100, 250));

  cp5.addButton("saveFile")
    .setValue(0)
      .setLabel("Save")
        .setPosition(10, 10)
          .setSize(40, 15)
            ;


  /*
  fator[1][1] = 38;
   fator[2][1] = 53;
   fator[3][1] = 27;
   fator[4][1] = 10;
   */
  fator[0][1] = 0;
  fator[1][1] = 0;
  fator[2][1] = 0;
  fator[3][1] = 0;


  fator[0][2] = 100.0/100.0;
  fator[1][2] = 100.0/100.0;
  fator[2][2] = 100.0/100.0;
  fator[3][2] = 100.0/100.0;
  fator[4][2] = 100.0/100.0;
  fator[5][2] = 100.0/100.0;


  plotColor[0] =  color(#B276B2);// (purple)
  plotColor[1] =  color(#5DA5DA);//  (blue)
  plotColor[2] =  color(#FAA43A);//  (orange)
  plotColor[3] =  color(#60BD68);//  (green)
  plotColor[4] =  color(#F17CB0);//  (pink)
  plotColor[5] =  color(#B2912F);//  (brown)

  baseColor[0] =  color(100, 100, 100, 100);//  (orange)
  baseColor[1] =  color(100, 100, 100, 100);//  (orange)
  baseColor[2] =  color(100, 100, 100, 100);//  (orange)
  baseColor[3] =  color(100, 100, 100, 100);//  (orange)
  baseColor[4] =  color(100, 100, 100, 100);//  (orange)

  px =0;
  py = 90;
  pw = width/5*4;
  ph = height/8*5;
  pd = 15;


  plot2 = new GPlot(this);
  plot2.setPos(px, py);
  plot2.setDim(pw, ph);
  //plot[i].getTitle().setText("Analog "+i);
  //plot2.getYAxis().getAxisLabel().setText("");
  //plot2.activateZooming(1.5);
  plot2.setFixedXLim(false);
  plot2.setFixedYLim(false);
  plot2.setXLim(0.0, limX);
  plot2.setYLim(0.0, 1024.0);

  plot2.setLineColor(plotColor[2]);
  plot2.setBoxBgColor(color(240));
  //plot2.setLineWidth(4.0);
  plot2.setMar(5.0, 60.0, 5.0, 5.0);
  //  plot2.getYAxis().setRotateTickLabels(false);
  plot2.getXAxis().setNTicks(xTicks); 
  plot2.getXAxis().setRotateTickLabels(true);

  plot2.activatePointLabels();
  GPointsArray points_C = new GPointsArray();

  for (int i=0; i<numSensors; i++) {
    String name = "sensor_" + i;
    plot2.addLayer(name, points_C);
    plot2.getLayer(name).setLineColor(plotColor[i]);
    plot2.getLayer(name).setLineWidth(1.0);
    // plot2.getLayer(name).drawLegend(name,100.0,100.0);
  }
}

void draw() {
  background(255);
  fill(0);

  fill(colorGray);
  textFont(fontCp5);
  textAlign(LEFT);
  if (logData) {
    text("Yes", 55, 22);
  } else {
    text("No", 55, 22);
  }
  textAlign(RIGHT);
  // dia = day();  mes = month();  ano = year();
  hora = hour();
  min = minute();
  sec = second();

  //  sData = nf(dia, 2) +"/"+ nf(mes, 2) +"/"+ ano;
  sHora = nf(hora, 2)  +":"+ nf(min, 2) +":"+ nf(sec, 2);
  sDataHora = ano + nf(mes, 2) + nf(dia, 2) + nf(hora, 2)  + nf(min, 2) + nf(sec, 2);
  //outputInitialized = true;
  int fontSize=24;
  int py=20;
  int rx=60;

  textFont(fontBold);
  fill(colorDark);
  textAlign(RIGHT);
  text(sData, width-rx, py);

  fill(colorGray);
  textAlign(LEFT);
  text(":D", width-rx, py);

  py+=fontSize;
  textFont(fontBold);
  fill(colorDark);
  textAlign(RIGHT);

  text(sHora, width-rx, py);
  fill(colorGray);
  textAlign(LEFT);
  text(":H", width-rx, py);

  textAlign(RIGHT);
  fill(colorDark);
  py+=fontSize;
  py+=fontSize;
  text(numPoints, width-rx, py);
  fill(colorGray);
  textAlign(LEFT);
  text(":i", width-rx, py);

  py+=fontSize;
  py+=fontSize;

  //  if (countPoints < interval) {
  if (millis() - millis_old <= millis_interval) {
    //    countPoints++;
  } else {
    millis_old = millis();
    String sLog = "";
    for (int i=0; i<numSensors; i++) {
      val = arduino.analogRead(i);     // read the value from the analog sensor
      /*      Vrl = val * ( 5.00 / 1024.0  );      // V
       Rs = 20000 * ( 5.00 - Vrl) / Vrl ;   // Ohm 
       
       ratio =  Rs/Ro;  
       CO2 = get_CO(ratio);
       
       AddNewValue(i, CO2);
       */
      AddNewValue(i, (float)val);
      readAverage = 0.0;
      if (count[i] > 0) {
        readAverage = sum[i] / count[i];
      }
      //    fator[i][0]= fator[i][1] + ( fator[i][2] * (float)arduino.analogRead(i) );
      fator[i][0]= fator[i][1] + ( fator[i][2] * readAverage );
      //    fator[i][0]=  (float)arduino.analogRead(i) /1024*5;
      plot2.getLayer("sensor_"+i)
        .addPoint(numPoints,  fator[i][0], ""+nf(fator[i][0], 1, 2));
      sLog += fator[i][0] +",";
    }
    if (logData) {
      String data1 =     numPoints +","+ sDataHora+","+sLog;
      appendToFile(fname, data1);
    }
    numPoints++;
    countPoints =0;
  }
  for (int i=0; i<numSensors; i++) {

    textAlign(RIGHT);
    fill(plotColor[i]);
    text(nf(fator[i][0], 1, 1), width-rx, py+(i*fontSize));
    fill(colorGray);
    textAlign(LEFT);
    text(":"+i, width-rx, py+(i*fontSize));
  }

  if ((numPoints >  (lastX + limX))) {
    lastX = lastX + limX;
    plot2.setXLim(lastX, lastX + limX );
  }
// if ((numPoints >  (lastX + 10))) {    lastX = lastX + 10;    plot2.setXLim(lastX, lastX + 10 );  }
  plot2.beginDraw();
  plot2.drawBackground();
  plot2.drawBox();
  plot2.drawXAxis();
  plot2.drawYAxis();
  plot2.drawTitle();
  plot2.drawGridLines(GPlot.BOTH);
  plot2.drawLines();
  plot2.drawLabels();
  //plot2.drawFilledContours(GPlot.HORIZONTAL, 0);
  //plot2.drawLine(reg1, reg2,200,1.0);
  //plot2.drawLine(reg3, reg4,200,1.0);
  plot2.endDraw();
}
void AddNewValue(int i, float val)
{
  if (count[i] < storedValues_length) {
    //array is not full yet
    storedValues[count[i]++][i] = val;
    sum[i] += val;
  } else {
    sum[i] += val; 
    sum[i] -= storedValues[0][i];
    //shift all of the values, drop the first one (oldest) 
    for (int j = 0; j < storedValues_length-1; j++)
    {
      storedValues[j][i] = storedValues[j+1][i] ;
    }
    //the add the new one
    storedValues[storedValues_length-1][i] = val;
  }
}
float mq135_getro(float resvalue, float ppm) {
  return (float)(resvalue * exp( log(MQ135_SCALINGFACTOR/ppm) / MQ135_EXPONENT ));
}
// get CO ppm
float get_CO (float ratio) {

  float ppm = 0.0;
  ppm = MQ135_SCALINGFACTOR * pow (ratio, MQ135_EXPONENT);
  return ppm;
}


void appendToFile(String filePath, String data) {
  filePath = dataPath("") +"/"+ filePath;
  //  println("log data at " + filePath);
  PrintWriter pw = null;
  try {
    pw = new PrintWriter(new BufferedWriter(new FileWriter(filePath, true))); // true means: "append"
    pw.println(data);
  }
  catch (IOException e) {
    // Report problem or handle it
    e.printStackTrace();
  }
  finally {
    if (pw != null) {
      pw.close();
    }
  }
}//
public void saveFile(int theValue) {
  if (logData ==true) {
    logData=false;
  } else {
    logData=true;
  }
  //println(logData);
}
