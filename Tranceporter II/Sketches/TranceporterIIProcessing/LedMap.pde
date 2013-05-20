/*
 Tracks the pixels for each Sketch and sends them to the hardware
 */

class LedMap {
  
  final boolean runConcurrent = true;
  final boolean kUseBitBang = true;

  color[] pixelData;
  int[] strandSizes;
  int maxPixelsPerStrand;
  private int[] strandMap;
  private int[] trainingStrandMap;

  LedMap() {
    strandSizes = new int[]
    {
      1001, //mapUpperHalfTopDriverSide
      400, //mapDriverSideLowerPart2
      850, //mapDriverSideLowerPart1
      997, //mapLowerHalfTopDriverSide
      1175, //TODO: mapPassengerSideUpperTop1
      
      973, //mapLowerHalfTopPassengerSide
      
      250, //mapPassengerSideLower2
      849, //mapPassengerSideLower1
    };
    
    
    int totalPixels = 0;
    maxPixelsPerStrand = 0;
    for (int i = 0; i < getNumStrands(); i++) {
      int strandSize = getStrandSize(i);
      if (strandSize > maxPixelsPerStrand) {
        maxPixelsPerStrand = strandSize;
      }
      totalPixels += strandSize;
    }
    
    int pixelDataSize = max(totalPixels, ledWidth * ledHeight);
    pixelData = new color[pixelDataSize];
    
    strandMap = new int[getNumStrands() * maxPixelsPerStrand];
    trainingStrandMap = new int[getNumStrands() * maxPixelsPerStrand];
    
    initTotalControl();
  }

  /*
   Data Format csv:
   'Offsetter', ordinal, 0, x, y (delta to previous offsetters)
   'set',       ordinal, 0, x, y
   'missing',   ordinalStart, ordinalEnd
   'unprogrammed', ordinalStart, ordinalEnd (not sure we need this)
   */
  
  String fileNameForStrand(int whichStrand) {
    return "strand" + (whichStrand + 1) + ".csv";
  }
  
  static final String kCommandOffsetter = "offsetter";
  static final String kCommandMap = "map";
  static final String kCommandMissing = "missing";
  static final String kCommandUnprogrammed = "unprogrammed";
  
  static final String kColumnCommand = "command";
  static final String kColumnOrdinal = "ordinalStart";
  static final String kColumnOrdinalEnd = "ordinalEnd";
  static final String kColumnCoordX = "x";
  static final String kColumnCoordY = "y";
  
  // TODO: not needed after 2.0b9
  static final int STRING = 0;
  static final int INT = 1;
  static final int LONG = 2;
  static final int FLOAT = 3;
  static final int DOUBLE = 4;
  static final int CATEGORY = 5;

  
  void writeOneStrand(int whichStrand) {
    println("================== writeOneStrand " + (whichStrand + 1));
    
    int strandSize = getStrandSize(whichStrand);
//    strandSize = min(strandSize, 50);
    Table table = new Table();
    table.addColumn(kColumnCommand, STRING);
    table.addColumn(kColumnOrdinal, INT);
    table.addColumn(kColumnOrdinalEnd, INT);
    table.addColumn(kColumnCoordX, INT);
    table.addColumn(kColumnCoordY, INT);
    
    TableRow row = null;
    
    for (int whichLed = 0; whichLed < strandSize; whichLed++) {
      
      int value = ledGetRawValue(whichStrand, whichLed, false); // TODO: just pull it out directly for faster performance
      if (value >= 0) {
        Point p = i2c(value);

        if (row != null) {
          if (!row.getString(kColumnCommand).equals(kCommandMap)) {
            row = null;
//            println("row = null, whichLed = " + whichLed + " reason = 1");
          }
          else {
            int ordinalEnd = row.getInt(kColumnOrdinalEnd);
            if (ordinalEnd + 1 != whichLed) {
              row = null;
//              println("row = null, whichLed = " + whichLed + " reason = 2");
            }
            else {
              // If prev is a map
              // if prev.ordinalEnd + 1 == curr.ordinal
              // if direction of pre => cur is the same
              // change ordinalEnd, change x or y
              
              int numRows = table.getRowCount();
              if (numRows >= 2) {
                
                TableRow startRow = table.getRow(numRows - 2);
                if (startRow.getString(kColumnCommand).equals(kCommandMap)) {
                  int startX = startRow.getInt(kColumnCoordX);
                  int startY = startRow.getInt(kColumnCoordY);
                  int endX = row.getInt(kColumnCoordX);
                  int endY = row.getInt(kColumnCoordY);
                  
                  int deltaX = endX - startX;
                  int deltaY = endY - startY;
                  int ordinalStart = startRow.getInt(kColumnOrdinal);
                  int deltaOrdinal = whichLed - ordinalStart;
                  
                  if ((deltaX == 0) == (deltaY == 0)) {
                    row = null;
//                    println("row = null, whichLed = " + whichLed + " reason = 6");
                  }
                  else if ((p.y == endY) && ((endX > startX && p.x == endX + 1 && p.x == startX + deltaOrdinal) ||
                           (endX < startX && p.x == endX - 1 && p.x == startX - deltaOrdinal))) {
                    assert(startY == endY) : "startY = " + startY + " endY = " + endY + " whichLed = " + whichLed;
                    row.setInt(kColumnCoordX, p.x);
                    row.setInt(kColumnOrdinalEnd, whichLed);
                  }
                  else if ((p.x == endX) && ((endY > startY && p.y == endY + 1 && p.y == startY + deltaOrdinal) ||
                      (endY < startY && p.y == endY - 1 && p.y == startY - deltaOrdinal))) {
                    assert(startX == endX) : "startX = " + startX + " endX = " + endX + " whichLed = " + whichLed + " whichStrand = " + whichStrand;
                    row.setInt(kColumnCoordY, p.y);
                    row.setInt(kColumnOrdinalEnd, whichLed);
                  }
                  else {
                    row = null;
//                    println("row = null, whichLed = " + whichLed + " deltaOrdinal = " + deltaOrdinal + " reason = 3");
                  }
                }
                else {
                  row = null;
//                  println("row = null, whichLed = " + whichLed + " reason = 4");
                }
              }
              else {
                row = null;
//                println("row = null, whichLed = " + whichLed + " reason = 5");
              }
            }
          }
        }
        
        if (row == null) {
          row = table.addRow();
          row.setString(kColumnCommand, kCommandMap);
          row.setInt(kColumnOrdinal, whichLed);
          row.setInt(kColumnOrdinalEnd, whichLed);
          row.setInt(kColumnCoordX, p.x);
          row.setInt(kColumnCoordY, p.y);
        }
      }
      else if (value == TC_PIXEL_UNUSED) {
        
        if (row != null) {
          if (!row.getString(kColumnCommand).equals(kCommandMissing)) {
            row = null;
          }
          else {
            int ordinalEnd = row.getInt(kColumnOrdinalEnd);
            if (ordinalEnd + 1 == whichLed) {
              row.setInt(kColumnOrdinalEnd, whichLed);
            }
          }
        }
          
        if (row == null) {
          row = table.addRow();
          row.setString(kColumnCommand, kCommandMissing);
          row.setInt(kColumnOrdinal, whichLed);
          row.setInt(kColumnOrdinalEnd, whichLed);
        }
      }
      else {
        assert (value == TC_PIXEL_DISCONNECTED || value == TC_PIXEL_UNDEFINED) : "unexpected value is " + value;
      }
    }
    saveTable(table, "data/" + fileNameForStrand(whichStrand));
  }
  
  void readOneStrand(int whichStrand) {
    
    assert (whichStrand < getNumStrands());
    
    //top of top driver side
    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    Table table = loadTable(fileNameForStrand(whichStrand), "header");
    
    println("strand " + (whichStrand + 1) + " rows: " + table.getRowCount());
    assert table.getRowCount() > 0 : "rowCount = 0 for strand " + (whichStrand + 1);
    
    for (TableRow row : table.rows()) {
      
      String command = row.getString(kColumnCommand);
      int ordinalStart = row.getInt(kColumnOrdinal);
      int ordinalEnd = row.getInt(kColumnOrdinalEnd);
      int coordX = row.getInt(kColumnCoordX);
      int coordY = row.getInt(kColumnCoordY);
      
      if (command.equals(kCommandMap)) {
        ledSet(whichStrand, ordinalEnd, coordX, coordY);
      }
      else if (command.equals(kCommandMissing)) {
        for (int i = ordinalStart; i <= ordinalEnd; i++) {
          ledMissing(whichStrand, i);
        }
      }
      else {
        assert false : "unimplemented command: " + command;
      }
    }
  }
  
  void copyPixels(int[] pixels, DrawType drawType) {
    final int halfWidth = ledWidth / 2;
    
    if (drawType == DrawType.MirrorSides) {
      // Image is mirrored
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + (ledWidth - x - 1)] = pixel;
        }
      }
    }
    else if (drawType == DrawType.RepeatingSides) {
      // Image is repeated
      for (int y = 0; y < ledHeight; y++) {
        final int baseY = y * halfWidth;
        final int baseYData = y * ledWidth;
        for (int x = 0; x < halfWidth; x++) {
          color pixel = pixels[baseY + x];
          pixelData[baseYData + x] = pixel;
          pixelData[baseYData + x + halfWidth] = pixel;
        }
      }
    }
    else if (drawType == DrawType.TwoSides) {
      arrayCopy(pixels, 0, pixelData, 0, pixels.length);
    }
    else {
      assert false : "unknown drawType = " + drawType;
    }
  }
  // LED MAP 3
  void mapDriverSideLowerPart1(int panel) {
    assert (panel < getNumStrands());
    
    //highest y is 28
    
    xOffsetter = 21;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledSet(panel, 0, 0, 0);
    ledSet(panel, 4, 0, 4);
    ledSet(panel, 5, 1, 4);
    ledSet(panel, 9, 1, 0);
    ledSet(panel, 10, 2, 0);
    ledSet(panel, 16, 2, 6);
    ledSet(panel, 17, 3, 6);
    ledSet(panel, 22, 3, 1);
    ledSet(panel, 23, 4, 1);
    ledSet(panel, 30, 4, 8);
    ledSet(panel, 31, 5, 8);
    ledSet(panel, 38, 5, 1);
    ledSet(panel, 39, 6, 1);
    ledSet(panel, 48, 6, 10);
    ledSet(panel, 49, 7, 10);
    ledSet(panel, 58, 7, 1);
    ledSet(panel, 59, 8, 1);
    ledSet(panel, 70, 8, 12);
    ledSet(panel, 71, 9, 12);
    ledSet(panel, 82, 9, 1);
    ledSet(panel, 83, 10, 1);
    ledSet(panel, 95, 10, 13);
    ledSet(panel, 96, 11, 13);
    ledSet(panel, 108, 11, 1);
    ledSet(panel, 109, 12, 1);
    ledSet(panel, 122, 12, 14);
    ledSet(panel, 123, 13, 14);
    ledSet(panel, 137, 13, 0);
    ledSet(panel, 138, 14, 0);
    ledSet(panel, 153, 14, 15);
    ledSet(panel, 154, 15, 15);
    ledSet(panel, 169, 15, 0);
    ledSet(panel, 170, 16, 0);
    ledSet(panel, 187, 16, 17);
    ledSet(panel, 188, 17, 17);
    ledSet(panel, 205, 17, 0);
    ledSet(panel, 206, 18, 0);
    ledSet(panel, 224, 18, 18);
    ledSet(panel, 225, 19, 18);
    ledSet(panel, 241, 19, 2);
    ledMissing(panel, 242);
    ledSet(panel, 243, 19, 1);
    ledSet(panel, 244, 19, 0);
    ledSet(panel, 245, 20, 0);
    ledSet(panel, 264, 20, 19);
    ledSet(panel, 265, 21, 19);
    ledSet(panel, 285, 21, -1);
    ledSet(panel, 286, 22, -1);
    ledSet(panel, 306, 22, 19);
    ledSet(panel, 307, 23, 19);
    ledSet(panel, 327, 23, -1);
    ledSet(panel, 328, 24, -1);
    ledSet(panel, 349, 24, 20);
    ledSet(panel, 350, 25, 20);
    ledSet(panel, 372, 25, -2);
    ledSet(panel, 373, 26, -2);
    ledSet(panel, 396, 26, 21);
    ledSet(panel, 397, 27, 21);
    ledSet(panel, 420, 27, -2);
    ledSet(panel, 421, 28, -2);
    ledSet(panel, 445, 28, 22);
    ledSet(panel, 446, 29, 22);
    ledSet(panel, 470, 29, -2);
    ledSet(panel, 471, 30, -2);
    ledSet(panel, 495, 30, 22);
    ledSet(panel, 496, 31, 22);
    ledSet(panel, 520, 31, -2);
    ledSet(panel, 521, 32, -2);
    ledSet(panel, 546, 32, 23);
    ledSet(panel, 547, 33, 23);
    ledSet(panel, 572, 33, -2);
    ledSet(panel, 573, 34, -2);
    ledSet(panel, 598, 34, 23);
    ledSet(panel, 599, 35, 23);
    ledSet(panel, 625, 35, -3);
    ledSet(panel, 626, 36, -3);
    ledSet(panel, 652, 36, 23);
    ledSet(panel, 653, 37, 23);
    ledSet(panel, 679, 37, -3);
    ledSet(panel, 680, 38, -3);
    ledSet(panel, 706, 38, 23);
    ledSet(panel, 707, 39, 23);
    ledSet(panel, 733, 39, -3);
    ledSet(panel, 734, 40, -3);
    ledSet(panel, 760, 40, 23);
    ledSet(panel, 761, 41, 23);
    ledSet(panel, 787, 41, -3);
    ledSet(panel, 788, 42, -3);
    ledSet(panel, 814, 42, 23);
    ledSet(panel, 815, 43, 23);
    ledSet(panel, 841, 43, -3);
    ledSet(panel, 842, 44, -3);
    ledSet(panel, 849, 44, 4);
  }
  
  // TODO: LED MAP 2
  void mapDriverSideLowerPart2(int panel) {
    assert (panel < getNumStrands());
    
    xOffsetter = 21;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledSet(panel, 0, 44, 5);
    ledSet(panel, 18, 44, 23);
    ledSet(panel, 19, 45, 23);
    ledSet(panel, 45, 45, -3);
    ledSet(panel, 46, 46, -3);
    ledSet(panel, 72, 46, 23);
    ledSet(panel, 73, 47, 23);
    ledSet(panel, 99, 47, -3);
    ledSet(panel, 100, 48, -3);
    ledSet(panel, 125, 48, 22);
    ledSet(panel, 126, 49, 22);
    ledSet(panel, 149, 49, -1);
    ledSet(panel, 150, 50, -1);
    ledSet(panel, 173, 50, 22);
    ledSet(panel, 174, 51, 22);
    ledSet(panel, 198, 51, -2);
    ledSet(panel, 199, 52, -2);
    ledSet(panel, 223, 52, 22);
    ledSet(panel, 224, 53, 22);
    ledSet(panel, 249, 53, -3);
    ledSet(panel, 250, 54, -3);
    ledSet(panel, 274, 54, 21);
    ledSet(panel, 275, 55, 21);
    ledSet(panel, 299, 55, -3);
    ledSet(panel, 300, 56, -3);
    ledSet(panel, 323, 56, 20);
    ledSet(panel, 324, 57, 20);
    ledSet(panel, 345, 57, -1);
    ledSet(panel, 346, 58, -1);
    ledSet(panel, 366, 58, 19);
    ledSet(panel, 367, 59, 19);
    ledSet(panel, 387, 59, -1);
    ledSet(panel, 388, 60, -1);
    ledSet(panel, 399, 60, 10);
  }
  
  void mapDriverSideUpper(int panel) {
    //800 pixels
    assert (panel < getNumStrands());
 
    //OBSOLETE?????
    
    xOffsetter = 0;
    yOffsetter = 10;
    ordinalOffsetter = -1;
    
    ledSet(panel, 1, 5, 12);
    ledSet(panel, 5, 5, 16);
    ledSet(panel, 6, 6, 16);
    ledSet(panel, 15, 6, 7);
    ledSet(panel, 16, 7, 7);
    ledSet(panel, 25, 7, 16);
    ledSet(panel, 26, 8, 16);
    ledSet(panel, 36, 8, 6);
    ledSet(panel, 37, 9, 6);
    ledSet(panel, 47, 9, 16);
    ledSet(panel, 48, 10, 16);
    ledSet(panel, 59, 10, 5);
    ledSet(panel, 60, 11, 5);
    ledSet(panel, 71, 11, 16);
    ledSet(panel, 72, 12, 16);
    ledSet(panel, 85, 12, 3);
    ledSet(panel, 86, 13, 3);
    ledSet(panel, 97, 13, 14);
    ledSet(panel, 98, 14, 14);
    ledSet(panel, 110, 14, 2);
    ledSet(panel, 111, 15, 2);
    ledSet(panel, 123, 15, 14);
    ledSet(panel, 124, 16, 14);
    ledSet(panel, 138, 16, 0);
    ledSet(panel, 139, 17, 0);
    ledSet(panel, 153, 17, 14);
    ledSet(panel, 154, 18, 14);
    ledSet(panel, 168, 18, 0);
    ledSet(panel, 169, 19, 0);
    ledSet(panel, 183, 19, 14);
    ledSet(panel, 184, 20, 14);
    ledSet(panel, 198, 20, 0);
    ledSet(panel, 199, 21, 0);
    ledSet(panel, 213, 21, 14);
    ledSet(panel, 214, 22, 14);
    ledSet(panel, 228, 22, 0);
    ledSet(panel, 229, 23, 0);
    ledSet(panel, 242, 23, 13);
    ledSet(panel, 243, 24, 13);
    ledSet(panel, 255, 24, 1);
    ledSet(panel, 256, 25, 1);
    ledSet(panel, 267, 25, 12);
    ledSet(panel, 268, 26, 12);
    ledSet(panel, 279, 26, 1);
    ledSet(panel, 280, 27, 1);
    ledSet(panel, 291, 27, 12);
    ledSet(panel, 292, 28, 12);
    ledSet(panel, 301, 28, 3);
    ledSet(panel, 302, 29, 3);
    ledSet(panel, 311, 29, 12);
    ledSet(panel, 312, 30, 12);
    ledSet(panel, 322, 30, 2);
    ledSet(panel, 323, 31, 2);
    ledSet(panel, 333, 31, 12);
    ledSet(panel, 334, 32, 12);
    ledSet(panel, 346, 32, 0);
    ledSet(panel, 347, 33, 0);
    ledSet(panel, 359, 33, 12);
    ledSet(panel, 360, 34, 12);
    ledSet(panel, 371, 34, 1);
    ledSet(panel, 372, 35, 1);
    ledSet(panel, 383, 35, 12);
    ledSet(panel, 384, 36, 12);
    ledSet(panel, 394, 36, 2);
    ledSet(panel, 395, 37, 2);
    ledSet(panel, 405, 37, 12);
    ledSet(panel, 406, 38, 12);
    ledSet(panel, 415, 38, 3);
    ledSet(panel, 416, 39, 3);
    ledSet(panel, 425, 39, 12);
    ledSet(panel, 426, 40, 12);
    ledSet(panel, 435, 40, 3);
    ledSet(panel, 436, 41, 3);
    ledSet(panel, 445, 41, 12);
    ledSet(panel, 446, 42, 12);
    ledSet(panel, 454, 42, 4);
    ledSet(panel, 455, 43, 4);
    ledSet(panel, 463, 43, 12);
    ledSet(panel, 464, 44, 12);
    ledSet(panel, 472, 44, 4);
    ledSet(panel, 473, 45, 4);
    ledSet(panel, 481, 45, 12);
    ledSet(panel, 482, 46, 12);
    ledSet(panel, 490, 46, 4);
    ledSet(panel, 491, 47, 4);
    ledSet(panel, 499, 47, 12);
    ledSet(panel, 500, 48, 12);
    ledSet(panel, 509, 48, 3);
    ledSet(panel, 510, 49, 3);
    ledSet(panel, 521, 49, 14);
    ledSet(panel, 522, 50, 14);
    ledSet(panel, 546, 50, -10);
    ledSet(panel, 547, 51, -10);
    ledSet(panel, 570, 51, 13);
    ledSet(panel, 571, 52, 13);
    ledSet(panel, 593, 52, -9);
    ledSet(panel, 594, 53, -9);
    ledSet(panel, 615, 53, 12);
    ledSet(panel, 616, 54, 12);
    ledSet(panel, 636, 54, -8);
    ledSet(panel, 637, 55, -8);
    ledSet(panel, 657, 55, 12);
    ledSet(panel, 658, 56, 12);
    ledSet(panel, 676, 56, -6);
    ledSet(panel, 677, 57, -6);
    ledSet(panel, 695, 57, 12);
    ledSet(panel, 696, 58, 12);
    ledSet(panel, 713, 58, -5);
    ledSet(panel, 714, 59, -5);
    ledSet(panel, 733, 59, 14);
    ledSet(panel, 734, 60, 14);
    ledSet(panel, 752, 60, -4);
    ledSet(panel, 753, 61, -4);
    ledSet(panel, 770, 61, 13);
    ledSet(panel, 771, 62, 13);
    ledSet(panel, 786, 62, -2);
    ledSet(panel, 787, 63, -2);
    ledSet(panel, 800, 63, 11);
  }
  
  // TODO: LED MAP 8
  void mapPassengerSideLower1(int panel) {
    assert (panel < getNumStrands());
    //    Passenger Side Part 1:
    xOffsetter = 20;
    yOffsetter = 32;
    ordinalOffsetter = 0;
    
    ledMissing(panel, 0);
    ledSet(panel, 1, 0, 0);
    ledSet(panel, 6, 0, 5);
    ledSet(panel, 7, 1, 5);
    ledSet(panel, 12, 1, 0);
    ledSet(panel, 13, 2, 0);
    ledSet(panel, 20, 2, 7);
    ledSet(panel, 21, 3, 7);
    ledSet(panel, 28, 3, 0);
    ledSet(panel, 29, 4, 0);
    ledSet(panel, 38, 4, 9);
    ledSet(panel, 39, 5, 9);
    ledSet(panel, 48, 5, 0);
    ledSet(panel, 49, 6, 0);
    ledSet(panel, 60, 6, 11);
    ledSet(panel, 61, 7, 11);
    ledSet(panel, 72, 7, 0);
    ledSet(panel, 73, 8, 0);
    ledSet(panel, 85, 8, 12);
    ledSet(panel, 86, 9, 12);
    ledSet(panel, 98, 9, 0);
    ledSet(panel, 99, 10, 0);
    ledSet(panel, 112, 10, 13);
    ledSet(panel, 113, 11, 13);
    ledSet(panel, 126, 11, 0);
    ledSet(panel, 127, 12, 0);
    ledSet(panel, 142, 12, 15);
    ledSet(panel, 143, 13, 15);
    ledSet(panel, 158, 13, 0);
    ledSet(panel, 159, 14, 0);
    ledSet(panel, 175, 14, 16);
    ledSet(panel, 176, 15, 16);
    ledSet(panel, 192, 15, 0);
    ledSet(panel, 193, 16, 0);
    ledSet(panel, 210, 16, 17);
    ledSet(panel, 211, 17, 17);
    ledSet(panel, 226, 17, 2);
    ledSet(panel, 227, 18, 2);
    ledSet(panel, 243, 18, 18);
    ledSet(panel, 244, 19, 18);
    ledSet(panel, 262, 19, 0);
    ledSet(panel, 263, 20, 0);
    ledSet(panel, 282, 20, 19);
    ledSet(panel, 283, 21, 19);
    ledSet(panel, 302, 21, 0);
    ledSet(panel, 303, 22, 0);
    ledSet(panel, 323, 22, 20);
    ledSet(panel, 324, 23, 20);
    ledSet(panel, 344, 23, 0);
    ledSet(panel, 345, 24, 0);
    ledSet(panel, 365, 24, 20);
    ledSet(panel, 366, 25, 20);
    ledSet(panel, 386, 25, 0);
    ledSet(panel, 387, 26, 0);
    ledSet(panel, 408, 26, 21);
    ledSet(panel, 409, 27, 21);
    ledSet(panel, 430, 27, 0);
    ledSet(panel, 431, 28, 0);
    ledSet(panel, 452, 28, 21);
    ledSet(panel, 453, 29, 21);
    ledSet(panel, 475, 29, -1);
    ledSet(panel, 476, 30, -1);
    ledSet(panel, 499, 30, 22);
    ledSet(panel, 500, 31, 22);
    ledSet(panel, 523, 31, -1);
    ledSet(panel, 524, 32, -1);
    ledSet(panel, 547, 32, 22);
    ledSet(panel, 548, 33, 22);
    ledSet(panel, 571, 33, -1);
    ledSet(panel, 572, 34, -1);
    ledSet(panel, 596, 34, 23);
    ledSet(panel, 597, 35, 23);
    ledSet(panel, 621, 35, -1);
    ledSet(panel, 622, 36, -1);
    ledSet(panel, 646, 36, 23);
    ledSet(panel, 647, 37, 23);
    ledSet(panel, 671, 37, -1);
    ledSet(panel, 672, 38, -1);
    ledSet(panel, 698, 38, 25);
    ledSet(panel, 699, 39, 25);
    ledSet(panel, 725, 39, -1);
    ledSet(panel, 726, 40, -1);
    ledSet(panel, 752, 40, 25);
    ledSet(panel, 753, 41, 25);
    ledSet(panel, 779, 41, -1);
    ledSet(panel, 780, 42, -1);
    //TODO: disappeared
    
    ledSet(panel, 805, 42, 24);
    ledSet(panel, 806, 43, 24);
    ledSet(panel, 831, 43, -1);
    ledSet(panel, 832, 44, -1);
    ledSet(panel, 848, 44, 15);
  }
  
  // TODO: LED MAP 7
  void mapPassengerSideLower2(int panel) {
    assert (panel < getNumStrands());

    xOffsetter = 0;
    yOffsetter = 10;
    ordinalOffsetter = 0;
    
    ledSet(panel, 0, 44, 16);
    ledSet(panel, 8, 44, 24);
    ledSet(panel, 9, 45, 24);
    ledSet(panel, 34, 45, -1);
    ledSet(panel, 35, 46, -1);
    ledSet(panel, 59, 46, 23);
    ledSet(panel, 60, 47, 23);
    ledSet(panel, 83, 47, 0);
    ledSet(panel, 84, 48, 0);
    ledMissing(panel, 85);
    ledMissing(panel, 86);
    ledSet(panel, 87, 48, 2);
    ledSet(panel, 107, 48, 22);
    ledSet(panel, 108, 49, 22);
    ledSet(panel, 129, 49, 1);
    ledSet(panel, 130, 50, 1);
    ledSet(panel, 151, 50, 22);
    ledSet(panel, 152, 51, 22);
    ledSet(panel, 173, 51, 1);
    ledSet(panel, 174, 52, 1);
    ledSet(panel, 194, 52, 21);
    ledSet(panel, 195, 53, 21);
    ledSet(panel, 215, 53, 1);
    ledSet(panel, 216, 54, 1);
    ledSet(panel, 236, 54, 21);
    ledSet(panel, 237, 55, 21);
    ledSet(panel, 249, 55, 9);
  }
  
  // TODO: LED MAP 4
  void mapLowerHalfTopDriverSide(int panel) {
    assert (panel < getNumStrands());

    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledSet(panel, 0, 14, 31);
    ledSet(panel, 1, 15, 31);
    ledSet(panel, 3, 15, 33);
    ledSet(panel, 4, 14, 33);
    ledSet(panel, 5, 14, 32);
    ledSet(panel, 6, 13, 32);
    ledSet(panel, 8, 13, 34);
    ledSet(panel, 9, 12, 34);
    ledSet(panel, 11, 12, 32);
    ledSet(panel, 12, 11, 32);
    ledSet(panel, 15, 11, 35);
    ledSet(panel, 16, 10, 35);
    ledSet(panel, 19, 10, 32);
    ledSet(panel, 20, 9, 32);
    ledSet(panel, 24, 9, 36);
    ledSet(panel, 25, 8, 36);
    ledSet(panel, 29, 8, 32);
    ledSet(panel, 30, 7, 32);
    ledSet(panel, 35, 7, 37);
    ledSet(panel, 36, 6, 37);
    ledSet(panel, 41, 6, 32);
    ledSet(panel, 42, 5, 32);
    ledSet(panel, 47, 5, 37);
    for (int i = 48; i <= 63; i++) {
      ledMissing(panel, i);
    }
    ledSet(panel, 64, 0, 22);
    ledSet(panel, 65, 0, 23);
    ledMissing(panel, 66);
    ledSet(panel, 67, 1, 24);
    ledSet(panel, 69, 1, 22);
    ledSet(panel, 70, 2, 22);
    ledSet(panel, 75, 2, 27);
    ledSet(panel, 76, 3, 27);
    ledSet(panel, 82, 3, 21);
    ledSet(panel, 83, 4, 21);
    ledSet(panel, 93, 4, 31);
    ledSet(panel, 94, 5, 31);
    ledSet(panel, 98, 5, 27);
    ledMissing(panel, 99);
    ledSet(panel, 100, 5, 26);
    ledSet(panel, 107, 5, 19);
    ledSet(panel, 108, 6, 19);
    ledSet(panel, 120, 6, 31);
    ledSet(panel, 121, 7, 31);
    ledSet(panel, 135, 7, 17);
    ledSet(panel, 136, 8, 17);
    ledSet(panel, 150, 8, 31);
    ledSet(panel, 151, 9, 31);
    ledSet(panel, 170, 9, 12);
    ledSet(panel, 171, 10, 12);
    ledSet(panel, 190, 10, 31);
    ledSet(panel, 191, 11, 31);
    ledSet(panel, 214, 11, 8);
    ledSet(panel, 215, 12, 8);
    ledSet(panel, 238, 12, 31);
    ledSet(panel, 239, 13, 31);
    ledSet(panel, 262, 13, 8);
    ledSet(panel, 263, 14, 8);
    ledSet(panel, 285, 14, 30);
    ledSet(panel, 286, 15, 30);
    ledSet(panel, 295, 15, 21);
    ledSet(panel, 296, 16, 21);
    ledMissing(panel, 299);
    ledSet(panel, 306, 16, 31);
    ledSet(panel, 307, 17, 31);
    ledSet(panel, 316, 17, 22);
    ledSet(panel, 317, 18, 22);
    ledSet(panel, 326, 18, 31);
    ledSet(panel, 327, 19, 31);
    ledSet(panel, 336, 19, 22);
    ledSet(panel, 337, 20, 22);
    ledSet(panel, 346, 20, 31);
    ledSet(panel, 347, 21, 31);
    ledMissing(panel, 348);
    ledSet(panel, 360, 21, 18);
    ledSet(panel, 361, 22, 18);
    ledSet(panel, 374, 22, 31);
    ledSet(panel, 375, 23, 31);
    ledSet(panel, 393, 23, 13);
    ledSet(panel, 394, 24, 13);
    
    //strand starts at 397
    ledSet(panel, 413, 24, 32);
    ledSet(panel, 414, 25, 32);
    ledSet(panel, 432, 25, 14);
    ledSet(panel, 433, 26, 14);
    ledSet(panel, 451, 26, 32);
    ledSet(panel, 452, 27, 32);
    ledSet(panel, 461, 27, 23);
    ledSet(panel, 462, 28, 23);
    ledSet(panel, 471, 28, 32);
    ledSet(panel, 472, 29, 32);
    ledSet(panel, 482, 29, 22);
    ledSet(panel, 483, 30, 22);
    ledSet(panel, 493, 30, 32);
    ledSet(panel, 494, 31, 32);
    ledSet(panel, 505, 31, 21);
    ledSet(panel, 506, 32, 21);
    ledSet(panel, 517, 32, 32);
    ledSet(panel, 518, 33, 32);
    ledSet(panel, 531, 33, 19);
    ledSet(panel, 532, 34, 19);
    ledSet(panel, 543, 34, 30);
    ledSet(panel, 544, 35, 30);
    ledSet(panel, 556, 35, 18);
    ledSet(panel, 557, 36, 18);
    ledSet(panel, 569, 36, 30);
    ledSet(panel, 570, 37, 30);
    ledSet(panel, 584, 37, 16);
    ledSet(panel, 585, 38, 16);
    ledSet(panel, 599, 38, 30);
    ledSet(panel, 600, 39, 30);
    ledSet(panel, 614, 39, 16);
    ledSet(panel, 615, 40, 16);
    ledSet(panel, 629, 40, 30);
    ledSet(panel, 630, 41, 30);
    ledSet(panel, 644, 41, 16);
    ledSet(panel, 645, 42, 16);
    ledSet(panel, 659, 42, 30);
    ledSet(panel, 660, 43, 30);
    ledSet(panel, 674, 43, 16);
    ledSet(panel, 675, 44, 16);
    ledSet(panel, 688, 44, 29);
    ledSet(panel, 689, 45, 29);
    ledSet(panel, 701, 45, 17);
    ledSet(panel, 702, 46, 17);
    ledSet(panel, 713, 46, 28);
    ledSet(panel, 714, 47, 28);
    ledSet(panel, 725, 47, 17);
    ledSet(panel, 726, 48, 17);
    ledSet(panel, 737, 48, 28);
    ledSet(panel, 738, 49, 28);
    ledSet(panel, 747, 49, 19);
    ledSet(panel, 748, 50, 19);
    ledSet(panel, 757, 50, 28);
    ledSet(panel, 758, 51, 28);
    ledSet(panel, 768, 51, 18);
    ledSet(panel, 769, 52, 18);
    ledSet(panel, 779, 52, 28);
    ledSet(panel, 780, 53, 28);
    ledSet(panel, 792, 53, 16);
    ledSet(panel, 793, 54, 16);
    ledSet(panel, 805, 54, 28);
    ledSet(panel, 806, 55, 28);
    ledSet(panel, 817, 55, 17);
    ledSet(panel, 818, 56, 17);
    ledSet(panel, 829, 56, 28);
    ledSet(panel, 830, 57, 28);
    ledSet(panel, 840, 57, 18);
    ledSet(panel, 841, 58, 18);
    ledSet(panel, 851, 58, 28);
    ledSet(panel, 852, 59, 28);
    //possible split point
    ledSet(panel, 861, 59, 19);
    ledSet(panel, 862, 60, 19);
    ledSet(panel, 871, 60, 28);
    ledSet(panel, 872, 61, 28);
    ledSet(panel, 881, 61, 19);
    ledSet(panel, 882, 62, 19);
    ledSet(panel, 891, 62, 28);
    ledSet(panel, 892, 63, 28);
    ledSet(panel, 900, 63, 20);
    ledSet(panel, 901, 64, 20);
    ledSet(panel, 909, 64, 28);
    ledSet(panel, 910, 65, 28);
    ledSet(panel, 918, 65, 20);
    ledSet(panel, 919, 66, 20);
    ledSet(panel, 927, 66, 28);
    ledSet(panel, 928, 67, 28);
    ledSet(panel, 936, 67, 20);
    ledSet(panel, 937, 68, 20);
    ledSet(panel, 945, 68, 28);
    ledSet(panel, 946, 69, 28);
    ledSet(panel, 955, 69, 19);
    ledSet(panel, 956, 70, 19);
    ledSet(panel, 967, 70, 30);
    ledSet(panel, 968, 71, 30);
    ledSet(panel, 992, 71, 6);
    ledSet(panel, 993, 72, 6);
    ledSet(panel, 996, 72, 9);
  }
  
  // TODO: LED MAP 6
  void mapLowerHalfTopPassengerSide(int panel) {
    
    assert (panel < getNumStrands());
    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    //    all offsets=?
    ledSet(panel,  0, 0, 24);
    ledSet(panel,  1, 0, 23);
    ledSet(panel,  2, 1, 23);
    ledSet(panel,  7, 1, 28);
    ledSet(panel,  8, 2, 28);
    ledSet(panel,  14, 2, 22);
    ledSet(panel,  15, 3, 22);
    ledSet(panel,  31, 3, 38);
    ledSet(panel,  32, 4, 38);
    ledSet(panel,  51, 4, 19);
    ledSet(panel,  52, 5, 19);
    ledSet(panel,  70, 5, 37);
    ledSet(panel,  71, 6, 37);
    ledSet(panel,  97, 6, 11);
    ledSet(panel,  98, 7, 11);
    ledSet(panel,  123, 7, 36);
    ledSet(panel,  124, 8, 36);
    ledSet(panel,  152, 8, 8);
    ledSet(panel,  153, 9, 8);
    ledSet(panel,  180, 9, 35);
    ledSet(panel,  181, 10, 35);
    ledSet(panel,  209, 10, 7);
    ledSet(panel,  210, 11, 7);
    ledSet(panel,  238, 11, 35);
    ledSet(panel,  239, 12, 35);
    ledSet(panel,  253, 12, 21);
    ledSet(panel,  254, 13, 21);
    ledSet(panel,  264, 13, 31);
    ledSet(panel,  265, 14, 31);
    ledSet(panel,  274, 14, 22);
    ledSet(panel,  275, 15, 22);
    ledSet(panel,  283, 15, 30);
    ledSet(panel,  284, 16, 30);
    ledSet(panel,  292, 16, 22);
    ledSet(panel,  293, 17, 22);
    ledSet(panel,  301, 17, 30);
    ledSet(panel,  302, 18, 30);
    ledSet(panel,  310, 18, 22);
    ledSet(panel,  311, 19, 22);
    ledSet(panel,  320, 19, 31);
    ledSet(panel,  321, 20, 31);
    ledSet(panel,  336, 20, 16);
    ledSet(panel,  337, 21, 16);
    ledMissing(panel, 349);
    ledSet(panel, 350, 21, 28);
    ledSet(panel,  353, 21, 31);
    ledSet(panel,  354, 22, 31);
    ledSet(panel,  369, 22, 16);
    ledSet(panel,  370, 23, 16);
    ledSet(panel,  385, 23, 31);
    ledSet(panel,  386, 24, 31);
    ledSet(panel,  399, 24, 18);
    ledSet(panel,  400, 25, 18);
    ledSet(panel,  413, 25, 31);
    ledSet(panel,  414, 26, 31);
    ledSet(panel,  423, 26, 22);
    ledSet(panel,  424, 27, 22);
    ledSet(panel,  433, 27, 31);
    ledSet(panel,  434, 28, 31);
    ledSet(panel,  442, 28, 23);
    ledSet(panel,  443, 29, 23);
    ledSet(panel,  451, 29, 31);
    ledSet(panel,  452, 30, 31);
    ledSet(panel,  459, 30, 24);
    ledSet(panel,  460, 31, 24);
    ledSet(panel,  467, 31, 31);
    ledSet(panel,  468, 32, 31);
    ledSet(panel,  484, 32, 15);
    ledSet(panel,  485, 33, 15);
    ledSet(panel,  501, 33, 31);
    ledSet(panel,  502, 34, 31);
    ledSet(panel,  518, 34, 15);
    ledSet(panel,  519, 35, 15);
    ledSet(panel,  535, 35, 31);
    ledSet(panel,  536, 36, 31);
    ledSet(panel,  552, 36, 15);
    ledSet(panel,  553, 37, 15);
    ledSet(panel,  569, 37, 31);
    ledMissing(panel, 570);
    ledMissing(panel, 571);
    ledSet(panel,  572, 38, 15);
    ledSet(panel,  588, 38, 31);
    ledSet(panel,  589, 39, 31);
    ledSet(panel,  605, 39, 15);
    ledSet(panel,  606, 40, 15);
    ledSet(panel,  622, 40, 31);
    ledSet(panel,  623, 41, 31);
    ledSet(panel,  636, 41, 18);
    ledSet(panel,  637, 42, 18);
    ledSet(panel,  650, 42, 31);
    ledSet(panel,  651, 43, 31);
    ledSet(panel,  661, 43, 21);
    ledSet(panel,  662, 44, 21);
    ledSet(panel,  672, 44, 31);
    ledSet(panel,  673, 45, 31);
    ledSet(panel,  683, 45, 21);
    ledSet(panel,  684, 46, 21);
    ledSet(panel,  694, 46, 31);
    ledSet(panel,  695, 47, 31);
    ledSet(panel,  709, 47, 17);
    ledSet(panel,  710, 48, 17);
    ledSet(panel,  724, 48, 31);
    ledSet(panel,  725, 49, 31);
    ledSet(panel,  740, 49, 16);
    ledSet(panel,  741, 50, 16);
    ledSet(panel,  754, 50, 29);
    ledSet(panel,  755, 51, 29);
    ledSet(panel,  768, 51, 16);
    ledSet(panel,  769, 52, 16);
    ledSet(panel,  782, 52, 29);
    ledSet(panel,  783, 53, 29);
    
    //TODO: messed up?
    
    ledSet(panel,  796, 53, 16);
    ledSet(panel,  797, 54, 16);
    ledSet(panel,  810, 54, 29);
    ledSet(panel,  811, 55, 29);
    ledSet(panel,  824, 55, 16);
    ledSet(panel,  825, 56, 16);
    ledSet(panel,  838, 56, 29);
    ledSet(panel,  839, 57, 29);
    ledSet(panel,  851, 57, 17);
    ledSet(panel,  852, 58, 17);
    ledSet(panel,  864, 58, 29);
    ledSet(panel,  865, 59, 29);
    ledSet(panel,  875, 59, 19);
    ledSet(panel,  876, 60, 19);
    ledSet(panel,  886, 60, 29);
    ledSet(panel,  887, 61, 29);
    ledSet(panel,  895, 61, 21);
    ledSet(panel,  896, 62, 21);
    ledSet(panel,  904, 62, 29);
    ledSet(panel,  905, 63, 29);
    ledSet(panel,  912, 63, 22);
    ledSet(panel,  913, 64, 22);
    ledSet(panel,  920, 64, 29);
    ledSet(panel,  921, 65, 29);
    ledSet(panel,  929, 65, 21);
    ledSet(panel,  930, 66, 21);
    ledSet(panel,  938, 66, 29);
    ledSet(panel,  939, 67, 29);
    ledSet(panel,  961, 67, 7);
    ledSet(panel,  962, 68, 7);
    ledSet(panel,  972, 68, 17);
  }
  
  // TODO: LED MAP 1
  void mapUpperHalfTopDriverSide(int panel) {
    assert (panel < getNumStrands());

    //top of top driver side
    xOffsetter = 15;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledSet(panel, 0, 0, 6);
    ledSet(panel, 3, 0, 9);
    ledSet(panel, 4, 0, 11);
    ledSet(panel, 5, 0, 13);
    ledSet(panel, 8, 0, 16);
    ledSet(panel, 9, 1, 16);
    ledSet(panel, 12, 1, 13);
    ledSet(panel, 13, 1, 11);
    ledSet(panel, 14, 1, 9);
    ledSet(panel, 18, 1, 5);
    ledSet(panel, 19, 2, 5);
    ledSet(panel, 24, 2, 10);
    ledSet(panel, 25, 2, 12);
    ledSet(panel, 28, 2, 15);
    ledSet(panel, 29, 3, 14);
    ledSet(panel, 30, 3, 13);
    ledSet(panel, 31, 3, 12);
    ledSet(panel, 32, 3, 11);
    ledSet(panel, 38, 3, 5);
    ledSet(panel, 39, 4, 5);
    ledSet(panel, 46, 4, 12);
    ledSet(panel, 47, 5, 12);
    ledSet(panel, 55, 5, 4);
    ledSet(panel, 56, 6, 4);
    ledSet(panel, 63, 6, 11);
    ledSet(panel, 64, 7, 11);
    ledSet(panel, 71, 7, 4);
    ledSet(panel, 72, 8, 4);
    ledSet(panel, 80, 8, 12);
    ledSet(panel, 81, 9, 12);
    ledSet(panel, 89, 9, 4);
    ledSet(panel, 90, 10, 4);
    ledSet(panel, 99, 10, 13);
    ledSet(panel, 100, 11, 13);
    ledSet(panel, 111, 11, 2);
    ledSet(panel, 112, 12, 2);
    ledSet(panel, 123, 12, 13);
    ledSet(panel, 124, 13, 13);
    ledSet(panel, 136, 13, 1);
    ledSet(panel, 137, 14, 1);
    ledSet(panel, 149, 14, 13);
    ledSet(panel, 150, 15, 13);
    ledSet(panel, 162, 15, 1);
    ledSet(panel, 163, 16, 1);
    ledSet(panel, 176, 16, 14);
    ledSet(panel, 177, 17, 14);
    ledSet(panel, 191, 17, 0);
    ledSet(panel, 192, 18, 0);
    ledSet(panel, 207, 18, 15);
    ledSet(panel, 208, 19, 15);
    ledSet(panel, 223, 19, 0);
    ledSet(panel, 224, 20, 0);
    ledSet(panel, 241, 20, 17);
    ledSet(panel, 242, 21, 17);
    ledSet(panel, 259, 21, 0);
    ledSet(panel, 260, 22, 0);
    ledSet(panel, 275, 22, 15);
    ledSet(panel, 276, 23, 15);
    ledSet(panel, 291, 23, 0);
    ledSet(panel, 292, 24, 0);
    ledSet(panel, 307, 24, 15);
    ledSet(panel, 308, 25, 15);
    ledSet(panel, 323, 25, 0);
    ledSet(panel, 324, 26, 0);
    ledSet(panel, 339, 26, 15);
    ledSet(panel, 340, 27, 15);
    ledSet(panel, 355, 27, 0);
    ledSet(panel, 356, 28, 0);
    ledSet(panel, 371, 28, 15);
    ledSet(panel, 372, 29, 15);
    ledSet(panel, 387, 29, 0);
    ledSet(panel, 388, 30, 0);
    //note: 400 has double
    ledSet(panel, 399, 30, 11);
    ledMissing(panel, 400);
    ledMissing(panel, 401);
    ledSet(panel, 402, 30, 12);
    ledSet(panel, 406, 30, 16);
    ledSet(panel, 407, 31, 16);
    ledSet(panel, 423, 31, 0);
    ledSet(panel, 424, 32, 0);
    ledSet(panel, 435, 32, 11);
    ledSet(panel, 436, 33, 11);
    ledSet(panel, 447, 33, 0);
    ledSet(panel, 448, 34, 0);
    ledSet(panel, 459, 34, 11);
    ledSet(panel, 460, 35, 11);
    //460 on double mesh
    ledSet(panel, 471, 35, 0);
    ledSet(panel, 472, 36, 0);
    ledSet(panel, 483, 36, 11);
    ledSet(panel, 484, 37, 11);
    ledSet(panel, 495, 37, 0);
    ledSet(panel, 496, 38, 1);
    //500 is final light of strand
    ledSet(panel, 508, 38, 13);
    ledSet(panel, 509, 39, 13);
    ledSet(panel, 521, 39, 1);
    ledSet(panel, 522, 40, 1);
    ledSet(panel, 537, 40, 16);
    ledSet(panel, 538, 41, 16);
    ledSet(panel, 553, 41, 1);
    ledSet(panel, 554, 42, 1);
    ledSet(panel, 570, 42, 17);
    ledSet(panel, 571, 43, 17);
    ledSet(panel, 587, 43, 1);
    ledSet(panel, 588, 44, 1);
    ledSet(panel, 605, 44, 18);
    ledSet(panel, 606, 45, 18);
    ledSet(panel, 622, 45, 2);
    ledSet(panel, 623, 46, 2);
    ledSet(panel, 632, 46, 11);
    ledSet(panel, 633, 47, 11);
    ledSet(panel, 641, 47, 3);
    ledSet(panel, 642, 48, 3);
    ledSet(panel, 650, 48, 11);
    ledSet(panel, 651, 49, 10);
    ledSet(panel, 658, 49, 3);
    ledSet(panel, 659, 50, 4);
    ledSet(panel, 666, 50, 11);
    ledSet(panel, 667, 51, 11);
    ledSet(panel, 674, 51, 4);
    ledSet(panel, 675, 52, 5);
    ledSet(panel, 681, 52, 11);
    ledMissing(panel, 682);
    ledMissing(panel, 683);
    ledMissing(panel, 684);
    ledMissing(panel, 685);
    ledSet(panel, 686, 54, 7);
    ledSet(panel, 692, 54, 13);
    ledSet(panel, 693, 55, 13);
    ledSet(panel, 700, 55, 6);
    ledSet(panel, 701, 57, 10);
    ledSet(panel,  720, 57, 29);
    ledSet(panel,  721, 58, 29);
    ledSet(panel,  743, 58, 7);
    ledSet(panel,  744, 59, 7);
    ledSet(panel,  765, 59, 28);
    ledSet(panel,  766, 60, 28);
    ledSet(panel,  786, 60, 8);
    ledSet(panel,  787, 61, 8);
    ledSet(panel,  807, 61, 27);
    ledSet(panel,  808, 62, 27);
    ledSet(panel,  826, 62, 10);
    ledSet(panel,  827, 63, 10);
    ledSet(panel,  845, 63, 28);
    ledSet(panel,  846, 64, 28);
    ledSet(panel,  863, 64, 11);
    ledSet(panel,  864, 65, 11);
    ledSet(panel,  883, 65, 30);
    ledSet(panel,  884, 66, 30);
    ledSet(panel,  902, 66, 12);
    ledSet(panel,  903, 67, 12);
    ledSet(panel,  920, 67, 29);
    ledSet(panel,  921, 68, 29);
    ledSet(panel,  936, 68, 14);
    ledSet(panel,  937, 69, 14);
    ledSet(panel,  950, 69, 27);
    ledSet(panel,  951, 70, 27);
    ledSet(panel,  962, 70, 16);
    ledSet(panel,  963, 71, 16);
    ledSet(panel,  973, 71, 26);
    ledSet(panel,  974, 72, 26);
    ledSet(panel,  982, 72, 18);
    ledSet(panel,  983, 73, 18);
    ledSet(panel,  989, 73, 24);
    ledSet(panel,  990, 74, 24);
    ledSet(panel,  994, 74, 20);
    ledSet(panel,  995, 75, 20);
    ledSet(panel,  998, 75, 23);
    ledSet(panel,  999, 76, 23);
    ledSet(panel,  1000, 76, 22);
  }
  
  // TODO: LED MAP 5
  void mapPassengerSideUpperTop1(int panel) {
    assert (panel < getNumStrands());
    
    //top of top driver side
    xOffsetter = 0;
    yOffsetter = 0;
    ordinalOffsetter = 0;
    
    ledMissing(panel, 0);
    ledMissing(panel, 1);
    ledMissing(panel, 2);
    
    ledSet(panel, 3, 14, 4);
    ledSet(panel, 4, 13, 4);
    ledSet(panel, 5, 12, 5);
    ledSet(panel, 16, 12, 16);
    ledSet(panel, 17, 13, 16);
    ledSet(panel, 29, 13, 5);
    ledSet(panel, 30, 14, 5);
    ledSet(panel, 41, 14, 16);
    ledSet(panel, 42, 15, 16);
    ledSet(panel, 54, 15, 4);
    ledSet(panel, 55, 16, 4);
    ledSet(panel, 66, 16, 15);
    ledSet(panel, 67, 17, 15);
    ledSet(panel, 78, 17, 4);
    ledSet(panel, 79, 18, 3);
    ledSet(panel, 91, 18, 15);
    ledSet(panel, 92, 19, 15);
    ledSet(panel, 106, 19, 1);
    ledSet(panel, 107, 20, 1);
    ledSet(panel, 121, 20, 15);
    ledSet(panel, 122, 21, 15);
    ledSet(panel, 136, 21, 1);
    ledSet(panel, 137, 22, 1);
    ledSet(panel, 151, 22, 15);
    ledSet(panel, 152, 23, 15);
    ledSet(panel, 166, 23, 1);
    ledSet(panel, 167, 24, 1);
    ledSet(panel, 183, 24, 17);
    ledSet(panel, 184, 25, 17);
    ledSet(panel, 200, 25, 1);
    ledSet(panel, 201, 26, 1);
    ledSet(panel, 217, 26, 17);
    ledSet(panel, 218, 27, 17);
    ledSet(panel, 235, 27, 0);
    ledSet(panel, 236, 28, 0);
    ledSet(panel, 252, 28, 16);
    ledSet(panel, 253, 29, 16);
    ledSet(panel, 269, 29, 0);
    ledSet(panel, 270, 30, 0);
    ledSet(panel, 285, 30, 15);
    ledSet(panel, 286, 31, 15);
    ledSet(panel, 301, 31, 0);
    ledSet(panel, 302, 32, 0);
    ledSet(panel, 316, 32, 14);
    ledSet(panel, 317, 33, 14);
    ledSet(panel, 331, 33, 0);
    ledSet(panel, 332, 34, 0);
    ledSet(panel, 346, 34, 14);
    ledSet(panel, 347, 35, 14);
    ledSet(panel, 361, 35, 0);
    ledSet(panel, 362, 36, 0);
    ledSet(panel, 376, 36, 14);
    ledSet(panel, 377, 37, 14);
    ledSet(panel, 391, 37, 0);
    ledSet(panel, 392, 38, 0);
    ledSet(panel, 406, 38, 14);
    ledSet(panel, 407, 39, 14);
    ledSet(panel, 421, 39, 0);
    ledSet(panel, 422, 40, 0);
    ledSet(panel, 436, 40, 14);
    ledSet(panel, 437, 41, 14);
    ledSet(panel, 451, 41, 0);
    ledSet(panel, 452, 42, 0);
    ledSet(panel, 467, 42, 15);
    ledSet(panel, 468, 43, 15);
    ledSet(panel, 483, 43, 0);
    ledSet(panel, 484, 44, 0);
    ledSet(panel, 498, 44, 14);
    ledSet(panel, 499, 45, 14);
    
    //TODO: disappear?
    ledSet(panel, 513, 45, 0);
    ledSet(panel, 514, 46, 0);
    ledSet(panel, 528, 46, 14);
    ledSet(panel, 529, 47, 14);
    ledSet(panel, 542, 47, 1);
    ledSet(panel, 543, 48, 1);
    ledSet(panel, 557, 48, 15);
    ledSet(panel, 558, 49, 15);
    ledSet(panel, 573, 49, 1);
    ledSet(panel, 574, 50, 1);
    ledSet(panel, 587, 50, 15);
    ledSet(panel, 588, 51, 15);
    ledSet(panel, 602, 51, 1);
    ledSet(panel, 603, 52, 1);
    ledSet(panel, 617, 52, 15);
    ledSet(panel, 618, 53, 15);
    ledSet(panel, 631, 53, 2);
    ledSet(panel, 632, 54, 2);
    ledSet(panel, 645, 54, 15);
    ledSet(panel, 646, 55, 15);
    ledSet(panel, 658, 55, 3);
    ledSet(panel, 659, 56, 3);
    ledSet(panel, 671, 56, 15);
    ledSet(panel, 672, 57, 15);
    ledSet(panel, 684, 57, 3);
    ledSet(panel, 685, 58, 3);
    
    ledSet(panel, 697, 58, 15);
    ledMissing(panel, 698);
    ledSet(panel, 699, 59, 14);
    ledSet(panel, 710, 59, 3);
    ledSet(panel, 711, 60, 4);
    ledSet(panel, 719, 60, 12);
    ledSet(panel, 720, 61, 12);
    ledSet(panel, 728, 61, 4);
    ledSet(panel, 729, 62, 4);
    ledSet(panel, 735, 62, 10);
    ledSet(panel, 736, 63, 10);
    ledSet(panel, 741, 63, 5);
    ledSet(panel, 742, 64, 5);
    ledSet(panel, 749, 64, 12);
    ledSet(panel, 750, 65, 12);
    ledSet(panel, 756, 65, 6);
    for (int i = 757; i < 774; i++) {
      ledMissing(panel, i);
    }
    
    ledSet(panel, 774, 67, 18);
    ledSet(panel, 785, 67, 29);
    ledSet(panel, 786, 68, 29);
    ledSet(panel, 807, 68, 8);
    ledSet(panel, 808, 69, 8);
    
    
    ledSet(panel, 831, 69, 31);
    ledSet(panel, 832, 70, 31);
    ledSet(panel, 854, 70, 9);
    ledSet(panel, 855, 71, 9);
    ledSet(panel, 877, 71, 31);
    ledSet(panel, 878, 72, 31);
    ledSet(panel, 898, 72, 11);
    ledSet(panel, 899, 73, 11);
    ledSet(panel, 918, 73, 30);
    ledSet(panel, 919, 74, 30);
    ledSet(panel, 937, 74, 12);
    ledSet(panel, 938, 75, 12);
    ledSet(panel, 957, 75, 31);
    ledSet(panel, 958, 76, 31);
    ledSet(panel, 976, 76, 13);
    ledSet(panel, 977, 77, 13);
    ledSet(panel, 995, 77, 31);
    ledSet(panel, 996, 78, 31);
    ledSet(panel, 1012, 78, 15);
    ledSet(panel, 1013, 79, 15);
    ledSet(panel, 1029, 79, 31);
    ledSet(panel, 1030, 80, 31);
    ledSet(panel, 1045, 80, 16);
    ledSet(panel, 1046, 81, 16);
    ledSet(panel, 1061, 81, 31);
    ledSet(panel, 1062, 82, 31);
    ledSet(panel, 1076, 82, 17);
    ledSet(panel, 1077, 83, 17);
    ledSet(panel, 1091, 83, 31);
    ledSet(panel, 1092, 84, 31);
    ledSet(panel, 1104, 84, 19);
    ledSet(panel, 1105, 85, 19);
    ledSet(panel, 1116, 85, 30);
    ledSet(panel, 1117, 86, 30);
    ledSet(panel, 1127, 86, 20);
    ledSet(panel, 1128, 87, 20);
    ledSet(panel, 1137, 87, 29);
    ledSet(panel, 1138, 88, 29);
    ledSet(panel, 1145, 88, 22);
    ledSet(panel, 1146, 89, 22);
    ledSet(panel, 1153, 89, 29);
    for (int i = 1154; i <= 1174; i++) {
      ledMissing(panel, i);
    }
  }
  
  int getStrandSize(int whichStrand) {
    return strandSizes[whichStrand];
  }
  
  int getNumStrands() {
    return 8;
  }
  
  ////////////////////////////////////////////////////////////////////
  //Total Control
  
  /*
   spreadsheet
   
   for each led:
   which strand, offset x, y, which shape
   
   strand1:
   1: 3, 10, shapeA
   2: 16, 10, shapeA
   3: 55, 9, shapeB
   4: unused
   3: 59, 49, shapeB
   
   strand2:
   1: 77, 14, shapeA
   2: 46, 98, shapeA
   3: 3, 12, shapeB
   
   */
  
  
  /*
   ..    00      01      02      03      04      05      06      07      08      09      10
   00    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   01    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   02    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   03    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   04    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   05    xx      xx      xx      xx      xx      xx      xx      xx      xx      xx      xx
   
   ..   00      01      02      03      04      05      06      07      08      09      10      11      12      13      14
   sA: (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sB  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   sC  (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00) (00,00)
   
   
   */
  
  //convert coordinates into index into pixel array index
  private int c2i(int x, int y) {
    return (y*ledWidth) + x;
  }
  
  private Point i2c(int index) {
    Point p = new Point();
    p.y = index / ledWidth;
    p.x = index % ledWidth;
    return p;
  }
  
  void ledSetRawValue(int whichStrand, int ordinal, int value) {
    assert(whichStrand < getNumStrands()) : "not this many strands";
    assert(ordinal < getStrandSize(whichStrand)) : "whichStrand exceeds number of leds per strand";
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    strandMap[index] = value;
    
  }
  
  void ledRawSet(int whichStrand, int ordinal, int x, int y) {
    int value = c2i(x, y);
    ledSetRawValue(whichStrand, ordinal, value);
  }
  
  void ledSetValue(int whichStrand, int ordinal, int value) {
    assert(whichStrand < getNumStrands()) : "not this many strands";
    assert(ordinal < getStrandSize(whichStrand)) : "" + ordinal + " exceeds number of leds per strand " + getStrandSize(whichStrand) + " on strand " + whichStrand;
    assert(ordinal < getStrandSize(whichStrand)) : "Cannot set LED " + ordinal + " on strand " + whichStrand +
    " because it is of length " + getStrandSize(whichStrand);
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    assert(strandMap[index] == TC_PIXEL_UNDEFINED) : "led " + ordinal + " on strand " + whichStrand + " is already defined: " + strandMap[index];
    strandMap[index] = value;
  }
  
  void ledMissing(int whichStrand, int ordinal) {
    ledSetValue(whichStrand, ordinal, TC_PIXEL_UNUSED);
  }
  
  int xOffsetter;
  int yOffsetter;
  int ordinalOffsetter;
  
  int lowestX = Integer.MAX_VALUE;
  int lowestY = Integer.MAX_VALUE;
  int biggestX = Integer.MIN_VALUE;
  int biggestY = Integer.MIN_VALUE;
  
  void ledSet(int whichStrand, int ordinal, int x, int y) {
    //    ledSetValue(whichStrand, ordinal, c2i(x, y+20));
    int newX = x + xOffsetter;
    int newY = y + yOffsetter;
    
    lowestX = min(newX, lowestX);
    lowestY = min(newY, lowestY);
    biggestX = max(newX, biggestX);
    biggestY = max(newY, biggestY);
    ledSetValue(whichStrand, ordinal + ordinalOffsetter, c2i(newX, newY));
  }
  
  int ledGetRawValue(int whichStrand, int ordinal, boolean useTrainingMode) {
    assert whichStrand < getNumStrands() : "not this many strands";
    assert ordinal < getStrandSize(whichStrand) : "ordinal exceeds number of leds per strand";
    int[] map = useTrainingMode?trainingStrandMap:strandMap;
    int index = (whichStrand * maxPixelsPerStrand) + ordinal;
    assert index < map.length : "strand: " + whichStrand + " ordinal: " + ordinal + " goes beyond end of map (" + index + " >= " + map.length + ")";
    int value = map[index];
    return value;
  }
  
  Point ledGet(int whichStrand, int ordinal, boolean useTrainingMode) {
    int value = ledGetRawValue(whichStrand, ordinal, useTrainingMode);
    if (value < 0) {
      return new Point(-1, -1);
    }
    return i2c(value);
  }
  
  Point ledGet(int whichStrand, int ordinal) {
    return ledGet(whichStrand, ordinal, main.currentMode().isTrainingMode());
  }
  
  void ledInterpolate() {
    int available = 0;
    
    for (int strand = 0; strand < getNumStrands(); strand++) {
      int start = strand * maxPixelsPerStrand;
      int lastIndexWithCoord = -1;
      available = 0;
      int strandSize = getStrandSize(strand);
      for (int i = start; i < start + strandSize; i++) {
        int value = strandMap[i];
        if (value == TC_PIXEL_UNDEFINED) {
          available++;
        }
        else if (value >= 0) {
          
          if (lastIndexWithCoord < 0) {
            
          }
          else {
            Point a = i2c(strandMap[lastIndexWithCoord]);
            Point b = i2c(value);
            int writable = abs(b.y - a.y) + abs(b.x - a.x) - 1;
            //println ("writable(" + writable + ") = abs(" + b.y + " - " + a.y + ") + abs(" + b.x + " - " + a.x + ")");
            
            if (writable == available) {
              if (!(a.x != b.x && a.y != b.y)) {
                
                int xChange = 0;
                int yChange = 0;
                if (b.x > a.x)
                  xChange = 1;
                else if (b.x < a.x)
                  xChange = -1;
                if (b.y > a.y)
                  yChange = 1;
                else if (b.y < a.y)
                  yChange = -1;
                
                int inc = 0;
                for (int j = lastIndexWithCoord + 1; j < i; j++) {
                  int jVal = strandMap[j];
                  if (jVal == TC_PIXEL_UNDEFINED) {
                    inc++;
                    int x = a.x + inc * xChange;
                    int y = a.y + inc * yChange;
                    strandMap[j] = c2i(x, y);
                    
                  }
                }
              }
            }
          }
          lastIndexWithCoord = i;
          available = 0;
        }
      }
    }
  }
  
  void ledMapDump(int minStrand, int maxStrand) {
    if (maxStrand < minStrand) {
      return;
    }
    
    assert(minStrand < getNumStrands());
    assert(maxStrand < getNumStrands());
    
    for (int whichStrand = minStrand; whichStrand <= maxStrand; whichStrand++) {
      int minX = 10000;
      int minY = 10000;
      int maxX = -10000;
      int maxY = -10000;
      
      println ("strand " + whichStrand);
      int strandSize = getStrandSize(whichStrand);
      StringBuilder s = new StringBuilder(200);
      
      int start = whichStrand  * maxPixelsPerStrand;
      for (int ordinal = 0; ordinal < strandSize; ordinal++) {
        int index = ordinal + start;
        if ((ordinal % 10) == 0)
        {
          println(s);
          s = new StringBuilder(200);
        }
        s.append(String.format(" %04d:", ordinal));
        int value = strandMap[index];
        if (value == TC_PIXEL_DISCONNECTED) {
          s.append(" DISC  ");
        } else if (value == TC_PIXEL_UNUSED) {
          s.append("UNUSED ");
        } else if (value == TC_PIXEL_UNDEFINED) {
          s.append("(??,??)");
        }
        else {
          assert (value >= 0) : "can't print unrecognized value " + value;
          Point p = i2c(value);
          s.append(String.format("(%02d,%02d) ", p.x, p.y));
          minX = min(minX, p.x);
          minY = min(minY, p.y);
          maxX = max(maxX, p.x);
          maxY = max(maxY, p.y);
        }
      }
      s.append("\n");
      println(s);
      println("min (" + minX + ", " + minY + ") max ("  + maxX + ", " + maxY + ")");
    }
  }
  
  
  boolean isStrandPortSide(int whichStrand) {
    return whichStrand < getNumStrands() / 2;
  }
  
  Point[] pointsForStrand(int whichStrand) {
    assert whichStrand < getNumStrands();
    int strandSize = getStrandSize(whichStrand);
    ArrayList<Point> points = new ArrayList<Point>();
    int start = whichStrand * maxPixelsPerStrand;
    for (int ordinal = 0; ordinal < strandSize; ordinal++) {
      int index = ordinal + start;
      int value = strandMap[index];
      if (value >= 0) {
        Point p = i2c(value);
        points.add(p);
      }
    }
    return (Point[]) points.toArray(new Point[0]);
  }
  
  TotalControlConcurrent totalControlConcurrent;
  boolean hardwareAlreadySetup = false;
  
  void initTotalControl() {
    int stealPixel = 0;
    int boundary = 0;
    //create the trainingStrandMap
    for (int whichStrand = 0; whichStrand < getNumStrands(); whichStrand++) {
      int numPixels = getStrandSize(whichStrand);
      int start = 0;
      if (true) {
        start = whichStrand * maxPixelsPerStrand;
        boundary = start + numPixels;
      }
      else {
        start = boundary;
        boundary = start + numPixels;
      }
      int j;
      for (j = start; j < boundary; j++) {
        strandMap[j] = TC_PIXEL_UNDEFINED;
        trainingStrandMap[j] = stealPixel++;
        Point tester = i2c(trainingStrandMap[j]);
        assert(tester.x < ledWidth && trainingStrandMap[j] < pixelData.length) : "Strands have more LEDs than we have pixels to assign them\n" + " x:" + tester.x + " y:" + tester.y + " strand: " + whichStrand + " ordinal:" + (j-start) + " rawValue:" + trainingStrandMap[j];
        
      }
      if (true) {
        int end = start + maxPixelsPerStrand;
        for (; j < end; j++) {
          strandMap[j] = TC_PIXEL_DISCONNECTED;
          trainingStrandMap[j] = TC_PIXEL_DISCONNECTED;
        }
      }
    }
    
    if (false) {
      mapUpperHalfTopDriverSide(0);
      mapDriverSideLowerPart2(1);
      mapDriverSideLowerPart1(2);
      mapLowerHalfTopDriverSide(3);
      
      mapPassengerSideUpperTop1(4);
      mapLowerHalfTopPassengerSide(5);
      mapPassengerSideLower2(6);
      mapPassengerSideLower1(7);
      
      if (true) {
        for (int i = 0; i < getNumStrands(); i++) {
          writeOneStrand(i);
        }
      }
    }
    else {
      for (int i = 0; i < getNumStrands(); i++) {
        readOneStrand(i);
      }
    }
    
    ledInterpolate();
//    ledMapDump(2, 7); //set which strands you want to dump
    
    println("" + lowestX + " <= x <= " + biggestX + ", " + lowestY + " <= y <= " + biggestY);
    assert(lowestX == 0): "lowest LED should be X == 0";
    assert(lowestY == 0): "lowest LED should be Y == 0";
    assert((biggestX + 1) * 2 == ledWidth): "biggest LED should be X == " + ledWidth;
    assert(biggestY + 1 == ledHeight): "biggest LED should be Y == " + ledHeight;
    
    if (!useTotalControlHardware) {
      return;
    }
    
    hardwareAlreadySetup = true;
    
    if (runConcurrent) {
      totalControlConcurrent = new TotalControlConcurrent(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
    }
    else {
      int status = setupTotalControl(getNumStrands(), maxPixelsPerStrand, kUseBitBang);
      if (status != 0) {
        //useTotalControlHardware = false;
        //println("turning off Total Control because of error during initialization");
      }
    }
  }
  
  // This function loads the screen-buffer and sends it to the TotalControl p9813 driver
  void drawToLeds() {
    if (!useTotalControlHardware) {
      return;
    }
    
    if (!hardwareAlreadySetup) {
      initTotalControl();
    }
    
    int[] theStrandMap = main.currentMode().isTrainingMode()?trainingStrandMap:strandMap;
    color[] thePixelData = pixelData;
    //println("sending pixelData: " + pixelData.length + " strandMap: " + theStrandMap.length);
    if (runConcurrent) {
      totalControlConcurrent.put(thePixelData, theStrandMap);
    }
    else {
      int status = writeOneFrame(thePixelData, theStrandMap);
    }
  }
}