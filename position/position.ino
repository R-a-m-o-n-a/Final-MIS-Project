#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>

uint16_t BNO055_SAMPLERATE_DELAY_MS = 10; //how often to read data from the board
uint16_t PRINT_DELAY_MS = 500; // how often to print the data
uint16_t printCount = 0; //counter to avoid printing every 10MS sample

float prevAngle = 0;
boolean thresholdExceeded = false;
boolean dataGoingUp = false;
boolean dataGoingDown = false;
const float THRESHOLD = 20;

// Check I2C device address and correct line below (by default address is 0x29 or 0x28)
//                                   id, address
Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28);

void setup(void)
{
  Serial.begin(115200);
  if (!bno.begin())
  {
    Serial.print("No BNO055 detected");
    while (1);
  }

  delay(1000);
}

void loop(void)
{
  //
  unsigned long tStart = micros();
  sensors_event_t orientationData;
  bno.getEvent(&orientationData, Adafruit_BNO055::VECTOR_EULER);

  if (printCount * BNO055_SAMPLERATE_DELAY_MS >= PRINT_DELAY_MS) {
    //enough iterations have passed that we can print the latest data
    /*Serial.print("Heading: ");
    Serial.print(orientationData.orientation.x);
    Serial.print(" , ");
    Serial.print(orientationData.orientation.y);
    Serial.print(" , ");
    Serial.println(orientationData.orientation.z);*/

    detectMove(orientationData.orientation.y);

    printCount = 0;
  }
  else {
    printCount = printCount + 1;
  }



  while ((micros() - tStart) < (BNO055_SAMPLERATE_DELAY_MS * 1000))
  {
    //poll until the next sample is ready
  }
}

void detectMove(float angle) {
  //Serial.println(angle);
  if (thresholdExceeded) {
    // extrema are always registered on the first dataPoint after the real peak to make sure each peak is only registered once
    if(angle < prevAngle && dataGoingUp) { // found maximum
      Serial.println(1);
    }
    if(angle > prevAngle && dataGoingDown) { // found minimum
      Serial.println(-1);
    }
  }
  dataGoingUp = angle > prevAngle;
  dataGoingDown = angle < prevAngle;
  thresholdExceeded = abs(angle) > THRESHOLD;
  prevAngle = angle;
}
