// Class to detect beats
// Implementation by Greg Friedland in 2012 based on methods described by Simon Dixon in 
// "ONSET DETECTION REVISITED" Proc. of the 9th Int. Conference on Digital Audio Effects (DAFx-06), Montreal, Canada, September 18-20, 2006
// ( http://www.dafx.ca/proceedings/papers/p_133.pdf )

import java.util.HashMap;
import ddf.minim.analysis.*;

class BeatDetect {

  // String[] metricNames = {"spectralFlux", "spectrum"}; 

  // HashMap onsetHists, thresholds, metrics, metricSDs;
  
  CircularArray[] fullSpec;
  boolean[] analyzeBands;
  float[] bandFreqs;
  float[] threshSensitivity;
  long[] lastOnsetTimes;
  // int[] fftBandMap;
  int[] beatLength;
  int numBands;
  int historySize;
  FFT fft;

  // float MIN_FREQ         = 100;
  // float MAX_FREQ         = 10000;
  // float MIN_THRESHOLD    = 0; 
  // int[] NUM_NEIGHBORS    = {1, 5, 5};
  // int SHORT_HIST_SIZE    = 3;
  // int LONG_HIST_SIZE     = 5; 
  // int THRESH_SENSITIVITY = 1;
  int BEAT_LENGTH           = 150;

  boolean[] isBandOnset;

  // This is The New Stuff
  int config_SAMPLERATE        = 44100;
  int config_BUFFERSIZE        = 512;
  int config_BPM               = 140;
  int config_FFT_BAND_PER_OCT  = 12;
  int config_FFT_BASE_FREQ     = 55;
  private boolean scaleEq      = true;
  public boolean onBeat        = false;
  public boolean oscOnBeat     = false;
  public boolean autoBeatSense = true;

  public float beatSense         = 4;
  public float beatSenseSense    = 1;
  private long lastbeatTimestamp = 0;
  private float level            = 0;
  private float leveldB          = -100;
  private int lastBand           = 0;
  private int lastBandCount      = 0;
  private int nbAverage          = config_SAMPLERATE / config_BUFFERSIZE * 2; // one second
  private float modulationSmooth = 0.30f;

  private int nbAverageLongTerm  = 8 * config_SAMPLERATE / config_BUFFERSIZE;
  private int nbAverageShortTerm = config_SAMPLERATE / config_BUFFERSIZE / 3;
  // skip beat for a quarter of beat
  private int repeatDelay        = (int) ((60f / config_BPM / 4f) * (config_SAMPLERATE / config_BUFFERSIZE));

  public int numZones      = 0;
  public boolean zoneEnabled[];
  private float score2     = 0;
  private float modulation = 0;
  private float[][] zoneEnergy;
  private float[][] zoneEnergyShortTerm;
  private float[][] zoneScore;
  private float[] score         = new float[nbAverage];
  private float[] scoreLongTerm = new float[nbAverageLongTerm];

  private int playhead          = 0;
  private int playheadShortTerm = 0;
  private int playheadLongTerm  = 0;
  private int skipFrames        = 0;

  // private float[] zoneEnergyVuMeter;
  // private float[] zoneEnergyPeak;
  // private int[] zoneEnergyPeakHoldTimes;
  // private int peakHoldTime        = 30; // hold longer
  // private float peakDecayRate     = 0.98f; // decay slower
  private float linearEQIntercept = 0.8f; // reduced gain at lowest frequency
  private float linearEQSlope     = 0.2f; // increasing gain at higher frequencies

  // End This is The New Stuff

  /**
   * BeatDetect Class Constructor Method
   *
   * @arg FFT fft Fast Forier Transform object
   * @arg int numBands number of bands we'll be reading
   * @arg int historySize number of historical data points we keep in memory
   * 
   */
  BeatDetect(FFT fft, int numBands, int historySize) {

    // the low end of the frequencies we watch
    // MIN_FREQ          = max(MIN_FREQ, SAMPLE_RATE/SAMPLE_SIZE);

    // assign arguments to class members
    this.fft          = fft;
    this.historySize  = historySize;
    this.numBands = numBands;

    // create historical data objects
    
    // beatLength tells us how long a beat may last until we call it a new beat
    beatLength        = new int[numBands];

    // threshSensitivity is used to determine whether a band has enough volume to count as a beat
    threshSensitivity = new float[numBands];

    // assign the default values to all bands for now. They can be reset later.
    for (int i=0; i<numBands; i++) {
      // threshSensitivity[i] = THRESH_SENSITIVITY;
      beatLength[i]        = BEAT_LENGTH;
    }

    // analyzeBands is an array that tells us whether we care about a given band. 
    // For now they're all set to 'true'    
    analyzeBands = new boolean[numBands];
    for (int i=0; i<numBands; i++) {
        analyzeBands[i] = true;
    }

    // whether this is onset for the band
    isBandOnset = new boolean[numBands];

    // // bandFreqs is an array that contains the frequecies of our sub-bands    
    // bandFreqs          = new float[numBands];
    // float logBandwidth = (log(MAX_FREQ) - log(MIN_FREQ)) / (numBands - 1);
    // // println("Using log bandwidth " + logBandwidth);
    // for (int i=0; i<numBands; i++) {
    //   bandFreqs[i] = MIN_FREQ * exp(i*logBandwidth);
    //   // println("Band " + i + " using frequency " + bandFreqs[i]);
    // }
    
    // this appears to be unused
    // // fftBandMap maps fft bands (samplesize/2+1) to our band definition
    // fftBandMap = new int[fft.specSize()];
    // for (int i=0; i<fftBandMap.length; i++) {
    //   float freq    = fft.indexToFreq(i);
    //   int ind       = round(log(freq/MIN_FREQ) / logBandwidth);
    //   fftBandMap[i] = ind;
    //   println("Mapping fft band " + i + " with freq " + freq + " to our band " + ind);
    // }
    
    // more historical data holders, but these are hashes whose keys are our metric names defined above
    // onsetHists    = new HashMap();
    // thresholds    = new HashMap();
    // metrics       = new HashMap();
    // metricSDs     = new HashMap();

    // initialize a set of "circular arrays"
    // for (int i=0; i<metricNames.length; i++) {
      // CircularArrayWithAvgs[] m  = new CircularArrayWithAvgs[numBands];
      // CircularArrayWithAvgs[] sd = new CircularArrayWithAvgs[numBands];
      // // CircularArray[] o          = new CircularArray[numBands];
      // CircularArray[] t          = new CircularArray[numBands];

      // populate our circular arrays with default values
      // for (int j=0; j<numBands; j++) {
        // m[j]  = new CircularArrayWithAvgs(historySize, SHORT_HIST_SIZE, LONG_HIST_SIZE);
        // sd[j] = new CircularArrayWithAvgs(historySize, SHORT_HIST_SIZE, LONG_HIST_SIZE);
        // o[j]  = new CircularArray(historySize);
        // t[j]  = new CircularArray(historySize);
      // }
      
      // map our metric names to the default values we just defined
      // onsetHists.put(metricNames[i], o);
      // thresholds.put(metricNames[i], t);
      // metrics.put(metricNames[i], m);
      // metricSDs.put(metricNames[i], sd);
    // }

    // lastOnsetTimes holds the last time we detected a new beat for each given band
    lastOnsetTimes = new long[numBands];    


    // ////////////////////////everything below this is The New Stuff

    numZones = fft.avgSize();

    zoneEnergy              = new float[numZones][];
    zoneEnergyShortTerm     = new float[numZones][];
    zoneScore               = new float[numZones][];
    zoneEnabled             = new boolean[numZones];
    
    // zoneEnergyVuMeter       = new float[numZones];
    // zoneEnergyPeak          = new float[numZones];
    // zoneEnergyPeakHoldTimes = new int[numZones];

    for (int i = 0; i < numZones; i++) {
      zoneEnergy[i]          = new float[nbAverage];
      zoneScore[i]           = new float[nbAverage];
      zoneEnergyShortTerm[i] = new float[nbAverageShortTerm];
      zoneEnabled[i]         = true;
    }

    // everything above this is The New Stuff

  }

  // /**
  //  * Not quite sure what's going on here
  //  */
  // private CircularArray getArray(String type, String metricName, int band) {
  //   HashMap hm;
  //   if (type.equals("metric")) hm         = metrics;
  //   // else if (type.equals("onsetHist")) hm = onsetHists;
  //   // else if (type.equals("threshold")) hm = thresholds;
  //   // else if (type.equals("sd")) hm        = metricSDs;
  //   else {
  //     assert(false):"Invalid array type " + type;
  //     return null;
  //   }
    
  //   CircularArray[] ca = (CircularArray[]) hm.get(metricName);
  //   return ca[band];
  // }  
  
  // /**
  //  * Not quite sure what's going on here
  //  */
  // private CircularArrayWithAvgs getArrayAvgs(String type, String metricName, int band) {
  //   return (CircularArrayWithAvgs) getArray(type, metricName, band);
  // }

  /**
   * Set the object's thresholdSensititivy and beatLength for the given band
   *
   * @arg int band  the band we're setting values for
   * @arg float threshSensitivity   the threshhold sentivity value to set
   * @arg int beatLength    The beat length to set
   */
  // void setSensitivity(int band, float threshSensitivity, int beatLength) {
  //   this.threshSensitivity[band] = threshSensitivity;
  //   this.beatLength[band] = beatLength;
  // }

  /**
   * Set the object's thresholdSensititivy and beatLength for the given band
   *
   * @arg int band  the band we're setting values for
   * @arg int beatLength    The beat length to set
   */
  void setBeatLength(int band, int beatLength) {
    this.beatLength[band] = beatLength;
  }

  // this appears to be unused
  // /**
  //  * Get the FFT band map for the given band
  //  */
  // int getBandMapping(int fftBand) {
  //   return fftBandMap[fftBand];
  // }

  /**
   * Set the FFT Window
   */
  void setFFTWindow() {
    fft.window(FFT.HAMMING);
  }
  
  /**
   * The workhorse method
   * This examines incoming audiobuffer data and decideds whether we are entering or leaving a beat
   * @arg AudioBuffer data the audio data for the moment we're examining
   */
  void update(AudioBuffer data) {

    fft.forward(data);
    
    // ////////////////// The New Stuff

    // update our round robins heads
    int playhead2          = (playhead + 1) % nbAverage;
    int playheadLongTerm2  = (playheadLongTerm + 1) % nbAverageLongTerm;
    int playheadShortTerm2 = (playheadShortTerm + 1) % nbAverageShortTerm;

    int localAvg = 0;

    // loop through all zones
    for (int i = 0; i < numZones; i++) {
      // get energy
      zoneEnergy[i][playhead2] = fft.getAvg(i) * (linearEQIntercept + i * linearEQSlope);
      // System.out.println("ZONE " + i + " got zoneenergy for " + playhead2 + " of " + zoneEnergy[i][playhead2]);

      // // // compute peaks
      // if (zoneEnergy[i][playhead2] >= zoneEnergyPeak[i]) {

      //   // save new peak level, also reset the hold timer
      //   zoneEnergyPeak[i] = zoneEnergy[i][playhead2];
      //   zoneEnergyPeakHoldTimes[i] = peakHoldTime;
      // } else {

      //   // current average does not exceed peak, so hold or decay the peak
      //   if (zoneEnergyPeakHoldTimes[i] > 0) {
      //     zoneEnergyPeakHoldTimes[i]--;
      //   } else {
      //     zoneEnergyPeak[i] *= peakDecayRate;
      //   }
      // }

      // zoneEnergyVuMeter[i] = zoneEnergy[i][playhead2];

      zoneEnergyShortTerm[i][playheadShortTerm2] = zoneEnergy[i][playhead2];
      // System.out.println(zoneEnergy[i][playhead2]+" "+average(zoneEnergy[i]));

      // compute a per band score
      if (zoneEnergy[i][playhead2] > 0.3 && average(zoneEnergy[i]) > 0.1) {
        zoneScore[i][playhead2] = zoneEnergy[i][playhead2] 
        / average(zoneEnergy[i])
        * zoneEnergyShortTerm[i][playheadShortTerm2]
        / average(zoneEnergyShortTerm[i]);
      }

      else {
        zoneScore[i][playhead2] = 0;
      }

      if (zoneEnabled[i]) {
        // println(zoneEnergy[i][playhead2]);
        localAvg += zoneEnergy[i][playhead2];
        if (zoneScore[i][playhead2] < 100) {
          score[playhead2] += zoneScore[i][playhead2];
        } else {
          score[playhead2] += 100;
        }
        // if(zoneScore[i][playhead2]>25) {
        // System.out.println(zoneScore[i][playhead2]);
        // }
      }
    } // end loop through all zones

    // pitch detect
    float maxE   = 0;
    int bandmaxE = 0;
    int minBand  = 0;
    int thres    = 0;
    for (int i = minBand; i < numZones; i++) {
      if (zoneEnergy[i][playhead2] > maxE && zoneEnabled[i]) {
        bandmaxE = i;
        maxE = zoneEnergy[i][playhead2];
      }
    }

    if (bandmaxE != lastBand) {

      // if (lastBandCount > thres) {
      //     // System.out.print(".\n");
      // }
      lastBandCount = 0;

    } else {

      // these do nothing but print output  
      // if (thres == lastBandCount) {
      //   // System.out.print(bandmaxE+" "+fft.getBandWidth()*bandmaxE+"Hz ");
      //   if (bandmaxE > 0) {
      //     for (int i = 0; i <= bandmaxE; i++) {
      //         // System.out.print("#");
      //     }
      //   }
      // }
      // if (lastBandCount > thres) {
      //     // System.out.print(".");
      // }
      lastBandCount++;
    }
    lastBand = bandmaxE;

    // compute a global score
    int numZoneEnabled = 0;
    for (int ii = 0; ii < numZones; ii++) {
      numZoneEnabled += (zoneEnabled[ii]) ? 1 : 0;
    }
    if (numZoneEnabled == 0) {
      score[playhead2] = 0;
      scoreLongTerm[playheadLongTerm2] = 0;
    } else {
      score[playhead2] = score[playhead2] / numZoneEnabled;
      scoreLongTerm[playheadLongTerm2] = score[playhead2]/ numZoneEnabled;
    }

    // only used for the graphic equalizer    
    // float smooth = 0.9f;
    // if (score2 * smooth < score[playhead2]) {
    //   score2 = score[playhead2];
    // } else {
    //   score2 *= smooth;
    // }

    // are we on the beat ?
    if (skipFrames <= 0 && score[playhead2] > beatSense) {

      // if we weren't already on the beat, this is the onset
      if(!onBeat) {
        for(int i=0;i<numBands;i++) {
          if(isBandOnset[i]) { 
            isBandOnset[i] = false;
          } else {
            isBandOnset[i] = true;
          }
        }
      }

      onBeat = true;
      skipFrames = repeatDelay;
    }
    else {
      for(int i=0;i<numBands;i++) {
        isBandOnset[i] = false;
      }
      onBeat = false;
    }

    if (skipFrames > 0) {
      skipFrames--;
    }

    // compute auto beat sense
    float max = max(score);
    if (max > 30) {
      max = 30;
    }

    // float min = min(score);
    float avg = average(scoreLongTerm);
    if (avg < 1.5) {
      avg = 1.5f;
    }

    if (autoBeatSense && max > 1.1) {
      beatSense = beatSense * 0.995f + 0.002f * max * beatSenseSense + 0.003f * avg * beatSenseSense;
      if (beatSense < 1.1) {
        beatSense = 1.1f;
      }
    }

    // System.out.println(" max:"+max+" min:"+min+" avg:"+avg+" var:"+average(score));

    // make our round robin heads public
    playhead          = playhead2;
    playheadShortTerm = playheadShortTerm2;
    playheadLongTerm  = playheadLongTerm2;

    System.out.println("threshold : "     + this.beatSense);
    System.out.println("current score : " + score[playhead2]);
    System.out.println("on Beat :"        + this.onBeat);

    // set all our bands to this band's value
    for (int i=0; i< main.NUM_BANDS; i++) {
        if(onBeat) {
          int myMillis = millis();
          lastOnsetTimes[i] = myMillis;
        }
    }

    // ////////////////// END The New Stuff


    // for (int i=0; i< main.NUM_BANDS; i++) {

      // if (!analyzeBands[i]) continue;
    
      // // multiply neighbors
      // int fftBand = fft.freqToIndex(bandFreqs[i]);
      // double val = 1;
      // for (int j=max(0, fftBand-NUM_NEIGHBORS[i]); j<=min(fft.specSize()-1, fftBand+NUM_NEIGHBORS[i]); j++) {
      //   val *= fft.getBand(j);
      // }
      // // println("Band " + i + " val " + val);
      // getArray("metric", "spectrum", i).add(val);
      
      // //spectrum[i].add(specSums[i] / counts[i]);
      // int ind = getArray("metric", "spectrum", i).getIndex();
      // getArray("sd", "spectrum", i).add(getArray("metric", "spectrum", i).sd(ind-LONG_HIST_SIZE+1, ind));

      // // calculate GF metric
      // double thresh = getArrayAvgs("metric", "spectrum", i).getEMA2(ind-1) + threshSensitivity[i] * getArrayAvgs("sd", "spectrum", i).getEMA2(ind-1);
      // getArray("threshold", "spectrum", i).add(thresh);
      // if (getArrayAvgs("metric", "spectrum", i).getEMA1(ind) > max((float)thresh, MIN_THRESHOLD)) {
      //   getArray("onsetHist", "spectrum", i).add(1);
      // } else {
      //   getArray("onsetHist", "spectrum", i).add(0);
      // }
      
      // // calculate spectral flux     
      // float diff = abs((float)getArray("metric", "spectrum", i).get()) - abs((float)getArray("metric", "spectrum", i).getPrev());
      // getArray("metric", "spectralFlux", i).add((diff + abs(diff)) / 2.0);
      // getArray("sd", "spectralFlux", i).add(getArray("metric", "spectralFlux", i).sd(ind-LONG_HIST_SIZE+1, ind));
      
      // thresh = getArrayAvgs("metric", "spectralFlux", i).getEMA2(ind-1) + threshSensitivity[i] * getArrayAvgs("sd", "spectralFlux", i).getEMA2(ind-1);
      // getArray("threshold", "spectralFlux", i).add(thresh);
      // if (getArrayAvgs("metric", "spectralFlux", i).getEMA1(ind) > 
      //       max((float)thresh, MIN_THRESHOLD) && millis() - lastOnsetTimes[i] >= beatLength[i]) {
      //   getArray("onsetHist", "spectralFlux", i).add(1);


      //   // HERE! RIGHT THE FUCK HERE!!!!
      //   // println("beat gap" + (i+1) + ": " + (millis() - lastOnsetTimes[i]));
      //   lastOnsetTimes[i] = millis();
      // } else {
        // getArray("onsetHist", "spectralFlux", i).add(0);
      // }
    // }
  }
  
  /**
   * Set the "analyzeBands" flag for the given band
   * @arg int band the band to set the value for
   * @arg boolean the value to set
   */
  void analyzeBand(int band, boolean on) { 
    analyzeBands[band] = on; 
  }
  
  // unused
  // double getMetric(String type, int band, int index) {
  //   return getArray("metric", type, band).get(index);
  // }
  
  // unused
  // double getMetricMean(String type, int band, int index) {
  //   return getArrayAvgs("metric", type, band).getEMA1(index);
  // }
  
  // unused
  // double getThreshold(String type, int band, int index) {
  //   return getArray("threshold", type, band).get(index);
  // }
  
  // unused
  // double getMetricMax(String type, int band) {
  //   return getArray("metric", type, band).maxVal();
  // }
  
  /**
   * Get the onset history value for the type, band and index
   */
  boolean isOnset(String type, int band, int index) {
    // return getArray("onsetHist", type, band).get(index) == 1;
    return isBandOnset[band];
  }
  
  // /**
  //  * metricNames getter class
  //  */
  // String[] getMetricNames() {
  //   return metricNames;
  // }
  
  /**
   * Is the given type and band currently in a beat
   */
  boolean isBeat(String type, int band) { 
    return (millis() - lastOnsetTimes[band]) < beatLength[band]; 
    // return onBeat;
  }

  /**
   * Where in the beat are we? How long as this beat been going on?
   * Will be a value between 0 and 1. Some mathemagic is done to stir the values up a bit
   */
  float beatPos(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1) { 
      // println("Band " + band + " Got diff  " + diff + " from millis " + millis() + " lOT: " + lastOnsetTimes[band] + " bl: " + beatLength[band]);
      float val = sin(diff*PI/2);
      //float val = 1 - abs(diff-0.5) * 2; //exp(-pow(diff - 0.5, 2.0)*25);
      // println("Returning val " + val + " from diff " + diff);
      return val;
    }
    else {
      return 0;
    }
  }
  
  /**
   * Where in the beat are we? How long as this beat been going on?
   * Will be a value between 0 and 1. The raw value is returned without any math performed
   */
  float beatPosSimple(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1) return diff;
    else return 0;
  }

  // ///////////////// New Stuff
  // method average
  private float average(float[] array) {
    float sum = 0;
    for (int i = 0; i < array.length; i++) {
      sum += array[i];
    }
    return (sum / array.length);
  } // end method average

  // method sum
  private float[] sum(float[] array, float[] array2) {
    float[] array3 = new float[array.length];
    for (int i = 0; i < array.length; i++) {
      array3[i] += array[i] + array2[i];
    }
    return (array3);
  } // end method sum


}

