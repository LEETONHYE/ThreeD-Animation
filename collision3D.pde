int numBalls = 50;
Ball[] balls = new Ball[numBalls];

int segments = 40;
Ground[] ground = new Ground[segments];


void setup(){
  size(1020, 580,P3D);
  
  for (int i = 0; i< numBalls; i++){
    balls[i] = new Ball(random(width), random(height), random(10,50), i, balls, numBalls);
  }
  
  // Calculate ground peak heights 
  float[] peakHeights = new float[segments+1];
  float[] peakHeights2 = new float[segments+1];
  for (int i=0; i<peakHeights.length; i++){
    peakHeights[i] = random(height-50, height-25);
    peakHeights2[i]=random(10, 50);
  }
  
  // create segments for the ground
  float segs = segments;
  for (int i=0; i<segments; i++){
    ground[i]  = new Ground(width/segs*i, peakHeights[i],peakHeights2[i], width/segs*(i+1), peakHeights[i+1],peakHeights2[i+1]);
  }
}

void draw(){
  background(51);

  for (Ball ball:balls){
      ball.checkBoundaryCollision();
      ball.checkCollision();
      for (int i=0; i<segments; i++){
        ball.checkGroundCollision(ground[i]);
      }
      ball.update();
      ball.display();
  }
  
  // Draw ground
  fill(127);
  beginShape();
  for (int i=0; i<segments; i++){
    vertex(ground[i].x1, ground[i].y1,ground[i].z1);
    vertex(ground[i].x2, ground[i].y2,ground[i].z2);
  }
  vertex(ground[segments-1].x2, height,ground[segments-1].z2);
  vertex(ground[0].x1, height,ground[0].z1);
  textSize(18);
  endShape(CLOSE);
  
   fill(0, 102, 153);
  text("Tenghai Li", width-300, height-50);
  text("8586933", width-200, height-50);
  
}

class Ball{
  PVector position;
  PVector velocity;
  float radius;
  float damping = 0.8;
  float m;
  int id;
  int numBalls;
  Ball[] others;
  
  Ball(float x_, float y_, float r_, int idin, Ball[] othersin, int numBallsIn){
    position = new PVector(x_, y_);
    velocity = PVector.random2D();
    velocity.mult(5);
    radius = r_;
    m = radius*0.1;
    id = idin;
    others = othersin;
    numBalls = numBallsIn;
  }
  
  void update(){
    //velocity.y+=0.03;
    position.add(velocity);
  }
  
  void checkBoundaryCollision(){
     if (position.x>width-radius){
       position.x=width-radius;
       velocity.x *= -1;
     } else if (position.x < radius){
       position.x = radius;
       velocity.x *= -1;
     } else if (position.y > height-radius){
       position.y = height-radius;
       velocity.y *= -1;
     } else if (position.y < radius){
       position.y = radius;
       velocity.y *= -1;
     }
  }
  
  void checkCollision(){
    for (int i = id + 1; i < numBalls; i++){
         
      // get the distance vector between current ball and balls to be compared
      PVector distanceVect = PVector.sub(others[i].position, position);
      
      // calculate magnitude of the vector separating the balls
      float distanceVectMag = distanceVect.mag();
      
      // Minimum distance before they are touching
      float minDistance = radius + others[i].radius;
      
      if (distanceVectMag < minDistance){
         float distanceCorrection = (minDistance - distanceVectMag)/2.0;
         PVector d = distanceVect.copy();
         PVector correctionVector = d.normalize().mult(distanceCorrection);
         others[i].position.add(correctionVector);
         position.sub(correctionVector);
         
         // get angle of distanceVect
         float theta = distanceVect.heading();
         
         //precalculate trig values
         float sine = sin(theta);
         float cosine = cos(theta);
         
         
         PVector[] bTemp = {
           new PVector(), new PVector()
         };
         
         bTemp[1].x = cosine*distanceVect.x+sine*distanceVect.y;
         bTemp[1].y = cosine*distanceVect.y-sine*distanceVect.x;
         
         PVector[] vTemp = {
           new PVector(), new PVector()
         };
         
         vTemp[0].x = cosine*velocity.x + sine*velocity.y;
         vTemp[0].y = cosine*velocity.y - sine*velocity.x;
         vTemp[1].x = cosine*others[i].velocity.x+sine*others[i].velocity.y;
         vTemp[1].y = cosine*others[i].velocity.y-sine*others[i].velocity.x;
         
         PVector[] vFinal = {  
            new PVector(), new PVector()
         };
         
         vFinal[0].x = ((m - others[i].m) * vTemp[0].x + 2 * others[i].m * vTemp[1].x) / (m + others[i].m);
         vFinal[0].y = vTemp[0].y;
         
         // final rotated velocity for b[0]
         vFinal[1].x = ((others[i].m - m) * vTemp[1].x + 2 * m * vTemp[0].x) / (m + others[i].m);
         vFinal[1].y = vTemp[1].y;
         
         // hack to avoid clumping
         bTemp[0].x += vFinal[0].x;
         bTemp[1].x += vFinal[1].x;
         
         PVector[] bFinal = {
             new PVector(), new PVector()
         };
         
         bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
         bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
         bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
         bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

         // update balls to screen position
         //others[i].position.x = position.x + bFinal[1].x;
         //others[i].position.y = position.y + bFinal[1].y;       
         //position.add(bFinal[0]);
         
         // update velocities
         velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
         velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
         others[i].velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
         others[i].velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
       }
    }      
  }
  
  void checkGroundCollision(Ground groundSegment) {

    // calculate difference between ball and ground
    float deltaX = position.x - groundSegment.x;
    float deltaY = position.y - groundSegment.y;

    // Precalculate trig values
    float cosine = cos(groundSegment.rot);
    float sine = sin(groundSegment.rot);

    //orthogonal collision calculation
    float groundXTemp = cosine * deltaX + sine * deltaY;
    float groundYTemp = cosine * deltaY - sine * deltaX;
    float velocityXTemp = cosine * velocity.x + sine * velocity.y;
    float velocityYTemp = cosine * velocity.y - sine * velocity.x;

    // check collision against the ground 
    if (groundYTemp > -radius &&
      position.x > groundSegment.x1 &&
      position.x < groundSegment.x2 ) {
      groundYTemp = -radius;
      velocityYTemp *= -1.0;
      velocityYTemp *= damping;
    }

    // Reset ground
    deltaX = cosine * groundXTemp - sine * groundYTemp;
    deltaY = cosine * groundYTemp + sine * groundXTemp;
    velocity.x = cosine * velocityXTemp - sine * velocityYTemp;
    velocity.y = cosine * velocityYTemp + sine * velocityXTemp;
    position.x = groundSegment.x + deltaX;
    position.y = groundSegment.y + deltaY;
  }
  
  void display(){
    pushMatrix();
    noStroke();
    lights();
    translate(position.x, position.y, 0);
    sphere(radius);
    popMatrix();
  }
}

class Ground {
  float x1, y1,z1, x2, y2,z2;
  float x, y,z, len, rot;
  
  Ground(float x1, float y1,float z1, float x2, float y2,float z2) {
    this.x1 = x1;
    this.y1 = y1;
    this.z1 = z1;
    this.x2 = x2;
    this.y2 = y2;
    this.z2 = z2;
    x = (x1+x2)/2;
    y = (y1+y2)/2;
    z =(z1+z2)/2;
    len = dist(x1, y1, x2, y2);
    rot = atan2((y2-y1), (x2-x1));
  }
}