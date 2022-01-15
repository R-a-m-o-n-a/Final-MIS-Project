import java.util.concurrent.ThreadLocalRandom;

// track constants
int TRACK_LENGTH = 1000; // how many rows in the track array
int TRACK_WIDTH = 600; // how many pixels the whole track is wide
int ROW_HEIGHT = 80; // how many pixels each row is high
int NO_OF_LANES = 4;
int CIRCLE_SPACING = 4; // the amount of pixels that should be on top and bottom when the ball is in a lane. The ball size gets calculated based on this

// wall parameters
int NO_OF_WALLS = 170;
int PERCENTAGE_OF_BIG_WALLS = 20;
int COLLISION_TIMEOUT = 2000;  // how long the ball cannot move after hitting a wall (in ms)
int PERVIOUS_WALLS_FOR_AMOUNT_OF_PIXELS = ceil(ROW_HEIGHT * 2.5);  // the walls are pervious for an amount of pixels moved, that way the difficulty stays the same if we change the speed

// colors
color GRAVEL_COLOR = color(53,51,50);
color TRACK_COLOR_A = color(20,65,120);
color TRACK_COLOR_B = color(0,55,104);
color WALL_COLOR = color(240,80,50);
color BIG_WALL_COLOR = color(240,20,50);

public class Track {
  int[][] track = new int[TRACK_LENGTH][NO_OF_LANES];
  Circle circle;
  int laneWidth = TRACK_WIDTH / NO_OF_LANES;
  int leftBorderX; // the pixel value of the left side of the track (the window is bigger than the track)
  int circleTop; // top-most position of the circle
  int maxShownLanes; // the maximum amount of lanes that could be visible on screen so that the others can be disregarded when drawing the track to save calculation power
  int position = 0; // the field of the track the ball is currently on, gets calculated based on the pixelPosition
  int pixelPosition = 0; // a value that counts up pixel by pixel when the track starts moving
  int speed = 3; // amount of pixels that we move each frame
  WallCollision collision = null; // variable that will be filled once we hit a wall
  boolean redWallsArePervious = false; // if the user claps, the red walls will become pervious for a specified amount of milliseconds, during this time this variable is true
  int perviousWallsStartPixelPosition; // will hold the start position of when the red walls became pervious

  // constructor: creates the circle and sets some important variables. Also fills track with walls
  public Track() {
    maxShownLanes = height / ROW_HEIGHT + 2; // add 2 more lanes just to be safe
    leftBorderX = ((width-TRACK_WIDTH)/2);
    circle = new Circle(NO_OF_LANES, TRACK_WIDTH, ROW_HEIGHT, CIRCLE_SPACING);
    circleTop = circle.getTopY();
    fillTrackWithWalls();
  }

  // move the whole track down so that the ball is "driving" without actually changing y position
  public void drive(int pixelsToMove) {
    if (isColliding() && collision == null) { // new collision detected → do not move forward
      sendOscMessage("/hitWall", COLLISION_TIMEOUT); // tell PD that we bumped into a wall and how long we are going to be unable to move (in ms)
      collision = new WallCollision(position+1, COLLISION_TIMEOUT); // create a new WallCollision object for the current collision
    } else if (collision == null) { // only move forward if no collision is currently freezing the ball
      pixelPosition += pixelsToMove; // add the amount of pixels to move to the current pixelPosition
      if (pixelPosition < 0) pixelPosition = 0; // might be obsolete, but just in case a negative value ever gets passed
      
      /* the position (the row we are currently on) is calculated
       * the first part [pixelPosition - (CIRCLE_SPACING + laneHeight/2)] aligns the top edge of the circle with the row change (the line between two rows)
       * we then divide all pixels that we have driven so far by the height of the row
       * we need to add two because the circle start position is already on the track and not before the track */
      position = (pixelPosition - (CIRCLE_SPACING + ROW_HEIGHT/2)) / ROW_HEIGHT + 2; 
      
      calculateWallDistance(); // to create sound of wall approaching
    }
  }

  // loop that draws and drives the game
  public void draw() {
    drive(speed); // move the track
    
    if(collision != null) { // if there is still a collision
      if(collision.isOver()) { // if the timer is run out and we are allowed to move again
        removeWall(collision.getRow()); // remove the wall so we can continue driving
        /* we also need to remove the wall on the previous row, because if the tail of the ball gets stuck in a reappearing red wall that was pervious before,
         * this is the actual wall that needs to be removed. In any other case the previous row is empty anyways and it will not change anything. */
        removeWall(collision.getRow()-1);
        collision = null; // and set the variable to null, so the collision is officially over
      }
    }
    
    if(redWallsArePervious && perviousWallsStartPixelPosition + PERVIOUS_WALLS_FOR_AMOUNT_OF_PIXELS <= pixelPosition) { // make red walls solid again after moved specified amount of pixels
       redWallsArePervious = false;
    }
  
    // draw the actual track
    for (int row = position-2; row < position-2 + maxShownLanes || row < TRACK_LENGTH; row++) { // iterates over all rows that are currently visible on screen
      for (int lane = 0; lane < NO_OF_LANES; lane++) { // iterates over all lanes
        fill(getFillColor(row, lane)); // gets the color in which to draw the current
        // the first two rectangle parameters are the coordinates of the upper left corner, then width, then height
        rect(leftBorderX + laneWidth * lane, height + pixelPosition - row * ROW_HEIGHT, laneWidth, ROW_HEIGHT);
      }
    }

    circle.draw();
  }

  /* function called by the constructor to add walls on the track
   * 0 - empty field, no wall
   * 1 - normal wall that spans over one lane only (plus the adjacent gravel lane)
   * 2 - big wall that spans over all lanes and can not be avoided by changing lane
   */
  public void fillTrackWithWalls() {
    for (int w = 0; w < NO_OF_WALLS; w++) { // places one wall after the other until specified number is reached
      int randomRow = generateRandomRowNumber(); // picks a random row
      while (!randomNumberOk(randomRow)) { // checks if the wall can be placed here (if there are no walls already close). generates new row until the placement can be carried out
        randomRow = generateRandomRowNumber();
      }
      if(makeBigWall()) { // calculates whether a wall should be a big wall based on the probability specified
        for(int lane = 0; lane < NO_OF_LANES; lane++) { // spread wall over all lanes
          track[randomRow][lane] = 2;
        }
      } else { 
        /* if the wall should not be big, place it on one randomly picked lane
         * only center lanes (not the gravel lanes) are picked for wall placement
         * but if the lane that the wall is on touches a gravel lane, the wall is spread also over the gravel lanes so that they cannot be used to pass by walls without ever changing lane
         */
        int randomLane = generateRandomNumber(1, NO_OF_LANES - 2);
        track[randomRow][randomLane] = 1;
        if (randomLane == 1) {
          track[randomRow][0] = 1;
        }
        if (randomLane == NO_OF_LANES - 2) {
          track[randomRow][NO_OF_LANES - 1] = 1;
        }
      }
    }
  }

  /* function that determines the fill color of the rectangles that make up the track */
  public color getFillColor(int row, int lane) {
    color fillColor;
    color wallColor;
    color trackColor;
    if (lane == 0 || lane == NO_OF_LANES - 1) { // outside lane? (gravel lane)
      trackColor = GRAVEL_COLOR;
    } else { // inside lane (no gravel)
      if (row % 2 == 0) { // even rows get a slightly different color than uneven rows
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
      if(redWallsArePervious) {
        wallColor = lerpColor(BIG_WALL_COLOR, trackColor, 0.5);
      } else {
        wallColor = BIG_WALL_COLOR;
      }
      fillColor = wallColor;
    }
    // during a collision the wall slowly disappears until the player is allowed to move again, so the color is interpolated between the wall and the track color
    if(collision != null && (row == collision.getRow() || row == collision.getRow()-1)) {
      fillColor =  lerpColor(wallColor, trackColor, collision.getTimeoutPercentage());
    }
    return fillColor;
  } 
  
  private boolean isColliding() { // is the ball touching a wall?
    return isAnyPartOfTheBallOnAWall(circle.getLane());
  }
  
  public void removeWall(int row) { // fills an entire track row with 0, so that there is no more wall
    for (int lane = 0; lane < NO_OF_LANES; lane++) {
      track[row][lane] = 0;
    }
  }

  public boolean randomNumberOk(int r) { // there is no wall in this line or the three lines before or after → ensures that the player is able to change lanes in order to avoid normal walls
    return (track[r][1] == 0 && track[r][2] == 0)
            && (track[r + 1][1] == 0 && track[r + 1][2] == 0)
            && (track[r - 1][1] == 0 && track[r - 1][2] == 0)
            && (track[r + 2][1] == 0 && track[r + 2][2] == 0)
            && (track[r - 2][1] == 0 && track[r - 2][2] == 0)
            && (track[r + 3][1] == 0 && track[r + 3][2] == 0)
            && (track[r - 3][1] == 0 && track[r - 3][2] == 0);
  }

  public int generateRandomNumber(int min, int max) {
    return ThreadLocalRandom.current().nextInt(min, max + 1);
  }

  public boolean makeBigWall() { // calculates whether a wall should be a big wall based on the probability specified
    return generateRandomNumber(0, 100) < PERCENTAGE_OF_BIG_WALLS;
  }

  public int generateRandomRowNumber() {
    return generateRandomNumber(7, TRACK_LENGTH-5);
  }

  public void moveCircle(int dir) { // tries to change lane, if not allowed will not change
    if(collision == null) {
      boolean isBallOnGravel = circle.move(dir, movingWouldCauseCollision(dir));
    }
  }
  
  private boolean movingWouldCauseCollision(int dir) { // is any part of the ball next to a wall? In that case we are not allowed to change lane
    int newLane = circle.getLane() + dir;
    if(newLane < 0 || newLane >= NO_OF_LANES) return true;
    
    return isAnyPartOfTheBallOnAWall(newLane);
  }
  
  /* for each central lane (not gravel lanes) this function calculates how many pixels ahead the next wall is placed 
   * it then sends this value to PD in order to generate a sound representing this distance */
  private void calculateWallDistance() { 
    for(int lane = 1; lane < NO_OF_LANES - 1; lane++) { // only for middle lanes
    
      // find the next wall
      int positionOfNextWall = position+1;
      while(track[positionOfNextWall][lane] == 0) positionOfNextWall++;
      
      // calculate the distance
      int pixelPositionOfNextWall = (positionOfNextWall - 2) * ROW_HEIGHT;
      int distance = pixelPositionOfNextWall - pixelPosition;
      
      if(isAnyPartOfTheBallOnAWall(lane)) distance = 0;
      
      sendOscMessage("/wallDistanceLane"+lane, distance);
    }
  }
  
  private boolean isAnyPartOfTheBallOnAWall(int lane) {
    /* the circle is tracked on its top. So the first parameter only checks whether the top of the ball is on a wall
     * therefore we need the second double boolean to check whether in the row under the top of the ball is a wall and the tail of the ball is still next to it.
     * Don't touch it. Took me hours to figure out how to do it right */
    return fieldIsHardWall(position+1, lane) || (fieldIsHardWall(position, lane) && !((position - 1) * ROW_HEIGHT + (ROW_HEIGHT/2 - CIRCLE_SPACING*2) <= pixelPosition));
  }
  
  public void makeRedWallsPervious() {
    // we only start the pervious walls timeout if it is not currently running because otherwise the player could keep the mode on endlessly
    if(!redWallsArePervious) {
      this.perviousWallsStartPixelPosition = pixelPosition;
      redWallsArePervious = true;
    }
  }
  
  private boolean fieldIsHardWall(int row, int lane) {
    // field is hard wall if it either has a normal (orange) wall, or a big (red) wall that is not currently pervious
    return track[row][lane] == 1 || (track[row][lane] == 2 && !redWallsArePervious);
  }
}
