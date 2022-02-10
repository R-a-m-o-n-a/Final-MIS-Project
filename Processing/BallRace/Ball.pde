color BALL_COLOR = color(255, 255, 255);

// constants for gradually changing lanes
float STANDARD_OFFSET_RECOVERY_RATE = 0.9;
float GRAVEL_OFFSET_RECOVERY_RATE = 0.96;

public class Ball {
  int lane = 1; // which lane to start on
  int laneWidth;
  int laneHeight;
  int noOfLanes;
  int ballSize; // current diameter of the ball
  int originalBallSize; // diameter of the ball - saved in case we change the ball size (for jumping for example)
  int changingLaneOffset; // this value regulates gradually chaging lanes, it is added to the xPos in draw and adjusted so that it becomes 0 again after the change is finished
  float offsetRecoveryRate; // determines how fast the changingLaneOffset shrinks. Differs if ball has been on gravel or not
  boolean isSpeedingUp = false;
  boolean isSlowingDown = false;

  // constructor. sets all the important values that are passed over from the track class
  public Ball(int noOfLanes, int trackWidth, int laneHeight, int ballSpacing) {
    laneWidth = trackWidth / noOfLanes;
    ballSize = laneHeight - ballSpacing * 2;
    originalBallSize = ballSize;
    this.noOfLanes = noOfLanes;
    this.laneHeight = laneHeight;
  }

  public void move(int dir, boolean wouldCauseCollision) {
    boolean wasBallOnGravel = (lane==0 || lane == noOfLanes-1);

    /* change is allowed when
     *ball does not go off track with this change &&   not next to wall   &&  not already changing lane  &&   not currently jumping       */
    if (lane + dir >= 0 && lane + dir < noOfLanes && !wouldCauseCollision && abs(changingLaneOffset) < 10 && ballSize == originalBallSize) {
      if (wasBallOnGravel) {
        offsetRecoveryRate = GRAVEL_OFFSET_RECOVERY_RATE;
      } else {
        offsetRecoveryRate = STANDARD_OFFSET_RECOVERY_RATE;
      }

      lane += dir; // actually change lane
      sendOscMessage("/laneChanged", lane); // notify PD of lane change
      changingLaneOffset = laneWidth * dir * (-1); // start the offset for the gradual lane change
    } else {
      sendOscMessage("/changeLaneProhibited", 1);
      println("PROHIBITED!");
    }

    boolean isBallOnGravel = (lane == 0 || lane == noOfLanes - 1);

    if (isBallOnGravel && !wasBallOnGravel) {
      gravelTimer.start();
    } 
    if (wasBallOnGravel && !isBallOnGravel) {
      gravelTimer.stop();
    }

    isSlowingDown = isBallOnGravel; // slow game down if ball is on gravel
    isSpeedingUp = !isBallOnGravel && wasBallOnGravel; // start gradually going back to normal game speed if ball is moved away from gravel
    if (!isBallOnGravel && !wasBallOnGravel) frameRate(60); // normal speed
  }

  public void draw() {
    int balancedLane = lane - 2;
    /* horizontal ball position is calculated like this:
     * initially set to middle of screen
     *  → move half a lane to the right, so that ball is now placed centrally in the lane on the right of middle
     *  → move to correct lane by applying the previous balancedLane parameter
     *  → add the offset if ball is currently changing lane */
    int xPos = width / 2 + laneWidth / 2 + balancedLane * laneWidth + changingLaneOffset;

    if (isSpeedingUp && abs(changingLaneOffset) < laneWidth/2) { // when back on normal track change back to normal speed
      if (frameRate < 57) {
        frameRate(frameRate *= 1.08);
        sendOscMessage("/frameRateChanged", (int) frameRate); // tell PD the frameRate changed so that the speed of the ball can be represented in the sound
      } else {
        frameRate(60);
        isSpeedingUp = false; // speed transition is over, speed back to normal (60fps)
      }
    }

    if (isSlowingDown && abs(changingLaneOffset) < laneWidth/2) { // slow down when reaching gravel
      if (frameRate > 25) {
        frameRate(frameRate + (20 - frameRate) * 0.96);
        sendOscMessage("/frameRateChanged", (int) frameRate); // tell PD the frameRate changed so that the speed of the ball can be represented in the sound
      } else {
        isSlowingDown = false; // speed transition is over, speed back to normal (60fps)
      }
    }

    if (abs(changingLaneOffset) > 0) changingLaneOffset*=offsetRecoveryRate; // reduce the offset so that the ball gets closer to the lane it just changed to
    if (abs(changingLaneOffset) < 2) changingLaneOffset = 0; // if the offset gets small enough it is set to 0
    fill(BALL_COLOR); // set ball color
    ellipse(xPos, height - laneHeight, ballSize, ballSize); // draw the actual ball
  }

  public int getLane() { // return the lane the ball is currently on
    return lane;
  }

  public int getTopY() { // return the top-most y coordinate of the ball
    return height - laneHeight - ballSize;
  }

  public void setBallSize(float factor) {
    ballSize = round(originalBallSize * factor);
  }
}
