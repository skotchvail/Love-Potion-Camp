
class Heart extends Drawer
{
  
  Heart(Pixels p, Settings s) {
    super(p, s, JAVA2D);
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
//  frameRate(20);
    
    images = new PImage[numFrames];

    images[0]  = loadImage("split_0beatnhrt_upd_408.gif");
    images[1]  = loadImage("split_1beatnhrt_upd_408.gif");
    images[2]  = loadImage("split_2beatnhrt_upd_408.gif");
    images[3]  = loadImage("split_3beatnhrt_upd_408.gif");
    images[4]  = loadImage("split_4beatnhrt_upd_408.gif");
    images[5]  = loadImage("split_5beatnhrt_upd_408.gif");
    images[6]  = loadImage("split_6beatnhrt_upd_408.gif");
    images[7]  = loadImage("split_7beatnhrt_upd_408.gif");
    images[8]  = loadImage("split_8beatnhrt_upd_408.gif");
    images[9]  = loadImage("split_9beatnhrt_upd_408.gif");
    images[10] = loadImage("split_10beatnhrt_upd_408.gif");
    images[11] = loadImage("split_11beatnhrt_upd_408.gif");
    images[12] = loadImage("split_12beatnhrt_upd_408.gif");
    images[13] = loadImage("split_13beatnhrt_upd_408.gif");
    images[14] = loadImage("split_14beatnhrt_upd_408.gif");
    images[15] = loadImage("split_15beatnhrt_upd_408.gif");
    images[16] = loadImage("split_16beatnhrt_upd_408.gif");
    images[17] = loadImage("split_17beatnhrt_upd_408.gif");
    
    // If you don't want to load each image separately
    // and you know how many frames you have, you
    // can create the filenames as the program runs.
    // The nf() command does number formatting, which will
    // ensure that the number is (in this case) 4 digits.
    //for(int i=0; i<numFrames; i++) {
    //  String imageName = "PT_anim" + nf(i, 4) + ".gif";
    //  images[i] = loadImage(imageName);
    //}
  }
  
  void draw()
  {
    float scalex = 0.14;
    pg.background(getColor(frame));
    pg.scale(scalex);
    

    // JJ - LOOK AT POSITIONING......
    pg.image(images[frame], (3*width - (images[frame].width*scalex)), (height*2.6 - (images[frame].height*scalex))/2);
    
    
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
    if (settings.isBeat(1))
    {
      frame = 6; // actual pulsing beat part is frame 6 on. so the pulse occurs on the beat.
      //settings.isBeat(1)||settings.isBeat(2)||
    }
    frame = (frame+1) % numFrames;  // Use % to cycle through frames
    
  }
  
}
