package com.omnibond.designer.junetsu;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.draw2d.ColorConstants;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.resource.ColorRegistry;
import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.OwnerDrawLabelProvider;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.TableViewerColumn;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
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
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.forms.widgets.ExpandableComposite;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.forms.widgets.Section;
import org.eclipse.ui.plugin.AbstractUIPlugin;

import com.novell.core.CoreCursors;
import com.novell.core.util.JavaUtil;
import com.novell.idm.model.DesignElement;
import com.novell.idm.modeler.Modeler;


// Categories
// org.eclipse.datatools.connectivity.db.category
// org.eclipse.datatools.connectivity.connectionProfileRepositoryCategory
// org.eclipse.datatools.connectivity.oda.profileCategory

public class JuNetSuHistory 
{

   
   final String[] dbColumns = { JuNetSu.COL_USER_DN, JuNetSu.COL_IP_ADDR, JuNetSu.COL_HW_ADDR, 
                              JuNetSu.COL_DESCRIPTION, JuNetSu.COL_DISABLED, JuNetSu.COL_INFECTED, JuNetSu.COL_INFECTED_PORTS, 
                              JuNetSu.COL_STATIC_ADDR, JuNetSu.COL_ACTION, JuNetSu.COL_LOG_TIMESTAMP, JuNetSu.COL_REG_ADD_TIME };
   
   final int IND_USER_DN = 0;
   final int IND_IP_ADDR = 1;
   final int IND_HW_ADDR = 2;
   final int IND_DESCRIPTION = 3;
   final int IND_DISABLED = 4;
   final int IND_INFECTED = 5;
   final int IND_INFECTED_PORTS = 6;
   final int IND_STATIC_ADDR = 7;
   final int IND_ACTION = 8;
   final int IND_LOG_TIMESTAMP = 9;
   final int IND_REG_ADD_TIME = 10;
   
   private class HistSearchInput
   {
      public static final String SEARCH_MODE = "Search Mode";      
      public static final String USER_NAME = "User Name";
      public static final String IP_ADDRESS = "IP Address";
      public static final String MAC_ADDRESS = "MAC Address";
      public static final String ADDED_FROM = "Added From";
      public static final String ADDED_TO = "Added To";
      public static final String ACTION = "Action";
      public static final String WHEN_ADDED = "When Added";
      public static final String LOG_TIMESTAMP = "Log Timestamp";
      public static final String DESCRIPTION = "Description";
      public static final String DISABLED = "Disabled";
      public static final String INFECTED = "Infected";
      public static final String INF_PORTS = "Inf. Ports";
      public static final String STATIC = "Static";
      public static final String DATABASE_NAME = "Database Name";
      
      private HashMap<String, String> properties = new HashMap<String, String>();
      
      Connection m_dataConn;
      
      public HistSearchInput() { }
      
      public HistSearchInput(Connection conn) {
         m_dataConn = conn;
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
      
      public Connection getConnection() {
         return m_dataConn;
      }
      
   }
   
   
   // Run the DB search in a separate thread
   private class HistSearchRunnable
   {
      private Statement m_stmt;
      private String m_sql, m_msg = null;
      private ResultSet m_resultSet = null;
      
      public HistSearchRunnable(Statement stmt, String sql) {
         m_stmt = stmt;
         m_sql = sql;
      }
      
      public void run() {
         
         MyProfiler.start("com.omnibond.designer.junetsu#sql", "SQL Exec");
         try {
            // Set timeout
            m_stmt.setQueryTimeout(60);
            m_resultSet = m_stmt.executeQuery(m_sql);
         }
         catch (Exception e) {
            m_msg = e.getMessage();
         }
         MyProfiler.stop("com.omnibond.designer.junetsu#sql", "SQL Exec");
         
      }
      
      public ResultSet getResultSet() {
         return m_resultSet;
      }

      public String getMessage() {
         return m_msg;
      }
   }

   private class HistSearchContentProvider
      implements IStructuredContentProvider 
   {

      HistSearchInput m_input = null;
      String m_message;
      Object[] m_cachedElements;
      boolean m_changed = true;
      
      // Create a WHERE condition based on parameters, with wildcard support
      private String buildCondition(String current, String column, String value, String operator) {
         String result = current;
         if (JavaUtil.hasString(value)) {
            if (!result.endsWith("JNSU_HISTORY ")) {
               // append AND / OR
               result = result.concat(operator);
            }
            else {
               // first condition
               result = result.concat("WHERE ");
            }
            // append column name
            result = result.concat(column);
            // backslashes must be escaped
            value = value.replace("\\", "\\\\");
            if (value.contains("*")) {
               value = value.replace("*", "%");
               result = result.concat(" LIKE '" + value + "'");
            }
            else {
               result = result.concat(" = '" + value + "'");
            }
         }
             
         return result; 
      }
      
      @Override
      public Object[] getElements(Object inputElement) {
         
         List<String[]> rows = null;
         Object[] elements;
         
         // Return cached elements if no data change (usually sorting)
         if (!m_changed) {
            return m_cachedElements;
         }
         
         // Search database         
         if (m_input != null) {
            Connection sqlConn = m_input.getConnection();
            try {
               

               // Get database name
               String dbName = m_input.getPropertyValue(HistSearchInput.DATABASE_NAME);
               String sql = "SELECT USER_DN, IP_ADDR, HW_ADDR, DESCRIPTION, DISABLED, " +
               		              "INFECTED, INFECTED_PORTS, STATIC_ADDR, ACTION, LOG_TIMESTAMP, REG_ADD_TIME " +
               		       " FROM " + dbName + ".JNSU_HISTORY ";
               
               String searchMode = m_input.getPropertyValue(HistSearchInput.SEARCH_MODE);
               String operator = " AND ";
               if (searchMode.equals("any")) {
                  operator = " OR ";
               }
               
               // Build the SQL statement
               
               // User DN is stored in backslash format... unless a full DN is specified, 
               // use the wildcard to match user name in any container
               String userName = m_input.getPropertyValue(HistSearchInput.USER_NAME);
               if (JavaUtil.hasString(userName) && !userName.contains("\\")) {
                  userName = "*" + userName;
               }

               sql = buildCondition(sql, JuNetSu.COL_USER_DN, userName, operator);               
               sql = buildCondition(sql, JuNetSu.COL_IP_ADDR, m_input.getPropertyValue(HistSearchInput.IP_ADDRESS), operator);
               sql = buildCondition(sql, JuNetSu.COL_HW_ADDR, m_input.getPropertyValue(HistSearchInput.MAC_ADDRESS), operator);
               sql = buildCondition(sql, JuNetSu.COL_DESCRIPTION, m_input.getPropertyValue(HistSearchInput.DESCRIPTION), operator);
               sql = buildCondition(sql, JuNetSu.COL_DISABLED, m_input.getPropertyValue(HistSearchInput.DISABLED), operator);
               sql = buildCondition(sql, JuNetSu.COL_INFECTED, m_input.getPropertyValue(HistSearchInput.INFECTED), operator);
               sql = buildCondition(sql, JuNetSu.COL_STATIC_ADDR, m_input.getPropertyValue(HistSearchInput.STATIC), operator);
               sql = buildCondition(sql, JuNetSu.COL_ACTION, m_input.getPropertyValue(HistSearchInput.ACTION), operator);

               // timestamp conditions
               String earliestTime = m_input.getPropertyValue(HistSearchInput.ADDED_FROM);
               String latestTime = m_input.getPropertyValue(HistSearchInput.ADDED_TO);
               if (JavaUtil.hasString(earliestTime)) {
                  if (!sql.endsWith("JNSU_HISTORY ")) {
                     sql = sql + " AND ";
                  }
                  else {
                     // first condition
                     sql = sql + "WHERE";
                  }
                  sql = sql + " LOG_TIMESTAMP >= '" + earliestTime + "'";                     
               }
               if (JavaUtil.hasString(latestTime)) {
                  if (!sql.endsWith("JNSU_HISTORY ")) {
                     sql = sql + " AND ";
                  }
                  else {
                     // first condition
                     sql = sql + "WHERE";
                  }
                  sql = sql + " LOG_TIMESTAMP <= '" + latestTime + "'";                  
               }

               sql = sql + " ORDER BY LOG_TIMESTAMP DESC LIMIT 20000";                                                           
               
               Statement stmt = sqlConn.createStatement();              
               
               // Execute the query in a separate thread
               final HistSearchRunnable runnable = new HistSearchRunnable(stmt, sql);

               //ModalContext.run(runnable, true, monitor, PlatformUI.getWorkbench().getDisplay());
               Thread histSearchThread = new Thread() {

                  @Override
                  public void run() {
                     runnable.run();
                  }
                  
               };
               monitor.beginTask("Searching database...", 75);
               // Process up to 10 pending UI events so that the monitor text above
               // is displayed
               for (int i = 0; i < 10 && Display.getCurrent().readAndDispatch(); i++) ;
               histSearchThread.start();
               // in this thread, advance the monitor to approximate a search time of about 15 seconds
               // the monitor stops at 14 ticks
               int count = 0;
               while (histSearchThread.isAlive()) {
                  if (count < 75) {
                     Thread.sleep(200);
                     monitor.worked(1);
                     count++;
                  }
                  // process pending UI events while the thread is alive
                  while (histSearchThread.isAlive() &&
                         !Display.getCurrent().readAndDispatch())  ;                  
               }
               monitor.done();
               
               // Copy the entries into the array
               ResultSet rs = runnable.getResultSet();
               if (rs != null) {
                  MyProfiler.start("com.omnibond.designer.junetsu#elements", "Elements");
                  rows = new ArrayList<String[]>();
                  while (rs.next()) {
                     
                     /*HistSearchInput rowInput = new HistSearchInput();*/
                     String[] entry = new String[11]; 
                     for (int i = 0; i < 11; i++) {
                        //rowInput.setPropertyValue(column, rs.getString(column));
                        entry[i] = rs.getString(i+1);
                     }
                     rows.add(entry);
                  }
               }
               else {
                  throw new Exception(runnable.getMessage());                  
               }
               
            }
            catch (Exception e) {
               e.printStackTrace();
               m_message = "Error: " + e.getMessage();
               return new Object[0];
            }
         }
         
         m_message = "";
         
         elements = new Object[rows.size()];
         rows.toArray(elements);

         // Copy elements to cache
         m_cachedElements = new Object[elements.length];
         System.arraycopy(elements, 0, m_cachedElements, 0, elements.length);
         
         m_changed = false;

         MyProfiler.stop("com.omnibond.designer.junetsu#elements", "Elements");

         // Start monitor on loading entries 
         MyProfiler.start("com.omnibond.designer.junetsu#dbprocessentries", "Entries");
         monitor.beginTask("Loading entries...", elements.length * 11);
         
         return elements;
      }

      @Override
      public void dispose() {
         
      }

      @Override
      public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
         if (newInput instanceof HistSearchInput) {
            m_input = (HistSearchInput) newInput;
            
            m_changed = true;
         }
      }
      
      public String getMessage() {
         return m_message;
      }
      
   }
    
   private class HistSearchLabelProvider
      extends ColumnLabelProvider
   {
      //String m_column;
      int m_index;
      Display m_display;
      SimpleDateFormat inFormat, outFormat;
      
      public HistSearchLabelProvider(int index /*String column*/) {
         //m_column = column;
         m_index = index;
         m_display = Display.getCurrent();
      }
      
      @Override
      public String getText(Object element) {
         if (element instanceof String[]) {
            //String value = ((HistSearchInput) element).getPropertyValue(m_column);
            String value = ((String[]) element)[m_index];
            String retVal = value;
            if (JavaUtil.hasString(value)) {
               //if (m_column.equals(JuNetSu.COL_USER_DN)) {
               if (m_index == IND_USER_DN) {
                  // Only display the user name, not the full DN
                  retVal = value.substring(value.lastIndexOf("\\") + 1, value.length());
               }
               //else if (m_column.equals(JuNetSu.COL_STATIC_ADDR)) {
               else if (m_index == IND_STATIC_ADDR) {
                  retVal = value.equalsIgnoreCase("true") ? "yes" : "no";
               }
               //else if (m_column.equals(JuNetSu.COL_LOG_TIMESTAMP)) {
               else if (m_index == IND_LOG_TIMESTAMP) {
                  inFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.S");
                  outFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
                  try {                     
                     retVal = outFormat.format(inFormat.parse(value));
                  }
                  catch (ParseException e) {
                     
                  }
               }
               //else if (m_column.equals(JuNetSu.COL_REG_ADD_TIME)) {
               else if (m_index == IND_REG_ADD_TIME) {
                  SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
                  retVal = df.format(new Date(Long.parseLong(value)*1000));               
               }
               //else if (m_column.equals(JuNetSu.COL_INFECTED_PORTS)) {
               else if (m_index == IND_INFECTED_PORTS) {
                  // The format is {port}-{hits}[,{port}-{hits},...]
                  // Only display port numbers
                  String[] tokens = retVal.split(",");
                  retVal = "";
                  for (int i = 0; i < tokens.length; i++) {
                     if (tokens[i].indexOf("-") != -1) {
                        retVal = retVal + tokens[i].substring(0, tokens[i].indexOf("-"));
                     }
                     else {
                        retVal = retVal + tokens[i];
                     }
                     if (i != tokens.length-1) {
                        retVal = retVal + ",";
                     }
                  }
               }
            }
            monitor.worked(1);
            m_display.readAndDispatch();

            return retVal; 
         }
                  
         return null;
      }
      
   }
   
   private class HistSearchImageProvider
      extends OwnerDrawLabelProvider
   {
      String /*m_column,*/ m_imageName;
      int m_index;
      Display m_display;
      
      public HistSearchImageProvider(int index, String imageName) {
         //m_column = column;
         m_index = index;
         m_imageName = imageName;
         m_display = Display.getCurrent();
      }
            
      protected void measure(Event event, Object element) {   }

      protected void paint(Event event, Object element) {
         Image image = null;
         
         if (element instanceof String[]) {
            // Check if attribute is true
            //String value = ((HistSearchInput) element).getPropertyValue(m_column);
            String value = ((String []) element)[m_index];
            if (JavaUtil.hasString(value) && value.equalsIgnoreCase("true")) {
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
         
         monitor.worked(1);
         m_display.readAndDispatch();
      }
            
   }

   private class HistSearchFilter 
      extends ViewerFilter 
   {

      String m_address;
      boolean m_active;
      int m_prefix, m_prefixmask, m_bitmask;
      String m_search;
   
      public HistSearchFilter(String address) {
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

         if (element instanceof String[]) {
            String address = ((String[]) element)[IND_IP_ADDR];
            if (JavaUtil.hasString(address)) {
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
         }         
         return false;
      }

   }

   private class HistSearchComparator 
      extends ViewerComparator
   {
      private int m_sortIndex;
      private int m_sortDirection;
      private String m_message;
      
      public HistSearchComparator(int sortIndex, int sortDirection) {
         m_sortIndex = sortIndex;
         m_sortDirection = sortDirection;
      }
      
      @Override
      public int compare(Viewer viewer, Object e1, Object e2) {
         int rc = 0;         

         // Compare string attributes
         String s1 = ((String[]) e1)[m_sortIndex];
         String s2 = ((String[]) e2)[m_sortIndex];
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
            if (m_sortIndex == IND_USER_DN) {
               // Compare user names, not the full DNs
               String name1 = s1.substring(s1.lastIndexOf("\\") + 1, s1.length());
               String name2 = s2.substring(s2.lastIndexOf("\\") + 1, s2.length());
               
               rc = name1.compareToIgnoreCase(name2);
            }
            else if (m_sortIndex == IND_REG_ADD_TIME) {
               // do numerical comparison for ADD Time
               long l1 = Long.parseLong(s1); 
               long l2 = Long.parseLong(s2);
                 
               rc = new Long(l1).compareTo(new Long(l2));
            }
            else if (m_sortIndex == IND_IP_ADDR) {
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
                  
         // Invert sort direction
         if (m_sortDirection == SWT.DOWN)
            rc *= -1;
         
         return rc;
      }
      
      public String getMessage() {
         return m_message;
      }

   }
   
   private class HistSearchComparatorListener 
   implements Listener 
   {
      TableViewer m_viewer;
      Composite m_parent;
      boolean m_locked = false;

      public HistSearchComparatorListener(Composite parent, TableViewer viewer) {
         m_viewer = viewer;
         m_parent = parent;
      }

      @Override
      public void handleEvent(Event event) {
         
         // Don't allow a sort while sorting!
         if (m_locked) return;
         
         TableColumn column = (TableColumn) event.widget;
         Table table = column.getParent();
         //TableColumn[] columns = table.getColumns();
         
         int sortIndex = 0;
         for ( ; sortIndex < table.getColumnCount(); sortIndex++) {
            if (column.equals(table.getColumn(sortIndex))) {
               break;
            }
         }
         

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
         try {            
            m_parent.setCursor(CoreCursors.AppStarting);
            m_locked = true;
            searchBtn.setEnabled(false);
            HistSearchComparator searchComparator = new HistSearchComparator(sortIndex, sortDirection); 
            m_viewer.setComparator(searchComparator);
         }
         finally {
            searchBtn.setEnabled(true);
            m_locked = false;
            m_parent.setCursor(CoreCursors.Normal);            
            // monitor.done();
         }
      }

   }
   
/*   
   private class ConnectThread 
      extends Thread
   {
      IConnectionProfile m_profile;
      
      public ConnectThread(IConnectionProfile profile) {
         m_profile = profile;
      }
      
      public void run() {
         synchronized (this) {         
            m_profile.connect();
            
            int counter = 300;  // 30 second timeout
            IManagedConnection mngConn = null;
            while (counter-- > 0 && m_profile.getConnectionState() != IConnectionProfile.CONNECTED_STATE) {
               if (mngConn == null) {
                  mngConn = m_profile.getManagedConnection("org.eclipse.datatools.connectivity.sqm.core.connection.ConnectionInfo");
                  if (mngConn != null) {
                     IConnection conn = mngConn.getConnection();
                     if (conn != null && conn.getConnectException() != null) {
                        // An error has occurred... Designer will display the error automatically
                        break;
                     }
                  }
               }
               try {
                  Thread.sleep(100);
               }
               catch (Exception e) {
                  e.printStackTrace();
                  break;
               }
            }
            m_connected = m_profile.getConnectionState() == IConnectionProfile.CONNECTED_STATE;
         }         
      }
   }
  */
   
   private int AVG_CHAR_WIDTH, AVG_CHAR_HEIGHT, DEFAULT_WIDTH;
   
   private FormToolkit toolkit;
   private ColorRegistry colorRegistry = null;
   private IProgressMonitor monitor;
   private JunetsuDBProfileManager profileManager;
   private Connection m_conn;
   private Composite[] subComposites;
   private Combo profileCombo = null, actionCombo;
   private Text useridText, ipText, macText, descText, 
                addedFromText, addedToText;
   private Button allBtn, anyBtn, disabledBtn, infectedBtn, staticBtn;
   public Button searchBtn;
   private Label messageLabel;
   private TableViewer histViewer;
   private Table histTable;
   private HistSearchContentProvider histContentProvider;
   
   //private Modeler m_modeler;
   //private DesignElement dataElement;
   
   public JuNetSuHistory(Modeler modeler, DesignElement element) {

      // Get progress monitor
      monitor = modeler.getEditorSite().getActionBars().getStatusLineManager().getProgressMonitor();
      
      // Init our DB profile manager      
      profileManager = JunetsuDBProfileManager.getInstance(modeler, element);

      // Init model objects
      //m_modeler = modeler;
      //dataElement = element;
         
      // Init color registry
      colorRegistry = PlatformUI.getWorkbench().getThemeManager().getCurrentTheme().getColorRegistry();

   }
   
   public void checkProfiles() {
      
   }
      
   public void dispose() {
      profileManager.disconnect();
   }
         
   private void createHistorySearchSection(Section section) {
                  
      Composite mainComposite = toolkit.createComposite(section);      
      FormData formData = new FormData();
      formData.top = new FormAttachment(0, 2);
      formData.bottom = new FormAttachment(100, 0);
      formData.left = new FormAttachment(0, 2);
      formData.right = new FormAttachment(100, -2);      
      mainComposite.setLayoutData(formData);
      GridLayout gridLayout = new GridLayout(1, false);
      gridLayout.verticalSpacing = 2;
      mainComposite.setLayout(gridLayout);
      
      section.setClient(mainComposite);
   
      Composite profileComposite = toolkit.createComposite(mainComposite);
      GridData gridData = new GridData(SWT.FILL, SWT.TOP, true, false);
      profileComposite.setLayoutData(gridData);
      gridLayout = new GridLayout(2, false);
      gridLayout.verticalSpacing = 2;
      profileComposite.setLayout(gridLayout);

      Label profileLabel = toolkit.createLabel(profileComposite, "Database Profile:");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false, 2, 1);
      profileLabel.setLayoutData(gridData);
      
      profileCombo = new Combo(profileComposite, SWT.DROP_DOWN|SWT.READ_ONLY);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = 100;
      profileCombo.setLayoutData(gridData);
      
      // register combo with profile manager
      profileManager.registerControl(profileCombo);
      
      // profile manager acts as listener
      profileCombo.addSelectionListener(profileManager);
      
      // Button to add profiles
      Button addProfileBtn = toolkit.createButton(profileComposite, "", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      addProfileBtn.setLayoutData(gridData);
      addProfileBtn.setToolTipText("Add database profile");
      addProfileBtn.setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/add.gif").createImage());
      addProfileBtn.addSelectionListener(new SelectionListener() {
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         public void widgetSelected(SelectionEvent e) {
            // profileManager handles new profile
            profileManager.addProfile();
         }         
      });

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
      
      // init subComposites
      subComposites = new Composite[4];
      
      subComposites[0] = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, true);
      subComposites[0].setLayoutData(gridData);
      gridLayout = new GridLayout(4, false);
      gridLayout.verticalSpacing = 2;
      gridLayout.marginHeight = 2;
      subComposites[0].setLayout(gridLayout);      
      
      // Search label      
      Label searchLabel = toolkit.createLabel(subComposites[0], "Search Fields: Match");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      searchLabel.setLayoutData(gridData);
      
      // Radio buttons
      allBtn = toolkit.createButton(subComposites[0], "All", SWT.RADIO);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      allBtn.setLayoutData(gridData);
      allBtn.setSelection(true);
      allBtn.setToolTipText("Select to require entries to match all search fields");
      
      anyBtn = toolkit.createButton(subComposites[0], "Any", SWT.RADIO);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      anyBtn.setLayoutData(gridData);
      anyBtn.setToolTipText("Select to require entries to match one or more search fields");
            
      // Second sub-composite
      subComposites[1] = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);      
      subComposites[1].setLayoutData(gridData);      
      gridLayout = new GridLayout(4, false);
      gridLayout.verticalSpacing = 0;
      gridLayout.marginHeight = 2;
      subComposites[1].setLayout(gridLayout);

      // Labels
      String [] labels1 = {"User Name:", "IP Address:", "MAC Address:", "Description:" };
      for (String label : labels1) {
         Label newLabel = toolkit.createLabel(subComposites[1], label);
         gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);
         newLabel.setLayoutData(gridData);
      }
      // Text boxes
      useridText = toolkit.createText(subComposites[1], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 14 * AVG_CHAR_WIDTH;
      useridText.setLayoutData(gridData);
      useridText.setToolTipText("Enter a User Name (supports * wildcard)");
      
      ipText = toolkit.createText(subComposites[1], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 17 * AVG_CHAR_WIDTH;      
      ipText.setLayoutData(gridData);
      ipText.setToolTipText("Enter an IP Address (supports * wildcard) or a CIDR subnet pattern to match entries by subnet (e.g. 192.168.10.0/24)");

      macText = toolkit.createText(subComposites[1], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = 19 * AVG_CHAR_WIDTH;
      macText.setLayoutData(gridData);
      macText.setToolTipText("Enter a MAC address as six hexadecimal values (e.g. 11:aa:22:bb:33:cc); supports * wildcard");

      descText = toolkit.createText(subComposites[1], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.widthHint = gridData.minimumWidth = DEFAULT_WIDTH;
      descText.setLayoutData(gridData);
      descText.setToolTipText("Enter a description; supports * wildcard");
      
      // Sub-composite 3 
      subComposites[2] = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.LEFT, SWT.TOP, true, false);
      subComposites[2].setLayoutData(gridData);
      gridLayout = new GridLayout(6, false);
      gridLayout.verticalSpacing = 2;
      gridLayout.marginHeight = 2;      
      subComposites[2].setLayout(gridLayout);      

      // Action labels and texts
      Label actionLabel = toolkit.createLabel(subComposites[2], "Action:");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      actionLabel.setLayoutData(gridData);
      
      Label addedFromLabel = toolkit.createLabel(subComposites[2], "Earliest Action Time:");
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false);      
      addedFromLabel.setLayoutData(gridData);

      Label addedToLabel = toolkit.createLabel(subComposites[2], "Latest Action Time:");
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false, 4, 1);
      addedToLabel.setLayoutData(gridData);      

      actionCombo = new Combo(subComposites[2], SWT.READ_ONLY|SWT.DROP_DOWN);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = gridData.widthHint = 12 * AVG_CHAR_WIDTH;
      actionCombo.setLayoutData(gridData);
      actionCombo.setToolTipText("Select action type");
      actionCombo.add("(ANY)");
      actionCombo.add("ADD");
      actionCombo.add("MODIFY");
      actionCombo.add("DELETE");
      actionCombo.select(0);
      
      addedFromText = toolkit.createText(subComposites[2], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = gridData.widthHint = 20 * AVG_CHAR_WIDTH;
      addedFromText.setLayoutData(gridData);
      addedFromText.setToolTipText("Enter earliest action time in YYYY-MM-DD [hh:mm:[ss] [TZ]] format");
            
      addedToText = toolkit.createText(subComposites[2], "");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = gridData.widthHint = 20 * AVG_CHAR_WIDTH;
      addedToText.setLayoutData(gridData);
      addedToText.setToolTipText("Enter latest action time in YYYY-MM-DD [hh:mm:[ss] [TZ]] format");
            
      // Checkboxes
      disabledBtn = toolkit.createButton(subComposites[2], "Disabled", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.horizontalIndent = 10;
      disabledBtn.setLayoutData(gridData);
      disabledBtn.setToolTipText("Select to match only disabled entries");
      
      infectedBtn = toolkit.createButton(subComposites[2], "Infected", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.horizontalIndent = 10;
      infectedBtn.setLayoutData(gridData);
      infectedBtn.setToolTipText("Select to match only infected entries");

      staticBtn = toolkit.createButton(subComposites[2], "Static", SWT.CHECK);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.horizontalIndent = 10;
      staticBtn.setLayoutData(gridData);
      staticBtn.setToolTipText("Select to match only static entries");
                                        
      // Search button and message label
      subComposites[3] = toolkit.createComposite(searchComposite);
      gridData = new GridData(SWT.FILL, SWT.TOP, true, false);
      subComposites[3].setLayoutData(gridData);
      gridLayout = new GridLayout(2, false);
      subComposites[3].setLayout(gridLayout);
      
      // Search Button
      searchBtn = toolkit.createButton(subComposites[3], "Search", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.TOP, false, false);
      gridData.minimumWidth = 10 * AVG_CHAR_WIDTH;
      gridData.verticalIndent = 2;
      searchBtn.setLayoutData(gridData);
      
      // Message label
      messageLabel = toolkit.createLabel(subComposites[3], "");
      gridData = new GridData(SWT.FILL, SWT.CENTER, true, false);
      gridData.horizontalIndent = 10;
      gridData.minimumHeight = 2 * AVG_CHAR_HEIGHT;
      messageLabel.setLayoutData(gridData);
            
      // Set search area's background color
      for (Composite composite: subComposites) {
         composite.setBackground(bgColor);
         for (Control control : composite.getChildren()) {
            if (!(control instanceof Text)) 
               control.setBackground(bgColor);
         }
      }      

   }
   
   private void createHistoryResultsSection(Section section) {

      final Composite parent = section.getParent();
      
      // Create results composite
      Composite resultsComposite = toolkit.createComposite(section);
      GridData gridData = new GridData(SWT.FILL, SWT.FILL, true, true);
      resultsComposite.setLayoutData(gridData);
      GridLayout gridLayout = new GridLayout(1, true);
      resultsComposite.setLayout(gridLayout);

      section.setClient(resultsComposite);
      
      // Create table viewer
      histViewer = new TableViewer(toolkit.createTable(resultsComposite, SWT.SINGLE));
      histTable = histViewer.getTable();
      gridData = new GridData(SWT.FILL, SWT.TOP, true, true);
      histTable.setLayoutData(gridData);

      // Columns
      String[] headers = { "User Name", "IP Address", "MAC Address", "Description", 
            "Disabled", "Infected", "Inf. Ports", "Static", "Action", "Action Time", "Last Update" };

      // Listener for column selection (sorting)
      HistSearchComparatorListener searchComparatorListener = new HistSearchComparatorListener(parent, histViewer);
      
      // Create viewer columns
      for (int i = 0; i < headers.length; i++) {
         TableViewerColumn histColumn = null;         
         if (headers[i].equals("Disabled")) {
            histColumn = new TableViewerColumn(histViewer, SWT.CENTER);
            histColumn.setLabelProvider(new HistSearchImageProvider(i /*JuNetSu.COL_DISABLED*/, "icons/disabled.gif")); 
            histColumn.getColumn().setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/disabled.gif").createImage());
            histColumn.getColumn().setToolTipText("Disabled");
            histColumn.getColumn().setWidth(32);
         }
         else if (headers[i].equals("Infected")) {
            histColumn = new TableViewerColumn(histViewer, SWT.CENTER);
            histColumn.setLabelProvider(new HistSearchImageProvider(i /*JuNetSu.COL_INFECTED*/, "icons/bug.gif"));
            histColumn.getColumn().setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/bug.gif").createImage());
            histColumn.getColumn().setToolTipText("Infected");
            histColumn.getColumn().setWidth(30);
         }
         else {
            histColumn = new TableViewerColumn(histViewer, SWT.LEFT);
            histColumn.setLabelProvider(new HistSearchLabelProvider(i /*dbColumns[i]*/));
            histColumn.getColumn().setText(headers[i]);            
            if (headers[i].equals("Inf. Ports")) {
               histColumn.getColumn().setToolTipText("Infected Ports");
            }
            histColumn.getColumn().pack();
         }
         histColumn.getColumn().addListener(SWT.Selection, searchComparatorListener);
      }

      for (int i = 0; i < headers.length; i++) {
         TableColumn histColumn = histTable.getColumn(i);         
         if (headers[i].equals("User Name")) {
            histColumn.setWidth(15 * AVG_CHAR_WIDTH);
         }
         else if (headers[i].equals("IP Address") ) {
            histColumn.setWidth(17 * AVG_CHAR_WIDTH);
         }
         else if (headers[i].equals("MAC Address")) {
            histColumn.setWidth(19 * AVG_CHAR_WIDTH);
         }
         else if (headers[i].equals("Description")) {
            histColumn.setWidth(DEFAULT_WIDTH);
         }
         else if (headers[i].equals("Disabled")) {         
            histColumn.setWidth(32);            
            histColumn.setResizable(false);
         }
         else if (headers[i].equals("Infected")) {
            histColumn.setWidth(30);            
            histColumn.setResizable(false);            
         }
         else if (headers[i].equals("Inf. Ports")) {
            histColumn.setWidth(10 * AVG_CHAR_WIDTH);
         }
         else if (headers[i].equals("Action")) {
            histColumn.setWidth(12 * AVG_CHAR_WIDTH);
         }
         else if (headers[i].equals("Action Time")) {
            histColumn.setWidth(25 * AVG_CHAR_WIDTH);            
         }
         else if (headers[i].equals("Last Update")) {
            histColumn.setWidth(25 * AVG_CHAR_WIDTH);
         }
         else {
            histColumn.pack();
         }
      }
      
      histTable.setHeaderVisible(true);     

      // Content Provider
      histContentProvider = new HistSearchContentProvider();
      histViewer.setContentProvider(histContentProvider);

      searchBtn.addSelectionListener(new SelectionListener() {
         @Override
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         @Override
         public void widgetSelected(SelectionEvent e) {

            doSearch();
            
         }
         
      });
      
   }
   
   public void createHistoryPage(Composite parent) {
      
      // Compute font width
      GC gc = new GC(parent);
      AVG_CHAR_WIDTH = gc.getFontMetrics().getAverageCharWidth();
      AVG_CHAR_HEIGHT = gc.getFontMetrics().getHeight();
      DEFAULT_WIDTH = 25 * AVG_CHAR_WIDTH; 
      gc.dispose();
      
      toolkit = new FormToolkit(parent.getDisplay());
      
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
      searchSection.setText("History Search");
      searchSection.setExpanded(true);
      
      createHistorySearchSection(searchSection);
      
      // Results section
      Section resultsSection = toolkit.createSection(parent, ExpandableComposite.TITLE_BAR|ExpandableComposite.TWISTIE);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(searchSection, 0, SWT.BOTTOM);
      layoutData.left = new FormAttachment(0, 0);
      layoutData.right = new FormAttachment(100, 0);
      layoutData.bottom = new FormAttachment(100, 0);
      resultsSection.setLayoutData(layoutData);
      resultsSection.setLayout(new GridLayout(1, true));
      resultsSection.setText("Search Results");
      resultsSection.setExpanded(true);
      
      // Create the controls for the results section
      createHistoryResultsSection(resultsSection);
      
   }
   
   public void doSearch() {
      boolean errorFlag = false;
      
      boolean warningFlag = !JavaUtil.hasString(useridText.getText()) &&
                            !JavaUtil.hasString(ipText.getText()) &&
                            !JavaUtil.hasString(macText.getText()) &&
                            !JavaUtil.hasString(descText.getText()) &&                                        
                            !JavaUtil.hasString(addedFromText.getText()) &&
                            !JavaUtil.hasString(addedToText.getText()) &&
                            !disabledBtn.getSelection() &&
                            !infectedBtn.getSelection() &&
                            !staticBtn.getSelection();

      // Warn if no criteria is filled
      if (warningFlag) {
         if (!MessageDialog.openQuestion(null, 
                                    "Junetsu",
                                    "Your search will return a very large number of entries. Do you wish to proceed?"))
            return;
      }
      
      try {
         searchBtn.getShell().setCursor(CoreCursors.AppStarting);
         searchBtn.setEnabled(false);
         MyProfiler.start("com.omnibond.designer.junetsu#total", "Total");

         // Get database profile
         /*
         m_profile = profileManager.getProfileByName(profileCombo.getText());
         if (m_profile != null) {
            if (!m_connected) {
         */               
         // Connect to the database -- Designer will catch and report connection errors
         MyProfiler.start("com.omnibond.designer.junetsu#connect", "DB Connect");
         if (profileManager.connect()) {
            MyProfiler.stop("com.omnibond.designer.junetsu#connect", "DB Connect");
            
            m_conn = profileManager.getConnection();
            if (m_conn != null) {
               // Clear search input
               histViewer.setInput(null);

               HistSearchInput histSearchInput = new HistSearchInput(m_conn);

               // add database name
               String dbName = profileManager.getProperty("org.eclipse.datatools.connectivity.db.databaseName");
               histSearchInput.setPropertyValue(HistSearchInput.DATABASE_NAME, dbName);

               // add search properties
               histSearchInput.setPropertyValue(HistSearchInput.SEARCH_MODE, allBtn.getSelection() ? "all" : "any");
               histSearchInput.setPropertyValue(HistSearchInput.USER_NAME, useridText.getText());
               histSearchInput.setPropertyValue(HistSearchInput.IP_ADDRESS, ipText.getText());
               histSearchInput.setPropertyValue(HistSearchInput.MAC_ADDRESS, macText.getText());
               histSearchInput.setPropertyValue(HistSearchInput.DESCRIPTION, descText.getText());
               histSearchInput.setPropertyValue(HistSearchInput.DISABLED, disabledBtn.getSelection() ? "true" : null);
               histSearchInput.setPropertyValue(HistSearchInput.INFECTED, infectedBtn.getSelection() ? "true" : null);
               histSearchInput.setPropertyValue(HistSearchInput.STATIC, staticBtn.getSelection() ? "true" : null);
               if (!actionCombo.getText().equals("(ANY)")) {
                  histSearchInput.setPropertyValue(HistSearchInput.ACTION, actionCombo.getText());
               }
               histSearchInput.setPropertyValue(HistSearchInput.ADDED_FROM, addedFromText.getText());
               histSearchInput.setPropertyValue(HistSearchInput.ADDED_TO, addedToText.getText());

               // IP Address filter
               for (ViewerFilter filter: histViewer.getFilters()) {
                  histViewer.removeFilter(filter);
               }
               if (JavaUtil.hasString(ipText.getText())) {
                  HistSearchFilter filter = new HistSearchFilter(ipText.getText());
                  // if the address is a CIDR pattern, add the filter
                  if (filter.getValid()) {
                     histViewer.addFilter(filter);
                     // set the IP search string to a subnet string
                     histSearchInput.setPropertyValue(HistSearchInput.IP_ADDRESS, filter.getSearchString());
                  }
                  else {
                     // only report if user tried to actually use pattern
                     if (ipText.getText().contains("/")) {
                        updateMessageLabel("Error: the CIDR pattern entered as the IP Address is invalid.");
                        errorFlag = true;
                     }
                  }

               }

               // Set Action Time as default sort column
               if (histTable.getSortColumn() == null) {
                  histTable.setSortColumn(histTable.getColumn(9));
                  histTable.setSortDirection(SWT.DOWN);
               }

               // Perform search by setting search input
               histViewer.setInput(histSearchInput);
               
               String msg = histContentProvider.getMessage();
               errorFlag = msg.startsWith("Error:");
               
               // Set table height            
               if (histTable.getItemCount() > 0) {
                  int maxHeight = histTable.getParent().getSize().y;
                  // round off maxHeight to number of items
                  maxHeight -= histTable.getHeaderHeight();
                  maxHeight = maxHeight / (histTable.getItemHeight()) * histTable.getItemHeight();
                  maxHeight += histTable.getHeaderHeight();
                  int totalHeight = histTable.getItemHeight() * histTable.getItemCount() + histTable.getHeaderHeight();
                  int actualHeight = Math.min(maxHeight, totalHeight);
                  GridData gridData = (GridData) histTable.getLayoutData();
                  gridData.heightHint = actualHeight;  
                  histTable.getParent().layout(true);
               }

               if (!errorFlag) {
                  int count = histTable.getItemCount();
                  msg = count + " entries found";
                  if (count == 20000) {
                     msg = "20000+ entries found";
                  }
                  else if (count == 1) {
                     msg = "1 entry found";
                  }                        
               }
               updateMessageLabel(msg);
               
            } // m_conn != null
         } // connect
         else {
            updateMessageLabel("Error: could not connect to selected database");
         }
      }
      catch (Exception ex) {
         ex.printStackTrace();
         updateMessageLabel(ex.getClass().getCanonicalName() + ": " + ex.getMessage());
         errorFlag = true;
      }
      finally {
         MyProfiler.stop("com.omnibond.designer.junetsu#dbprocessentries", "Process Entries");               
         MyProfiler.stop("com.omnibond.designer.junetsu#total", "Total");
         MyProfiler.report();
         
         monitor.done();
         searchBtn.getShell().setCursor(CoreCursors.Normal);
         searchBtn.setEnabled(true);
      }
      
   }
   
   public void externalSearch(String attribute, String searchText) {
      
      // Clear Search fields
      for (Composite subComposite : subComposites) {
         for (Control control : subComposite.getChildren()) {
            if (control instanceof Text) {
               ((Text) control).setText("");               
            }
            else if (control instanceof Button &&
                     (((Button) control).getStyle() & SWT.CHECK) != 0) {
               ((Button) control).setSelection(false);
            }
         }
      }
      actionCombo.select(0);
      allBtn.setSelection(true);
      
      // Populate search field
      if (attribute.equals(JuNetSu.ATTRIBUTE_DHCP_ADDRESS)) {
         ipText.setText(searchText);
      }
      else if (attribute.equals(JuNetSu.ATTRIBUTE_HW_ADDRESS)) {
         macText.setText(searchText);
      }
      else if (attribute.equals(JuNetSu.ATTRIBUTE_USER_DN)) {
         useridText.setText(searchText);
      }
      
      // Only search 1 month in the past
      Calendar now = Calendar.getInstance();
      now.add(Calendar.MONTH, -1);
      SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
      addedFromText.setText(df.format(now.getTime()));
      
      doSearch();
      
   }
   
   private void updateMessageLabel(String text) {
      if (text.startsWith("Error")) {
         messageLabel.setForeground(ColorConstants.red);
      }
      else {
         messageLabel.setForeground(colorRegistry.get("org.eclipse.ui.editors.foregroundColor"));
      }
      messageLabel.setText(text);
   }
   
   
}
