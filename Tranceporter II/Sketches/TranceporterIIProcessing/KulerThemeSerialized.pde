//class KulerThemeSerialized extends KulerTheme {
//
//  KulerThemeSerialized(KulerTheme baseKulerTheme) {
//    super(p, baseKulerTheme.getcolors);
//    kulerTheme.setThemeID(baseKulerTheme.getThemeID());
//    kulerTheme.setThemeTitle(baseKulerTheme.getThemeTitle());
//    kulerTheme.setAuthorID(baseKulerTheme.getAuthorID);
//    kulerTheme.setAuthorLabel(baseKulerTheme.getAuthorLabel);
//    kulerTheme.setThemeTags(baseKulerTheme.getThemeTags);
//    kulerTheme.setThemeRating(baseKulerTheme.getThemeRating);
//    kulerTheme.setThemeDownloadCount(baseKulerTheme.getThemeDownloadCount);
//    kulerTheme.setThemeCreatedAt(baseKulerTheme.getThemeCreatedAt);
//    kulerTheme.setThemeEditedAt(baseKulerTheme.getThemeEditedAt);
//  }
//
//  KulerTheme readKulerTheme() {
//    
//  }
//  
//  void writeKulerTheme(KulerTheme theme) {
//    
//    for (int j = 0; j < themeSwatches.length; j++) {
//      colors[j] = PApplet.unhex("FF" + themeSwatches[j].getContent());
//    }
//
//    KulerTheme kulerTheme = new KulerTheme(p, colors);
//    
//    kulerTheme.setThemeID();
//    kulerTheme.setThemeTitle();
//    kulerTheme.setAuthorID();
//    kulerTheme.setAuthorLabel();
//    kulerTheme.setThemeTags();
//    kulerTheme.setThemeRating();
//    kulerTheme.setThemeDownloadCount();
//    kulerTheme.setThemeCreatedAt();
//    kulerTheme.setThemeEditedAt();
//    
//
//  }
//
//
//  void writePalettToBuffer();
//  {
//    byte[] bytes = new byte[768];
//    
//    for (int i = 0; i < swatches.length; i++) {
//      int color = swatches[i].getColor();
//      bytes[i*3]   = (byte) ((color >> 16) & 0xff);
//      bytes[i*3+1] = (byte) ((color >> 8) & 0xff);
//      bytes[i*3+2] = (byte) (color & 0xff);
//    }
//    
//    for (int i = swatches.length*3; i < 768; i++) {
//      bytes[i] = (byte) (0);
//    }
//    
//    p.saveBytes(i_name+".act", bytes);
//  }
//
//  
//  void readPaletteFromBuffer(byte[] b)
//  {
//    int start = 0;
//    int steps = 3;
//    int length = 255;
//    
//    int cnt = 0;
//    for (int i = 0; i < length; i++) {
//      if (b[start + i * steps] != -1 && b[start + i * steps + 1] != -1
//          && b[start + i * steps + 2] != -1) {
//        cnt++;
//      }
//    }
//    swatches = new Swatch[cnt];
//    cnt = 0;
//    for (int i = 0; i < length; i++) {
//      if (b[start + i * steps] != -1 && b[start + i * steps + 1] != -1
//          && b[start + i * steps + 2] != -1) {
//        swatches[cnt] = new Swatch(p, (0xff << 24)
//                                   + ((b[start + i * steps] & 0xff) << 16)
//                                   + ((b[start + i * steps + 1] & 0xff) << 8)
//                                   + (b[start + i * steps + 2] & 0xff));
//        cnt++;
//      }
//    }
//  }
//
//
//}
