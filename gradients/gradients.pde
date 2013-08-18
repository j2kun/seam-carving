
PImage img, gradient;
boolean pressed = false;

void setup() {
  int x = (int) random(400,1024);
  int y = (int) random(400,768);
  
  String url = "http://lorempixel.com/" + x + "/" + y;
  img = loadImage(url, "jpg");
  size(x,y);
  
  gradient = horizontalGradient(img);
}

int colorDistance(color c1, color c2) {
  float r = red(c1) - red(c2);
  float g = green(c1) - green(c2);
  float b = blue(c1) - blue(c2);
  return (int)sqrt(r*r + g*g + b*b);
}

PImage horizontalGradient(PImage img) {
  color left, right;
  int center;
  PImage newImage = createImage(img.width, img.height, RGB);
  
  for (int x = 0; x < img.width; x++) {
    for (int y = 0; y < img.height; y++) {
      center = x + y*img.width;
      
      // use center pixel if we're on a boundary
      left = x == 0 ? img.pixels[center] : img.pixels[(x-1) + y*img.width]; 
      right = x == img.width-1 ? img.pixels[center] : img.pixels[(x+1) + y*img.width];

      // New color is difference between pixel and left neighbor
      newImage.pixels[center] = color(colorDistance(left, right));
    }
  }
  
  return newImage;
}

void draw() {
  if (!pressed) {
    background(255);
    image(img, 0, 0);
  }
}

void mousePressed() {
  background(255);
  if (mouseButton == LEFT) {
    image(gradient, 0, 0);
    pressed = true;
  } else {
    image(img, 0, 0);
  }
}

void keyPressed() {
   setup(); 
   pressed = false;
}

