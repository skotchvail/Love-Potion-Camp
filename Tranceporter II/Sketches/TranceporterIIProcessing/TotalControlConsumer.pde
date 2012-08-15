import TotalControl.*;

/*
 Writes to the p9813 on a separate thread to increase our frame rate
 */

class TotalControlConcurrent implements Runnable {
  private PixelDataAndMapQueue q;
  private int lastError;
  private int numStrands;
  private int pixelsPerStrand;
  private int lastStat;
  
  TotalControlConcurrent(int numStrands, int pixelsPerStrand) {
    this.numStrands = numStrands;
    this.pixelsPerStrand = pixelsPerStrand;
    q = new PixelDataAndMapQueue();
    
    new Thread(this, "TotalControlConcurrent").start();
  }
  
  PixelDataAndMapQueue getQueue() {
    return q;
  }
  
  int getLastError() {
    return lastError;
  }
  
  void put(color[] pixelData, int[] strandMap) {
    q.put(pixelData, strandMap);
  }
  
  public void run() {
    lastError = TotalControl.open(numStrands, pixelsPerStrand);
    if(lastError != 0) {
      TotalControl.printError(lastError);
    }
    TotalControl.setGamma(2.4);
    
    while(true) {
      PixelDataAndMap dm = q.get();
      assert(dm != null) : "no data to write to TotalControl";
      //println("writing dm.pixelData: " + dm.pixelData.length + " dm.strandMap: " + dm.strandMap.length);
      int status = TotalControl.refresh(dm.pixelData, dm.strandMap);
      if(status != lastError) {
        lastError = status;
        TotalControl.printError(status);
      }
      
      if (millis() - lastStat > 3000) {
        lastStat = millis();
        TotalControl.printStats();
      }
    }
  }
  
  class PixelDataAndMap {
    color[] pixelData;
    int[] strandMap;
  }
  
  class PixelDataAndMapQueue {
    
    PixelDataAndMap n;
    boolean valueSet = false;
    
    synchronized PixelDataAndMap get() {
      if(!valueSet) {
        try {
          wait();
        } catch(InterruptedException e) {
          System.out.println("InterruptedException caught");
        }
      }
      PixelDataAndMap result = n;
      assert(result != null) : "get() has nothing to get";
      n = null;
      valueSet = false;
      notify();
      return result;
    }
    
    synchronized void put(color[] pixelData, int[] strandMap) {
      PixelDataAndMap newDM = new PixelDataAndMap();
      newDM.pixelData = pixelData.clone(); //pixelData changes each frame
      newDM.strandMap = strandMap; //strandMap should point to static data
      if(valueSet)
        try {
          wait();
        } catch(InterruptedException e) {
          System.out.println("InterruptedException caught");
        }
      assert (this.n == null) : "pixel data should always be null before writing";
      this.n = newDM;
      valueSet = true;
      notify();
    }
  }
}


