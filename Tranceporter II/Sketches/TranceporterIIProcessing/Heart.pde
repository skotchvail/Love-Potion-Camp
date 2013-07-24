
class Heart extends Drawer
{
  
  Heart(Pixels p, Settings s) {
    super(p, s, JAVA2D, DrawType.MirrorSides);
  }

  int numFrames = 18;  // The number of frames in the animation
  int frame = 0;
  PImage[] images;
  
  String getName()
  {
    return "Heart";
  }
  
  
  void setup()
  {
    images = new PImage[numFrames];
    for (int i = 0; i < numFrames; i++) {
      images[i]  = loadImage("split_" + i + "beatnhrt_upd_408.gif");
    }
  }
  
  void draw()
  {
    float scalex = 0.37;
    pg.background(getColor(frame));
    pg.scale(scalex);
    
    // JJ - LOOK AT POSITIONING......
    //   pg.image(images[frame], (4.0*width - (images[frame].width*scalex)), (height*5.0 - (images[frame].height*scalex))/2);
    
    pg.translate(0,12);
    pg.rotate(-PI/4);
    pg.image(images[frame], 0 - width/3, 0);
    
    // JJ Look at looping on the beat...
    // settings.isBeat(1);
    //settings.isBeat(2);
    //settings.isBeat(3);
    
    //This are one when there is a beat on the treble, mid range, or bass.
    //Janaka Jayasingha
    
    //getNumColors();
    //getColor(index);
    //see the other sketches for how this is used.
    
    
    //only cycle through if bass beats on music changes.
//    if (settings.isBeat(1))
//    {
//      frame = 6; // actual pulsing beat part is frame 6 on. so the pulse occurs on the beat.
//      //settings.isBeat(1)||settings.isBeat(2)||
//    }
    frame = (frame+1) % numFrames;  // Use % to cycle through frames
    
  }
  
}
