import java.util.concurrent.ThreadLocalRandom;

// track constants
int TRACK_LENGTH = 380; // how many rows in the track array
int TRACK_WIDTH = 1000; // how many pixels the whole track is wide
int ROW_HEIGHT = 100; // how many pixels each row is high
int NO_OF_LANES = 4;
int BALL_SPACING = 4; // the amount of pixels that should be on top and bottom when the ball is in a lane. The ball size gets calculated based on this
int wallPlacementTrials = 0; // for the wall placement, an indication of how many times the calculation restarted
/* the wall placement may not be done in the very best way. I might change it in a way that walls are placed subsequently along the track, in a range of minDistance to maxDistance from the last wall, instead of completely randomly */

// wall parameters
int NO_OF_WALLS = 30;
int MIN_DISTANCE_BETWEEN_WALLS = 10;
int PERCENTAGE_OF_BIG_WALLS = 30;
int COLLISION_TIMEOUT = 2000;  // how long the ball cannot move after hitting a wall (in ms)
int JUMP_DURATION_IN_PIXELS = ceil(ROW_HEIGHT * 3);  // the ball jumps for an amount of pixels moved, that way the difficulty stays the same if we change the speed
int MAX_CONSECUTIVE_WALLS_ON_ONE_LANE = 2;
int CHANGING_AFTER_WALL_ALLOWANCE = 15; // for explanantion see function isAnyPartOfTheBallOnAWall()
int THRESHOLD_FOR_SENDING_WALL_DISTANCE = 500;

// colors
color GRAVEL_COLOR = color(53,51,50);
color TRACK_COLOR_A = color(20,65,120);
color TRACK_COLOR_B = color(0,55,104);
color WALL_COLOR = color(240,210,70);
color BIG_WALL_COLOR = color(200,20,50);

public class Track {
  int[][] track = new int[TRACK_LENGTH][NO_OF_LANES];
  Ball ball;
  int laneWidth = TRACK_WIDTH / NO_OF_LANES;
  int leftBorderX; // the pixel value of the left side of the track (the window is bigger than the track)
  int ballTopY; // top-most position of the ball
  int maxShownLanes; // the maximum amount of lanes that could be visible on screen so that the others can be disregarded when drawing the track to save calculation power
  int position = 2; // the field of the track the ball is currently on, gets calculated based on the pixelPosition
  int pixelPosition = 0; // a value that counts up pixel by pixel when the track starts moving
  int speed = 10; // amount of pixels that we move each frame
  WallCollision collision = null; // variable that will be filled once we hit a wall
  boolean isBallJumping = false; // if the user claps, the ball will jump and red walls can be avoided while this variable is true
  int pixelPositionAtJumpStart; // will hold the start position of when the ball started jumping
  IntList wallPositionsWarnedAbout = new IntList(); // list holds all the walls that we warned the user about (via PD messages), so that each wall is only warned about once

  // constructor: creates the ball and sets some important variables. Also fills track with walls
  public Track() {
    maxShownLanes = height / ROW_HEIGHT + 3; // add 3 more lanes just to be safe (for lanes going in and out)
    leftBorderX = ((width-TRACK_WIDTH)/2);
    ball = new Ball(NO_OF_LANES, TRACK_WIDTH, ROW_HEIGHT, BALL_SPACING);
    ballTopY = ball.getTopY();
    fillTrackWithWalls();
  }

  // move the whole track down so that the ball is "driving" without actually changing y position
  public void drive() {
    
    if(position >= TRACK_LENGTH-3) { // reached end of track
      frameRate(frameRate*0.7); // slow game down exponentially
    } if(position >= TRACK_LENGTH-2) { // stop game
      finishedGame();
    }
    
    if (isColliding() && collision == null) { // new collision detected → do not move forward
      stats_noOfWallsHit++;
      sendOscMessage("/hitWall", COLLISION_TIMEOUT); // tell PD that we bumped into a wall and how long we are going to be unable to move (in ms)
      collision = new WallCollision(position+1, COLLISION_TIMEOUT); // create a new WallCollision object for the current collision
      frozenTimer.start();
    } else if (collision == null) { // only move forward if no collision is currently freezing the ball
      pixelPosition += speed; // add the amount of pixels to move to the current pixelPosition
      if (pixelPosition < 0) pixelPosition = 0; // might be obsolete, but just in case a negative value ever gets passed
      
      /* the position (the row we are currently on) is calculated
       * the first part [pixelPosition - (BALL_SPACING + laneHeight/2)] aligns the top edge of the ball with the row change (the line between two rows)
       * we then divide all pixels that we have driven so far by the height of the row
       * we need to add two because the ball start position is already on the track and not before the track */
      position = (pixelPosition - (BALL_SPACING + ROW_HEIGHT/2)) / ROW_HEIGHT + 2; 
      
      sendNextWallMessages(); // to create sound of wall approaching
    }
  }

  // loop that draws and drives the game
  public void draw() {    
    if(collision != null) { // if there is still a collision
      if(collision.isOver()) { // if the timer is run out and we are allowed to move again
        frozenTimer.stop();
        removeWall(collision.getRow()); // remove the wall so we can continue driving
        /* we also need to remove the wall on the previous row, because if the tail of the ball gets stuck in a red wall while coming down from a jump
         * this is the actual wall that needs to be removed. In any other case the previous row is empty anyways and it will not change anything. */
        removeWall(collision.getRow()-1);
        collision = null; // and set the variable to null, so the collision is officially over
      }
    }
    
    if(isBallJumping) {
      float factor = abs((pixelPositionAtJumpStart - pixelPosition) /(float) JUMP_DURATION_IN_PIXELS); // get percentage of how many pixels have passed
      if(factor>0.5) factor = 1 - factor; // map values from 0→1 to 0→0.5→0
      factor*=1.5; // here we can control how big the maximum factor (maximum size of ball) should be
      factor += 1; // add 1 for 1→1.5→1
      ball.setBallSize(factor);
    }
    if(isBallJumping && pixelPositionAtJumpStart + JUMP_DURATION_IN_PIXELS <= pixelPosition) { // make red walls solid again after moved specified amount of pixels
       isBallJumping = false;
       ball.setBallSize(1);
    }
  
    // draw the actual track
    for (int row = position-2; row < position-2 + maxShownLanes && row < TRACK_LENGTH; row++) { // iterates over all rows that are currently visible on screen
      if(row == TRACK_LENGTH - 3) {
        drawFinishLine();
      } else {
        for (int lane = 0; lane < NO_OF_LANES; lane++) { // iterates over all lanes
          fill(getFillColor(row, lane)); // gets the color in which to draw the current
          // the first two rectangle parameters are the coordinates of the upper left corner, then width, then height
          rect(leftBorderX + laneWidth * lane, height + pixelPosition - row * ROW_HEIGHT, laneWidth, ROW_HEIGHT);
        }
      }
    }

    ball.draw();
  }

  /* function called by the constructor to add walls on the track
   * 0 - empty field, no wall
   * 1 - normal wall that spans over one lane only (plus the adjacent gravel lane)
   * 2 - big wall that spans over all lanes and can not be avoided by changing lane
   */
  public void fillTrackWithWalls() {
    IntList wallRows = new IntList();
    for (int w = 0; w < NO_OF_WALLS; w++) { // places one wall after the other until specified number is reached
      int randomRow = generateRandomRowNumber(); // picks a random row
      int loopCount = 0; // use the loopCount to send messages if the wall placement would lead to an endless loop
      while (!randomNumberOk(randomRow, wallRows)) { // checks if the wall can be placed here (if there are no walls already close). generates new row until the placement can be carried out
        loopCount++;
        randomRow = generateRandomRowNumber();
        if(loopCount == 1000) {
          println("Problems placing wall no. " + w);
        }
        if(loopCount == 3000) {
          println("Retrying. If this message shows up too many times (like more than 5000), change the no. of walls, distance between them, or track length! This is no. " + wallPlacementTrials++);
          track = new int[TRACK_LENGTH][NO_OF_LANES];
          wallRows = new IntList();
          w = 0;
        }
      }
      // we add the remaining walls to a list because we want to place them on alternating lanes. the easiest way for this is to sort the list and then alternate
      wallRows.append(randomRow);
    }
    wallRows.sort();
    int prevLane = 2;
    int prevLaneCount = 0;
    for(int i = 0; i < wallRows.size(); i++) { // add normal walls to each previously picked row
      int row = wallRows.get(i);
      
      if(makeBigWall()) { // calculates whether a wall should be a big wall based on the probability specified
        for(int lane = 0; lane < NO_OF_LANES; lane++) { // spread wall over all lanes
          track[row][lane] = 2;
        }
      } else { // place wall on random lane
        int randomLane = generateRandomNumber(1, NO_OF_LANES - 2);
        
        // the following code makes sure that not more than MAX_CONSECUTIVE_WALLS_ON_ONE_LANE walls are placed on one single lane
        if(randomLane == prevLane) {
          if(prevLaneCount >= MAX_CONSECUTIVE_WALLS_ON_ONE_LANE) {
            while(randomLane == prevLane) {
              //println("recalculating because max on lane " + prevLane + " and row " + row);
              randomLane = generateRandomNumber(1, NO_OF_LANES - 2);
            }
            prevLane = randomLane;
            prevLaneCount = 1;
          } else {
            prevLaneCount++;
          }
        } else {
          prevLane = randomLane;
          prevLaneCount = 1;
        }
        
        track[row][randomLane] = 1; // set the wall on the calculated position            
        
         // also add wall to adjacent gravel lane so it can't be avoided by going there
        if(randomLane == 1) {
          track[row][0] = 1;
        } 
        if(randomLane == NO_OF_LANES - 2) {
          track[row][NO_OF_LANES - 1] = 1;
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
      /* this was to make the walls penetrable and semi-transparent as an alternative to the ball jumping
      if(isBallJumping) {
        wallColor = lerpColor(BIG_WALL_COLOR, trackColor, 0.5);
      } else {
      */
        wallColor = BIG_WALL_COLOR;
      //}
      fillColor = wallColor;
    }
    // during a collision the wall slowly disappears until the player is allowed to move again, so the color is interpolated between the wall and the track color
    if(collision != null && (row == collision.getRow() || row == collision.getRow()-1)) {
      fillColor =  lerpColor(wallColor, trackColor, collision.getTimeoutPercentage());
    }
    return fillColor;
  } 
  
  private boolean isColliding() { // is the ball touching a wall?
    return isAnyPartOfTheBallOnAWall(ball.getLane());
  }
  
  public void removeWall(int row) { // fills an entire track row with 0, so that there is no more wall
    for (int lane = 0; lane < NO_OF_LANES; lane++) {
      track[row][lane] = 0;
    }
  }

  public boolean randomNumberOk(int r, IntList wallRows) { // checks whether there is no wall in this line or the lines before or after yet → ensures that the player is able to change lanes in order to avoid normal walls
    boolean surroundingRowsFree = true;
    for(int d = 0; d < MIN_DISTANCE_BETWEEN_WALLS+1; d++) {
      if(wallRows.hasValue(r+d) || wallRows.hasValue(r-d)) surroundingRowsFree = false;
    }
    return surroundingRowsFree;
  }

  public int generateRandomNumber(int min, int max) {
    return ThreadLocalRandom.current().nextInt(min, max + 1);
  }

  public boolean makeBigWall() { // calculates whether a wall should be a big wall based on the probability specified
    return generateRandomNumber(0, 100) < PERCENTAGE_OF_BIG_WALLS;
  }

  public int generateRandomRowNumber() {
    return generateRandomNumber(7, TRACK_LENGTH-6);
  }

  public void moveBall(int dir) { // tries to change lane, if not allowed will not change
    if(isGameRunning && collision == null) {
      ball.move(dir, movingWouldCauseCollision(dir));
    }
  }
  
  private boolean movingWouldCauseCollision(int dir) { // is any part of the ball next to a wall? In that case we are not allowed to change lane
    int newLane = ball.getLane() + dir;
    if(newLane < 0 || newLane >= NO_OF_LANES) return true;
    
    return isAnyPartOfTheBallOnAWall(newLane);
  }
  
  private int getPositionOfNextWallOnLane(int lane) {
    int positionOfNextWall = position;
    do {
      positionOfNextWall++;
      
      if(positionOfNextWall >= TRACK_LENGTH) {
        // no more walls
        //sendOscMessage("/wallDistanceLane"+lane, -1000);
        return 99999; // leave the function and don't do anything else.
      }
    } while(track[positionOfNextWall][lane] == 0);
    return positionOfNextWall;
  }
  
  /* this is a specific method adapted to the setup of 4 lanes, which is what we use in our PD patch
   * it replaces a method we had before for an arbitrary number of lanes, but since the PD sketch ended up being specific to 4 lanes, we adapted this message to send exactly what PD needs
   */
  private void sendNextWallMessages() {
    int positionOfNextWallLane1 = getPositionOfNextWallOnLane(1);
    int positionOfNextWallLane2 = getPositionOfNextWallOnLane(2);
        
    int laneOfNextWall;
    int positionOfNextWall;
            
    if(positionOfNextWallLane1 < positionOfNextWallLane2) {
      laneOfNextWall = 1;
      positionOfNextWall = positionOfNextWallLane1;
    } else {
      laneOfNextWall = 2;
      positionOfNextWall = positionOfNextWallLane2;
    }
    
    //println(wallPositionsWarnedAbout.size() + " "+ positionOfNextWall + " " + wallPositionsWarnedAbout.hasValue(positionOfNextWall));
    
    if(positionOfNextWall == 99999) { // no more walls. Just leave the function.
      return;
    } else { // only send OSC message when wall is first spotted. Only once for each wall
      
      int typeOfWall = track[positionOfNextWall][laneOfNextWall]; // 1 is solid wall → lower sound, 2 is red wall, higher sound (because jumpable)
      
      // calculate the distance
      int pixelPositionOfNextWall = (positionOfNextWall - 2) * ROW_HEIGHT;
      int distance = pixelPositionOfNextWall - pixelPosition;
      
      if(distance < 0) distance = 0; // the top of the ball is past the wall, but the rest of the ball is still next to it
      if(distance < THRESHOLD_FOR_SENDING_WALL_DISTANCE && collision == null) {
        
        if (typeOfWall == 1) {
          if(!wallPositionsWarnedAbout.hasValue(positionOfNextWall)) {
            sendOscMessage("/wallType", laneOfNextWall);
          }
          sendOscMessage("/wallDistanceLane"+laneOfNextWall, distance);
        }
        else if (typeOfWall == 2) {
          if(!wallPositionsWarnedAbout.hasValue(positionOfNextWall)) {
            sendOscMessage("/wallType", 5);
          }
          sendOscMessage("/wallDistanceRed", distance);
        }
        wallPositionsWarnedAbout.append(positionOfNextWall); // add wall to the list of walls we already warned the user about
      }
    }
  }
  
  private boolean isAnyPartOfTheBallOnAWall(int lane) {
    /* the ball is tracked on its top. So the first parameter only checks whether the top of the ball is on a wall
     * therefore we need the second double boolean to check whether in the row under the top of the ball is a wall and the tail of the ball is still next to it.
     * the CHANGING_AFTER_WALL_ALLOWANCE that is subtracted are to allow moving, even when the ball is still technically next to the wall, 
     * but based on the speed it won't touch the wall because once it reaches the other lane the game (and wall) will have moved down already
     * if we leave the CHANGING_AFTER_WALL_ALLOWANCE pixels out the user feels like the move was not registered.
     * Don't touch it. Took me hours to figure out how to do it right */
    return fieldIsHardWall(position+1, lane) || (fieldIsHardWall(position, lane) && !((position - 1) * ROW_HEIGHT + (ROW_HEIGHT/2 - BALL_SPACING*2 - CHANGING_AFTER_WALL_ALLOWANCE) <= pixelPosition));
  }
  
  public void jump() {
    // we only start the jumping timeout if it is not currently running because otherwise the player could keep the mode on endlessly
    if(!isBallJumping) {
      this.pixelPositionAtJumpStart = pixelPosition;
      isBallJumping = true;
    }
  }
  
  private boolean fieldIsHardWall(int row, int lane) {
    // field is hard wall if it either has a normal (yellow) wall, or a big (red) wall that the ball is not currently jumping over
    return track[row][lane] == 1 || (track[row][lane] == 2 && !isBallJumping);
  }
  
  private void drawFinishLine() {
    int checkerSize = 10;
    boolean black = true;
    for(int y = 0; y < ROW_HEIGHT; y += checkerSize) {
      black = y % 20 == 0;
      for (int x = leftBorderX; x < leftBorderX+TRACK_WIDTH; x += checkerSize) {
        fill(black ? color(0,0,0) : color(250,250,250));
        black = !black;
        // the first two rectangle parameters are the coordinates of the upper left corner, then width, then height
        rect(x, height + pixelPosition - (TRACK_LENGTH-3) * ROW_HEIGHT + y, checkerSize, checkerSize);
      }
    }
  }
}
