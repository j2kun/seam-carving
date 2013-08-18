PImage img, newImg;
float[][] gradientMagnitude;
float[][] seamFitness;

void setup() {
  int x = (int) random(400, 600);
  int y = (int) random(500, 600);

  println("x: " + x + " y: " + y);

  String url = "http://lorempixel.com/" + x + "/" + y;
  img = loadImage(url, "jpg");
  size(x, y);

  background(255);
  image(img, 0, 0);
}

float colorDistance(color c1, color c2) {
  float r = red(c1) - red(c2);
  float g = green(c1) - green(c2);
  float b = blue(c1) - blue(c2);
  return (r*r + g*g + b*b);
}

void computeGradient() {
  color left, right, above, below;
  int center;
  gradientMagnitude = new float[img.width][img.height];
  img.loadPixels();

  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      center = x + y*img.width;

      left = img.pixels[x == 0 ? center : (x-1) + y*img.width];
      right = img.pixels[x == img.width-1 ? center : (x+1) + y*img.width];
      above = img.pixels[y == 0 ? center : x + (y-1)*img.width];
      below = img.pixels[y == img.height - 1 ? center : x + (y+1)*img.width];

      gradientMagnitude[x][y] = colorDistance(left, right) + colorDistance(above, below);
    }
  }
}

void computeVerticalSeams() {
  seamFitness = new float[img.width][img.height];
  for (int i = 0; i < img.width; i++) {
    seamFitness[i][0] = gradientMagnitude[i][0];
  }

  for (int y = 1; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      seamFitness[x][y] = gradientMagnitude[x][y];

      if (x == 0) {
        seamFitness[x][y] += min(seamFitness[x][y-1], seamFitness[x+1][y-1]);
      } else if (x == img.width-1) {
        seamFitness[x][y] += min(seamFitness[x][y-1], seamFitness[x-1][y-1]);
      } else {
        seamFitness[x][y] += min(seamFitness[x-1][y-1], seamFitness[x][y-1], seamFitness[x+1][y-1]);
      }
    }
  }
}

void computeHorizontalSeams() {
  seamFitness = new float[img.width][img.height];
  for (int i = 0; i < img.height; i++) {
    seamFitness[0][i] = gradientMagnitude[0][i];
  }

  for (int x = 1; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      seamFitness[x][y] = gradientMagnitude[x][y];

      if (y == 0) {
        seamFitness[x][y] += min(seamFitness[x-1][y], seamFitness[x-1][y+1]);
      } else if (y == img.height-1) {
        seamFitness[x][y] += min(seamFitness[x-1][y-1], seamFitness[x-1][y]);
      } else {
        seamFitness[x][y] += min(seamFitness[x-1][y-1], seamFitness[x-1][y], seamFitness[x-1][y+1]);
      }
    }
  }
}

PImage removeVerticalSeams(int numAttempts) {
  computeGradient();
  computeVerticalSeams();
  
  newImg = createImage(img.width-numAttempts, img.height, RGB);
  newImg.loadPixels();

  for (int attempt = 0; attempt < numAttempts; attempt++) {
    int bestCol = 0;
    for (int i = 0; i < img.width-attempt; i++) {
      if (seamFitness[bestCol][img.height-1] > seamFitness[i][img.height-1]) {
        bestCol = i;
      }
    }
  
    for (int y = newImg.height-1; y >= 0; y--) {
      boolean pastBestCol = false;
  
      for (int x = 0; x < newImg.width; x++) {
        if (x == bestCol) {
          pastBestCol = true;
        }
  
        int newLoc = x + y*newImg.width;
        int oldLoc = (pastBestCol ? x+1 : x) + y*img.width;
  
        newImg.pixels[newLoc] = img.pixels[oldLoc];
      }
  
      if (y > 0) {
        // update best column for the next row
        float theMin = seamFitness[bestCol][y-1];
  
        if (bestCol > 0 && seamFitness[bestCol-1][y-1] <= theMin) {
          bestCol = bestCol - 1;
        } else if (bestCol < img.width-1 && seamFitness[bestCol+1][y-1] <= theMin) {
          bestCol = bestCol + 1;
        }
      }
    }
  }

  newImg.updatePixels();
  return newImg;
}

PImage removeHorizontalSeams(int numAttempts) {
  computeGradient();
  computeHorizontalSeams();

  for (int attempt = 0; attempt < numAttempts; attempt++) {
    int bestRow = 0;
    for (int i = 0; i < img.height - numAttempts; i++) {
      if (seamFitness[img.width-1][bestRow] > seamFitness[img.width-1][i]) {
        bestRow = i;
      }
    }
  
    // insert new seam
    newImg = createImage(img.width, img.height-1, RGB);
    newImg.loadPixels();
  
    for (int x = newImg.width-1; x >= 0; x--) {
      boolean pastBestRow = false;
  
      for (int y = 0; y < newImg.height; y++) {
        if (y == bestRow) {
          pastBestRow = true;
        }
  
        int newLoc = x + y*newImg.width;
        int oldLoc = x + (pastBestRow ? y+1 : y)*img.width;
  
        newImg.pixels[newLoc] = img.pixels[oldLoc];
      }
  
      if (x > 0) {
        // update best column for the next row
        float theMin = seamFitness[x-1][bestRow];
  
        if (bestRow > 0 && seamFitness[x-1][bestRow-1] <= theMin) {
          bestRow = bestRow - 1;
        } else if (bestRow < img.height-1 && seamFitness[x-1][bestRow+1] <= theMin) {
          bestRow = bestRow + 1;
        }
      }
    }
  }
  
  newImg.updatePixels();
  return newImg;
}


void seamCarveTo(int newWidth, int newHeight) {  
  if (newWidth < img.width) {
    while (newWidth < img.width) {
      int dWidth = newWidth - img.width;
      int kWidth = dWidth > 10 ? dWidth / 10 : 1;
      img = removeVerticalSeams(kWidth);
    }
  }
  
  if (newHeight < img.height) {
    while (newHeight < img.height) {
      int dHeight = newHeight - img.height;
      int kHeight = dHeight > 10 ? dHeight / 10 : 1;
      img = removeHorizontalSeams(kHeight);
    }
  }
}


void mousePressed() {
  if (mouseX > 0 && mouseY > 0) {
     seamCarveTo(mouseX, mouseY);
  }
}

void draw() {
   background(255);
   image(img, 0, 0);
}

void keyPressed() {
  setup();
}

