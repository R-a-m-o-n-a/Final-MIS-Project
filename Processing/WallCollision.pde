public class WallCollision {
  int row;
  int timeout;
  int impactTime;
  
  WallCollision(int row, int timeout) {
    this.impactTime = millis();
    this.row = row;
    this.timeout = timeout;
  }
  
  public boolean isOver() { // the timeout is over, the ball can move again
    return impactTime + timeout <= millis();
  }
  
  public float getTimeoutPercentage() { // which percentage of the waiting time has passed?
    return (millis() - impactTime) /  (float) timeout;
  }
  
  public int getRow() {
    return row;
  }
}
