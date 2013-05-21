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
  private Table[] strandTables;

  static final String kCommandOffsetter = "offsetter";
  static final String kCommandMap = "map";
  static final String kCommandMissing = "missing";
  static final String kCommandUnprogrammed = "unprogrammed";
  
  static final String kColumnCommand = "command";
  static final String kColumnOrdinal = "ordinalStart";
  static final String kColumnOrdinalEnd = "ordinalEnd";
  static final String kColumnCoordX = "x";
  static final String kColumnCoordY = "y";
  
  LedMap() {
    strandSizes = new int[8];
    
    strandTables = new Table[getNumStrands()];
    int totalPixels = 0;
    maxPixelsPerStrand = 0;
    for (int i = 0; i < getNumStrands(); i++) {
      
      Table table = loadTable(fileNameForStrand(i), "header");
      strandTables[i] = table;
      TableRow lastRow = table.getRow(table.lastRowIndex());
      strandSizes[i] = lastRow.getInt(kColumnOrdinalEnd) + 1;
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
  
  void writeOneStrand(int whichStrand) {
    println("================== writeOneStrand " + (whichStrand + 1));
    
    int strandSize = getStrandSize(whichStrand);
    Table table = new Table();
    table.addColumn(kColumnCommand, Table.STRING);
    table.addColumn(kColumnOrdinal, Table.INT);
    table.addColumn(kColumnOrdinalEnd, Table.INT);
    table.addColumn(kColumnCoordX, Table.INT);
    table.addColumn(kColumnCoordY, Table.INT);
    
    TableRow row = null;
    
    for (int whichLed = 0; whichLed < strandSize; whichLed++) {
      
      int value = ledGetRawValue(whichStrand, whichLed, false); // TODO: just pull it out directly for faster performance
      if (value >= 0) {
        Point p = i2c(value);
        // TODO: this can probably be cleaned up to not have so many else row = null statements. 
        if (row != null) {
          if (!row.getString(kColumnCommand).equals(kCommandMap)) {
            row = null;
          }
          else {
            int ordinalEnd = row.getInt(kColumnOrdinalEnd);
            if (ordinalEnd + 1 != whichLed) {
              row = null;
            }
            else {
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
                  }
                }
                else {
                  row = null;
                }
              }
              else {
                row = null;
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
    
    Table table = strandTables[whichStrand];
    
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
  
  int getStrandSize(int whichStrand) {
    int result = strandSizes[whichStrand];
    assert result >= 0 : "strand " + (whichStrand + 1) + "size = " + result;
    return result;
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
    
    for (int i = 0; i < getNumStrands(); i++) {
      readOneStrand(i);
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