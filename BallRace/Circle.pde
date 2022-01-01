public class Circle {
  int lane = 2;
  int laneWidth;
  int laneHeight;
  int noOfLanes;
  int ballSize;

  public Circle(int noOfLanes, int trackWidth, int laneHeight, int circleSpacing) {
    laneWidth = trackWidth / noOfLanes;
    ballSize = laneHeight - circleSpacing * 2;
    this.noOfLanes = noOfLanes;
    this.laneHeight = laneHeight;
  }

  public boolean move(int step) {// returns whether ball is on gravel
    if (lane + step >= 0 && lane + step < noOfLanes) lane += step;
    return lane == 0 || lane == noOfLanes - 1;
  }

  public void draw() {
    int balancedLane = lane - 2;
    int xPos = width / 2 + laneWidth / 2 + balancedLane * laneWidth;
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
