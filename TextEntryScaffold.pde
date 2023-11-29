import java.util.Arrays;
import java.util.Collections;
import java.util.Random;
import java.lang.Math;

String[] phrases; //contains all of the phrases
int totalTrialNum = 2; //the total number of phrases to be tested - set this low for testing. Might be ~10 for the real bakeoff!
int currTrialNum = 0; // the current trial number (indexes into trials array above)
float startTime = 0; // time starts when the first letter is entered
float finishTime = 0; // records the time of when the final trial ends
float lastTime = 0; //the timestamp of when the last trial was completed
float lettersEnteredTotal = 0; //a running total of the number of letters the user has entered (need this for final WPM computation)
float lettersExpectedTotal = 0; //a running total of the number of letters expected (correct phrases)
float errorsTotal = 0; //a running total of the number of errors (when hitting next)
String currentPhrase = ""; //the current target phrase
String currentTyped = ""; //what the user has typed so far
final int DPIofYourDeviceScreen = 120; //you will need to look up the DPI or PPI of your device to make sure you get the right scale. Or play around with this value.
final float sizeOfInputArea = DPIofYourDeviceScreen*1; //aka, 1.0 inches square!
PImage watch;
PImage finger;

// For tracking currently selected menu
enum Menu {
  MAIN,
  CONTEXT1,
  CONTEXT2,
  CONTEXT3,
  CONTEXT4
}

Menu currentMenu = Menu.MAIN;

// Button drawing/mapping information
ArrayList<PVector> fourRadialPoints;
ArrayList<PVector> sixRadialPoints;
ArrayList<PVector> sevenRadialPoints;
HashMap<Menu, ArrayList<PVector>> radialPointsMap = new HashMap<Menu, ArrayList<PVector>>();

// Display drawing values
int menuStrokeWeight = 4;
float centerButtonDiameter = sizeOfInputArea/3.5;

//You can modify anything in here. This is just a basic implementation.
void setup()
{
  //noCursor();
  watch = loadImage("watchhand3smaller.png");
  //finger = loadImage("pngeggSmaller.png"); //not using this
  phrases = loadStrings("phrases2.txt"); //load the phrase set into memory
  Collections.shuffle(Arrays.asList(phrases), new Random()); //randomize the order of the phrases with no seed
  //Collections.shuffle(Arrays.asList(phrases), new Random(100)); //randomize the order of the phrases with seed 100; same order every time, useful for testing
 
  orientation(LANDSCAPE); //can also be PORTRAIT - sets orientation on android device
  size(800, 800); //Sets the size of the app. You should modify this to your device's native size. Many phones today are 1080 wide by 1920 tall.
  textFont(createFont("Arial", 20)); //set the font to arial 24. Creating fonts is expensive, so make difference sizes once in setup, not draw
  noStroke(); //my code doesn't use any strokes
  
  fourRadialPoints = generateRadialPoints(4);
  sixRadialPoints = generateRadialPoints(6);
  sevenRadialPoints = generateRadialPoints(7);
  
  radialPointsMap.put(Menu.MAIN, fourRadialPoints);
  radialPointsMap.put(Menu.CONTEXT1, sevenRadialPoints);
  radialPointsMap.put(Menu.CONTEXT2, sixRadialPoints);
  radialPointsMap.put(Menu.CONTEXT3, sevenRadialPoints);
  radialPointsMap.put(Menu.CONTEXT4, sixRadialPoints);
}

//You can modify anything in here. This is just a basic implementation.
void draw()
{
  background(255); //clear background
  
   //check to see if the user finished. You can't change the score computation.
  if (finishTime!=0)
  {
    fill(0);
    textAlign(CENTER);
    text("Trials complete!",400,200); //output
    text("Total time taken: " + (finishTime - startTime),400,220); //output
    text("Total letters entered: " + lettersEnteredTotal,400,240); //output
    text("Total letters expected: " + lettersExpectedTotal,400,260); //output
    text("Total errors entered: " + errorsTotal,400,280); //output
    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    text("Raw WPM: " + wpm,400,300); //output
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    text("Freebie errors: " + nf(freebieErrors,1,3),400,320); //output
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    text("Penalty: " + penalty,400,340);
    text("WPM w/ penalty: " + (wpm-penalty),400,360); //yes, minus, because higher WPM is better
    return;
  }
  
  drawWatch(); //draw watch background
  fill(100);
  rect(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea); //input area should be 1" by 1"
  

  if (startTime==0 & !mousePressed)
  {
    fill(128);
    textAlign(CENTER);
    text("Click to start time!", 280, 150); //display this messsage until the user clicks!
  }

  if (startTime==0 & mousePressed)
  {
    nextTrial(); //start the trials!
  }

  if (startTime!=0)
  {
    //feel free to change the size and position of the target/entered phrases and next button 
    textAlign(LEFT); //align the text left
    fill(128);
    text("Phrase " + (currTrialNum+1) + " of " + totalTrialNum, 70, 50); //draw the trial count
    fill(128);
    text("Target:   " + currentPhrase, 70, 100); //draw the target string
    text("Entered:  " + currentTyped +"|", 70, 140); //draw what the user has entered thus far 

    //draw very basic next button
    fill(255, 0, 0);
    rect(600, 600, 200, 200); //draw next button
    fill(255);
    text("NEXT > ", 650, 650); //draw next label

    //example design draw code
    drawContextMenu();
  }
 
 
  //drawFinger(); //no longer needed as we'll be deploying to an actual touschreen device
}

void drawContextMenu() {
  pushStyle();
  
  drawRadialLines(radialPointsMap.get(currentMenu));
  
  // Center circle button
  stroke(0);
  strokeWeight(menuStrokeWeight);
  fill(100);
  circle(width/2, height/2, centerButtonDiameter); //draw left red button
  
  popStyle();
}

void drawRadialLines(ArrayList<PVector> radialPoints) {
  pushStyle();
  stroke(0);
  strokeWeight(menuStrokeWeight);
  
  for (PVector point : radialPoints) {
    line(width/2, height/2, point.x, point.y);
  }
  
  popStyle();
}

// Generates a given amount of evenly spaced radial x, y points around the edge of the input area
ArrayList<PVector> generateRadialPoints(int numOfPoints) {
  
  ArrayList<PVector> radialPoints = new ArrayList<PVector>();
  float radius = sizeOfInputArea/2;
  float startAngle = PI/numOfPoints;
  
  for (int i = 0; i < numOfPoints; i++) {
    
    float angle = map(i, 0, numOfPoints, -PI/2, PI * 3/2) + startAngle;
    
    // Calculate x positions around a circle with radius / the width of the size of input area
    float x = cos(angle) * radius;
    float y = sin(angle) * radius;
    
    // Adjust x and y position to reach to edge of input area
    if (angle >= -PI/4 && angle <= PI/4) { // right side points
      float newX = radius;
      float scaleFactor = newX/x;
      x = newX;
      y = y * scaleFactor;
    }
    else if (angle >= PI/4 && angle <= PI * 3/4) { // bottom points
      float newY = radius;
      float scaleFactor = newY/y;
      x = x * scaleFactor;
      y = newY;
    }
    else if (angle >= PI * 3/4 && angle <= PI * 5/4) { // left points
      float newX = -radius;
      float scaleFactor = newX/x;
      x = newX;
      y = y * scaleFactor;
    }
    else { // top points
      float newY = -radius;
      float scaleFactor = newY/y;
      x = x * scaleFactor;
      y = newY;
    }
    
    // Adjust x and y positions to go from center of screen
    x += width/2;
    y += height/2;
    
    radialPoints.add(new PVector(x, y));
  }
  
  return radialPoints;
}

boolean didMouseClick(float x, float y, float w, float h) //simple function to do hit testing
{
  return (mouseX > x && mouseX < x+w && mouseY > y && mouseY < y+h); //check to see if it is in button bounds
}

//my terrible implementation you can entirely replace
void mousePressed()
{
  if (startTime == 0) return;
  
  // Click is in watch input area
  if (didMouseClick(width/2-sizeOfInputArea/2, height/2-sizeOfInputArea/2, sizeOfInputArea, sizeOfInputArea)) //check if click in left button
  {  
    // Click is in center button
    if (clickInCircle(width/2, height/2, centerButtonDiameter/2)) {
      println("Center button clicked");
      currentMenu = Menu.MAIN;
    }
    // Click is in one of the radial buttons
    else {
      int buttonClicked = getRadialButtonClicked();
      switch (currentMenu) {
        case MAIN:
          switch (buttonClicked) {
            case 0:
              currentMenu = Menu.CONTEXT1;
              break;
            case 1:
              currentMenu = Menu.CONTEXT2;
              break;
            case 2:
              currentMenu = Menu.CONTEXT3;
              break;
            case 3:
              currentMenu = Menu.CONTEXT4;
              break;
          }
          break;
        default:
          println("Button clicked: " + buttonClicked);
      }
    }
  }

  //You are allowed to have a next button outside the 1" area
  if (didMouseClick(600, 600, 200, 200)) //check if click is in next button
  {
    nextTrial(); //if so, advance to next trial
  }
}

boolean clickInCircle(float circleCenterX, float circleCenterY, float circleRadius) {
  return Math.sqrt(Math.pow(mouseX - circleCenterX, 2) + Math.pow(mouseY - circleCenterY, 2)) <= circleRadius;
}

// Returns the button clicked. 0 represents the top button, then num returned increases clockwise
int getRadialButtonClicked() {
  ArrayList<PVector> radialPoints = radialPointsMap.get(currentMenu);
  for (int i = 0; i < radialPoints.size() - 1; i++) {
    if (pointInTriangle(new PVector(mouseX, mouseY), new PVector(width/2, height/2), radialPoints.get(i), radialPoints.get(i + 1))) {
      return (i + 1) % radialPoints.size();
    }
  }
  // If button clicked was none of the others, it must be the last
  return 0;
}

void nextTrial()
{
  if (currTrialNum >= totalTrialNum) //check to see if experiment is done
    return; //if so, just return

  if (startTime!=0 && finishTime==0) //in the middle of trials
  {
    System.out.println("==================");
    System.out.println("Phrase " + (currTrialNum+1) + " of " + totalTrialNum); //output
    System.out.println("Target phrase: " + currentPhrase); //output
    System.out.println("Phrase length: " + currentPhrase.length()); //output
    System.out.println("User typed: " + currentTyped); //output
    System.out.println("User typed length: " + currentTyped.length()); //output
    System.out.println("Number of errors: " + computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim())); //trim whitespace and compute errors
    System.out.println("Time taken on this trial: " + (millis()-lastTime)); //output
    System.out.println("Time taken since beginning: " + (millis()-startTime)); //output
    System.out.println("==================");
    lettersExpectedTotal+=currentPhrase.trim().length();
    lettersEnteredTotal+=currentTyped.trim().length();
    errorsTotal+=computeLevenshteinDistance(currentTyped.trim(), currentPhrase.trim());
  }

  //probably shouldn't need to modify any of this output / penalty code.
  if (currTrialNum == totalTrialNum-1) //check to see if experiment just finished
  {
    finishTime = millis();
    System.out.println("==================");
    System.out.println("Trials complete!"); //output
    System.out.println("Total time taken: " + (finishTime - startTime)); //output
    System.out.println("Total letters entered: " + lettersEnteredTotal); //output
    System.out.println("Total letters expected: " + lettersExpectedTotal); //output
    System.out.println("Total errors entered: " + errorsTotal); //output

    float wpm = (lettersEnteredTotal/5.0f)/((finishTime - startTime)/60000f); //FYI - 60K is number of milliseconds in minute
    float freebieErrors = lettersExpectedTotal*.05; //no penalty if errors are under 5% of chars
    float penalty = max(errorsTotal-freebieErrors, 0) * .5f;
    
    System.out.println("Raw WPM: " + wpm); //output
    System.out.println("Freebie errors: " + freebieErrors); //output
    System.out.println("Penalty: " + penalty);
    System.out.println("WPM w/ penalty: " + (wpm-penalty)); //yes, minus, becuase higher WPM is better
    System.out.println("==================");

    currTrialNum++; //increment by one so this mesage only appears once when all trials are done
    return;
  }

  if (startTime==0) //first trial starting now
  {
    System.out.println("Trials beginning! Starting timer..."); //output we're done
    startTime = millis(); //start the timer!
  } 
  else
    currTrialNum++; //increment trial number

  lastTime = millis(); //record the time of when this trial ended
  currentTyped = ""; //clear what is currently typed preparing for next trial
  currentPhrase = phrases[currTrialNum]; // load the next phrase!
  //currentPhrase = "abc"; // uncomment this to override the test phrase (useful for debugging)
}

//probably shouldn't touch this - should be same for all teams.
void drawWatch()
{
  float watchscale = DPIofYourDeviceScreen/138.0; //normalizes the image size
  pushMatrix();
  translate(width/2, height/2);
  scale(watchscale);
  imageMode(CENTER);
  image(watch, 0, 0);
  popMatrix();
}

//probably shouldn't touch this - should be same for all teams.
void drawFinger()
{
  float fingerscale = DPIofYourDeviceScreen/150f; //normalizes the image size
  pushMatrix();
  translate(mouseX, mouseY);
  scale(fingerscale);
  imageMode(CENTER);
  image(finger,52,341);
  if (mousePressed)
     fill(0);
  else
     fill(255);
  ellipse(0,0,5,5);

  popMatrix();
}
  

//=========SHOULD NOT NEED TO TOUCH THIS METHOD AT ALL!==============
int computeLevenshteinDistance(String phrase1, String phrase2) //this computers error between two strings
{
  int[][] distance = new int[phrase1.length() + 1][phrase2.length() + 1];

  for (int i = 0; i <= phrase1.length(); i++)
    distance[i][0] = i;
  for (int j = 1; j <= phrase2.length(); j++)
    distance[0][j] = j;

  for (int i = 1; i <= phrase1.length(); i++)
    for (int j = 1; j <= phrase2.length(); j++)
      distance[i][j] = min(min(distance[i - 1][j] + 1, distance[i][j - 1] + 1), distance[i - 1][j - 1] + ((phrase1.charAt(i - 1) == phrase2.charAt(j - 1)) ? 0 : 1));

  return distance[phrase1.length()][phrase2.length()];
}

// The following methods are used to check if a point occurs inside a triangle
// based on the SameSide technique as explained by blackpawn.com: 
// https://blackpawn.com/texts/pointinpoly/#:~:text=Same%20Side%20Technique,but%20it%20is%20very%20slow

// Measures that two points are on the same side of a line ab
boolean sameSide(PVector p1, PVector p2, PVector a, PVector b) {
  PVector bSubA = new PVector(b.x - a.x, b.y - a.y);
  PVector p1SubA = new PVector(p1.x - a.x, p1.y - a.y);
  PVector p2SubA = new PVector(p2.x - a.x, p2.y - a.y);

  // Get cross products
  float cp1 = bSubA.x * p1SubA.y - bSubA.y * p1SubA.x;
  float cp2 = bSubA.x * p2SubA.y - bSubA.y * p2SubA.x;

  // Return dot product >= 0
  return cp1 * cp2 >= 0;
}

// Checks if given point is inside 3 given points of triangle
boolean pointInTriangle(PVector clickPoint, PVector pointA, PVector pointB, PVector pointC) {
  return sameSide(clickPoint, pointA, pointB, pointC) 
         && sameSide(clickPoint, pointB, pointA, pointC) 
         && sameSide(clickPoint, pointC, pointA, pointB);
}
