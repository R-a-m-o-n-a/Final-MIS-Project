int trackWidth = 500;
int laneHeight = 50;
int noOfLanes = 4;
int time;
Track track;
float speed =10;

void setup(){
  size(1500,800);
  background(0, 0, 0); 
  track = new Track(noOfLanes,trackWidth, laneHeight, (width-trackWidth)/2);
  noStroke();
  time = millis();
}

void draw() {
  if (millis() > time + 100/speed)
  {
    track.drive(1);
    time = millis();
  }
  track.draw();
}

void keyPressed() {
  if (key == 'a') {
    track.moveCircle(-1);
  } else if (key == 'd') {
    track.moveCircle(1);
  }
}
