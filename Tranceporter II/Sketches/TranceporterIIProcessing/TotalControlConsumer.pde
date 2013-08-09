//import TotalControl.*;  // If you don't have the hardware driver, comment out this line

import java.lang.InterruptedException;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

static class TotalControl { // If you don't have the hardware driver, rename this class to TotalControl
  static int open(int nStrands,int pixelsPerStrand)
	{
    return TC_OK;
	}

  public static int setGamma()
	{
    return TC_OK;
	}

	public static int setGamma(float g)
	{
    return TC_OK;
	}

	public static int setGamma(
                             int rMin,int rMax,float rGamma,
                             int gMin,int gMax,float gGamma,
                             int bMin,int bMax,float bGamma)
	{
    return TC_OK;
	}

	public static void initStats()
	{
	}

	public static int refresh(int[] pixels, int[] remap)
	{
    return TC_OK;
	}

  public static int setStrandPin(int strand,short bit)
	{
    return TC_OK;
	}

	public static void close()
	{
	}

	public static void printStats()
	{
	}

	public static void printError(int status)
	{
	}
}

/*
 Writes to the p9813 on a separate thread to increase our frame rate
 */


static final int TC_OK = 0;       /* Function completed successfully      */
static final int TC_ERR_VALUE = 1;     /* Parameter out of range               */
static final int TC_ERR_MALLOC = 2;    /* malloc() failure                     */
static final int TC_ERR_OPEN = 3;      /* Could not open FTDI device           */
static final int TC_ERR_WRITE = 4;     /* Error writing to FTDI device         */
static final int TC_ERR_MODE = 5;      /* Could not enable async bit bang mode */
static final int TC_ERR_DIVISOR = 6;   /* Could not set baud divisor           */
static final int TC_ERR_BAUDRATE = 7;   /* Could not set baud rate              */

static final int TC_PIXEL_UNUSED =       -1;     // Pixel is attached but not used
static final int TC_PIXEL_DISCONNECTED = -2;     // Pixel is not attached to strand
static final int TC_PIXEL_UNDEFINED =    -3;     // Pixel not yet assigned a value

/* FTDI pin-to-bitmask mappings */

static final short  TC_FTDI_TX   = 0x01;  /* Avail on all FTDI adapters,  strand 0 default */
static final short  TC_FTDI_RX   = 0x02;  /* Avail on all FTDI adapters,  strand 1 default */
static final short  TC_FTDI_RTS  = 0x04;  /* Avail on FTDI-branded cable, strand 2 default */
static final short  TC_FTDI_CTS  = 0x08;  /* Avail on all FTDI adapters,  clock default    */
static final short  TC_FTDI_DTR  = 0x10;  /* Avail on third-party cables, strand 2 default */
static final short  TC_FTDI_DSR  = 0x20;  /* Avail on full breakout board */
static final short  TC_FTDI_DCD  = 0x40;  /* Avail on full breakout board */
static final short  TC_FTDI_RI   = 0x80;  /* Avail on full breakout board */


/* Special mode bits optionally added to first parameter to TCopen()    */
static final int TC_CBUS_CLOCK = 8;   /* Use hardware for serial clock, not bitbang */
/* Hardware (CBUS) clock yields 2X throughput boost but requires a full
 FTDI breakout board with a specially-configured chip; this will not
 work with standard FTDI adapter cable (e.g. LilyPad programmer).
 See README.txt for further explanation.                              */



/*

 From https://github.com/PaintYourDragon/p9813

 In the call to TCopen(), the number of strands should be set to 8, or,
 if using fewer than 8 strands but the high-speed mode is still desired,
 add TC_CBUS_CLOCK to the number of strands, e.g.:

 status = TCopen(3 + TC_CBUS_CLOCK, 100);

 Secondly, if using more than the default three strands (or if a different
 order or combination of pins is desired), TCsetStrandPin() should be used
 to assign FTDI pins to strand data lines, e.g.:

 TCsetStrandPin(3, TC_FTDI_CTS);
 */

class TotalControlConsumer {

  int lastError;
  int lastStat;
  private Thread correctThread;

  synchronized int setupTotalControl(int numStrands, int pixelsPerStrand, boolean useBitBang) {

    assert correctThread == null : "Thread must not yet be set";
    correctThread = Thread.currentThread();
    assert correctThread != null: "unable to get the current thread";

    assert(numStrands <= 8);
    if (useBitBang && numStrands < 8) {
      numStrands += TC_CBUS_CLOCK;
    }

    if (useBitBang) {
      TotalControl.setStrandPin(0, TC_FTDI_TX);
      TotalControl.setStrandPin(1, TC_FTDI_RX);
      TotalControl.setStrandPin(2, TC_FTDI_RTS);
      TotalControl.setStrandPin(3, TC_FTDI_CTS);
      TotalControl.setStrandPin(4, TC_FTDI_DTR);
      TotalControl.setStrandPin(5, TC_FTDI_DSR);
      TotalControl.setStrandPin(6, TC_FTDI_DCD);
      TotalControl.setStrandPin(7, TC_FTDI_RI);
    }

    int error = TotalControl.open(numStrands, pixelsPerStrand);
    if (error != 0) {
      println("could not open, retrying");
      TotalControl.close();
      error = TotalControl.open(numStrands, pixelsPerStrand);
    }

    if(error != 0) {
      TotalControl.printError(lastError);
      //exit();
    }
    else {
      println("success: TotalControl.open(" + numStrands + ", " + pixelsPerStrand + ")");
    }
    TotalControl.setGamma(main.DEFAULT_GAMMA);

    return error;
  }

  synchronized int writeOneFrame(color[] pixelData, int[] strandMap) {

    assert correctThread == Thread.currentThread() : "No longer talking to TotalControl on the correct thread";
    //    println("pixelData:" + pixelData.length + " strandMap:" + strandMap.length);

    int status = TotalControl.refresh(pixelData, strandMap); // TODO: might be faster if we don't have to send the strandMap each time, but only when it changes
    if(status != lastError) {
      lastError = status;
      TotalControl.printError(status);
    }
    if (millis() - lastStat > 3000) {
      lastStat = millis();
      if (false) {
        TotalControl.printStats();
      }
    }
    return status;
  }

  synchronized void close() {
    // In general, this won't be called on the correctThread, but synchronized should make this okay
    correctThread = null;
    TotalControl.close();
    println("closed TotalControl driver");
  }

}

class TotalControlConcurrent implements Runnable {
  private PixelDataAndMapQueue q;
  private int numStrands;
  private boolean useBitBang;
  private int pixelsPerStrand;
  TotalControlConsumer totalControlConsumer;

  TotalControlConcurrent(int numStrands, int pixelsPerStrand, boolean useBitBang) {
    this.numStrands = numStrands;
    this.pixelsPerStrand = pixelsPerStrand;
    this.useBitBang = useBitBang;
    q = new PixelDataAndMapQueue();

    new Thread(this, "TotalControlConcurrent").start();
  }

  int getLastError() {
    return totalControlConsumer.lastError;
  }

  void put(color[] pixelData, int[] strandMap) {
    try {
      q.put(pixelData, strandMap);
    } catch (InterruptedException ex) {
      Thread.currentThread().interrupt();
    }
  }

  void close() {
    q.close();
  }

  public void run() {
    totalControlConsumer = new TotalControlConsumer();
    totalControlConsumer.setupTotalControl(numStrands, pixelsPerStrand, useBitBang);

    while(true) {
      PixelDataAndMap dm;
      try {
        dm = q.take();
      } catch (InterruptedException ex) {
        Thread.currentThread().interrupt();
        break;
      }

      if (dm == null) {
        totalControlConsumer.close();
        break;
      }

      totalControlConsumer.writeOneFrame(dm.pixelData, dm.strandMap);
    }
    println("exiting Total Control run thread");
  }

  /**
   * Encapsulates the pixel data and strand map.
   */
  class PixelDataAndMap {
    color[] pixelData;
    int[] strandMap;

    /**
     * Creates a new object and stores the given arguments.
     *
     * @param pixelData the pixel data
     * @param strandMap the strand map
     */
    PixelDataAndMap(color[] pixelData, int[] strandMap) {
      this.pixelData = pixelData;
      this.strandMap = strandMap;
    }
  }

  class PixelDataAndMapQueue {
    final Lock lock = new ReentrantLock();
    final Condition notFull = lock.newCondition();
    final Condition notEmpty = lock.newCondition();

    private boolean closed;

    PixelDataAndMap map;

    /**
     * Takes a value from the queue, waiting until one is available.  This returns {@code null} if closed.
     *
     * @return the latest data, or {@code null} if this structure was closed.
     * @throws InterruptedException if the current thread was interrupted while waiting.
     * @see #close()
     */
    PixelDataAndMap take() throws InterruptedException {
      lock.lock();
      try {
        if (closed) {
          return null;
        }

        while (this.map == null) {
          notEmpty.await();
          if (closed) {
            return null;
          }
        }

        PixelDataAndMap retval = this.map;
        this.map = null;
        notFull.signal();
        return retval;
      } finally {
        lock.unlock();
      }
    }

    /**
     * Puts data into the queue, waiting until the queue is empty.  This will do nothing if this is closed.
     *
     * @param pixelData
     * @param strandMap
     * @throws InterruptedException if the current thread was interrupted while waiting.
     * @see #close()
     */
    void put(color[] pixelData, int[] strandMap) throws InterruptedException {
      // TODO: pass in a param that tells us if it has changed

      lock.lock();
      try {
        if (closed) {
          return;
        }

        while (this.map != null) {
          notFull.await();
          if (closed) {
            return;
          }
        }

        // pixelData changes each frame
        // strandMap can change when we are programming the strand.
        this.map = new PixelDataAndMap(pixelData.clone(), strandMap.clone());
        notEmpty.signal();
      } finally {
        lock.unlock();
      }
    }

    void close() {
      lock.lock();
      try {
        closed = true;
        notEmpty.signal();
        notFull.signal();
      } finally {
        lock.unlock();
      }
    }
  }
}


