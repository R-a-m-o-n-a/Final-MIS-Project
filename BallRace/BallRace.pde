import controlP5.*; 
import oscP5.*;
import netP5.*;

// Variables for communication via OSC messages
OscP5 oscP5;
NetAddress PD_Location;
String PD_IP = "127.0.0.1";
int LISTENING_PORT = 32000;
int SENDING_PORT = 12000;

// constants to set up the game


// variables for the game itself
int startTime;
Track track;
boolean isGameRunning = false;

void setup(){
  size(1500, 800);
  frameRate(60);
  
  oscP5 = new OscP5(this, LISTENING_PORT); // start oscP5, listening for incoming messages at specified port
  PD_Location = new NetAddress(PD_IP, SENDING_PORT); // set up connection to PD for sending OSC messages

  // set the OSC messages that Processing needs to listen to. Syntax: plug(this, nameOfMethod, scope)
  oscP5.plug(this,"receiveChangeLane","/changeLane");   
  oscP5.plug(this,"receiveClap","/clap");   
    
  track = new Track();
  noStroke(); // don't draw border on shapes
  startTime = millis(); // set the start time
}

// loop that is repeated all over again
void draw() {
  background(0, 0, 0); 
  if(isGameRunning ||frameCount < 5) { 
    track.draw();
  } 
}

// alternative key controls for testing
void keyPressed() {
  if (key == 'a') {
    track.moveCircle(-1);
  } else if (key == 'd') {
    track.moveCircle(1);
  } else if(key == 'q') { // to examine specific behaviours
    frameRate(2);
  } else if(key ==  ' ') {
    if(isGameRunning) {
      track.makeRedWallsPervious();
    } else {
      startGame();
    }
  }
}

private void startGame() {
  isGameRunning = true;
  sendOscMessage("/startGame", 1);
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
  oscP5.send(message, PD_Location);
}

// method to handle the change lane when the OSC message /changeLane is received
void receiveChangeLane(int dir) {
  println("received OSC message '/changeLane' with dir " + dir);
  track.moveCircle(dir);   
}

// method to handle the clap function to avoid big walls, called when OSC message /clap is received
void receiveClap() {
  println("received OSC message '/clap'");
  track.makeRedWallsPervious(); 
}
