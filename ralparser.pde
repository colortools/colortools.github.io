import java.util.*;
import processing.pdf.*;          // Import PDF code

RalColor[] colors;
Table table;

boolean makeApp = true; 

PFont lightFont;
PFont boldFont;
PFont smallFont;
PFont smallFontStrong;

PGraphicsPDF pdf = null;
int appWidth = 595; // A4
int appHeight = (int) (appWidth * sqrt(2));
String resultFile = "colors";
color textColor = color(10, 10, 10);
int pagePadding = 25;
int squareSize = 80;
int squareGap = 12;

String colorText = "";
List<RalColor> candidates = new ArrayList<RalColor>();

void settings() {  
  if(makeApp) {
    appWidth = appWidth * 2;
    appHeight = appWidth;
    squareSize = squareSize * 2;
    pagePadding = 50;
    size(appWidth, appHeight);
  } else {
    size(appWidth, appHeight, PDF, resultFile + ".pdf");
  }
}

void setup() {
  if(makeApp) {
    smallFont = createFont("fonts/OpenSans-Light.ttf", 12);
    smallFontStrong = createFont("fonts/OpenSans-Regular.ttf", 12);
    lightFont = createFont("fonts/OpenSans-Regular.ttf", 18);
    boldFont = createFont("fonts/OpenSans-Bold.ttf", 24);
  } else {
    noLoop();
  
    smallFont = createFont("fonts/OpenSans-Light.ttf", 7);
    smallFontStrong = createFont("fonts/OpenSans-Regular.ttf", 7);
    lightFont = createFont("fonts/OpenSans-Regular.ttf", 12);
    boldFont = createFont("fonts/OpenSans-Bold.ttf", 21);
  }
  
  loadData();
}

void draw() {
  if(makeApp) {
    background(10);
    fill(255);
    textAlign(LEFT);
    textFont(boldFont);
    text("RAL MATCHING", pagePadding, 30);
    textFont(lightFont);
    text("#" + colorText, pagePadding, 70);
    
    if(colorText.length() == 6) {
      fill(unhex("FF" + colorText));
      rect(pagePadding + squareSize - 30, 50, 30, 30);
    }
    
    int startX = pagePadding;
    int startY = 95;
    
    for (RalColor c : candidates) {
      noStroke();
      fill(unhex("FF" + c.rgb));
      rect(startX, startY, squareSize, squareSize);
      
      textAlign(CENTER);
      if(c.dark) {
        fill(0);
      } else {
        fill(255);
      }
      textFont(smallFontStrong);
      text(c.nameDE, startX + (squareSize / 2), startY + (squareSize / 2) - 16);
      textFont(smallFont);
      text("RGB  #" + c.rgb, startX + (squareSize / 2), startY + (squareSize / 2));
      text("CMYK  " + c.cmyk, startX + (squareSize / 2), startY + (squareSize / 2) + 16);
      text("Similarity  " + c.rank, startX + (squareSize / 2), startY + (squareSize / 2) + 32);
      
      startX += squareSize + squareGap;
      if(startX + squareSize > (appWidth - pagePadding)) {
        startY += squareSize + squareGap;
        startX = pagePadding;
      }
      if(startY + squareSize > (appHeight - pagePadding)) {
        break;
      }
    }
  } else {
    pdf = (PGraphicsPDF) g;
    pdf.beginDraw();
    
    pdf.background(255);
    
    pdf.fill(textColor);
    pdf.textFont(boldFont);
    pdf.text("RAL FARBEN", pagePadding, 35);
    
    // Display colors
    int startX = pagePadding;
    int startY = 95;
    String currentRange = colors[0].range;
    pdf.textFont(lightFont);
    pdf.text(currentRange, pagePadding, 75);
    for (RalColor c : colors) {
      if(!currentRange.equals(c.range)) {
        currentRange = c.range;
        pdf.nextPage();
        startX = pagePadding;
        startY = 55;
        pdf.fill(0);
        pdf.textAlign(LEFT);
        pdf.textFont(lightFont);
            pdf.text(currentRange, pagePadding, 35);
      }
  
      pdf.noStroke();
      pdf.fill(unhex("FF" + c.rgb));
      pdf.rect(startX, startY, squareSize, squareSize);
      
      pdf.textAlign(CENTER);
      if(c.dark) {
        fill(0);
      } else {
        fill(255);
      }
      pdf.textFont(smallFontStrong);
      pdf.text(c.nameDE, startX + (squareSize / 2), startY + (squareSize / 2) - 8);
      pdf.textFont(smallFont);
      pdf.text("RGB  #" + c.rgb, startX + (squareSize / 2), startY + (squareSize / 2));
      pdf.text("CMYK  " + c.cmyk, startX + (squareSize / 2), startY + (squareSize / 2) + 8);
      
      startX += squareSize + squareGap;
      if(startX + squareSize > (appWidth - pagePadding)) {
        startY += squareSize + squareGap;
        startX = pagePadding;
      }
      if(startY + squareSize > (appHeight - pagePadding)) {
        pdf.nextPage();
        startX = pagePadding;
        startY = 20;
      }
    }
    
    // cleanup and exit
    pdf.dispose();
    pdf.endDraw();
  
    exit();
  }
}

void keyPressed() {
  if (key==CODED) {
    if (keyCode==LEFT) {
      println ("left");
    }
    else {
      // message
      println ("unknown special key");
    }
  }
  else
  {
    if (key==BACKSPACE) {
      if (colorText.length()>0) {
        colorText=colorText.substring(0, colorText.length()-1);
      }
    }
    else if (colorText.length() < 6) {
      if ((key >= 'a' && key <= 'f') || (key >= '0' && key <= '9'))
        colorText+=key;
        if(colorText.length() == 6) findMatches();
    }
  }
}

void findMatches() {
  candidates = new ArrayList<RalColor>();
  
  for (RalColor c : colors) {
    int diff = c.difference(colorText);
    if(diff < 80) {
      c.rank = diff;
      candidates.add(c);
    }
  }
  
  Collections.sort(candidates);
  
  while (candidates.size() > 30) {
    candidates.remove(candidates.size() - 1);
  }

  //for (RalColor col : candidates) {
  //  println(col.nameDE + " " + col.rank);
  //}
}

void loadData() {
  // Load CSV file into a Table object
  // "header" option indicates the file has a header row
  table = loadTable("colors.csv", "header");

  // The size of the array of Bubble objects is determined by the total number of rows in the CSV
  colors = new RalColor[table.getRowCount()]; 

  // You can access iterate over all the rows in a table
  int rowCount = 0;
  for (TableRow row : table.rows()) {
    // You can access the fields via their column name (or index)    
    String rgb = row.getString("rgb");
    String cmyk = row.getString("cmyk");
    String url = row.getString("url");
    boolean dark = row.getInt("dark") == 1;
    String ral = row.getString("ral");
    String nameDE = row.getString("nameDE");
    String nameEN = row.getString("nameEN");
    String range = row.getString("range");
    // Make a RalColor object out of the data read
    colors[rowCount] = new RalColor(rgb, cmyk, url, dark, ral, nameDE, nameEN, range);
    rowCount++;
  }
}
