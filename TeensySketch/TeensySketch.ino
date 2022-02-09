/* 
   This sketch reads data from a BNO055 IMU sensor and sends it to the serial port. 
   The data that we send over is related to the direction of movement of the user, 
   which is transformed in -1 for movement towards the left and 1 for movement towards the right.
   We took inspiration for this code from AdaFruit's public repositories on GitHub. 
   In particular, we started from this code to learn how to track position, and then we added our own custom solution to track direction:
   >>> https://github.com/adafruit/Adafruit_BNO055/blob/master/examples/position/position.ino <<<
   
   Then, we amended the code seen in class about BNO0550 maintenance, and we added the possibility of calibrating the sensor to this sketch.
   Lastly, we added code for bidirectional communication with Pure Data by implementing code snippets seen in class, 
   although we have adapted some parts (specifically, the motors' pin-outs and behaviour) to our own specific needs, 
   as we (for now) have decided to implement 4 motors in the SensoRoll system.
   
   ===============================
   Connections to the Teensy 3.6
   ===============================

   Connect BNO055 SCL to analog 5
   Connect BNO055 to analog 4
   Connect Vibrotactile motors to Digital Pins 2,3,4,5
   Connect VDD to 3.3V DC
   Connect GROUND to common ground
   ====================================================
   
*/

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>
#include <EEPROM.h>
#include <string.h>


// variables to determine behaviour of the BNO055
uint16_t BNO055_SAMPLERATE_DELAY_MS = 10; // how often to read data from the board
uint16_t PRINT_DELAY_MS = 500; // how often to print the data
uint16_t printCount = 0; //counter to avoid printing every 10MS sample

// variables for movement detection (2nd alternative: register peak as soon as data exceeds threshold)
const float THRESHOLD = 10; // threshold for move detection (when user bends left/right)
boolean minRegistered = false;
boolean maxRegistered = false;

// Check I2C device address and correct line below (by default address is 0x29 or 0x28)
//                                   id, address
Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28);


/* Variables for incoming messages *************************************************************/

const byte MAX_LENGTH_MESSAGE = 64;
char received_message[MAX_LENGTH_MESSAGE];

char START_MARKER = '[';
char END_MARKER = ']';


boolean new_message_received = false;


/* Digital outputs *************************************************************/

// Motors pins - Teensy PWM Digital pins

const uint16_t motor1_pin = 2;
const uint16_t motor2_pin = 3;
const uint16_t motor3_pin = 4;
const uint16_t motor4_pin = 5;


#define ANALOG_BIT_RESOLUTION 12 // Only for Teensy



/* IMU code for calibration, amended from code seen in class ***************************************************************************************************/

/* Set the delay between fresh samples */
static const unsigned long BNO055_PERIOD_MILLISECS = 100; // E.g. 4 milliseconds per sample for 250 Hz
//static const float BNO055_SAMPLING_FREQUENCY = 1.0e3f / PERIOD_MILLISECS;
#define BNO055_PERIOD_MICROSECS 100.0e3f //= 1000 * PERIOD_MILLISECS;



bool reset_calibration = false;  // set to true if you want to redo the calibration rather than using the values stored in the EEPROM
bool display_BNO055_info = false; // set to true if you want to print on the serial port the infromation about the status and calibration of the IMU


/* Set the correction factors for the three Euler angles according to the wanted orientation */
float  correction_x = 0; // -177.19;
float  correction_y = 0; // 0.5;
float  correction_z = 0; // 1.25;



/* Displays some basic information on this sensor from the unified sensor API sensor_t type (see Adafruit_Sensor for more information) */
void displaySensorDetails(void)
{
    sensor_t sensor;
    bno.getSensor(&sensor);
    Serial.println("------------------------------------");
    Serial.print("Sensor:       "); Serial.println(sensor.name);
    Serial.print("Driver Ver:   "); Serial.println(sensor.version);
    Serial.print("Unique ID:    "); Serial.println(sensor.sensor_id);
    Serial.print("Max Value:    "); Serial.print(sensor.max_value); Serial.println(" xxx");
    Serial.print("Min Value:    "); Serial.print(sensor.min_value); Serial.println(" xxx");
    Serial.print("Resolution:   "); Serial.print(sensor.resolution); Serial.println(" xxx");
    Serial.println("------------------------------------");
    Serial.println("");
    delay(500);
}

/* Display some basic info about the sensor status */
void displaySensorStatus(void)
{
    /* Get the system status values (mostly for debugging purposes) */
    uint8_t system_status, self_test_results, system_error;
    system_status = self_test_results = system_error = 0;
    bno.getSystemStatus(&system_status, &self_test_results, &system_error);

    /* Display the results in the Serial Monitor */
    Serial.println("");
    Serial.print("System Status: 0x");
    Serial.println(system_status, HEX);
    Serial.print("Self Test:     0x");
    Serial.println(self_test_results, HEX);
    Serial.print("System Error:  0x");
    Serial.println(system_error, HEX);
    Serial.println("");
    delay(500);
}

/* Display sensor calibration status */
void displayCalStatus(void)
{
    /* Get the four calibration values (0..3) */
    /* Any sensor data reporting 0 should be ignored, */
    /* 3 means 'fully calibrated" */
    uint8_t system, gyro, accel, mag;
    system = gyro = accel = mag = 0;
    bno.getCalibration(&system, &gyro, &accel, &mag);

    /* The data should be ignored until the system calibration is > 0 */
    Serial.print("\t");
    if (!system)
    {
        Serial.print("! ");
    }

    /* Display the individual values */
    Serial.print("Sys:");
    Serial.print(system, DEC);
    Serial.print(" G:");
    Serial.print(gyro, DEC);
    Serial.print(" A:");
    Serial.print(accel, DEC);
    Serial.print(" M:");
    Serial.print(mag, DEC);
}

/* Display the raw calibration offset and radius data */
void displaySensorOffsets(const adafruit_bno055_offsets_t &calibData)
{
    Serial.print("Accelerometer: ");
    Serial.print(calibData.accel_offset_x); Serial.print(" ");
    Serial.print(calibData.accel_offset_y); Serial.print(" ");
    Serial.print(calibData.accel_offset_z); Serial.print(" ");

    Serial.print("\nGyro: ");
    Serial.print(calibData.gyro_offset_x); Serial.print(" ");
    Serial.print(calibData.gyro_offset_y); Serial.print(" ");
    Serial.print(calibData.gyro_offset_z); Serial.print(" ");

    Serial.print("\nMag: ");
    Serial.print(calibData.mag_offset_x); Serial.print(" ");
    Serial.print(calibData.mag_offset_y); Serial.print(" ");
    Serial.print(calibData.mag_offset_z); Serial.print(" ");

    Serial.print("\nAccel Radius: ");
    Serial.print(calibData.accel_radius);

    Serial.print("\nMag Radius: ");
    Serial.print(calibData.mag_radius);
}


/* Magnetometer calibration */
void performMagCal(void) {

  /* Get the four calibration values (0..3) */
  /* Any sensor data reporting 0 should be ignored, */
  /* 3 means 'fully calibrated" */
  uint8_t system, gyro, accel, mag;
  system = gyro = accel = mag = 0;

  while (mag != 3) {

    bno.getCalibration(&system, &gyro, &accel, &mag);
    if(display_BNO055_info){

      displayCalStatus();
      Serial.println("");
    }
  }

  if(display_BNO055_info){

    Serial.println("\nMagnetometer calibrated!");
  }
}



/** Functions for handling received messages ***********************************************************************/

void receive_message() {

    static boolean reception_in_progress = false;
    static byte ndx = 0;
    char rcv_char;

    while (Serial.available() > 0 && new_message_received == false) {
        rcv_char = Serial.read();
        Serial.println(rcv_char);

        if (reception_in_progress == true) {
            if (rcv_char!= END_MARKER) {
                received_message[ndx] = rcv_char;
                ndx++;
                if (ndx >= MAX_LENGTH_MESSAGE) {
                    ndx = MAX_LENGTH_MESSAGE - 1;
                }
            }
            else {
                received_message[ndx] = '\0'; // terminate the string
                reception_in_progress = false;
                ndx = 0;
                new_message_received = true;
            }
        }
        else if (rcv_char == START_MARKER) {
            reception_in_progress = true;
        }
    }

    if (new_message_received) {
      handle_received_message(received_message);
      new_message_received = false;
    }
}




void handle_received_message(char *received_message) {

  //Serial.print("received_message: ");
  //Serial.println(received_message);


  char *all_tokens[2]; //NOTE: the message is composed by 2 tokens: command and value
  const char delimiters[5] = {START_MARKER, ',', ' ', END_MARKER,'\0'};
  int i = 0;

  all_tokens[i] = strtok(received_message, delimiters);

  while (i < 2 && all_tokens[i] != NULL) {
    all_tokens[++i] = strtok(NULL, delimiters);
  }

  char *command = all_tokens[0];
  char *value = all_tokens[1];


/* Motors' behaviour code, amended from code seen in class and adapted to our need. 
   In this sketch, we refer to the 4 motors that we hooked up with the Teensy; these are the motors that go on the belt of the user.

*/
  if (strcmp(command,"motor_lane_0") == 0 && strcmp(value,"1") == 0) {

    /*
    Serial.print("activating message 1: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */

    analogWrite(motor1_pin, 255);

  }

  if (strcmp(command,"motor_lane_0") == 0 && strcmp(value,"0") == 0) {

    /*
    Serial.print("activating message 2: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */
    analogWrite(motor1_pin, 0);

  }


  if (strcmp(command,"motor_lane_1") == 0 && strcmp(value,"1") == 0) {

    /*
    Serial.print("activating message 1: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */

    analogWrite(motor2_pin, 100);

  }

  if (strcmp(command,"motor_lane_1") == 0 && strcmp(value,"0") == 0) {

    /*
    Serial.print("activating message 2: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */
    analogWrite(motor2_pin, 0);

  }


if (strcmp(command,"motor_lane_2") == 0 && strcmp(value,"1") == 0) {

    /*
    Serial.print("activating message 1: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */

    analogWrite(motor3_pin, 100);

  }

  if (strcmp(command,"motor_lane_2") == 0 && strcmp(value,"0") == 0) {

    /*
    Serial.print("activating message 2: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */
    analogWrite(motor3_pin, 0);

  }

  if (strcmp(command,"motor_lane_3") == 0 && strcmp(value,"1") == 0) {

    /*
    Serial.print("activating message 1: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */

    analogWrite(motor4_pin, 255);

  }

  if (strcmp(command,"motor_lane_3") == 0 && strcmp(value,"0") == 0) {

    /*
    Serial.print("activating message 2: ");
    Serial.print(command);
    Serial.print(" ");
    Serial.print(value);
    Serial.println(" ");
    */
    analogWrite(motor4_pin, 0);

  }
}

// ************************************************* SETUP AND LOOP ******************************************************************

void setup(void)
{
  Serial.begin(115200); //actually, because we are using Teensy, we do not need this. We kept it anyway when we tested our system with the Arduino.

  // loop for setting up the motors as OUTPUTs. To comment out if not needed.

  for (int pinNumber = 2; pinNumber < 6; pinNumber++) {
  pinMode(pinNumber, OUTPUT);
  digitalWrite(pinNumber, LOW);
  }

  if (!bno.begin())
  {
    Serial.print("No BNO055 detected");
    while (1);
  }
  int eeAddress = 0;
  long eeBnoID;
  long bnoID;
  bool foundCalib = false;


  if(reset_calibration){// Then reset the EEPROM so a new calibration can be made

    EEPROM.put(eeAddress, 0);
    eeAddress += sizeof(long);
    EEPROM.put(eeAddress, 0);
    eeAddress = 0;
    if(display_BNO055_info){
      Serial.println("EEPROM reset.");
      delay(10000);
    }
  }

  EEPROM.get(eeAddress, eeBnoID);

  adafruit_bno055_offsets_t calibrationData;
  sensor_t sensor;

  /*
  *  Look for the sensor's unique ID at the beginning oF EEPROM.
  *  This isn't foolproof, but it's better than nothing.
  */
  bno.getSensor(&sensor);
  bnoID = sensor.sensor_id;

  if (eeBnoID != bnoID) {

    if(display_BNO055_info){

      Serial.println("\nNo Calibration Data for this sensor exists in EEPROM");
      delay(2000);
    }
  }
  else{

    if(display_BNO055_info){

      Serial.println("\nFound Calibration for this sensor in EEPROM.");
    }

    eeAddress += sizeof(long);
    EEPROM.get(eeAddress, calibrationData);

    if(display_BNO055_info){

      displaySensorOffsets(calibrationData);
      Serial.println("\n\nRestoring Calibration data to the BNO055...");
    }

    bno.setSensorOffsets(calibrationData);

    if(display_BNO055_info){

      Serial.println("\n\nCalibration data loaded into BNO055");
      delay(2000);
    }

    foundCalib = true;
  }

  if(display_BNO055_info){

    /* Display some basic information on this sensor */
    displaySensorDetails();

    /* Optional: Display current status */
    displaySensorStatus();

  }

  /* Crystal must be configured AFTER loading calibration data into BNO055. */
  bno.setExtCrystalUse(true);

  //sensors_event_t orientationData;
  //bno.getEvent(&orientationData, Adafruit_BNO055::VECTOR_EULER);


  if (foundCalib){

    performMagCal(); /* always recalibrate the magnetometers as it goes out of calibration very often */
  }
  else {

    if(display_BNO055_info){

      Serial.println("Please Calibrate Sensor: ");
      delay(2000);
    }

    while (!bno.isFullyCalibrated()){

      if(display_BNO055_info){

            displayCalStatus();
            Serial.println("");
            delay(BNO055_PERIOD_MILLISECS); // Wait for the specified delay before requesting new data
        }
    }

    adafruit_bno055_offsets_t newCalib;
    bno.getSensorOffsets(newCalib);

    if(display_BNO055_info){

      Serial.println("\nFully calibrated!");
      delay(3000);
      Serial.println("--------------------------------");
      Serial.println("Calibration Results: ");

      displaySensorOffsets(newCalib);

      Serial.println("\n\nStoring calibration data to EEPROM...");
    }

    eeAddress = 0;
    EEPROM.put(eeAddress, bnoID);
    eeAddress += sizeof(long);
    EEPROM.put(eeAddress, newCalib);


    if(display_BNO055_info){
      Serial.println("Data stored to EEPROM.");
      Serial.println("\n--------------------------------\n");
      delay(3000);
      }

  }

  delay(1000);
}


void loop(void)
{
  receive_message(); // function to handle received message

  unsigned long tStart = micros();
  sensors_event_t orientationData;
  bno.getEvent(&orientationData, Adafruit_BNO055::VECTOR_EULER);

// this part was taken from AdaFruit's public GitHub repository about the BNO055

  if (printCount * BNO055_SAMPLERATE_DELAY_MS >= PRINT_DELAY_MS) {
    //enough iterations have passed that we can print the latest data
    /*Serial.print("Heading: ");
    Serial.print(orientationData.orientation.x);
    Serial.print(" , ");
    Serial.print(orientationData.orientation.y);
    Serial.print(" , ");
    Serial.println(orientationData.orientation.z);*/
    printCount = 0;
  }
  else {
    printCount = printCount + 1;
  }

  detectMoveVersion2(orientationData.orientation.y);

  while ((micros() - tStart) < (BNO055_SAMPLERATE_DELAY_MS * 1000))
  {
    //poll until the next sample is ready
  }
}

/* 
   down below is our custom solution. We detect the angle of movement and we compare it with a threshold set at the beginning of the sketch. 
   The result of this comparison is either a -1, which signals movement to the left, or a 1, which signals movement to the right.
   Lastly, the Serial.print() sends this data to the serial port, which is then received in Pure Data to handle movement of the ball
   in Processing.
   
*/

void detectMoveVersion2(float angle) {
  if (angle > THRESHOLD && !maxRegistered) { // found maximum
    Serial.print("dir, ");
    Serial.println(1);
    maxRegistered = true;
  }
  if (angle < (-1) * THRESHOLD && !minRegistered) { // found minimum
    Serial.print("dir, ");
    Serial.println(-1);
    minRegistered = true;
  }

  // reset ability to detect peaks once the angle falls under the threshold (range between -Threshold and +Threshold)
  if (angle < THRESHOLD && maxRegistered) {
    maxRegistered = false;

    Serial.print("dir, ");
    Serial.println(0);
  }
  if (angle > (-1) * THRESHOLD && minRegistered) {
    minRegistered = false;

    Serial.print("dir, ");
    Serial.println(0);
  }
}
