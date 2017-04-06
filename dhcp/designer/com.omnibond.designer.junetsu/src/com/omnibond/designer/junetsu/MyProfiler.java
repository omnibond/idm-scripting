package com.omnibond.designer.junetsu;

import org.eclipse.osgi.internal.profile.Profile;

public class MyProfiler {

   public static void start(String id, String description) {
      Profile.logEnter(id, description);      
   }
   
   public static void stop(String id, String description) {
      Profile.logExit(id, description);
   }
   
   public static void report() {
      System.out.println(Profile.getProfileLog());
   }
   
}
