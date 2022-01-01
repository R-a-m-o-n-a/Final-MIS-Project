//This sketch receives data from analog sensors, filters it, and then sends it to Processing via Serial communication.

#include <IIRFilter.h>

uint16_t analog_input0_pin = 0;
uint16_t analog_input1_pin = 1;
uint16_t analog_input2_pin = 2;

uint16_t analog_input0 = 0;
uint16_t analog_input1 = 0;
uint16_t analog_input2 = 0;


uint16_t analog_input0_lp_filtered = 0;
uint16_t analog_input1_lp_filtered = 0;
uint16_t analog_input2_lp_filtered = 0;

uint16_t previous_analog_input0_lp_filtered = 0;
uint16_t previous_analog_input1_lp_filtered = 0;
uint16_t previous_analog_input2_lp_filtered = 0;

// 50 Hz Butterworth low-pass
double a_lp_50Hz[] = {1.000000000000, -3.180638548875, 3.861194348994, -2.112155355111, 0.438265142262};
double b_lp_50Hz[] = {0.000416599204407, 0.001666396817626, 0.002499595226440, 0.001666396817626, 0.000416599204407};
IIRFilter lp_analog_input0(b_lp_50Hz, a_lp_50Hz);
IIRFilter lp_analog_input1(b_lp_50Hz, a_lp_50Hz);
IIRFilter lp_analog_input2(b_lp_50Hz, a_lp_50Hz);



//three characters used for Serial communication
 
char START_BYTE = '*';
char DELIMITER = ',';
char END_BYTE = '#';

// variables to receive incoming data from Processing

char signal = '0'; // Data received from the serial port
int ledPin = 13; // Set the pin to digital I/O 13


// *************************************************************************************************************** 

void setup() {
  
  pinMode(ledPin, OUTPUT);
  Serial.begin(9600); //begin Serial communication. It is of capital importance to set same baud rate for Arduino and Processing.
  establishContact(); //function that allows communication between Processing and Arduino to start
  
}

// *************************************************************************************************************** 

void loop(){

  //code below added to listen for Serial comm and receive data from Processing to have bidirectional communication
  
  /*
  if (Serial.available() > 0) {
    signal = Serial.read();
    
    switch(signal) {
    
      case '1': //condition in which Arduino receives '1' from Processing
      digitalWrite(ledPin, HIGH);
      break;
      
      case '2': //condition in which Arduino receives '2' from Processing2
      digitalWrite(ledPin, LOW);
      break;
    }
    }
    */
    
  //assign sensor value to a variable. Comment / Uncomment lines about sensorValue2 and 3 if it is needed to send more sensors' values or not.
  
    analog_input0 = analogRead(analog_input0_pin);
    analog_input0_lp_filtered =  (uint16_t)lp_analog_input0.filter((double)analog_input0);
    analog_input1 = analogRead(analog_input1_pin);
    analog_input1_lp_filtered =  (uint16_t)lp_analog_input1.filter((double)analog_input1);
    analog_input2 = analogRead(analog_input2_pin);
    analog_input2_lp_filtered =  (uint16_t)lp_analog_input2.filter((double)analog_input2);                


  //communication to Processing
  
  Serial.write(START_BYTE);//Start of sensor data being communicated
  Serial.print(DELIMITER);

  Serial.print(analog_input0_lp_filtered);//communicate sensor value
  Serial.print(DELIMITER);

  Serial.print(analog_input1_lp_filtered);//communicate sensor value 2
  Serial.print(DELIMITER);

  Serial.print(analog_input2_lp_filtered);//communicate sensor value 3
  Serial.print(DELIMITER);

  Serial.write(END_BYTE);//communicate that we're done communicating
  Serial.println();//send a carriage return
  
}

//function that checks if first contact between Processing and Arduino actually took place

void establishContact() {
    while (Serial.available() <= 0) {
    Serial.println("Hello");
    delay(300);
  }
}
