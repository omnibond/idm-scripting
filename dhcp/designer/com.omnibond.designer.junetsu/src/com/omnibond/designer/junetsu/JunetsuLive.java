package com.omnibond.designer.junetsu;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.eclipse.emf.ecore.EPackage;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.jface.resource.ColorRegistry;
import org.eclipse.jface.viewers.ITreeContentProvider;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.jface.viewers.TreeViewer;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.ui.PlatformUI;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.plugin.AbstractUIPlugin;

import com.novell.core.util.JavaUtil;
import com.novell.core.util.Log;
import com.novell.designer.model.CObject;
import com.novell.idm.model.DesignElement;
import com.novell.idm.model.IdmModelFactory;
import com.novell.idm.model.IdmModelPackage;
import com.novell.idm.modeler.Modeler;

public class JunetsuLive {
      
   
   // This class represents a range of IP addresses in the network
   // It also stores the statistical information for that range
   // These objects are returned by the content provider
   private class LiveNetworkElement
   {
      public String name;
      public String firstAddress, lastAddress, CIDR;
      public int addCount, modifyCount, deleteCount, infectedCount;
      
      public LiveNetworkElement parent;      
      public List<LiveNetworkElement> children;
      
      public DesignElement designElement;
      
      // This constructor is used when loading the element from disk
      // The properties of the DesignElement are assigned to the properties of the LiveNetworkElement
      public LiveNetworkElement(DesignElement designElement) {
         
         this.designElement = designElement;
         children = new ArrayList<LiveNetworkElement>();
         
         name = designElement.getValueString(JuNetSu.JUNETSU_NAME);
         CIDR = designElement.getValueString(JuNetSu.JUNETSU_CIDR);                                                 
         firstAddress = designElement.getValueString(JuNetSu.JUNETSU_FIRST_ADDRESS);
         lastAddress = designElement.getValueString(JuNetSu.JUNETSU_LAST_ADDRESS);

      }

      // This constructor creates a new network element and assigns the specified values to the DesignElement
      public LiveNetworkElement(DesignElement designElement, String name, String cidr, String firstAddress, String lastAddress) {         
         children = new ArrayList<LiveNetworkElement>();
         
         this.name = name;
         this.designElement = designElement;
         
         if (JavaUtil.hasString(cidr)) {
            // generate first and last addresses with CIDR
            this.firstAddress = getFirstBlockAddress(cidr);
            this.lastAddress = getLastBlockAddress(cidr);
            this.CIDR = getCanonicalCIDR(cidr);
         }
         else {
            this.firstAddress = firstAddress;
            this.lastAddress = lastAddress;
         }
         
         this.designElement.setType(JuNetSu.JUNETSU_LIVE_NETWORK);
         this.designElement.setAttribute(JuNetSu.JUNETSU_NAME, this.name);
         if (JavaUtil.hasString(this.CIDR)) 
            this.designElement.setAttribute(JuNetSu.JUNETSU_CIDR, this.CIDR);
         this.designElement.setAttribute(JuNetSu.JUNETSU_FIRST_ADDRESS, this.firstAddress);
         this.designElement.setAttribute(JuNetSu.JUNETSU_LAST_ADDRESS, this.lastAddress);
                           
      }
      
      // Get the first address given the specified CIDR block
      // Assumes that the block string is valid
      private String getFirstBlockAddress(String cidr) {         
         
         String[] tokens = cidr.split("[\\./]");
         int prefix = Integer.parseInt(tokens[4]);
         
         // Get the address as a 32-bit integer
         int address = Integer.parseInt(tokens[0]) << 24 |
                       Integer.parseInt(tokens[1]) << 16 | 
                       Integer.parseInt(tokens[2]) << 8 |
                       Integer.parseInt(tokens[3]);
         
         // Generate the mask for the network 
         int netmask = (prefix == 0) ? 0 : 0xFFFFFFFF << (32 - prefix);
         // Anding the netmask with the address gives the first address (the host portion will be 0)
         // Technically when the host portion = 0, that value represents the network itself if prefix < 31
         int firstAddress = address & netmask;
         // convert first address to a string
         String strAddress = String.valueOf((firstAddress & 0xFF000000) >>> 24) + "." +
                             String.valueOf((firstAddress & 0x00FF0000) >>> 16) + "." +
                             String.valueOf((firstAddress & 0x0000FF00) >>> 8) + "." +
                             String.valueOf((firstAddress & 0x000000FF));
         
         return strAddress;
      }
      
      // Get the last address given the specified CIDR block
      private String getLastBlockAddress(String cidr) {
         String[] tokens = cidr.split("[\\./]");
         int prefix = Integer.parseInt(tokens[4]);
         
         // Get the address as a 32-bit integer
         int address = Integer.parseInt(tokens[0]) << 24 |
                       Integer.parseInt(tokens[1]) << 16 | 
                       Integer.parseInt(tokens[2]) << 8 |
                       Integer.parseInt(tokens[3]);
         
         // Generate the mask for the host portion
         int hostmask = (prefix == 32) ? 0xFFFFFFFF : 0xFFFFFFFF >>> (prefix);
         // Oring the hostmask with the address gives the last address (the host portion will be maximal)
         // Technically when the host portion is maximal, that value represents the broadcast address when prefix < 31
         int lastAddress = address | hostmask;
         // convert first address to a string
         String strAddress = String.valueOf((lastAddress & 0xFF000000) >>> 24) + "." +
                             String.valueOf((lastAddress & 0x00FF0000) >>> 16) + "." +
                             String.valueOf((lastAddress & 0x0000FF00) >>> 8) + "." +
                             String.valueOf((lastAddress & 0x000000FF));
         
         return strAddress;
      }
      
      // A canonical CIDR block gives the first address for the block, i.e. the network address,
      // plus the prefix length
      private String getCanonicalCIDR(String cidr) {
         String[] tokens = cidr.split("/");
         
         return (getFirstBlockAddress(cidr) + "/" + tokens[1]);
      }
      
      public String toString() {
         return name + " " + firstAddress + " - " + lastAddress;
      }
            
   }
   
   private class LiveContentProvider
      implements ITreeContentProvider {

      //private Object m_input;
      private TreeViewer viewer;
      private IdmModelFactory factory;
      private List<LiveNetworkElement> rootList;
      private DesignElement modelElement;
      
      public LiveContentProvider(TreeViewer viewer, IdmModelFactory factory) {
         this.viewer = viewer;
         this.factory = factory;
         rootList = new ArrayList<LiveNetworkElement>();
      }
      
      @Override
      public Object[] getChildren(Object parentElement) {
         
         LiveNetworkElement element = (LiveNetworkElement) parentElement;
         Object[] children = new Object[element.children.size()];
         element.children.toArray(children);
         
         return children;
      }

      @Override
      public Object getParent(Object element) {
         
         return ((LiveNetworkElement) element).parent;
                  
      }

      @Override
      public boolean hasChildren(Object element) {
         
         return ((LiveNetworkElement) element).children.size() > 0;
         
      }

      @Override
      public Object[] getElements(Object inputElement) {         
         DesignElement element = (DesignElement) inputElement;
         
         // The immediate children of the input element are root network ranges         
         DesignElement[] elements = new DesignElement[element.getChildren().size()];
         element.getChildren().toArray(elements);                  
         
         // Recursively build tree for each root network
         rootList.clear();
         for (DesignElement dElement : elements) {
            buildNetworkElements(dElement, rootList);
         }
         
         LiveNetworkElement[] netElements = new LiveNetworkElement[rootList.size()];
         rootList.toArray(netElements);
         
         return netElements;
      }
      
      private void buildNetworkElements(DesignElement root, List<LiveNetworkElement> rootList) {
         
         LiveNetworkElement newElement = new LiveNetworkElement(root);
         
         rootList.add(newElement);
         
         buildNetworkElementsRecurse(newElement, root.getChildren());
      }
      
      private void buildNetworkElementsRecurse(LiveNetworkElement parent, List<CObject> children) {
         
         List<LiveNetworkElement> netChildren = new ArrayList<LiveNetworkElement>();
         
         Iterator<CObject> iter = children.iterator();
         while (iter.hasNext()) {
            DesignElement element = (DesignElement) iter.next();
            LiveNetworkElement newElement = new LiveNetworkElement(element);
            newElement.parent = parent;
            buildNetworkElementsRecurse(newElement, element.getChildren());
            
            netChildren.add(newElement);
         }
         
         parent.children.addAll(netChildren);
      }
      
      public void addNetworkElement(String name, String CIDR, String firstAddress, String lastAddress, boolean isRootNetwork) {
         
         // Create a new DesignElement for the network
         DesignElement dElement = factory.createDesignElement();
         LiveNetworkElement newElement = new LiveNetworkElement(dElement, name, CIDR, firstAddress, lastAddress);         
         
         if (isRootNetwork) {
            // Add network to root level
            rootList.add(newElement);
         }
         else {
            // locate place in tree for new network
            LiveNetworkElement parentElement = null;
            
            Iterator<LiveNetworkElement> iter = rootList.iterator();
            while (iter.hasNext() && (parentElement == null)) {
               parentElement = findNetworkParent(iter.next(), newElement);
            }
            
            // Add to root list if no parent element
            if (parentElement == null) {
               rootList.add(newElement);
               modelElement.internalSetEnableNotifications(false);
               modelElement.getDesignElements().add(newElement.designElement);
               modelElement.internalSetEnableNotifications(true);
            }
            else {
               newElement.parent = parentElement;
               newElement.designElement.setParent(parentElement.designElement);
               parentElement.designElement.internalSetEnableNotifications(false);
               parentElement.designElement.getDesignElements().add(newElement.designElement);
               parentElement.designElement.internalSetEnableNotifications(true);
            }
            modeler.setDirty(true);
         }
         
         // This is to cause the viewer to reread the elements
         viewer.setInput(modelElement);
         
      }
      
      public void deleteNetworkElement(LiveNetworkElement element) {
         
         // Remove DesignElement (and children) from Designer model
         element.designElement.getParent().getChildren().remove(element.designElement);
         modeler.setDirty(true);
         
         // Remove from our own model
         element.parent.children.remove(element);
         
         // Remove item from viewer
         viewer.remove(element);
      }
      
      private LiveNetworkElement findNetworkParent(LiveNetworkElement rootElement, LiveNetworkElement newElement) {
         // The root network is the parent of the new network if the network addresses
         // fall within the range of the root's addresses
         
         if (JuNetSu.addressInRange(newElement.firstAddress, rootElement.firstAddress, rootElement.lastAddress) &&
             JuNetSu.addressInRange(newElement.lastAddress, rootElement.firstAddress, rootElement.lastAddress)) {
            return rootElement;
         }

         LiveNetworkElement parentElement = null;
         Iterator<LiveNetworkElement> iter = rootElement.children.iterator();
         while (iter.hasNext() && (parentElement == null)) {
            parentElement = findNetworkParent(iter.next(), newElement);
         }
         
         return rootElement;
      }

      @Override
      public void dispose() {
         // TODO         
      }

      @Override
      public void inputChanged(Viewer viewer, Object oldInput, Object newInput) {
         modelElement = (DesignElement) newInput;
      }
            
   }
   
   /*
   private class LiveLabelProvider 
      extends OwnerDrawLabelProvider
   {

      @Override
      protected void measure(Event event, Object element) {
         //DesignElement dElement = (DesignElement) element;
         //String text = dElement.getValueString(JuNetSu.JUNETSU_NAME);
         event.width = ((Tree)event.widget).getClientArea().width - 100;         
         event.height = 30;
      }

      @Override
      protected void paint(Event event, Object element) {
         
         LiveNetworkElement netElement = (LiveNetworkElement) element;
         
         event.gc.drawText(netElement.name, 4, 4);
         
         event.gc.drawText(netElement.firstAddress + " - " + netElement.lastAddress, 100, 4);
         
      }
      
   }
   */
   
   private Modeler modeler;
   private DesignElement element;
   private IdmModelFactory factory;
   private ColorRegistry colorRegistry;
   private JunetsuDBProfileManager profileManager;
   private FormToolkit toolkit;
   private TreeViewer liveTreeViewer;
   private Tree liveTree;
   private LiveContentProvider liveContentProvider;
   private Combo profileCombo;
   private Spinner refreshSpn, historySpn;
   private Label testLabel;
   //private LiveNetworkElement[] rootNetworks;

   public JunetsuLive(Modeler modeler, DesignElement element) {
      this.modeler = modeler;
      this.element = element;
      
      // Init color registry
      colorRegistry = PlatformUI.getWorkbench().getThemeManager().getCurrentTheme().getColorRegistry();
      
      // Init our DB profile manager      
      profileManager = JunetsuDBProfileManager.getInstance(modeler, element);
      
      // Get Designer model factory
      Map<String, Object> registry = EPackage.Registry.INSTANCE;
      IdmModelPackage modPackage = (IdmModelPackage) registry.get(IdmModelPackage.eNS_URI);
      factory = modPackage.getIdmModelFactory();
      if (factory == null) {
         Log.error("Junetsu Live: could not get model factory.");
      }
      
      // TODO: temporary: create root network object
      /*
      List<CObject> children = element.getChildren();
      if (children.isEmpty()) {
         DesignElement newElement = factory.createDesignElement();
         newElement.setParent(element);
         newElement.setType(JuNetSu.JUNETSU_DATA);
         newElement.setAttribute(JuNetSu.JUNETSU_NAME, "main 10.1.5.x");
         newElement.setAttribute(JuNetSu.JUNETSU_FIRST_ADDRESS, "10.1.5.0");
         newElement.setAttribute(JuNetSu.JUNETSU_LAST_ADDRESS, "10.1.5.255");
         newElement.setAttribute(JuNetSu.JUNETSU_CIDR, "10.1.5.0/24");
         
         element.internalSetEnableNotifications(false);
         element.getDesignElements().add(newElement);
         element.internalSetEnableNotifications(true);
         
      }
      */
      
      // Initialize the tree of network elements
      // TODO ? 
      //rootNetworks = new LiveNetworkElement[element.getChildren().size()];
      
      

   }
   
   private void createSettingsSection(Composite parent) {
            
      Color bgColor = colorRegistry.get("org.eclipse.ui.workbench.ACTIVE_TAB_BG_START");
      final Shell shell = parent.getShell();
      
      Button liveBtn = toolkit.createButton(parent, "Live", SWT.TOGGLE);
      GridData gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      liveBtn.setLayoutData(gridData);
      
      // TODO: live button action
      
      Button addBtn = toolkit.createButton(parent, "Add...", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      addBtn.setLayoutData(gridData);
            
      addBtn.addSelectionListener(new SelectionListener() {

         @Override
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         @Override
         public void widgetSelected(SelectionEvent e) {
            // Prompt user to add network
            // TODO: edit network
            AddNetworkDialog dialog = new AddNetworkDialog(shell);
            if (dialog.open() == 0) {
               liveContentProvider.addNetworkElement(dialog.getName(), dialog.getCIDR(), 
                                                     dialog.getFirstAddress(), dialog.getLastAddress(), dialog.isRootNetwork());
            }
         }
         
      });
      
      Button deleteBtn = toolkit.createButton(parent, "Delete...", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      deleteBtn.setLayoutData(gridData);
      
      // TODO: delete button action
      deleteBtn.addSelectionListener(new SelectionListener() {
         
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }
         
         public void widgetSelected(SelectionEvent e) {
            ITreeSelection treeSelection = (ITreeSelection) liveTreeViewer.getSelection();
            
            
            LiveNetworkElement element = (LiveNetworkElement) treeSelection.getFirstElement();
            
            // testLabel.setText(element.getClass().toString() + " " + element.toString());
            
            if (element != null &&
                  MessageDialog.openQuestion(shell, "Delete network?", "Are you sure you want to delete this network and all sub-networks?")) {
               liveContentProvider.deleteNetworkElement(element);
            }
            
            
            
         }
         
      });
      
      Label profileLabel = toolkit.createLabel(parent, "Database Profile:");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      profileLabel.setLayoutData(gridData);
      
      profileCombo = new Combo(parent, SWT.DROP_DOWN|SWT.READ_ONLY);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      gridData.minimumWidth = 100;
      profileCombo.setLayoutData(gridData);
      
      profileManager.registerControl(profileCombo);

      profileCombo.addSelectionListener(profileManager);
      
      // Button to add profiles
      Button addProfileBtn = toolkit.createButton(parent, "", SWT.PUSH);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      addProfileBtn.setLayoutData(gridData);
      addProfileBtn.setToolTipText("Add database profile");
      addProfileBtn.setImage(AbstractUIPlugin.imageDescriptorFromPlugin(Activator.PLUGIN_ID, "icons/add.gif").createImage());
      addProfileBtn.addSelectionListener(new SelectionListener() {
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         public void widgetSelected(SelectionEvent e) {
            profileManager.addProfile();
         }         
      });
      
      Label label1 = toolkit.createLabel(parent, "Refresh: ");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      label1.setLayoutData(gridData);
      
      // Spinner to select number of seconds for refresh
      refreshSpn = new Spinner(parent, SWT.READ_ONLY);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      refreshSpn.setLayoutData(gridData);
      refreshSpn.setValues(60, 15, 3600, 0, 15, 60);
      
      Label label2 = toolkit.createLabel(parent, "sec.");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      label2.setLayoutData(gridData);
      
      Label label3 = toolkit.createLabel(parent, "Show last: ");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      label3.setLayoutData(gridData);
      
      // Spinner to specify minutes of history to show
      historySpn = new Spinner(parent, SWT.READ_ONLY);
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      historySpn.setLayoutData(gridData);
      historySpn.setValues(30, 1, 120, 0, 1, 5);
      
      Label label4 = toolkit.createLabel(parent, "min.");
      gridData = new GridData(SWT.LEFT, SWT.CENTER, false, false);
      label4.setLayoutData(gridData);      
                  
      toolkit.paintBordersFor(parent);

      parent.setBackground(bgColor);
      for (Control child : parent.getChildren()) {
         child.setBackground(bgColor);
      }
      
   }
   
   private void createNetworkSection(Composite parent) {
      
      // Create main composite
      
      // Create tree viewer
      liveTreeViewer = new TreeViewer(toolkit.createTree(parent, SWT.SINGLE));
      liveTree = liveTreeViewer.getTree();
      FormData layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 4);
      layoutData.left = new FormAttachment(0, 4);
      layoutData.right = new FormAttachment(100, -4);
      liveTree.setLayoutData(layoutData);
      
      liveContentProvider = new LiveContentProvider(liveTreeViewer, factory);
      liveTreeViewer.setContentProvider(liveContentProvider);
      // liveTreeViewer.setLabelProvider(new LiveLabelProvider());
      
      liveTreeViewer.setInput(element);
      
      testLabel = new Label(parent, SWT.LEFT);
      layoutData = new FormData();
      layoutData.left = new FormAttachment(0, 4);
      layoutData.top = new FormAttachment(liveTree, 4, SWT.BOTTOM);
      layoutData.right = new FormAttachment(100, 0);
      testLabel.setLayoutData(layoutData);
      

   }
   
   public void createLivePage(Composite parent) {
           
      toolkit = new FormToolkit(parent.getDisplay());
      
      Composite settingsComposite = toolkit.createComposite(parent);
      GridLayout layout = new GridLayout(12, false);
      settingsComposite.setLayout(layout);
      FormData layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 0);
      layoutData.left = new FormAttachment(0, 0);
      layoutData.right = new FormAttachment(100, 0);
      // layoutData.bottom = new FormAttachment(0, 100);
      settingsComposite.setLayoutData(layoutData);
      
      createSettingsSection(settingsComposite);
      
      Composite networkComposite = toolkit.createComposite(parent);
      FormLayout formLayout = new FormLayout();
      networkComposite.setLayout(formLayout);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(settingsComposite, 0, SWT.BOTTOM);
      layoutData.left = new FormAttachment(0, 0);
      layoutData.right = new FormAttachment(100, 0);
      layoutData.bottom = new FormAttachment(100, 0);
      networkComposite.setLayoutData(layoutData);
      //networkComposite.setBackground(ColorConstants.red);
      
      createNetworkSection(networkComposite);
      
   }
   
   
}
