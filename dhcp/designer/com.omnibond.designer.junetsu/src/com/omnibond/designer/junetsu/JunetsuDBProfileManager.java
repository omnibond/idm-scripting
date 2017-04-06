package com.omnibond.designer.junetsu;

import java.sql.Connection;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.datatools.connectivity.IConnectionProfile;
import org.eclipse.datatools.connectivity.ProfileManager;
import org.eclipse.datatools.connectivity.drivers.DriverInstance;
import org.eclipse.datatools.connectivity.drivers.DriverManager;
import org.eclipse.datatools.connectivity.sqm.core.connection.ConnectionInfo;
import org.eclipse.datatools.connectivity.ui.actions.AddProfileViewAction;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.internal.win32.OS;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Display;

import com.novell.idm.model.DesignElement;
import com.novell.idm.modeler.Modeler;

public class JunetsuDBProfileManager 
   implements SelectionListener
{

   private final String JUNETSU_DATABASE = "JuNetSuDB";
   private final String JAR_PATH = "lib/mysql-connector-java-5.1.7-bin.jar";
   private final String DRIVER_TEMPLATE = "org.eclipse.datatools.enablement.mysql.5_1.driverTemplate";

   private static JunetsuDBProfileManager instance = null; 
   
   private Modeler modeler;
   private DesignElement element;
   private String currProfile;
   private ProfileManager profileManager;
   private IConnectionProfile[] profiles;
   private IConnectionProfile profile;   
   private Connection conn;
   private List<Combo> comboList;
   private boolean connected = false;
   
   public JunetsuDBProfileManager(Modeler modeler, DesignElement element) {
      
      this.modeler = modeler;
      this.element = element;
      
      comboList = new ArrayList<Combo>();
      
      // Load profiles
      // Load available database connection profiles
      profileManager = ProfileManager.getInstance();
      
      // Create Driver for our MySQL driver if necessary
      installDBDriver();
            
      // Load saved profile
      currProfile = element.getValueString(JUNETSU_DATABASE);
      
      updateProfiles();
      
   }
   
   public static JunetsuDBProfileManager getInstance(Modeler modeler, DesignElement element) {
      if (instance == null) {
         instance = new JunetsuDBProfileManager(modeler, element);
      }
      return instance;
   }
   
   private void installDBDriver() {
      DriverInstance[] drivers = DriverManager.getInstance().getAllDriverInstances();
      
      String pluginPath = Activator.getDefault().getPluginPath().toLowerCase();
      String jarPath = pluginPath + JAR_PATH;
      
      // Search for a driver with our JAR
      boolean found = false;
      for (DriverInstance driver : drivers) {
         String jarList = driver.getJarList().toLowerCase().replace("\\", "/");
         if (jarList.contains(jarPath)) {
            found = true;
            break;
         }
      }
      
      if (!found) {
         if (OS.IsWinNT) {
            // Switch path back to backslashes
            jarPath = jarPath.replace("/", "\\");
         }
         // create driver
         DriverInstance newDriver = DriverManager.getInstance().createNewDriverInstance(DRIVER_TEMPLATE, "Junetsu MySQL 5.1 Driver", jarPath);         
         if (newDriver == null) {
            // TODO: error
         }
      }
   }

   // Save the control (a Combo) and populate it with the list of
   // profiles
   public void registerControl(Combo combo) {
      
      comboList.add(combo);

      updateControl(combo);
      
   }
   
   public void updateControl(Combo profileCombo) {
      int i = 0, index = -1;
      
      profileCombo.removeAll();
      
      for (IConnectionProfile profile : profiles) {
         profileCombo.add(profile.getName());
         if (currProfile != null && profile.getName().equals(currProfile)) {
            index = i;
         }
         i++;
      }
      if (profileCombo.getItemCount() > 0 && index != -1) {
         profileCombo.select(index);
      }
      else {
         profileCombo.select(0);
      }
      /* TODO elsewhere
      if (!profileCombo.getText().equals(savedProfile)) {
         m_modeler.setDirty(true);
      }
      */
   }

   
   public void updateAllControls() {
      for (Combo combo : comboList) {
         updateControl(combo);
      }
   }
   
   public void updateProfiles() {
      profiles = profileManager.getProfiles();

      // Add list of profiles to combos
      updateAllControls();
      
   }

   public boolean setProfile(String newProfile) {
      boolean status = false;
      
      // only change if different than existing profile
      if (currProfile == null || (!currProfile.equals(newProfile) &&            
          profileManager.getProfileByName(newProfile) != null)) {
      
         // Disconnect network connection
         if (connected) {
            profile.disconnect();
            connected = false;
         }
         profile = null;
      
         currProfile = newProfile;
      
         // set current profile
         element.setAttribute(JUNETSU_DATABASE, currProfile);            
         modeler.setDirty(true);
         
         updateAllControls();
         
         status = true;
      }
      
      return status;
   }

   public String getProfile() {
      return currProfile;
   }

   // Connect to the database using the current profile
   public boolean connect() {      
      profile = profileManager.getProfileByName(currProfile);
      if (profile != null) {
         if (!connected) {               
            // Connect to the database
            profile.connect();

            // Designer will catch and report connection errors
            if (profile.getConnectionState() == IConnectionProfile.CONNECTED_STATE) {
               conn = ((ConnectionInfo)profile.getManagedConnection("org.eclipse.datatools.connectivity.sqm.core.connection.ConnectionInfo")
                     .getConnection().getRawConnection()).getSharedConnection();
               connected = true;        
            }
         }
      }

      return connected;
   }

   // disconnect from the database
   public void disconnect() {
      if (connected) {
         profile.disconnect();
         conn = null;
         connected = false;
      }
   }
   
   public Connection getConnection() {
      return conn;
   }
   
   public boolean isConnected() {
      return connected;
   }
   
   public boolean noProfiles() {
      return profiles.length == 0;
   }
   
   public String getProperty(String id) {
      String value = null;
      
      if (profile != null) {
         value = profile.getProperties("org.eclipse.datatools.connectivity.db.generic.connectionProfile")
                        .getProperty(id);            
      }
      
      return value;
   }
   
   public String addProfile() {
      // Run the New Profile Wizard for a new db profile
      AddProfileViewAction action = new AddProfileViewAction();
      
      action.init(Display.getCurrent().getActiveShell());
      action.run();

      String newProfile = null;
      if (action.getAddedProfile() != null) {
         newProfile = action.getAddedProfile().getName();
      }
      
      updateProfiles();
      setProfile(newProfile);
      action.dispose();
      
      return newProfile;
   }
   
   
   public void widgetDefaultSelected(SelectionEvent e) {
      widgetSelected(e);
   }

   public void widgetSelected(SelectionEvent e) {
      // set the profile to the selected profile
      Combo profileCombo = (Combo) e.widget;
      setProfile(profileCombo.getText());
   }
}
