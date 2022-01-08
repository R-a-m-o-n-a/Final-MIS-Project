import java.util.concurrent.ThreadLocalRandom;

int NO_OF_WALLS = 250;
int PERCENTAGE_OF_BIG_WALLS = 20;
int TRACK_LENGTH = 1000;
int CIRCLE_SPACING = 4;
int COLLISION_TIMEOUT = 2000; 
color GRAVEL_COLOR = color(53,51,50);
color TRACK_COLOR_A = color(20,65,120);
color TRACK_COLOR_B = color(0,55,104);
color WALL_COLOR = color(240,80,50);
color BIG_WALL_COLOR = color(240,20,50);

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
  WallCollision collision = null;

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
    if (isColliding() && collision == null) {
      sendOscMessage("/hitWall", COLLISION_TIMEOUT); // tell PD that we bumped into a wall and how long we are going to be freezed (in ms)
      collision = new WallCollision(position+1, COLLISION_TIMEOUT);
    } else if (collision == null) { // only move forward if no collision is currently freezing the ball
      pixelPosition += steps;
      if (pixelPosition < 0) pixelPosition = 0; // might be obsolete
      
      position = (pixelPosition - (CIRCLE_SPACING + laneHeight/2)) / laneHeight + 2; // pixelPosition - (CIRCLE_SPACING + laneHeight/2) aligns top of circle with row change.
      
      calculateWallDistance(); // to create sound of wall approaching
    }
  }
  
  private boolean isColliding() {
    return track[position+1][circle.getLane()] != 0;
  }

  public void draw() {
    drive(speed);
    if(collision != null) {
      //println(collision.getTimeoutPercentage());
      if(collision.isOver()) {
        //println(collision.getTrackField());
        removeWall(collision.getTrackField());
        collision = null;
      }
    }
  
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
    color wallColor;
    color trackColor;
    if (lane == 0 || lane == noOfLanes - 1) {
      trackColor = GRAVEL_COLOR;
    } else {
      if (row % 2 == 0) {
        trackColor = TRACK_COLOR_A;
      } else {
        trackColor = TRACK_COLOR_B;
      }
    }
    fillColor = trackColor;
    wallColor = trackColor;
    if (track[row][lane] == 1) {
      wallColor = WALL_COLOR;
      fillColor = WALL_COLOR;
    }
    if (track[row][lane] == 2) {
      wallColor = BIG_WALL_COLOR;
      fillColor = BIG_WALL_COLOR;
    }
    if(collision != null && row == collision.getTrackField()) {
      fillColor =  lerpColor(wallColor, trackColor, collision.getTimeoutPercentage());
    }
    return fillColor;
  }
  
  public void removeWall(int trackField) {
    for (int lane = 0; lane < noOfLanes; lane++) {
      print(track[trackField][lane]);
      track[trackField][lane] = 0;
    }
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
    if(collision == null) {
      boolean isBallOnGravel = circle.move(dir, movingWouldCauseCollision(dir));
    }
  }
  
  private boolean movingWouldCauseCollision(int dir) {
    int newLane = circle.getLane() + dir;
    if(newLane < 0 || newLane >= noOfLanes) return true;
    
    /* the circle is tracked on its top. So the first parameter only checks whether the top of the ball is next to a wall
     * therefore we need the second double boolean to check whether in the row under the top of the ball is a wall and the tail of the ball is still next to it.
     * Don't touch it. Took me hours to figure out how to do it right */
    return track[position+1][newLane] != 0 || (track[position][newLane] != 0 && !((position - 1) * laneHeight + (laneHeight/2 - CIRCLE_SPACING*2) <= pixelPosition));
  }
  
  private void calculateWallDistance() {
    for(int lane = 1; lane < noOfLanes - 1; lane++) { // only for middle lanes
    
      // find the next wall
      int positionOfNextWall = position+1;
      while(track[positionOfNextWall][lane] == 0) positionOfNextWall++;
      
      // calculate the distance
      int pixelPositionOfNextWall = (positionOfNextWall - 2) * laneHeight;
      int distance = pixelPositionOfNextWall - pixelPosition;
      
      boolean onWall = track[position+1][lane] != 0 || (track[position][lane] != 0 && !((position - 1) * laneHeight + (laneHeight/2 - CIRCLE_SPACING*2) <= pixelPosition));
      
      //println(onWall ? ("Wall on lane " + lane + " is HERE!") : ("Wall on lane " + lane + " is " + distance + " pixels away."));
      
      sendOscMessageForWallDistance(lane, onWall ? 0 : distance);
    }
  }
}
