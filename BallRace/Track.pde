import java.util.concurrent.ThreadLocalRandom;

int NO_OF_WALLS = 250;
int PERCENTAGE_OF_BIG_WALLS = 20;
int TRACK_LENGTH = 1000;
int CIRCLE_SPACING = 4;
int CIRCLE_OFFSET = CIRCLE_SPACING + laneHeight/2;
color gravelColor = color(53,51,50);
color trackColor1 = color(20,65,120);
color trackColor2 = color(0,55,104);
color wallColor = color(240,80,50);
color bigWallColor = color(240,20,50);

public class Track {

  Circle circle;
  int noOfLanes = 4;
  int[][] track = new int[TRACK_LENGTH][noOfLanes];
  int trackWidth = 500;
  int laneHeight = 50;
  int position = 0;
  int pixelPosition = 0;
  int leftBorderX = 0;
  int laneWidth = trackWidth / noOfLanes;
  int maxShownLanes = height / laneHeight + 2;
  int circleTop;
  int speed = 1;

  public Track(int givenNoOfLanes, int givenTrackWidth, int givenLaneHeight, int leftX) {
    trackWidth = givenTrackWidth;
    laneHeight = givenLaneHeight;
    noOfLanes = givenNoOfLanes;
    maxShownLanes = height / laneHeight + 2;
    track = new int[TRACK_LENGTH][noOfLanes];
    leftBorderX = leftX;
    laneWidth = trackWidth / noOfLanes;
    circle = new Circle(noOfLanes, trackWidth, laneHeight, CIRCLE_SPACING);
    circleTop = circle.getTopY();
    fillTrackWithWalls();
  }

  public void drive(int steps) {
    if (isColliding()) {
      
    } else {
      pixelPosition += steps;
      if (pixelPosition < 0) pixelPosition = 0;
      position = (pixelPosition-CIRCLE_OFFSET) / laneHeight+2;
      println(pixelPosition + " " + position);
    }
  }
  
  private boolean isColliding() {
    return track[position+1][circle.getLane()] != 0;
  }

  public void draw() {
    drive(speed);
  
    for (int i = position-2; i < position-2 + maxShownLanes || i < TRACK_LENGTH; i++) {
      for (int lane = 0; lane < noOfLanes; lane++) {
        fill(getFillColor(i, lane));
        // upperleftcorner, width, height
        rect(leftBorderX + laneWidth * lane, height + pixelPosition - i * laneHeight, laneWidth, laneHeight);
      }
    }

    circle.draw();
  }

  public void fillTrackWithWalls() {
    for (int w = 0; w < NO_OF_WALLS; w++) {
      int rWallPosition = generateRandomWallNumber();
      while (!randomNumberOk(rWallPosition)) {
        rWallPosition = generateRandomWallNumber();
      }
      if(makeBigWall()) {
        for(int lane = 0; lane < noOfLanes; lane++) {
          track[rWallPosition][lane] = 2;
        }
      } else {
        int rLane = generateRandomNumber(1, noOfLanes - 2);
        track[rWallPosition][rLane] = 1;
        if (rLane == 1) {
          track[rWallPosition][0] = 1;
        }
        if (rLane == noOfLanes - 2) {
          track[rWallPosition][noOfLanes - 1] = 1;
        }
      }
    }
  }

  public color getFillColor(int row, int lane) {
    color fillColor;
    if (lane == 0 || lane == noOfLanes - 1) {
      fillColor = gravelColor;
    } else {
      if (row % 2 == 0) {
        fillColor = trackColor1;
      } else {
        fillColor = trackColor2;
      }
    }
    if (track[row][lane] == 1) {
      fillColor = wallColor;
    }
    if (track[row][lane] == 2) {
      fillColor = bigWallColor;
    }
    return fillColor;
  }

  public boolean randomNumberOk(int r) { // there is no wall in this line or the one before or after
    return (track[r][1] == 0 && track[r][2] == 0)
            && (track[r + 1][1] == 0 && track[r + 1][2] == 0)
            && (track[r - 1][1] == 0 && track[r - 1][2] == 0)
            && (track[r + 2][1] == 0 && track[r + 2][2] == 0)
            && (track[r - 2][1] == 0 && track[r - 2][2] == 0);
  }

  public int generateRandomWallNumber() {
    return generateRandomNumber(7, 997);
  }

  public int generateRandomNumber(int min, int max) {
    return ThreadLocalRandom.current().nextInt(min, max + 1);
  }

  public boolean makeBigWall() {
    return ThreadLocalRandom.current().nextInt(0, 100 + 1) < PERCENTAGE_OF_BIG_WALLS;
  }

  public void moveCircle(int dir) {
    boolean isBallOnGravel = circle.move(dir);
  }
}
