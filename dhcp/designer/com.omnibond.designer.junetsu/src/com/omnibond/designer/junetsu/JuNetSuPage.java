package com.omnibond.designer.junetsu;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.draw2d.ColorConstants;
import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.resource.ColorRegistry;
import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.ColumnViewer;
import org.eclipse.jface.viewers.EditingSupport;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.OwnerDrawLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.events.ControlListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.TabItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.ui.IEditorInput;
import org.eclipse.ui.IEditorSite;
import org.eclipse.ui.PartInitException;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.forms.events.HyperlinkEvent;
import org.eclipse.ui.forms.events.IHyperlinkListener;
import org.eclipse.ui.forms.widgets.ExpandableComposite;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.forms.widgets.Hyperlink;
import org.eclipse.ui.forms.widgets.Section;
import org.eclipse.ui.plugin.AbstractUIPlugin;

import com.novell.admin.common.exceptions.SPIException;
import com.novell.admin.ns.FilterResultModifier;
import com.novell.admin.ns.NSObject;
import com.novell.admin.ns.nds.NDSFilterResultModifier;
import com.novell.admin.ns.nds.NDSNamespace;
import com.novell.application.console.snapin.ObjectEntry;
import com.novell.application.console.snapin.ObjectEntryEnumeration;
import com.novell.core.CoreCursors;
import com.novell.core.datatools.access.nds.DSAccess;
import com.novell.core.datatools.access.nds.DSAccessException;
import com.novell.core.datatools.access.nds.DSUtil;
import com.novell.core.datatools.edirbrowser.EDirBrowser;
import com.novell.core.util.DNConverter;
import com.novell.core.util.JavaUtil;
import com.novell.core.util.Log;
import com.novell.idm.IdmApp;
import com.novell.idm.IdmModel;
import com.novell.idm.model.DesignElement;
import com.novell.idm.model.IdentityVault;
import com.novell.idm.model.IdmModelFactory;
import com.novell.idm.model.IdmModelPackage;
import com.novell.idm.model.Project;
import com.novell.idm.model.ProjectData;
import com.novell.idm.modeler.GlobalModelEditor;
import com.novell.idm.modeler.IGlobalModelEditorIntegrator;
import com.novell.idm.modeler.Modeler;
import com.novell.idm.modeler.pages.IModelerPage;
import com.novell.idm.modeler.util.ModelerUtil;
import com.novell.idm.services.ModelerEventManager;

public class JuNetSuPage 
   extends Modeler 
   implements IModelerPage, 
              IGlobalModelEditorIntegrator
{

   String[] attributes = { JuNetSu.ATTRIBUTE_DHCP_ADDRESS, JuNetSu.ATTRIBUTE_HW_ADDRESS, JuNetSu.ATTRIBUTE_USER_DN,
         JuNetSu.ATTRIBUTE_REG_ADD_TIME, JuNetSu.ATTRIBUTE_DESCRIPTION, JuNetSu.ATTRIBUTE_DISABLED,
         JuNetSu.ATTRIBUTE_INFECTED, JuNetSu.ATTRIBUTE_INFECTED_PORTS, JuNetSu.ATTRIBUTE_STATIC_ADDR,
         JuNetSu.ATTRIBUTE_NVR_EXPIRES };

   // class stores info needed for search
   private class RegSearchInput 
   {      
      public static final String VAULT = "Vault";
      public static final String CONTAINER = "Container";
      public static final String SEARCH_MODE = "Search Mode";
      public static final String IP_ADDRESS = "IP Address";
      public static final String MAC_ADDRESS = "MAC Address";
      public static final String USER_DN = "User DN";
      public static final String ADDED_FROM = "Added From";
      public static final String ADDED_TO = "Added To";
      public static final String WHEN_ADDED = "When Added";
      public static final String DESCRIPTION = "Description";
      public static final String DISABLED = "Disabled";
      public static final String INFECTED = "Infected";
      public static final String INF_PORTS = "Inf. Ports";
      public static final String STATIC = "Static";
      public static final String NEVER_EXPIRES = "Never Expires";
      
      private HashMap<String, String> properties = new HashMap<String, String>();
      
      public RegSearchInput() {
      }
      
      public void setPropertyValue(String key, String value) {         
         if (properties.get(key) != null) {
            properties.remove(key);
         }
         if (JavaUtil.hasString(value)) {
            properties.put(key, value);
         }
      }
      
      public String getPropertyValue(String key) {
         return properties.get(key) != null ? properties.get(key) : "";
      }
                  
   }   

   private class RegSearchContentProvider 
     implements IStructuredContentProvider 
   {

      RegSearchInput m_searchInput = null;
      String      m_message = null, m_helpString = null;
      Table       m_table;
      Object[]    cachedElements;
      boolean     changedFlag = true;      
      
      @Override
      public Object[] getElements(Object inputElement) {
         Object[] elements = new Object[0];
         
         // check input
         if (m_searchInput == null) {
            if (m_helpString != null) {
               elements = new Object[1];
               elements[0] = new String(m_helpString);
            }
            return elements;
         }
      
         if (!changedFlag) 
            return cachedElements;
            
         // locate Identity Vault
         IdentityVault vault = null;         
         if (project != null && project.getDomain() != null) {
            List<IdentityVault> vaults = IdmModel.findAllIdentityVaults(project.getDomain());
            Iterator<IdentityVault> iter = vaults.iterator();
            while (iter.hasNext()) {
               vault = iter.next();
               if (vault.getName().equals(m_searchInput.getPropertyValue(RegSearchInput.VAULT))) {
                  break;
               }
               else {
                  vault = null;
               }
            }
            if (vault == null) {
               m_message = "Error: could not locate an Identity Vault. Create an Identity Vault in the Developer.";
               return elements;
            }
         }   
         // Create list for entries
         DSAccess dsAccess = null;
         try {               
            dsAccess = getDSAccess(vault);
            if (dsAccess == null) {
               // a message has been set, or likely an exception has been thrown
               return elements;
            }
         }
         catch (Exception e) {
            e.printStackTrace();
            m_message = "Error: could not access eDirectory.\n" + e.getMessage();
            
            return elements;
         }
         // Do a user search if necessary
         if (!doUserSearch(dsAccess)) {
            m_message = "Error: could not locate user matching \"" + m_searchInput.getPropertyValue(RegSearchInput.USER_DN) + 
                        "\"";
            return elements;
         }
               
         ObjectEntry containerOE = null;
         try {
            // Get base container OE
            containerOE = DSUtil.getOEFromDN(dsAccess, m_searchInput.getPropertyValue(RegSearchInput.CONTAINER));
         }
         catch (SPIException e) {
            e.printStackTrace();
            m_message = "Error: could not open specified Base Container\n" + e.getMessage();
            
            return elements;
         }
         
         // Create filter 
         NDSFilterResultModifier.Filter filter = new NDSFilterResultModifier.Filter();
         NDSFilterResultModifier.FilterItemGroup filterItemGroup = new NDSFilterResultModifier.FilterItemGroup();
               
         // Filter modifier - defaults to OR (any) match
         String modifier = FilterResultModifier.OR;
         String searchMode = m_searchInput.getPropertyValue(RegSearchInput.SEARCH_MODE);
         if (searchMode.equals("all")) {
            modifier = FilterResultModifier.AND;
         }

         // Search fields
         // user ID
         filterItemGroup = new NDSFilterResultModifier.FilterItemGroup();
               
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.USER_DN))) {
            // search on UserID
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_USER_DN, "=", m_searchInput.getPropertyValue(RegSearchInput.USER_DN), 
                                          modifier);
         }
         // IP Address
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.IP_ADDRESS))) {
            // search on UserID
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_DHCP_ADDRESS, "=", m_searchInput.getPropertyValue(RegSearchInput.IP_ADDRESS),                          
                                          modifier);
         }
         // MAC (HW) Address
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.MAC_ADDRESS))) {
            // search on UserID
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_HW_ADDRESS, "=", m_searchInput.getPropertyValue(RegSearchInput.MAC_ADDRESS), 
                                          modifier);
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.DESCRIPTION))) {
            // search on Description
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_DESCRIPTION, "=", m_searchInput.getPropertyValue(RegSearchInput.DESCRIPTION),
                                          modifier);
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.DISABLED))) {
            // search on Disabled... the value will be true
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_DISABLED, "=", "true", modifier);
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.INFECTED))) {
            // search on Infected... the value will be true
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_INFECTED, "=", "true", modifier);
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.STATIC))) {
            // search on Static... the value will be true
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_STATIC_ADDR, "=", "true", modifier);
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.NEVER_EXPIRES))) {
            // search on Never Expires... the value will be true
            filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_NVR_EXPIRES, "=", "true", modifier);
         }
               
         // Add group if any filter items exist
         if (filterItemGroup.getFilterItems().length > 0) {
            filter.addFilterItemGroupPair(filterItemGroup, FilterResultModifier.AND);
         }
               
         // Date search
         filterItemGroup = new NDSFilterResultModifier.FilterItemGroup();
         String[] formats = {"yyyy-MM-dd HH:mm:ss z", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd"};
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.ADDED_FROM))) {
            // Greater or equal than the from date... expressed in seconds from the epoch
            int i = 0;
            Date date = null;
            while (date == null && i < formats.length) {                  
               try {
                  date = new SimpleDateFormat(formats[i++]).parse(m_searchInput.getPropertyValue(RegSearchInput.ADDED_FROM));
               }
               catch (ParseException e) {  }
            }
            if (date != null) {
               String value = new Long(date.getTime() / 1000).toString();
               filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_REG_ADD_TIME, ">=", value, FilterResultModifier.AND);
            }
            else {
               m_message = "Error: Earliest Time Added is not in the correct format";
            }
         }
         if (JavaUtil.hasString(m_searchInput.getPropertyValue(RegSearchInput.ADDED_TO))) {
            // Less than or equal to the to date
            int i = 0;
            Date date = null;
            while (date == null && i < formats.length) {                  
               try {
                  date = new SimpleDateFormat(formats[i++]).parse(m_searchInput.getPropertyValue(RegSearchInput.ADDED_TO));
               }
               catch (ParseException e) {  }
            }
            if (date != null) {
               String value = new Long(date.getTime() / 1000).toString();
               filterItemGroup.addFilterItem(JuNetSu.ATTRIBUTE_REG_ADD_TIME, "<=", value, FilterResultModifier.AND);
            }
            else {
               m_message = "Error: Latest Time Added is not in the correct format";                  		
            }
         }
            
         // Add group if any filter items exist
         if (filterItemGroup.getFilterItems().length > 0) {
            filter.addFilterItemGroupPair(filterItemGroup, FilterResultModifier.AND);
         }
            
         // Next group: Object class... search only JuNetSu Network Devices
         filterItemGroup = new NDSFilterResultModifier.FilterItemGroup();
         filterItemGroup.addFilterItem(DSUtil.ATTRIBUTE_OBJECT_CLASS, "=", JuNetSu.CLASS_NETWORK_DEVICE, 
                                       FilterResultModifier.AND);
         filter.addFilterItemGroupPair(filterItemGroup, null);

         // Execute the search
         NDSNamespace ndsNS = dsAccess.getNDSNamespace();
         ObjectEntryEnumeration registrations = null; 
         try {
            MyProfiler.start("junetsu#ivsearch", "IV Search");
            registrations = ndsNS.getChildren(containerOE, new NDSFilterResultModifier("", filter, true));
            MyProfiler.stop("junetsu#ivsearch", "IV Search");
         }
         catch (Exception e) {
            e.printStackTrace();
            m_message = "Error: search error." + e.getMessage();
            
            return elements;
         }
         MyProfiler.start("junetsu#entrycopy", "Entry Copy");
         List<ObjectEntry> entries = new ArrayList<ObjectEntry>();
         while (registrations.hasMoreElements()) {
            entries.add(registrations.next());
         }

         elements = new Object[entries.size()];
         entries.toArray(elements);
               
         // Copy elements to cache         
         cachedElements = new Object[elements.length];
         System.arraycopy(elements, 0, cachedElements, 0, elements.length);
               
         MyProfiler.stop("junetsu#entrycopy", "Entry Copy");
         
         changedFlag = false;         
               
         // Set message label
         if (entries.size() == 1) {
            m_message = "1 entry found";
         }
         else {
            m_message = entries.size() + " entries found";
         }
         
         // LabelProvider and ImageProvider will advance the monitor (progress bar)
         monitor.done();
         monitor.beginTask("Loading entries...", entries.size() * attributes.length-1);
         MyProfiler.start("junetsu#entryprocess", "Entry Process");

         return elements;
      }

      @Override
      public void dispose() {
         System.out.println("RegSearchContentProvider.dispose()");
      }

      @Override
      public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
         if (newInput instanceof RegSearchInput) {
            m_searchInput = (RegSearchInput) newInput;
         }
         else if (newInput instanceof String) {
            m_helpString = (String) newInput;
         }
         m_table = (Table) viewer.getControl();
         changedFlag = true;
      }
      
      private DSAccess getDSAccess(IdentityVault vault)
         throws SPIException, DSAccessException
      {
         DSAccess dsAccess = null;
         // Check 
         if (!JavaUtil.hasString(vault.getHost())) {
            m_message = "Error: specify the Identity Vault's Host Address property";
         }
         else if (!JavaUtil.hasString(vault.getUserName())) {
            m_message = "Error: specify the Identity Vault's User Name property";
         }
         else if (!JavaUtil.hasString(vault.getPassword())) {
            m_message = "Error: specify the Identity Vault's Password property";
         }
         else {          
            dsAccess = vault.getDSAccess();
         }
         
         return dsAccess;         
      }
      
      private boolean doUserSearch(DSAccess dsAccess) 
      {
         // User search pattern can be entered as
         //   <name>
         //   <name pattern>*
         //   <name pattern>*.container.etc
         boolean rc = true;
                  
         String userString = m_searchInput.getPropertyValue(RegSearchInput.USER_DN);
         // if just a name is entered, or a wildcard is entered, do a search
         if (JavaUtil.hasString(userString) && (!userString.contains(".") || userString.contains("*"))) {
            // split out container if necessary
            ObjectEntry containerOE;
            String userName = "";
            if (userString.contains(".")) {
               userName = userString.substring(0, userString.indexOf('.')-1);
               String container = userString.substring(userString.indexOf('.')+1, userString.length());
               try {
                  containerOE = DSUtil.getOEFromDN(dsAccess, container);
               }
               catch (SPIException e) {
                  e.printStackTrace();
                  m_message = "Error: could not open user container \"" + container + "\".\n" + e.getMessage();
                  return false;
               }
            }
            else {
               userName = userString;
               containerOE = dsAccess.getRootOE();
            }
            //ObjectEntry containerOE = dsAccess.getRootOE();
            // Do search for user on CN attribute
            NDSFilterResultModifier.FilterItemGroup filterItemGroup = new NDSFilterResultModifier.FilterItemGroup();
            filterItemGroup.addFilterItem(DSUtil.ATTRIBUTE_OBJECT_CLASS, "=", DSUtil.CLASS_USER, 
                  FilterResultModifier.AND);
            filterItemGroup.addFilterItem(DSUtil.ATTRIBUTE_CN, "=", userName, null);
            
            NDSFilterResultModifier.Filter filter = new NDSFilterResultModifier.Filter();
            filter.addFilterItemGroupPair(filterItemGroup, null);
            
            // Execute the search
            NDSNamespace ndsNS = dsAccess.getNDSNamespace();
            ObjectEntryEnumeration users = null;
            try {
               users = ndsNS.getChildren(containerOE, new NDSFilterResultModifier("", filter, true));
            }
            catch (SPIException e) {
               m_message = "Error: search for user.\n" + e.getMessage();
            }
            
            ObjectEntry userOE = null;
            // TODO: for now just select first object
            if (users.hasMoreElements())
               userOE = users.next();
            
            if (userOE != null) {
               // Set search DN to user value
               String userDN = DSUtil.getDNFromOE(userOE);
               m_searchInput.setPropertyValue(RegSearchInput.USER_DN, userDN);
            }
            else {
               rc = false;
            }
            
         }
         
         return rc;
      }
      
      public String getMessage() {
         return m_message;
      }
   }
   
   private class RegSearchObjectCache {
      
      private ObjectEntry m_element = null;
      private NSObject m_nso = null;
      
      public NSObject getNSObject(ObjectEntry element) {
         if (element != m_element) {
            try {
               m_nso = DSUtil.getNSOFromOE(element);
               m_element = element;               
            }
            catch (SPIException e) {
               // TODO: log error?
               e.printStackTrace();
               m_nso = null;
            }
         }
         
         return m_nso;
      }
   }
      
   private class RegSearchImageProvider extends OwnerDrawLabelProvider {
      
      String m_attribute, m_imageName;
      RegSearchObjectCache m_objectCache;
      
      public RegSearchImageProvider(String attribute, String imageName, RegSearchObjectCache objectCache) {
         m_attribute = attribute;
         m_imageName = imageName;
         m_objectCache = objectCache;
      }
      
      @Override
      protected void measure(Event event, Object element) { 
         event.width = 32; 
      }

      @Override
      protected void paint(Event event, Object element) {
         Image image = null;
         
         if (element instanceof ObjectEntry) {
            try {
               // Check if attribute is true
               String value = null;
               if (m_attribute == null) {
                  // always draw image for the Delete button column
                  value = "true";
               }
               else {
                  NSObject nso = m_objectCache.getNSObject((ObjectEntry) element);
                  if (nso != null) {
                    value = DSUtil.getCIStringFromAttribute(nso, m_attribute);
                  }
               }
               
               if (value != null && value.equalsIgnoreCase("true")) {
                  // Get image
                  image = AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, m_imageName).createImage();                     
               }
               if (image != null) {
                  // Paint centered image
                  Rectangle bounds = ((TableItem) event.item).getBounds(event.index);
                  int width = bounds.width;
                  int height = bounds.height;
                  Rectangle imgBounds = image.getBounds();
                  width /= 2;
                  width -= imgBounds.width / 2;
                  // fudge for border lines
                  //width -= 2;
                  height /= 2;
                  height -= imgBounds.height / 2;
                  
                  int x = width > 0 ? bounds.x + width : bounds.x;
                  int y = height > 0 ? bounds.y + height : bounds.y;
                  
                  event.gc.drawImage(image, x, y);
               }
            }
            finally {               
               monitor.worked(1);
               event.display.readAndDispatch();
            }
         }         
      }      
   }
   
   private class RegSearchLabelProvider extends ColumnLabelProvider
      
   {      
      private String m_attribute;
      private RegSearchObjectCache m_objectCache;
      
      public RegSearchLabelProvider(String attribute, RegSearchObjectCache objectCache) {
         m_attribute = attribute;
         m_objectCache = objectCache;
      }
      
      @Override
      public String getText(Object element) {
         String text = null;
         if (element instanceof ObjectEntry) {
            try {
               NSObject nso = m_objectCache.getNSObject((ObjectEntry) element);
               if (nso != null) {
                  if (m_attribute.equals(JuNetSu.ATTRIBUTE_REG_ADD_TIME)) {
                     String tstamp = DSUtil.getCIStringFromAttribute(nso, m_attribute);
                     if (JavaUtil.hasString(tstamp)) {
                        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
                        text = df.format(new Date(Long.parseLong(tstamp)*1000));
                     }                  
                  }
                  else if (m_attribute.equals(JuNetSu.ATTRIBUTE_NVR_EXPIRES)) {
                     Boolean value = DSUtil.getBooleanFromAttribute(nso, m_attribute);
                     text = (value != null && value.booleanValue()) ? "yes" : "no";                  
                  }
                  else if (m_attribute.equals(JuNetSu.ATTRIBUTE_INFECTED_PORTS)) {
                     // The format is {port}-{hits}[,{port}-{hits},...]
                     // Only display port numbers
                     String value = DSUtil.getCIStringFromAttribute(nso, m_attribute);                  
                     text = "";
                     if (value != null) {
                        String[] tokens = value.split(",");                  
                        for (int i = 0; i < tokens.length; i++) {
                           if (tokens[i].indexOf("-") != -1) {
                              text = text + tokens[i].substring(0, tokens[i].indexOf("-"));
                           }
                           else {
                              text = text + tokens[i];
                           }
                           if (i != tokens.length-1) {
                              text = text + ",";
                           }
                        }
                     }
                  }
                  else if (m_attribute.equals(JuNetSu.ATTRIBUTE_USER_DN)) {
                     // Only show the user name
                     String value = DSUtil.getCIStringFromAttribute(nso, m_attribute);
                     if (value != null) {
                        text = value.substring(0, value.indexOf("."));
                     }
                  }
                  else {
                     text = DSUtil.getCIStringFromAttribute(nso, m_attribute);
                     if (m_attribute.equals(JuNetSu.ATTRIBUTE_STATIC_ADDR)) {                     
                        text = (text != null && text.equals("true")) ? "yes" : "no";
                     }                  
                  }
               }
            }
            finally {
               monitor.worked(1);
               Display.getCurrent().readAndDispatch();
            }            
         }
         else if (element instanceof String) {
            text = (String) element;
         }
         return text;
      }
      
   }
   
   private class RegSearchFilter 
      extends ViewerFilter {

      String m_address;
      boolean m_active;
      //int[] m_octets;
      int m_prefix, m_prefixmask, m_bitmask;
      String m_search;
      
      public RegSearchFilter(String address) {
         m_active = false;
         // Check if the pattern is in CIDR notation (IP addr/n)
         if (JavaUtil.hasString(address)) {
            m_address = address;
            m_active = m_address.matches("[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+");
            if (m_active) {
               // divide address into octets and prefix length
               String[] tokens = m_address.split("[\\./]");
               if (tokens != null && tokens.length == 5) {
                  int[] octets = new int[4];
                  for (int i = 0; i < 4; i++) {
                     try {
                        octets[i] = Integer.parseInt(tokens[i]);
                     }
                     catch (Exception e) { octets[i] = -1; }
                     // verify valid range
                     m_active = m_active && (octets[i] >= 0 && octets[i] <= 255);
                  }
                  try {
                     m_prefix = Integer.parseInt(tokens[4]);
                  }
                  catch (Exception e) { m_prefix = 0; }
                  m_active = m_active && (m_prefix > 0 && m_prefix < 31);
                  // Create the bitmask for filtering 
                  if (m_active) {
                     m_prefixmask = ((int) Math.pow((double) 2, (double) m_prefix) - 1) << (32 - m_prefix);
                     int addr32 = 0;
                     for (int i = 0, shift = 24; i < 4; i++, shift -= 8) {
                        addr32 += octets[i] << shift;
                     }
                     m_bitmask = addr32 & m_prefixmask;
                     
                     // Build search pattern for eDir search... 
                     // adds one octet for each 8 bits of the prefix
                     m_search = "";
                     for (int i = 0; i < m_prefix / 8; i++ ) {
                        m_search += octets[i] + ".";
                     }
                     m_search += "*";
                  }

               }
               else {
                  m_active = false;
               }
            }
         }
      }
      
      public boolean getValid() {
         return m_active;
      }
      
      // The IP addr search string to be used in the eDir search 
      public String getSearchString() {
         return m_search;
      }
      
      @Override
      public boolean select(Viewer viewer, Object parentElement, Object element) {
         // An inactive filter returns everything
         // In practice it probably won't be used
         if (!m_active) return true;

         if (element instanceof ObjectEntry) {
            try {
               // Does one object at a time, so caching won't help
               NSObject nso = DSUtil.getNSOFromOE((ObjectEntry) element);
               String address = DSUtil.getCIStringFromAttribute(nso, JuNetSu.ATTRIBUTE_DHCP_ADDRESS);
               // Parse address into 32-bit value               
               String[] octets = address.split("\\.");               
               int addr32 = 0;
               for (int i = 0, shift = 24; i < 4; i++, shift -= 8) {
                  try { 
                     addr32 += Integer.parseInt(octets[i]) << shift;
                  }
                  catch (Exception e) { };
               }
               // get the valid bits for the "network"
               int net = addr32 & m_prefixmask;
               // return true if networks are equal
               return (net == m_bitmask);
            }
            catch (SPIException e) {
               e.printStackTrace();
            }
         }         
         return false;
      }
      
   }
   
   private class RegSearchComparator
      extends ViewerComparator 
   {

      private String m_sortAttribute;
      private int m_sortDirection, m_cacheNum = 0;
      private String m_message;
      private RegSearchObjectCache[] m_caches;
      
      public RegSearchComparator(String sortAttribute, int sortDirection) {
         m_sortAttribute = sortAttribute;
         m_sortDirection = sortDirection;
         m_caches = new RegSearchObjectCache[2]; 
         m_caches[0] = new RegSearchObjectCache();
         m_caches[1] = new RegSearchObjectCache();
      }
      
      @Override
      public int compare(Viewer viewer, Object e1, Object e2) {
         int rc = 0;
         NSObject nso1 = null, nso2 = null;
         
         try {
            // Get eDir object info
            // Use caching to improve performance...
            // Compares A to B, then B to C (etc.), so which cache is used flips
            // back and forth
            
            nso1 = m_caches[m_cacheNum].getNSObject((ObjectEntry) e1);
            nso2 = m_caches[1 - m_cacheNum].getNSObject((ObjectEntry) e2);
            
            /*
            nso1 = DSUtil.getNSOFromOE((ObjectEntry) e1);
            nso2 = DSUtil.getNSOFromOE((ObjectEntry) e2);
            */
            
            m_cacheNum = 1 - m_cacheNum;            
         }
         catch (Exception e) {
            e.printStackTrace();
            m_message = "Error during compare.\n" + e.getMessage();
            return rc;
         }

         if (m_sortAttribute.equals(JuNetSu.ATTRIBUTE_NVR_EXPIRES)) {
            // Compare boolean Never Expires attribute
            Boolean b1 = DSUtil.getBooleanFromAttribute(nso1, m_sortAttribute);
            Boolean b2 = DSUtil.getBooleanFromAttribute(nso2, m_sortAttribute);
            if (b1 == null && b2 == null) {
               rc = 0;
            }
            else if (b1 == null) {
               rc = -1;
            }
            else if (b2 == null) {
               rc = 1;
            }
            else {
               rc = b1.compareTo(b2);
            }
         }
         else {
            // Compare string attributes
            String s1 = DSUtil.getCIStringFromAttribute(nso1, m_sortAttribute);
            String s2 = DSUtil.getCIStringFromAttribute(nso2, m_sortAttribute);
            if (!JavaUtil.hasString(s1) && !JavaUtil.hasString(s2)) {
               rc = 0;
            }
            else if (!JavaUtil.hasString(s1)) {
               rc = -1;
            }
            else if (!JavaUtil.hasString(s2)) {
               rc = 1;                                    
            }
            else {
               // compare timestamps
               if (m_sortAttribute.equals(JuNetSu.ATTRIBUTE_REG_ADD_TIME)) {                     
                  long l1 = Long.parseLong(s1); 
                  long l2 = Long.parseLong(s2);
                  
                  rc = new Long(l1).compareTo(new Long(l2));
               }
               // do numerical comparison for IP Address
               else if (m_sortAttribute.equals(JuNetSu.ATTRIBUTE_DHCP_ADDRESS)) {
                  String[] octets1 = s1.split("\\.");
                  String[] octets2 = s2.split("\\.");
                  int i = 0;
                  while (rc == 0 && i++ < octets1.length) {
                     rc = Integer.parseInt(octets1[i-1]) - Integer.parseInt(octets2[i-1]); 
                  }
               }
               else {
                  rc = s1.compareToIgnoreCase(s2);
               }
            }
         }
                  
         // Invert sort direction
         if (m_sortDirection == SWT.DOWN)
            rc *= -1;
         
         // Prevent slowdown
         Display.getCurrent().readAndDispatch();
         
         return rc;
      }
      
      public String getMessage() {
         return m_message;
      }
   }
   
   private class RegSearchComparatorListener 
      implements Listener 
   {
      TableViewer m_viewer;
      boolean locked = false;
      
      public RegSearchComparatorListener(TableViewer viewer) {
         m_viewer = viewer;
      }
      
      @Override
      public void handleEvent(Event event) {
         // only do one sort at a time!
         if (locked) return;
         
         TableColumn column = (TableColumn) event.widget;
         Table table = column.getParent();
         TableColumn[] columns = table.getColumns();
         int i = 0;
         for ( ; i < table.getColumnCount(); i++) {
            if (column.equals(columns[i])) {
               break;
            }
         }
         
         String sortAttribute = attributes[i-1];
         
         TableColumn sortColumn = table.getSortColumn();
         // Change direction if same column selected
         int sortDirection = SWT.UP;
         if (sortColumn != null) {
            if (sortColumn.equals(column)) {
               table.setSortDirection(table.getSortDirection() == SWT.UP ? SWT.DOWN : SWT.UP);
               sortDirection = table.getSortDirection();
            }
            else {               
               table.setSortDirection(SWT.UP);
            }
         }
         else {
            // This is the first time a sort has been selected
            table.setSortDirection(SWT.UP);
         }
         
         // Make this column the sort column 
         table.setSortColumn(column);
         
         // Resort by creating new comparator
         RegSearchComparator searchComparator = new RegSearchComparator(sortAttribute, sortDirection); 
         MyProfiler.start("junetsu#sort", "IV Sort");
         try {
            locked = true;  
            searchBtn.setEnabled(false);
            table.getShell().setCursor(CoreCursors.AppStarting);
            m_viewer.setComparator(searchComparator);
         }
         finally {
            locked = false;
            searchBtn.setEnabled(true);
            table.getShell().setCursor(CoreCursors.Normal);
         }
         MyProfiler.stop("#junetsu#sort", "IV Sort");
         MyProfiler.report();
         if (JavaUtil.hasString(searchComparator.getMessage())) {
            updateMessageLabel(searchComparator.getMessage());
         }         
      }
            
   }
   
   // This class handles deletion of registrations
   private class RegSearchDeleter
     implements MouseListener
   {
      
      private boolean buttonFlag = false;

      @Override
      public void mouseDoubleClick(MouseEvent e) {
         
      }

      @Override
      public void mouseDown(MouseEvent e) {
         Table table = (Table) e.widget;
         TableColumn[] columns = table.getColumns();
         if (e.x <= (columns[0].getWidth())) {
            buttonFlag = true;
         }         
      }

      @Override
      public void mouseUp(MouseEvent e) {
         if (buttonFlag) {
            buttonFlag = false;
            Table table = (Table) e.widget;
            TableColumn[] columns = table.getColumns();
            if (e.x <= (columns[0].getWidth())) {
               TableItem item = table.getItem(new Point(e.x, e.y));
               if (item != null && item.getData() != null && item.getData() instanceof ObjectEntry) {
                  deleteRegistration(item);
               }
            }
         }         
      }
      
      private void deleteRegistration(TableItem item) {
         if (MessageDialog.openQuestion(item.getParent().getShell(), 
               "Junetsu Plug-in",
               "Are you sure you wish to delete this network registration? Network access will be terminated for its user.")) {
            ObjectEntry entry = (ObjectEntry) item.getData();
            IdentityVault vault = getIdentityVault();
            try {
               // delete the object from eDirectory
               DSUtil.deleteObjectFromNds(entry, vault.getDSAccess().getNDSNamespace());
               
               // redo the search to refresh the viewer
               doSearch();
            }
            catch (Exception e) {
               MessageDialog.openError(item.getParent().getShell(), "Junetsu Plug-in", "An error deleted the registration has occurred and recorded in the error log.");
               Log.error(e);
            }
         }
      }
   }
   
   public class RegSearchEditingSupport 
      extends EditingSupport
   {
      String m_attribute;
      RegSearchCellEditor cellEditor;
      
      public RegSearchEditingSupport(ColumnViewer viewer, String attribute) {
         super(viewer);
         m_attribute = attribute;
         cellEditor = new RegSearchCellEditor(((TableViewer) viewer).getTable(), m_attribute);
      }

      @Override
      protected boolean canEdit(Object element) {
         return true;
      }

      @Override
      protected CellEditor getCellEditor(Object element) {         
         return cellEditor;
      }

      @Override
      protected Object getValue(Object element) {
         String value = null;
         
         try {            
            NSObject nso = DSUtil.getNSOFromOE((ObjectEntry) element);
            if (nso != null) {
               value = DSUtil.getCIStringFromAttribute(nso, m_attribute);
               if (value != null && m_attribute.equals(JuNetSu.ATTRIBUTE_USER_DN)) {
                  value = value.substring(0, value.indexOf("."));
               }
            }
         }
         catch (SPIException e) {
            e.printStackTrace();
            Log.error(e);
         }
                  
         return value;
      }

      @Override
      protected void setValue(Object element, Object value) {
         // We don't actually modify a value         
      }
            
   }
   
   public class RegSearchCellEditor
      extends CellEditor
   {      
      class MyHyperlink extends Hyperlink {
         public MyHyperlink(Composite parent, int style) {
            super(parent, style);
         }
         
         public void setMarginWidth(int width) {
            marginWidth = width;
         }
         
         public void setMarginHeight(int height) {
            marginHeight = height;
         }
         
      }
      
      private MyHyperlink m_link;
      String m_attribute;
      
      public RegSearchCellEditor(Composite parent, String attribute) {
         super(parent);
         m_attribute = attribute;
      }
      
      @Override
      protected Control createControl(Composite parent) {
         m_link = new MyHyperlink(parent, getStyle());
         m_link.setMarginHeight(2);
         m_link.setMarginWidth(6);
         m_link.setBackground(parent.getBackground());
         m_link.setUnderlined(true);
         m_link.setForeground(ColorConstants.blue);                  
         m_link.addHyperlinkListener( new IHyperlinkListener() {

            @Override
            public void linkActivated(HyperlinkEvent e) {
               tabFolder.setSelection(1);
               tabFolder.getShell().setDefaultButton(jnsHistory.searchBtn);
               jnsHistory.externalSearch(m_attribute, m_link.getText());
            }

            @Override
            public void linkEntered(HyperlinkEvent e) {      }

            @Override
            public void linkExited(HyperlinkEvent e) {      }
            
         });
         
         return m_link;
      }

      @Override
      protected Object doGetValue() {
         return m_link != null ? m_link.getText() : null;
      }

      @Override
      protected void doSetFocus() {  }

      @Override
      protected void doSetValue(Object value) {
         m_link.setText("");
         if (value instanceof String) {
            m_link.setText((String) value);
            m_link.setToolTipText("Show history for " + ((String) value));
         }         
      }
      
   }
      
   private int AVG_CHAR_WIDTH, AVG_CHAR_HEIGHT, DEFAULT_WIDTH;

   private TabFolder tabFolder;
   private FormToolkit toolkit;
   private IProgressMonitor monitor;
   private Combo vaultCombo;
   private Label messageLabel;
   private Text cntrText, useridText, ipText, macText, descText, addedFromText, addedToText;
   private Button allBtn, anyBtn, disabledBtn, infectedBtn, staticBtn, expiresBtn, searchBtn;
   private TableViewer resultsTableViewer;
   private Table resultsTable;
   private RegSearchContentProvider searchContentProvider;
   private boolean pageCreated = false;
   private boolean firstTime = false;
   private boolean focus = false;
   private ColorRegistry colorRegistry = null;
   private DesignElement dataElement = null;
   private Modeler modeler = null;
   private IdmModelFactory factory = null;
   private Project project = null;
   private String baseContainer;
   private JuNetSuHistory jnsHistory = null;
   private JunetsuLive jnsLive = null;
   
   public JuNetSuPage() {
      super();
      modeler = this;
      ModelerEventManager.getInstance().notifyLoading( IdmApp.getInstance().getSelectedProject() );
      colorRegistry = PlatformUI.getWorkbench().getThemeManager().getCurrentTheme().getColorRegistry();
   }

   public JuNetSuPage(GlobalModelEditor globalEditor) {
      super(globalEditor);
      modeler = this;
      ModelerEventManager.getInstance().notifyLoading( IdmApp.getInstance().getSelectedProject() );
      colorRegistry = PlatformUI.getWorkbench().getThemeManager().getCurrentTheme().getColorRegistry();
   }

   @Override
   public void init(IEditorSite site, IEditorInput input)
         throws PartInitException {
      super.init(site, input);

      // Get progress monitor
      monitor = getEditorSite().getActionBars().getStatusLineManager().getProgressMonitor();

      // Create Model Factory for saving data
      Map<String, Object> registry = EPackage.Registry.INSTANCE;
      IdmModelPackage modPackage = (IdmModelPackage) registry.get(IdmModelPackage.eNS_URI);
      factory = modPackage.getIdmModelFactory();
      if (factory == null) {
         throw new PartInitException("Could not get IDM Model Factory");
      }     
      
      // Get the active Project 
      project = ModelerUtil.getProject();
      ProjectData projectData = null;
      if (project != null) {
         projectData = project.getProjectData();
      }
      if (project == null || projectData == null) {
         throw new PartInitException("Could not locate Project or ProjectData object");
      }
      
      // Look for a previously saved element
      List<DesignElement> elements = projectData.getDesignElements();
      Iterator<DesignElement> iter = elements.iterator();
      while (iter.hasNext()) {
         DesignElement element = iter.next();
         if (element.getType().equals(JuNetSu.JUNETSU_DATA)) {
            // Set the element and the base container
            dataElement = element;
            baseContainer = element.getValueString(JuNetSu.JUNETSU_CONTAINER);
            break;
         }
      }

      // Create the data element
      if (dataElement == null) {
         firstTime = true;
         dataElement = factory.createDesignElement();
         dataElement.setParent(projectData);
         dataElement.setType(JuNetSu.JUNETSU_DATA);
         
         projectData.internalSetEnableNotifications(false);
         projectData.getDesignElements().add(dataElement);
         projectData.internalSetEnableNotifications(true);
      }
   }
   
   private void createRegistrationSearchSection(Section section) {
      // Search Composite
      Composite mainComposite = toolkit.createComposite(section);      
      FormData layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 2);
      layoutData.bottom = new FormAttachment(100, 0);
      layoutData.left = new FormAttachment(0, 2);
      layoutData.right = new FormAttachment(100, -2);      
      mainComposite.setLayoutData(layoutData);
      GridLayout gridLayout = new GridLayout(1, false);
      gridLayout.verticalSpacing = 2;
      mainComposite.setLayout(gridLayout);
      
      section.setClient(mainComposite);
      
      Composite vaultComposite = toolkit.createComposite(mainComposite);
      GridData gridData = new GridData(SWT.FILL, SWT.TOP, true, false);
      vaultComposite.setLayoutData(gridData);
      gridLayout = new GridLayout(4, false);
      gridLayout.verticalSpacing = 2;
      vaultComposite.setLayout(gridLayout);
            
      // Vault and container labels
      Label vaultLabel = toolkit.createLabel(vaultComposite, "Identity Vault:");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH;
      vaultLabel.setLayoutData(gridData);

      Label cntrLabel = toolkit.createLabel(vaultComposite, "Base Container:");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false, 3, 1);
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH;
      cntrLabel.setLayoutData(gridData);     

      // Vault combo and container edit
      vaultCombo = new Combo(vaultComposite, SWT.DROP_DOWN|SWT.READ_ONLY);      
      gridData = new GridData(SWT.FILL, SWT.CENTER, false, false);
      // account for arrow button
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH - (4 * AVG_CHAR_WIDTH);
      vaultCombo.setLayoutData(gridData);
      vaultCombo.setToolTipText("Create Identity Vaults in the Developer and select one to search");
      
      cntrText = toolkit.createText(vaultComposite, "");      
      // Text spans 3 columns
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH;
      cntrText.setLayoutData(gridData);
      cntrText.setToolTipText("Enter Identity Vault container to be searched in dotted format (e.g. Network Devices.ACME)");
      // Retrieve saved container into member
      if (baseContainer != null) {
         cntrText.setText(baseContainer);
      }
      cntrText.addModifyListener(new ModifyListener() {
         @Override
         public void modifyText(ModifyEvent e) {
            String value = ((Text) (e.getSource())).getText(); 

            // Save text value to data model
            dataElement.setAttribute(JuNetSu.JUNETSU_CONTAINER, value);
            
            baseContainer = value;            
            setDirty(true);
         }         
      });
      
      Button browseButton = toolkit.createButton(vaultComposite, "", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false, 2, 1);
      browseButton.setLayoutData(gridData);
      browseButton.setToolTipText("Browse Identity Vault for container");
      browseButton.setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/browse_ds.gif").createImage());
      browseButton.addSelectionListener(new SelectionListener() {
         @Override
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         @Override
         public void widgetSelected(SelectionEvent e) {
            IdentityVault vault = getIdentityVault();            
            if (vault != null) {
               EDirBrowser eDirBrowser = new EDirBrowser(vault, new String[] { "Organization", "Organizational Unit" }, null);
               eDirBrowser.open();
               if (JavaUtil.hasString(eDirBrowser.getSelectedObject())) {
                  DNConverter conv = new DNConverter(eDirBrowser.getSelectedObject(), DNConverter.DCLIENT_QDOT_STRING);
                  cntrText.setText(conv.getDN(DNConverter.DCLIENT_DOT_STRING));
               }
            }
            else {
               updateMessageLabel("Error: could not open Identity Vault \"" + vaultCombo.getText() + "\"");
            }
         }
         
      });

      // Set tab order
      //Control[] tabList = new Control[] { vaultCombo, cntrText, browseButton };
      //vaultComposite.setTabList(tabList);
                  
      // Background color
      Color bgColor = colorRegistry.get("org.eclipse.ui.workbench.ACTIVE_TAB_BG_START");
      
      // Search composite
      final Composite searchComposite = toolkit.createComposite(mainComposite);
      gridData = new GridData(SWT.FILL, SWT.FILL, true, true, 4, 1);
      searchComposite.setLayoutData(gridData);
      gridLayout = new GridLayout(1, true);      
      gridLayout.horizontalSpacing = 0;
      gridLayout.verticalSpacing = 0;
      gridLayout.marginHeight = 0;
      gridLayout.marginWidth = 0;      
      searchComposite.setLayout(gridLayout);
      searchComposite.setBackground(bgColor);
      
      final Composite subComposite1 = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, true);
      subComposite1.setLayoutData(gridData);
      gridLayout = new GridLayout(4, false);
      /*
      gridLayout.marginHeight = 0;
      gridLayout.marginTop = 5;
      gridLayout.marginBottom = 2;
      */
      gridLayout.verticalSpacing = 2;
      gridLayout.marginHeight = 2;
      subComposite1.setLayout(gridLayout);      
      
      // Search label      
      Label searchLabel = toolkit.createLabel(subComposite1, "Search Fields: Match");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      searchLabel.setLayoutData(gridData);
      
      // Radio buttons
      allBtn = toolkit.createButton(subComposite1, "All", SWT.RADIO);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      allBtn.setLayoutData(gridData);
      allBtn.setSelection(true);
      allBtn.setToolTipText("Select to require entries to match all search fields");
      
      anyBtn = toolkit.createButton(subComposite1, "Any", SWT.RADIO);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      anyBtn.setLayoutData(gridData);
      anyBtn.setToolTipText("Select to require entries to match one or more search fields");
            
      // Second sub-composite
      final Composite subComposite2 = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);      
      subComposite2.setLayoutData(gridData);      
      gridLayout = new GridLayout(5, false);
      gridLayout.verticalSpacing = 0;
      gridLayout.marginHeight = 2;
      subComposite2.setLayout(gridLayout);

      // Labels
      String [] labels1 = { "User Name or DN:", "IP Address:", "MAC Address:", "Description:" };
      for (String label : labels1) {
         Label newLabel = toolkit.createLabel(subComposite2, label);
         if (label.equals("User Name or DN:")) {
            gridData = new GridData(SWT.LEFT, SWT.TOP, true, false, 2, 1);
         }
         else {
            gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);
         }
         newLabel.setLayoutData(gridData);
      }
      // Text boxes
      useridText = toolkit.createText(subComposite2, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 26 * AVG_CHAR_WIDTH;
      useridText.setLayoutData(gridData);
      useridText.setToolTipText("Enter a User DN in dotted format (e.g. Robert.ACME) or a User Name; the Vault will be searched for a User matching the name");
      
      Button browseButton2 = toolkit.createButton(subComposite2, "", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      browseButton2.setLayoutData(gridData);
      browseButton2.setToolTipText("Browse the Identity Vault for a User");
      browseButton2.setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/browse_ds.gif").createImage());
      browseButton2.addSelectionListener(new SelectionListener() {
         @Override
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         @Override
         public void widgetSelected(SelectionEvent e) {
            IdentityVault vault = getIdentityVault();            
            if (vault != null) {
               EDirBrowser eDirBrowser = new EDirBrowser(vault, new String[] { "User" }, null);
               eDirBrowser.open();
               if (JavaUtil.hasString(eDirBrowser.getSelectedObject())) {
                  DNConverter conv = new DNConverter(eDirBrowser.getSelectedObject(), DNConverter.DCLIENT_QDOT_STRING);
                  useridText.setText(conv.getDN(DNConverter.DCLIENT_DOT_STRING));
               }
            }
            else {
               updateMessageLabel("Error: could not open Identity Vault \"" + vaultCombo.getText() + "\"");
            }
         }
         
      });

      ipText = toolkit.createText(subComposite2, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 17 * AVG_CHAR_WIDTH;      
      ipText.setLayoutData(gridData);
      ipText.setToolTipText("Enter an IP Address (supports * wildcard) or a CIDR subnet pattern to match entries by subnet (e.g. 192.168.10.0/24)");

      macText = toolkit.createText(subComposite2, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 19 * AVG_CHAR_WIDTH;
      macText.setLayoutData(gridData);
      macText.setToolTipText("Enter a MAC address as six hexadecimal values (e.g. 11:aa:22:bb:33:cc); supports * wildcard");

      descText = toolkit.createText(subComposite2, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH;
      descText.setLayoutData(gridData);
      descText.setToolTipText("Enter a description; supports * wildcard");
      
      // Sub-composite 3 
      final Composite subComposite3 = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);
      subComposite3.setLayoutData(gridData);
      gridLayout = new GridLayout(6, false);
      gridLayout.verticalSpacing = 2;
      gridLayout.marginHeight = 2;      
      subComposite3.setLayout(gridLayout);      
      
      // "When Added" labels and texts
      Label addedFromLabel = toolkit.createLabel(subComposite3, "Earliest Time Added:");
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false);      
      addedFromLabel.setLayoutData(gridData);

      Label addedToLabel = toolkit.createLabel(subComposite3, "Latest Time Added:");
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false, 5, 1);
      addedToLabel.setLayoutData(gridData);      

      addedFromText = toolkit.createText(subComposite3, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = gridData.widthHint = 20 * AVG_CHAR_WIDTH;
      addedFromText.setLayoutData(gridData);
      addedFromText.setToolTipText("Enter earliest time entry added in YYYY-MM-DD [hh:mm:[ss] [TZ]] format");
            
      addedToText = toolkit.createText(subComposite3, "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = gridData.widthHint = 20 * AVG_CHAR_WIDTH;
      addedToText.setLayoutData(gridData);
      addedToText.setToolTipText("Enter latest time entry added in YYYY-MM-DD [hh:mm:[ss] [TZ]] format");
            
      // Checkboxes
      disabledBtn = toolkit.createButton(subComposite3, "Disabled", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, true, false);
      gridData.horizontalIndent = 10;
      disabledBtn.setLayoutData(gridData);
      disabledBtn.setToolTipText("Select to match only disabled entries");
      
      infectedBtn = toolkit.createButton(subComposite3, "Infected", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, true, false);
      infectedBtn.setLayoutData(gridData);
      infectedBtn.setToolTipText("Select to match only infected entries");

      staticBtn = toolkit.createButton(subComposite3, "Static", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, true, false);
      staticBtn.setLayoutData(gridData);
      staticBtn.setToolTipText("Select to match only static entries");

      expiresBtn = toolkit.createButton(subComposite3, "Never Expires", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, true, false);
      expiresBtn.setLayoutData(gridData);
      expiresBtn.setToolTipText("Select to match only entries that never expire");
                              
      // subComposite4 ... search button and message label
      final Composite subComposite4 = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.FILL, SWT.TOP, true, false);
      subComposite4.setLayoutData(gridData);
      gridLayout = new GridLayout(2, false);
      subComposite4.setLayout(gridLayout);
      //subComposite4.setBackground(ColorConstants.red);
      
      // Search Button
      searchBtn = toolkit.createButton(subComposite4, "Search", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false);
      gridData.minimumWidth = 10 * AVG_CHAR_WIDTH;
      gridData.verticalIndent = 2;
      searchBtn.setLayoutData(gridData);
      
      // Message label
      messageLabel = toolkit.createLabel(subComposite4, "");
      gridData = new GridData(SWT.FILL, SWT.CENTER, true, false);
      gridData.horizontalIndent = 10;
      gridData.minimumHeight = 2 * AVG_CHAR_HEIGHT;
      messageLabel.setLayoutData(gridData);
            
      // Set search area's background color
      for (Composite composite: new Composite[] { subComposite1, subComposite2, subComposite3, subComposite4 }) {
         composite.setBackground(bgColor);
         for (Control control : composite.getChildren()) {
            if (!(control instanceof Text)) 
               control.setBackground(bgColor);
         }
      }
      
      
   }
   
   private void createRegistrationResultsSection(Section section) {
      
      Composite resultsComposite = toolkit.createComposite(section);
      GridData gridData = new GridData(SWT.FILL, SWT.FILL, true, true);
      resultsComposite.setLayoutData(gridData);
      GridLayout gridLayout = new GridLayout(1, true);
      //gridLayout.marginHeight = 0;
      resultsComposite.setLayout(gridLayout);
      section.setClient(resultsComposite);
      
      // Results table
      resultsTableViewer = new TableViewer(toolkit.createTable(resultsComposite, SWT.SINGLE));
      resultsTable = resultsTableViewer.getTable();
      gridData = new GridData(SWT.FILL, SWT.TOP, true, true);
      resultsTable.setLayoutData(/*layoutData*/ gridData);
      resultsTable.addMouseListener(new RegSearchDeleter());
      
      // Columns
      String[] headers = { "Delete", "IP Address", "MAC Address", "User DN", "When Added", "Description", 
            "Disabled", "Infected", "Inf. Ports", "Static", "Never Expires" };

      // Listener for column selection (sorting)
      RegSearchComparatorListener searchComparatorListener = new RegSearchComparatorListener(resultsTableViewer);
      // eDir Object Cache
      RegSearchObjectCache objectCache = new RegSearchObjectCache();
      
      TableViewerColumn[] resultsColumns = new TableViewerColumn[headers.length];
      // Create viewer columns
      for (int i = 0; i < headers.length; i++) {
         TableViewerColumn resultColumn = null;         
         if (headers[i].equals("Delete")) {
            resultColumn = new TableViewerColumn(resultsTableViewer, SWT.CENTER);
            resultColumn.setLabelProvider(new RegSearchImageProvider(null, "icons/disabled.gif", null)); 
            resultColumn.getColumn().setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/disabled.gif").createImage());
            resultColumn.getColumn().setToolTipText("Delete Registration");            
         }
         else if (headers[i].equals("Disabled")) {
            resultColumn = new TableViewerColumn(resultsTableViewer, SWT.CENTER);
            resultColumn.setLabelProvider(new RegSearchImageProvider(JuNetSu.ATTRIBUTE_DISABLED, "icons/disabled.gif", objectCache)); 
            resultColumn.getColumn().setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/disabled.gif").createImage());
            resultColumn.getColumn().setToolTipText("Disabled");
         }
         else if (headers[i].equals("Infected")) {
            resultColumn = new TableViewerColumn(resultsTableViewer, SWT.CENTER);
            resultColumn.setLabelProvider(new RegSearchImageProvider(JuNetSu.ATTRIBUTE_INFECTED, "icons/bug.gif", objectCache));
            resultColumn.getColumn().setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/bug.gif").createImage());
            resultColumn.getColumn().setToolTipText("Infected");
         }
         else {
            resultColumn = new TableViewerColumn(resultsTableViewer, SWT.LEFT);
            resultColumn.setLabelProvider(new RegSearchLabelProvider(attributes[i-1], objectCache));
            resultColumn.getColumn().setText(headers[i]);
            if (headers[i].equals("Inf. Ports")) {
               resultColumn.getColumn().setToolTipText("Infected Ports");
            }
         }
         resultColumn.getColumn().addListener(SWT.Selection, searchComparatorListener);
         
         resultsColumns[i] = resultColumn;
      }
            
      // Set size & label provider for each column
      for (int i = 0; i < headers.length; i++) {
         TableColumn resultColumn = resultsTable.getColumn(i);         
         if (resultColumn.getText().equals("IP Address") ) {
            resultColumn.setWidth(17 * AVG_CHAR_WIDTH);
         }
         else if (resultColumn.getText().equals("MAC Address")) {
            resultColumn.setWidth(19 * AVG_CHAR_WIDTH);
         }
         else if (resultColumn.getText().equals("User DN")) {
            resultColumn.setWidth(19 * AVG_CHAR_WIDTH);
         }
         else if (resultColumn.getText().equals("When Added")) {
            resultColumn.setWidth(25 * AVG_CHAR_WIDTH);
         }
         else if (resultColumn.getText().equals("Description")) {
            resultColumn.setWidth(DEFAULT_WIDTH);
         }
         else if (headers[i].equals("Disabled") || headers[i].equals("Delete")) {         
            resultColumn.setWidth(32);            
            resultColumn.setResizable(false);
         }
         else if (headers[i].equals("Infected")) {
            resultColumn.setWidth(30);            
            resultColumn.setResizable(false);            
         }
         else {
            resultColumn.pack();
         }
      }
            
      resultsTable.setHeaderVisible(true);

      // Set up hyper link to show history of selected object
      for (int i = 1; i <= 3; i++) {
         resultsColumns[i].setEditingSupport(new RegSearchEditingSupport(resultsTableViewer, attributes[i-1]));
      }
            
      resultsTable.addMouseMoveListener(new MouseMoveListener() {

         @Override
         public void mouseMove(MouseEvent e) {            
            Table table = (Table) e.widget;
            
            int col = 0, wtotal = table.getColumn(0).getWidth();            
            // find column
            while (col < (table.getColumnCount()-1) && e.x >= wtotal) {
               wtotal += table.getColumn(++col).getWidth();               
            }
                        
            // does column support hyperlink?
            if (col < table.getColumnCount()) {
               TableColumn column = table.getColumn(col);
               if (column.getText().equals("IP Address") ||
                   column.getText().equals("MAC Address") ||
                   column.getText().equals("User DN")) {    
                  // Only the leftmost item has the data (ObjectEntry element)
                  TableItem item = table.getItem(new Point(table.getColumn(0).getWidth()/2, e.y));
                  if (item != null && JavaUtil.hasString(item.getText(col)) && 
                      item.getData() != null && item.getData() instanceof ObjectEntry) {
                     resultsTableViewer.editElement(item.getData(), col);
                  }
                  else {
                     resultsTableViewer.cancelEditing();
                  }
               }
               else {
                  resultsTableViewer.cancelEditing();               
               }
            }
         }
         
      });
      
      // Cancel hyperlink if cursor leaves table
      resultsComposite.addMouseMoveListener( new MouseMoveListener() {

         @Override
         public void mouseMove(MouseEvent e) {
            if (resultsTableViewer.isCellEditorActive()) {
               resultsTableViewer.cancelEditing();
            }
         }
         
      });
      // Content provider
      searchContentProvider = new RegSearchContentProvider();
      resultsTableViewer.setContentProvider(searchContentProvider);
            
      // Search button event listener      
      searchBtn.addSelectionListener(new SelectionListener() {
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }
         
         public void widgetSelected(SelectionEvent e) {
            // Search the vault given the parameters
            doSearch();
         }
      });
      
      // Resize listener for the table
      resultsComposite.addControlListener(new ControlListener() {

         @Override
         public void controlMoved(ControlEvent e) {
         }

         @Override
         public void controlResized(ControlEvent e) {
            if (resultsTable.getItemCount() > 0) {
               int maxHeight = resultsTable.getParent().getSize().y;
               // round off maxHeight to number of items
               maxHeight -= resultsTable.getHeaderHeight();
               maxHeight = maxHeight / (resultsTable.getItemHeight()) * resultsTable.getItemHeight();
               maxHeight += resultsTable.getHeaderHeight();
               int totalHeight = resultsTable.getItemHeight() * resultsTable.getItemCount() + resultsTable.getHeaderHeight();
               int actualHeight = Math.min(maxHeight, totalHeight);
               GridData gridData = (GridData) resultsTable.getLayoutData();
               gridData.heightHint = actualHeight;  
               resultsTable.getParent().layout(true);
            }
         }
         
      });

      searchBtn.getShell().setDefaultButton(searchBtn);
      
      pageCreated = true;
      
      updateIdentityVaults();
      
   }
   
   public void doSearch() {

      boolean errorFlag = false;
      
      try {
         // set the cursor and disable the button
         searchBtn.getShell().setCursor(CoreCursors.AppStarting);
         searchBtn.setEnabled(false);
         
         final RegSearchInput searchInput = new RegSearchInput();
         searchInput.setPropertyValue(RegSearchInput.VAULT, vaultCombo.getText());
         searchInput.setPropertyValue(RegSearchInput.CONTAINER, cntrText.getText());
         searchInput.setPropertyValue(RegSearchInput.SEARCH_MODE, allBtn.getSelection() ? "all" : "any");
         searchInput.setPropertyValue(RegSearchInput.USER_DN, useridText.getText());
         searchInput.setPropertyValue(RegSearchInput.IP_ADDRESS, ipText.getText());
         searchInput.setPropertyValue(RegSearchInput.MAC_ADDRESS, macText.getText());
         searchInput.setPropertyValue(RegSearchInput.DESCRIPTION, descText.getText());
         searchInput.setPropertyValue(RegSearchInput.DISABLED, disabledBtn.getSelection() ? "true" : null);
         searchInput.setPropertyValue(RegSearchInput.INFECTED, infectedBtn.getSelection() ? "true" : null);
         searchInput.setPropertyValue(RegSearchInput.STATIC, staticBtn.getSelection() ? "true" : null);
         searchInput.setPropertyValue(RegSearchInput.NEVER_EXPIRES, expiresBtn.getSelection() ? "true" : null);
         searchInput.setPropertyValue(RegSearchInput.ADDED_FROM, addedFromText.getText());
         searchInput.setPropertyValue(RegSearchInput.ADDED_TO, addedToText.getText());

         // Clear the current input
         resultsTableViewer.setInput(null);

         // IP Address filter
         for (ViewerFilter filter: resultsTableViewer.getFilters()) {
            resultsTableViewer.removeFilter(filter);
         }
         if (JavaUtil.hasString(ipText.getText())) {
            RegSearchFilter filter = new RegSearchFilter(ipText.getText());
            // if the address is a CIDR pattern, add the filter
            if (filter.getValid()) {
               resultsTableViewer.addFilter(filter);
               // set the IP search string to a subnet string
               searchInput.setPropertyValue(RegSearchInput.IP_ADDRESS, filter.getSearchString());
            }
            else {
               // only report if user tried to actually use pattern
               if (ipText.getText().contains("/")) {
                  updateMessageLabel("Error: the CIDR pattern entered as the IP Address is invalid.");
                  errorFlag = true;
               }
            }               
         }

         monitor.beginTask("Searching Identity Vault...", 100);
         MyProfiler.start("junetsu#ivsearchtotal", "IV Search");
         
         resultsTableViewer.setInput(searchInput);
         
         MyProfiler.stop("junetsu#entryprocess", "Entry Process");
         MyProfiler.stop("junetsu#ivsearchtotal", "IV Search");
         MyProfiler.report();
         
      } catch (Exception ex) {
         ex.printStackTrace();
         updateMessageLabel(ex.getClass().getCanonicalName() + ": " + ex.getMessage());
         errorFlag = true;
      }
      finally {
         searchBtn.setEnabled(true);
         monitor.done();
         searchBtn.getShell().setCursor(CoreCursors.Normal);
      }
      
      // Set table height            
      if (resultsTable.getItemCount() > 0) {
         int maxHeight = resultsTable.getParent().getSize().y;
         // round off maxHeight to number of items
         maxHeight -= resultsTable.getHeaderHeight();
         maxHeight = maxHeight / (resultsTable.getItemHeight()) * resultsTable.getItemHeight();
         maxHeight += resultsTable.getHeaderHeight();
         int totalHeight = resultsTable.getItemHeight() * resultsTable.getItemCount() + resultsTable.getHeaderHeight();
         int actualHeight = Math.min(maxHeight, totalHeight);
         GridData gridData = (GridData) resultsTable.getLayoutData();
         gridData.heightHint = actualHeight;  
         resultsTable.getParent().layout(true);
      }
      
      // Set the message label to the message from the content provider
      if (!errorFlag) {
         updateMessageLabel(searchContentProvider.getMessage());
      }
      
   }
   
   private void createRegistrationPage(Composite parent) {

      // Search section
      Section searchSection = toolkit.createSection(parent, ExpandableComposite.TITLE_BAR|ExpandableComposite.TWISTIE);
      FormData layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 0);
      layoutData.left = new FormAttachment(0, 0);
      layoutData.right = new FormAttachment(100, 0);
      searchSection.setLayoutData(layoutData);
      FormLayout formLayout = new FormLayout();
      formLayout.marginWidth = 4;
      formLayout.marginHeight = 4;
      searchSection.setLayout(formLayout);
      searchSection.setText("Registration Search");
      searchSection.setExpanded(true);
      
      // Create the controls for the search section
      createRegistrationSearchSection(searchSection);
            
      // Results section
      Section resultsSection = toolkit.createSection(parent, ExpandableComposite.TITLE_BAR|ExpandableComposite.TWISTIE);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(searchSection, 0, SWT.BOTTOM);
      layoutData.left = new FormAttachment(0, 0);
      layoutData.right = new FormAttachment(100, 0);
      layoutData.bottom = new FormAttachment(100, 0);
      resultsSection.setLayoutData(layoutData);
      GridLayout gridLayout = new GridLayout(1, true);
      resultsSection.setLayout(gridLayout);
      resultsSection.setText("Search Results");
      resultsSection.setExpanded(true);
      
      // Create the controls for the results section
      createRegistrationResultsSection(resultsSection);
      
   }

   public void createPartControl(Composite parent)  {
      
      try {
         // Compute font width
         GC gc = new GC(parent);
         AVG_CHAR_WIDTH = gc.getFontMetrics().getAverageCharWidth();
         AVG_CHAR_HEIGHT = gc.getFontMetrics().getHeight();
         DEFAULT_WIDTH = 25 * AVG_CHAR_WIDTH; 
         gc.dispose();

         // Use a Form layout
         parent.setLayout(new FormLayout());

         // Form toolkit
         toolkit = new FormToolkit(parent.getDisplay());

         // Tab folder with two tabs
         tabFolder = new TabFolder(parent, SWT.TOP);
         FormLayout formLayout = new FormLayout();
         tabFolder.setLayout(formLayout);      
         FormData layoutData = new FormData();
         layoutData.top = new FormAttachment(0, 0);
         layoutData.left = new FormAttachment(0, 0);
         layoutData.right = new FormAttachment(100, 0);
         layoutData.bottom = new FormAttachment(100, 0);
         tabFolder.setLayoutData(layoutData);
         final TabItem tabItem1 = new TabItem(tabFolder, SWT.NONE);
         tabItem1.setText("Search Registrations");
         final TabItem tabItem2 = new TabItem(tabFolder, SWT.NONE);
         tabItem2.setText("Search History");
         final TabItem tabItem3 = new TabItem(tabFolder, SWT.NONE);
         tabItem3.setText("Junetsu Live");

         Composite registrationComposite = toolkit.createComposite(tabFolder);
         formLayout = new FormLayout();
         registrationComposite.setLayout(formLayout);
         layoutData = new FormData();
         layoutData.top = new FormAttachment(0, 0);
         layoutData.left = new FormAttachment(0, 0);
         layoutData.right = new FormAttachment(100, 0);
         layoutData.bottom = new FormAttachment(100, 0);
         registrationComposite.setLayoutData(layoutData);
         tabItem1.setControl(registrationComposite);

         createRegistrationPage(registrationComposite);
         
         // Create the JuNetSu History Search tab page
         Composite historyComposite = toolkit.createComposite(tabFolder);
         formLayout = new FormLayout();
         historyComposite.setLayout(formLayout);
         layoutData = new FormData();
         layoutData.top = new FormAttachment(0, 0);
         layoutData.left = new FormAttachment(0, 0);
         layoutData.right = new FormAttachment(100, 0);
         layoutData.bottom = new FormAttachment(100, 0);
         historyComposite.setLayoutData(layoutData);
         tabItem2.setControl(historyComposite);
         
         jnsHistory = new JuNetSuHistory(this, dataElement);
         jnsHistory.createHistoryPage(historyComposite);
         
         // Create the Live tab page
         Composite liveComposite = toolkit.createComposite(tabFolder);
         formLayout = new FormLayout();
         liveComposite.setLayout(formLayout);
         layoutData = new FormData();
         layoutData.top = new FormAttachment(0, 0);
         layoutData.left = new FormAttachment(0, 0);
         layoutData.right = new FormAttachment(100, 0);
         layoutData.bottom = new FormAttachment(100, 0);
         liveComposite.setLayoutData(layoutData);
         tabItem3.setControl(liveComposite);
         
         jnsLive = new JunetsuLive(this, dataElement);
         jnsLive.createLivePage(liveComposite);
                  
         tabFolder.addSelectionListener(new SelectionListener() {

            public void widgetDefaultSelected(SelectionEvent e) {
               widgetSelected(e);
            }

            public void widgetSelected(SelectionEvent e) {
               // Select correct default button based on page
               if (e.item == tabItem1) {
                  tabFolder.getShell().setDefaultButton(searchBtn);
               }
               else if (e.item == tabItem2 || e.item == tabItem3){
                  JunetsuDBProfileManager profileManager = JunetsuDBProfileManager.getInstance(modeler, dataElement);
                  if (firstTime || profileManager.noProfiles()) {
                     firstTime = false;
                     // TODO: only do once per session                     
                     if (MessageDialog.openQuestion(tabFolder.getShell(), 
                                                   "Junetsu Plug-in",
                                                   "Do you wish to create a new database profile to access the Junetsu history database?")) {
                        profileManager.addProfile();
                     }
                                                   
                  }
                  if (e.item == tabItem2) {
                     if (profileManager.noProfiles()) {
                        jnsHistory.searchBtn.setEnabled(false);
                     }
                     else {
                        jnsHistory.searchBtn.setEnabled(true);
                     }
                     tabFolder.getShell().setDefaultButton(jnsHistory.searchBtn);
                  }
                  else { // tabItem3
                     // TODO
                  }
               }
               
            }
            
         });
      }
      catch (Exception e) {
         // Designer will not display an error; print stack trace for debugging
         e.printStackTrace();
      }
      
   }

   public void updateMessageLabel(String text) {
      if (text.startsWith("Error")) {
         messageLabel.setForeground(ColorConstants.red);
      }
      else {
         messageLabel.setForeground(colorRegistry.get("org.eclipse.ui.editors.foregroundColor"));
      }
      messageLabel.setText(text);
   }
   
   public void dispose() {   
      if (jnsHistory != null) {
         jnsHistory.dispose();
      }
      super.dispose();
   }

   @Override
   public void setFocus() {
      if (!focus) {         
         cntrText.setFocus();
         focus = true;
      }
      
   }

   private void updateIdentityVaults() {
      if (!pageCreated) {
         return;
      }
      
      // Get the currently selected item and clear the list
      String oldVault = vaultCombo.getText();
      vaultCombo.removeAll();
            
      // Find Identity Vaults in the Modeler
      int count = 0;
      if (project != null && project.getDomain() != null) {
         List<IdentityVault> vaults = IdmModel.findAllIdentityVaults(project.getDomain());
         Iterator<IdentityVault> iter = vaults.iterator();
         while (iter.hasNext()) {
            IdentityVault vault = (IdentityVault) iter.next();
            vaultCombo.add(vault.getName());
         }
         count = vaults.size();
      }
      
      if (count > 0) {
         // Select the old vault if possible
         int index = vaultCombo.indexOf(oldVault);
         if (index == -1) {
            index = 0;
         }
         vaultCombo.select(index);
         
         // enable Search button, hide label
         searchBtn.setEnabled(true);
         updateMessageLabel("");
      }
      else {
         // disable button, display message
         searchBtn.setEnabled(false);
         updateMessageLabel("Create an Identity Vault in the Developer and save the project");
      }
      
   }
   
   private IdentityVault getIdentityVault() {
      if (project != null && project.getDomain() != null) {
         List<IdentityVault> vaults = IdmModel.findAllIdentityVaults(project.getDomain());
         Iterator<IdentityVault> iter = vaults.iterator();
         while (iter.hasNext()) {
            IdentityVault vault = (IdentityVault) iter.next();
            if (vaultCombo.getText().equals(vault.getName())) {
               return vault;
            }
         }
      }         
      
      return null;
   }
      
   @Override
   public void handleActivateRefresh() {
   }

   @Override
   public void notifyChanged(Notification notification) {

   }

   @Override
   public void pageSelected() {
      updateIdentityVaults();      
   }


   @Override
   public void setGlobalModelEditor(GlobalModelEditor editor) {
      this.globalEditor = editor;
   }

   @Override
   public void paletteSwitched(String paletteID) {

   }

   @Override
   public void projectUnversioned(IProject project) {

   }

}
