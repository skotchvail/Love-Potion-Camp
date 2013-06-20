// Class to keep track of the current palette mode and current palette gradient colors.

import colorLib.*;
import toxi.color.*;
import toxi.color.theory.*;

class PaletteManager {
  private Palette[] kPs;
  private int kPalInd = 0;
  private int PT_KULER = 0;
  private int paletteType = PT_KULER;
  private ArrayList ptStrategies = ColorTheoryRegistry.getRegisteredStrategies();
  private int NUM_PT = 1 + ptStrategies.size();
  private int basePaletteColors = -1;
  
  void init(PApplet pa) {
  
    color[][] kulerColors = {
      // Colors hand copied from https://kuler.adobe.com/explore/
      {#8AC6FF, #1F5080, #3EA0FF, #456380, #3280CC},
      {#A3D9B0, #93BF9E, #F2F0D5, #8C8474, #40362E},
      {#DE5605, #F7A035, #B1DEB5, #EFECCA, #65ABA6},
      {#08A689, #82BF56, #C7D93D, #E9F2A0, #F2F2F2},
      {#292930, #4A4140, #168A83, #CCA18E, #820132},
      {#8FBABF, #F2EAD0, #D9C39A, #A68C6D, #593A2F},
      {#EAF4FF, #6A7E93, #B7CBE0, #937F5B, #E0D1B7},
      {#010A26, #04D9D9, #F2CF66, #F2994B, #F24B0F},
      {#849696, #FEFFFB, #232D33, #17384D, #FF972C},
      {#322E25, #504C40, #A6382E, #D94A3D, #DFC8BB},
      {#0096AF, #F2D0A7, #FFAB95, #EE8F8A, #517A6F},
      {#265573, #386D73, #81A68A, #9FBF8F, #D4D9B0},
      {#8C3E62, #7EBFB9, #F2EAD0, #D9BEB8, #F2A0A0},
      {#1F5B73, #1BA6A6, #1BAFBF, #F2EFC4, #CCD96A},
      {#FF6B6B, #556270, #C7F464, #4ECDC4, #EDC8BB},
      {#3E454C, #2185C5, #7ECEFD, #FFF6E5, #FF7F66},
    };
    
    kPs = new Palette[kulerColors.length + 1];

    // the first palette should be the basic full saturation/brightness HSB colors
    colorMode(HSB);
    color[] hsbWheel = new color[256];
    for (int i=0; i<256; i++) {
      hsbWheel[i] = color(i, 255, 255);
    }
    
    kPs[0] = new Palette(pa, hsbWheel);
    
    for (int i = 1; i <= kulerColors.length; i++) {
      kPs[i] = new Palette(pa, kulerColors[i-1]);
      kPs[i].addColor(kPs[i].getColor(0));
    }
  }
  
  void setupPalette(int numColors, color[] colors) {
    color[] c;
    assert colors != null: "setupPalette colors cannot be null!";

    assert(numColors != 0);
    assert(colors.length > 0);
    
    colorMode(RGB, 255);
    
    if (paletteType == PT_KULER) {
      Palette p = kPs[kPalInd];
      assert p != null : "Palette is nil";
      basePaletteColors = p.totalSwatches();      
      
      Gradient g = new Gradient(p, numColors, false);
      for (int i=0; i<g.totalSwatches(); i++) {
        colors[i] = g.getColor(i);
      }
    } else {
      ColorTheoryStrategy s = (ColorTheoryStrategy) ptStrategies.get(paletteType-1);
      assert s != null : "ColorTheoryStrategy is nil";
      TColor col = ColorRange.BRIGHT.getColor();
      ColorList colList = ColorList.createUsingStrategy(s, col);
      assert colList != null : "colList is nil";
      basePaletteColors = colList.size();
      
      ColorGradient grad = new ColorGradient();
      for (int i=0; i<colList.size(); i++) {
        grad.addColorAt(float(i)*numColors/colList.size(), colList.get(i));
      }
      grad.addColorAt(numColors-1, colList.get(0));
      ColorList colList2 = grad.calcGradient(0, numColors);
      
      for (int i=0; i<colList2.size(); i++) {
        colors[i] = colList2.get(i).toARGB();
      }
    }
  }
  
  void getNewPalette(int numColors, color[] colors) {
    if (paletteType == PT_KULER) {
      kPalInd = (kPalInd + 1) % kPs.length;
    }
    setupPalette(numColors, colors);
    println("NewPalette: " + kPalInd + " colors " + colors.length + " color[0]=" + hex(colors[0]));
  }
  
  int basePaletteColors() {
    return this.basePaletteColors;
  }
  
  void nextPaletteType() {
    paletteType = (paletteType + 1) % NUM_PT;
  } 
  
  String getPaletteDisplayName() {
    if (paletteType == PT_KULER) {
      return "Kuler";
    } else {
      ColorTheoryStrategy s = (ColorTheoryStrategy) ptStrategies.get(paletteType-1);
      return s.getName();
    }
  }
  
  int getPaletteType() {
    return paletteType;
  }
  
  void setPaletteType(int whichPalette, int numColors, color[] colors) {
    assert(whichPalette <  NUM_PT);
    paletteType = whichPalette;
    setupPalette(numColors, colors);
  }

}
