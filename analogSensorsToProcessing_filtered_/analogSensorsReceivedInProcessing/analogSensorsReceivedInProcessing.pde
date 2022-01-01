import processing.serial.*;

int sensor1 = 0;
int sensor2 = 0;
int sensor3 = 0;

int ypos = height;

Serial usbPort;
int[] sensors = null;
boolean firstContact = false;  


void setup () {
  size(1200, 1200);
  //for 3D spheres add argument P3D to size, then create the sphere(), and translate it in 3D coordinates with sensor data

  usbPort = new Serial (this, Serial.list( ) [0], 9600);
  usbPort.bufferUntil ('\n');
}

void draw () {
  background(0);
  Ball(sensor1);
  ypos -= 5;

  fill(255, 0, 0);
  rect(width/2, height/2, 300, 100);
  rect(width/2-300, height/2-300, 300, 100);

  if (ypos < 0) {
    ypos = height;
  }

  /*
 //lines to enable some data to go back to Arduino
   if (ypos < 200) {
   usbPort.write('1'); //communicate back to Arduino tu turn on led 13
   } else {
   usbPort.write('2'); //communicate back to Arduino to turn off led 13
   }
   */
}

void serialEvent (Serial usbPort) {
  String usbString = usbPort.readStringUntil ('\n');
  if (usbString != null) {
    usbString = trim(usbString);
    println(usbString);

    if (firstContact == false) {
      if (usbString.equals("Hello")) {
        usbPort.clear();
        firstContact = true;
        usbPort.write('A');
        println("contact");
      }
    } else {
      int sensors[] = int(split(usbString, ','));
      for (int sensorNum = 1; sensorNum < sensors.length; sensorNum++) {
        //println(sensorNum + " " + sensors[sensorNum]);
      }

      sensor1 = sensors[1];
      sensor2 = sensors[2];
      sensor3 = sensors[3];
    }
  }
}
