package com.omnibond.designer.junetsu;

import com.novell.core.util.JavaUtil;

// Definitions for JuNetSu classes and attributes
public class JuNetSu {
   
   // Designer Model properties
   public static final String    JUNETSU_DATA               = "JuNetSuData";
   public static final String    JUNETSU_CONTAINER          = "JuNetSuContainer";
   public static final String    JUNETSU_LIVE_NETWORK       = "JuNetSuLiveNetwork";
   public static final String    JUNETSU_NAME               = "JunetsuName";
   public static final String    JUNETSU_FIRST_ADDRESS      = "JunetsuFirstAddress";
   public static final String    JUNETSU_LAST_ADDRESS       = "JunetsuLastAddress";
   public static final String    JUNETSU_CIDR               = "JunetsuCIDR";
   
   // Classes
   public static final String    CLASS_GROUP                = "DirXMLjnsuGroup";
   public static final String    CLASS_NETWORK_DEVICE       = "DirXMLjnsuNetworkDevice";
   public static final String    CLASS_USER                 = "DirXMLjnsuUser";

   // Attributes
   public static final String    ATTRIBUTE_DDNS_PREFIX      = "DirXMLjnsuDDNSPrefix";
   public static final String    ATTRIBUTE_DESCRIPTION      = "DirXMLjnsuDescription";
   public static final String    ATTRIBUTE_DEVICE           = "DirXMLjnsuDevice";
   public static final String    ATTRIBUTE_DEVICE_NAME      = "DirXMLjnsuDeviceName";
   public static final String    ATTRIBUTE_DHCP_ADDRESS     = "DirXMLjnsuDHCPAddress";
   public static final String    ATTRIBUTE_DHCP_GROUP       = "DirXMLjnsuDHCPGroup";
   public static final String    ATTRIBUTE_DISABLED         = "DirXMLjnsuDisabled";
   public static final String    ATTRIBUTE_DISABLED_TIME    = "DirXMLjnsuDisabledTime";
   public static final String    ATTRIBUTE_GROUP_DN         = "DirXMLjnsuGroupDN";
   public static final String    ATTRIBUTE_GROUP_SERVICES   = "DirXMLjnsuGroupServices";
   public static final String    ATTRIBUTE_HW_ADDRESS       = "DirXMLjnsuHWAddress";
   public static final String    ATTRIBUTE_INFECTED         = "DirXMLjnsuInfected";
   public static final String    ATTRIBUTE_INFECTED_PORTS   = "DirXMLjnsuInfectedPorts";
   public static final String    ATTRIBUTE_M_DISABLED       = "DirXMLjnsuMDisabled";
   public static final String    ATTRIBUTE_M_DISABLER       = "DirXMLjnsuMDisabler";
   public static final String    ATTRIBUTE_NVR_EXPIRES      = "DirXMLjnsuNvrExpires";
   public static final String    ATTRIBUTE_PEN_DELETE_TS    = "DirXMLjnsuPenDeleteTS";
   public static final String    ATTRIBUTE_REG_ADD_TIME     = "DirXMLjnsuRegAddTime";
   public static final String    ATTRIBUTE_REG_VERSION      = "DirXMLjnsuRegVersion";
   public static final String    ATTRIBUTE_STATIC_ADDR      = "DirXMLjnsuStaticAddr";
   public static final String    ATTRIBUTE_STATIC_ADDRS     = "DirXMLjnsuStaticAddrs";
   public static final String    ATTRIBUTE_USER_DN          = "DirXMLjnsuUserDN";
   public static final String    ATTRIBUTE_WHY_DISABLED     = "DirXMLjnsuWhyDisabled";
   
   // Database columns
   public static final String    COL_ACTION                 = "ACTION";
   public static final String    COL_DDNS_PREFIX            = "DDNS_PREFIX";
   public static final String    COL_DESCRIPTION            = "DESCRIPTION";
   public static final String    COL_DEVICE                 = "DEVICE";
   public static final String    COL_DEVICE_NAME            = "DEVICE_NAME";
   public static final String    COL_DISABLED               = "DISABLED";
   public static final String    COL_DISABLED_TIME          = "DISABLED_TIME";
   public static final String    COL_HW_ADDR                = "HW_ADDR";
   public static final String    COL_INFECTED               = "INFECTED";
   public static final String    COL_INFECTED_PORTS         = "INFECTED_PORTS";
   public static final String    COL_IP_ADDR                = "IP_ADDR";
   public static final String    COL_LOG_TIMESTAMP          = "LOG_TIMESTAMP";
   public static final String    COL_MDISABLED              = "MDISABLED";
   public static final String    COL_MDISABLER              = "MDISABLER";
   public static final String    COL_NEVER_EXPIRES          = "NEVER_EXPIRES";
   public static final String    COL_REG_ADD_TIME           = "REG_ADD_TIME";
   public static final String    COL_REG_VERSION            = "REG_VERSION";
   public static final String    COL_STATIC_ADDR            = "STATIC_ADDR";
   public static final String    COL_USER_DN                = "USER_DN";
   public static final String    COL_WHY_DISABLED           = "WHY_DISABLED";
   
   // Determine whether the input IP address is valid
   public static boolean validIPAddress(String addr) {
      
      if (!JavaUtil.hasString(addr)) {
         return false;
      }
      
      String[] octets = addr.split("\\.");
      int i = 0;
      boolean valid = (octets.length == 4);
      while (valid && i < 4) {
         // octet
         valid = (Integer.parseInt(octets[i]) >= 0 && Integer.parseInt(octets[i]) <= 255);
         i++;
      }
      
      return valid;

   }
   
   // Compare two IP addresses 
   // Return 1 if addr1 > addr2, -1 if addr1 < addr2 and 0 if equal
   public static int compareIPAddresses(String addr1, String addr2) {
      int rc = 0;
      
      String[] octets1 = addr1.split("\\.");
      String[] octets2 = addr2.split("\\.");
      int i = 0;
      while (rc == 0 && i++ < octets1.length) {
         rc = Integer.parseInt(octets1[i-1]) - Integer.parseInt(octets2[i-1]); 
      }

      return (int) Math.signum((float) rc);
   }
   
   // Return whether addr is within firstAddr and lastAddr
   // The caller must verify that lastAddr > firstAddr
   public static boolean addressInRange(String addr, String firstAddr, String lastAddr) {      
      return (JuNetSu.compareIPAddresses(addr, firstAddr) >= 0) && 
             (JuNetSu.compareIPAddresses(addr, lastAddr) <= 0);
   }
      
}
