float STANDARD_OFFSET_RECOVERY_RATE = 0.9;
float GRAVEL_OFFSET_RECOVERY_RATE = 0.96;

public class Circle {
  int lane = 2;
  int laneWidth;
  int laneHeight;
  int noOfLanes;
  int ballSize;
  int changingLaneOffset;
  float offsetRecoveryRate;
  boolean frameRateResetTimeout = false;

  public Circle(int noOfLanes, int trackWidth, int laneHeight, int circleSpacing) {
    laneWidth = trackWidth / noOfLanes;
    ballSize = laneHeight - circleSpacing * 2;
    this.noOfLanes = noOfLanes;
    this.laneHeight = laneHeight;
  }

  public boolean move(int dir, boolean wouldCauseCollision) {// returns whether ball is on gravel
    boolean ballWasOnGravel = lane==0 || lane == noOfLanes-1;
    if (lane + dir >= 0 && lane + dir < noOfLanes && !wouldCauseCollision) {
      
      if(ballWasOnGravel) {
        offsetRecoveryRate = GRAVEL_OFFSET_RECOVERY_RATE;
      } else {
        offsetRecoveryRate = STANDARD_OFFSET_RECOVERY_RATE;
      }
      
      lane += dir;
      changingLaneOffset = laneWidth * dir * (-1);
    }
    boolean isBallOnGravel =  lane == 0 || lane == noOfLanes - 1;
    if(isBallOnGravel) {
      frameRate(20);
    } else if (ballWasOnGravel) {
      frameRateResetTimeout = true;
    } else {
      frameRate(60);
    }
    return isBallOnGravel;
  }

  public void draw() {
    int balancedLane = lane - 2;
    int xPos = width / 2 + laneWidth / 2 + balancedLane * laneWidth + changingLaneOffset;
  
    if(frameRateResetTimeout && abs(changingLaneOffset) < laneWidth/2) { // when back on normal track change back to normal speed
      if(frameRate < 60) {
        frameRate(frameRate++);
      } else {
        frameRateResetTimeout = false;
      }
    }
    if(abs(changingLaneOffset) > 0) changingLaneOffset*=offsetRecoveryRate;
    if(abs(changingLaneOffset) < 2) changingLaneOffset = 0;
    fill(color(255, 255, 255));
    ellipse(xPos, height - laneHeight, ballSize, ballSize);
  }

  public int getLane() {
    return lane;
  }

  public int getTopY() {
    return height - laneHeight - ballSize;
  }
}
