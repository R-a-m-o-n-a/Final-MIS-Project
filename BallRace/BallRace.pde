import controlP5.*; 
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress PD_Location;
String PD_IP = "127.0.0.1";
int LISTENING_PORT = 32000;
int SENDING_PORT = 12000;

int trackWidth = 500;
int laneHeight = 50;
int noOfLanes = 4;
int startTime;
Track track;

void setup(){
  size(1500,800);
  frameRate(30);
  
  oscP5 = new OscP5(this, LISTENING_PORT); /* start oscP5, listening for incoming messages at specified port */
  PD_Location = new NetAddress(PD_IP, SENDING_PORT); // set up connection to PD for sending OSC messages

  // set the OSC messages that Processing needs to listen to: plug(this, nameOfMethod, scope)
  oscP5.plug(this,"receiveChangeLane","/changeLane");   
  oscP5.plug(this,"receiveJump","/jump");   
  
  
  track = new Track(noOfLanes,trackWidth, laneHeight, (width-trackWidth)/2);
  noStroke(); // don't draw border on shapes
  startTime = millis();
  
  
}

void draw() {
  background(0, 0, 0); 
  track.draw();
}

void keyPressed() {
  if (key == 'a') {
    track.moveCircle(-1);
  } else if (key == 'd') {
    track.moveCircle(1);
  } else if(key == 'q') {
    frameRate(2);
  }
}

/** Send OSC Messages to PD.
 * Implemented Messages are
 * /frameRateChanged - sends new frameRate
 * /laneChanged - sends new lane
 * /hitWall - sends the amount of milliseconds that the ball will be frozen until it starts again
 * /wallDistanceLaneN - sends a message for lane N (for each middle lane) the value is the amount of pixels until a wall is hit on that lane
 */
void sendOscMessage(String scope, int value) {
  OscMessage message = new OscMessage(scope);
  message.add(value);
  oscP5.send(message, PD_Location); /* send the message */
}

// method to handle the change lane when the OSC message /changeLane is received
void receiveChangeLane(int dir) {
  println("received OSC message '/changeLane' with dir " + dir);
  track.moveCircle(dir);   
}


void receiveJump() {
  println("received OSC message '/jump'");
  //track.jumpCircle();   method does not exist yet 
}
