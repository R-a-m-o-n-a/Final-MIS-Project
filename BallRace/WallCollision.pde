public class WallCollision {
  int trackField;
  int timeout;
  int impactTime;
  
  WallCollision(int trackField, int timeout) {
   this.impactTime = millis() - startTime;
   this.trackField = trackField;
   this.timeout = timeout;
  }
  
  public boolean isOver() {
    return impactTime+timeout <= millis()-startTime;
  }
  
  public float getTimeoutPercentage() {
    return (millis() - impactTime) /  (float) timeout;
  }
  
  public int getTrackField() {
    return trackField;
  }
}
