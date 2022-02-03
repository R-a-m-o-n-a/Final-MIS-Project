import oscP5.*;
import netP5.*;

// Variables for communication via OSC messages
OscP5 oscP5;
NetAddress PD_Location;
String PD_IP = "127.0.0.1";
int LISTENING_PORT = 32000;
int SENDING_PORT = 12000;

// variables for the game itself
Track track;
int countdown = 8;
boolean isCountdownRunning = false;
boolean isGameRunning = false;

// variables for statistics
String USER_NAME = "SoundTest"; // fill in participant name here
boolean USING_VISUAL_MODE = true; // true for visual, false for auditory/haptic mode
String COMMENT = ""; // optional
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
boolean statsPublished = false; // they get published when the game ends. also if the window gets closed before, but not if the window gets closed after and they have already been published

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
  
  // load images
  infoIcon = loadImage("info.png");
  speechBubble = loadImage("speech_bubble.png");
    
  // create track
  track = new Track();
  noStroke(); // don't draw border on shapes
}

// loop that is repeated all over again
void draw() {
  background(0, 0, 0); 
  
  if(isGameRunning) { 
    track.drive(); // moves the track
  } 
  
  track.draw();
  
  if(!isGameRunning && !stats_successfullyFinished) { // before the game
    if(isCountdownRunning) {
      displayCountdown();
    } else {
      image(speechBubble, width-400, height-300, 370, 270);
      image(infoIcon, width-365, height-270, 60, 60);
      fill(color(0,0,0));
      textAlign(RIGHT);
      textSize(45);
      textLeading(50);
      text("press\nspace bar\nto start", width-360, height-270, 250, 250);
    }
  }
}

// key controls (keys a and d are alternative lane changing controls for testing, the space bar starts the game)
void keyPressed() {
  if (key == 'a') {
    track.moveBall(-1);
  } else if (key == 'd') {
    track.moveBall(1);
  } else if(key ==  ' ') {
    if(isGameRunning) {
      track.jump();
    } else {
      startCountdown();
    }
  } 
}

private void startCountdown() {
  isCountdownRunning = true;
  sendOscMessage("/startCountdown", USING_VISUAL_MODE ? 0 : 1);
  if(USING_VISUAL_MODE) {
    sendOscMessage("/visualMode", 0);
  }
}

private void displayCountdown() {
    String text = null;
    switch (countdown) {
      case 8:
        text = "READY?";
        break;
      case 7: 
        delay(500);
        break;
      case 5:
      case 3:
      case 1:
      case -1:
        delay(500);
        break;
      case 6:
      case 4:
      case 2:
        text = String.valueOf(countdown/2);
        delay(500);
        break;
      case 0:
        text = "START";
        delay(500); 
        break;
      case -2:
        startGame();          
    }
    if(text != null) {
      fill(color(0,0,0));
      textAlign(CENTER);
      textSize(170);
      text(text, width/2+5, height/2+5);
      fill(color(255,255,255));
      text(text, width/2, height/2);
    }
    countdown--;
}

private void startGame() {
  isGameRunning = true;
  stats_startTime = getCurrentTime();
  gameTimer.start();
  // sendOscMessage("/startCountdown", 0);
  sendOscMessage("/startGame", 1);
}

public void finishedGame() {
    sendOscMessage("/reachedFinishLine", 1);
    stats_successfullyFinished = true;
    isGameRunning = false;
    publishStats();
}

/** Send OSC Messages to PD.
 * Implemented Messages are
 * /frameRateChanged - sends new frameRate
 * /laneChanged - sends new lane
 * /changeLaneProhibited - to play error sound
 * /hitWall - sends the amount of milliseconds that the ball will be frozen until it starts again
 * /wallDistanceLaneN - sends a message for lane N (for each middle lane) the value is the amount of pixels until a wall is hit on that lane
 * /wallType - sends the lane (1 or 2) if the wall approaching is a yellow wall and 5 for the red walls (that are jumpable)
 * /startGame - 1 if starting, 0 if finished
 * /startCountdown - 1 at countdown start
 * /visualMode - sends a 0 to turn off the sound engine in visual only mode
 * /reachedFinishLine
 */
void sendOscMessage(String scope, int value) {
  OscMessage message = new OscMessage(scope);
  message.add(value);
  oscP5.send(message, PD_Location);
  println("OSCmessage " + scope + " " + value);
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

private void publishStats() {
  frozenTimer.stop();
  gravelTimer.stop();
  gameTimer.stop();
  
  stats_totalGameTime = gameTimer.getTotal();
  stats_timeSpentOnGravel = gravelTimer.getTotal();
  stats_timeSpentFrozen = frozenTimer.getTotal();
    
  String timestamp = fixTime(hour()) + fixTime(minute()) + fixTime(second());
 
  stats_json = new JSONObject();

  stats_json.setString("name", USER_NAME);
  stats_json.setBoolean("visual", USING_VISUAL_MODE);
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
  
  statsPublished = true;
  println("Datei gesichert");
}

void exit() {
  isGameRunning = false;
  if (!statsPublished) {
    publishStats();
  }
  sendOscMessage("/startGame", 0);
}

private String getCurrentTime() {
  return fixTime(hour()) + ":" + fixTime(minute()) + ":" + fixTime(second());
}

private String fixTime(int time) { // add leading zeros and covert to String
  String t = String.valueOf(time);
  
  if(t.length() < 2) t = "0" + t;
  
  return t;
}
