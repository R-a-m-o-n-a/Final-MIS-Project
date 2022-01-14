public class WallCollision {
  int row;
  int timeout;
  int impactTime;
  
  WallCollision(int row, int timeout) {
   this.impactTime = millis() - startTime;
   this.row = row;
   this.timeout = timeout;
  }
  
  public boolean isOver() { // the timeout is over, the ball can move again
    return impactTime+timeout <= millis()-startTime;
  }
  
  public float getTimeoutPercentage() { // which percentage of the waiting time has passed?
    return (millis() - impactTime - startTime) /  (float) timeout;
  }
  
  public int getRow() {
    return row;
  }
}
