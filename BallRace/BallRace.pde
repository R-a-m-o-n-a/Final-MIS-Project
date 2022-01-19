import controlP5.*; 
import oscP5.*;
import netP5.*;
// Variables for communication via OSC messages
OscP5 oscP5;
NetAddress PD_Location;
String PD_IP = "127.0.0.1";
int LISTENING_PORT = 32000;
int SENDING_PORT = 12000;
int THRESHOLD_FOR_SENDING_WALL_DISTANCE = 500;

// variables for the game itself
Track track;
boolean isGameRunning = false;

// variables for statistics
String USER_NAME = "Tim";
String COMMENT = "";
Timer gravelTimer = new Timer();
Timer frozenTimer = new Timer();
Timer gameTimer = new Timer();
String stats_startTime;
int stats_noOfWallsHit = 0;
int stats_timeSpentOnGravel = 0;
int stats_timeSpentFrozen = 0;
int stats_totalGameTime = 0;
boolean stats_successfullyFinished = false;
JSONObject stats_json;

// images to display info text
PImage infoIcon, speechBubble;

void setup(){
  size(1500, 800);
  frameRate(60);
  
  oscP5 = new OscP5(this, LISTENING_PORT); // start oscP5, listening for incoming messages at specified port
  PD_Location = new NetAddress(PD_IP, SENDING_PORT); // set up connection to PD for sending OSC messages

  // set the OSC messages that Processing needs to listen to. Syntax: plug(this, nameOfMethod, scope)
  oscP5.plug(this,"receiveChangeLane","/changeLane");   
  oscP5.plug(this,"receiveClap","/clap");   
  
  infoIcon = loadImage("info.png");
  speechBubble = loadImage("speech_bubble.png");
    
  track = new Track();
  noStroke(); // don't draw border on shapes
}

// loop that is repeated all over again
void draw() {
  background(0, 0, 0); 
  
  if(isGameRunning) { 
    track.drive();
  } else {
    image(speechBubble, width-400, height-300, 370, 270);
    image(infoIcon, width-365, height-270, 60, 60);
    fill(color(0,0,0));
    textAlign(RIGHT);
    textSize(45);
    textLeading(50);
    text("press\nspace bar\nto start", width-360, height-270, 250, 250);
  }
  track.draw();
}

// alternative key controls for testing
void keyPressed() {
  if (key == 'a') {
    track.moveBall(-1);
  } else if (key == 'd') {
    track.moveBall(1);
  } else if(key == 'q') { // to examine specific behaviours
    frameRate(2);
  } else if(key ==  ' ') {
    if(isGameRunning) {
      track.jump();
    } else {
      startGame();
    }
  }
}

private void startGame() {
  isGameRunning = true;
  stats_startTime = getCurrentTime();
  gameTimer.start();
  sendOscMessage("/startGame", 1);
}

/** Send OSC Messages to PD.
 * Implemented Messages are
 * /frameRateChanged - sends new frameRate
 * /laneChanged - sends new lane
 * /hitWall - sends the amount of milliseconds that the ball will be frozen until it starts again
 * /wallDistanceLaneN - sends a message for lane N (for each middle lane) the value is the amount of pixels until a wall is hit on that lane
 * //wallTypeLaneN - sends 1 if the wall approaching is a yellow one and 2 for the red walls (that are jumpable)
 * /changeLaneProhibited - to play error sound
 * /startGame
 * /stopGame
 */
void sendOscMessage(String scope, int value) {
  OscMessage message = new OscMessage(scope);
  message.add(value);
  oscP5.send(message, PD_Location);
}

// method to handle the change lane when the OSC message /changeLane is received
void receiveChangeLane(int dir) {
  println("received OSC message '/changeLane' with dir " + dir);
  track.moveBall(dir);   
}

// method to handle the clap function to avoid big walls, called when OSC message /clap is received
void receiveClap() {
  println("received OSC message '/clap'");
  track.jump(); 
}

void exit() {
  frozenTimer.stop();
  gravelTimer.stop();
  gameTimer.stop();
  
  println("exited");
  isGameRunning = false;
  sendOscMessage("/stopGame", 0);
  
  stats_totalGameTime = gameTimer.getTotal();
  stats_timeSpentOnGravel = gravelTimer.getTotal();
  stats_timeSpentFrozen = frozenTimer.getTotal();
    

  String timestamp = fixTime(hour()) + fixTime(minute()) + fixTime(second());
 
  stats_json = new JSONObject();

  stats_json.setString("name", USER_NAME);
  if(COMMENT.length() > 0)  stats_json.setString("comment", COMMENT);
  stats_json.setBoolean("successfullyFinished", stats_successfullyFinished);
  stats_json.setFloat("totalGameTime", stats_totalGameTime/1000.0);
  stats_json.setFloat("timeSpentOnGravel", stats_timeSpentOnGravel*0.001);
  stats_json.setFloat("timeSpentFrozen", stats_timeSpentFrozen/1000.0);
  stats_json.setInt("numberOfWallsHit", stats_noOfWallsHit);
  stats_json.setString("date", fixTime(day()) + "." + fixTime(month()) + "." + fixTime(year()));
  stats_json.setString("startTime", stats_startTime);
  stats_json.setString("finishTime", getCurrentTime());

  saveJSONObject(stats_json, "trial_data/" + USER_NAME + "_" + timestamp + ".json");
  println("Datei gesichert");
}

private String getCurrentTime() {
  return fixTime(hour()) + ":" + fixTime(minute()) + ":" + fixTime(second());
}

private String fixTime(int time) { // add leading zeros and covert to String
  String t = String.valueOf(time);
  
  if(t.length() < 2) t = "0" + t;
  
  return t;
}
