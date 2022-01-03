int trackWidth = 500;
int laneHeight = 50;
int noOfLanes = 4;
int startTime;
Track track;

void setup(){
  size(1500,800);
  track = new Track(noOfLanes,trackWidth, laneHeight, (width-trackWidth)/2);
  noStroke();
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
