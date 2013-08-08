import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import com.qindesign.hid.HidDevice;
import com.qindesign.hid.HidDeviceInfo;
import com.qindesign.hid.HidManager;
import com.qindesign.wii.Wiimote;
import com.qindesign.wii.WiimoteListener;
import com.qindesign.wii.WiimoteMath;
import com.qindesign.wii.WiimoteStatus;

class WiimoteManager {
  /** The retry interval for searching for Wii remotes. */
  private static final long RETRY_INTERVAL = 10000L;

  private ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);
  private OscPacketReceiver oscReceiver;

  /**
   * Continuously watches for Wii controllers and attempts reconnects if the paired one disconnects.
   */
  private final class WiimoteWatcher implements Runnable {
    @Override
    public void run() {
      HidManager hid = HidManager.getInstance();
      Wiimote wiimote = null;

      try {
        List<HidDeviceInfo> wiimotes = Wiimote.findWiimotes(hid);

        if (!wiimotes.isEmpty()) {
          // Try all of the found wiimotes

          HidDevice wiiDevice = null;
          for (HidDeviceInfo device : wiimotes) {
            wiiDevice = hid.open(device);
            if (wiiDevice != null) {
              break;
            }
          }

          if (wiiDevice != null) {
            System.out.println("Monitoring Wiimote: " + wiiDevice);

            wiimote = new Wiimote(wiiDevice);
            wiimote.requestStatus();
            wiimote.setLed(1, true);
            wiimote.requestData(Wiimote.REPORT_BUTTONS_AND_ACCEL, false);

            // Start the event loop and wait for it to be finished

            Future eventLoopFuture = executor.submit(wiimote.getEventLoop(wiimoteListener));
            eventLoopFuture.get();
          }
        }
      } catch (Exception ex) {
        // End
      } finally {
        if (wiimote != null) {
          wiimote.close();
        }
        hid.close();
      }

      // Reschedule the Wiimote search
      executor.schedule(this, RETRY_INTERVAL, TimeUnit.MILLISECONDS);
    }
  }

  /** Listens for Wiimote events and transforms them into OSC events. */
  private WiimoteListener wiimoteListener = new WiimoteListener() {
    @Override
    public void status(WiimoteStatus status) {
    }

    private boolean lastButtonState;
    @Override
    public void buttons(int buttons) {
      oscReceiver.oscMessage(new OscMessage(Settings.keyWiimoteButtons, new Object[] {
          buttons }));
    }

    private long lastTime;

    @Override
    public void accelerometer(float x, float y, float z) {
      long time = System.currentTimeMillis();

      if (time - lastTime < 100L) return;

      double roll = Math.abs(WiimoteMath.roll(x, y, z));
      double pitch = WiimoteMath.pitch(x, y, z);
      double tilt = WiimoteMath.tilt(x, y, z);

      oscReceiver.oscMessage(new OscMessage(Settings.keyWiimoteAccel, new Object[] {
          x, y, z, (float) pitch, (float) roll, (float) tilt }));

      lastTime = time;
    }

    @Override
    public void memory(int error, int offset, byte[] data, int dataOff, int dataLen) {
    }

    @Override
    public void ack(int report, int error) {
    }
  };

  /**
   * Creates a new Wiimote interface and sends messages to the given OSC receiver.
   *
   * @param oscReceiver receives OSC messages generated by the Wiimote
   */
  WiimoteManager(OscPacketReceiver oscReceiver) {
    this.oscReceiver = oscReceiver;
  }

  /**
   * Initializes this class.
   */
  void setup() {
    executor.submit(new WiimoteWatcher());
  }
}
