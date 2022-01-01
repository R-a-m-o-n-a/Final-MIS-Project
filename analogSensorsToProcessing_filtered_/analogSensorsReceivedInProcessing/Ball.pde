void Ball(int sensor1) {  
  fill(255);
  int sensor1_Scaled = int (map (sensor1, 0, 1023, 0, width)) ;
  ellipse(sensor1_Scaled, ypos, 100, 100);
  

}
