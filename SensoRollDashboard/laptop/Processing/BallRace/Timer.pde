public class Timer {
  int total;
  int lastStart;
  boolean running;
  
  public Timer() {
    total = 0;
    running = false;
  }
  
  public void start() {
    if (!running) {
      lastStart = millis();
      running = true;
    } else {
      println("Timer already running");
    }
  }
  
  public void stop() {
    if(running) {
      total += millis() - lastStart;
    }
    running = false;
  }
  
  public int getTotal() { return total; }
}
  
