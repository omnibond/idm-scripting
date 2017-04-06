package com.omnibond.designer.junetsu;

import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.layout.FormAttachment;
import org.eclipse.swt.layout.FormData;
import org.eclipse.swt.layout.FormLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;

import com.novell.core.util.JavaUtil;

public class AddNetworkDialog extends Dialog {

   private Text nameText, cidrText, firstAddrText, lastAddrText;
   private String name, cidr, firstAddr, lastAddr;
   private Button rootBtn;   
   private boolean isRootNetwork;
   
   public AddNetworkDialog(Shell parent) {
      super(parent);
      name = null;
      cidr = null;
      firstAddr = null;
      lastAddr = null;
   }

   public Control createDialogArea(Composite parent) {
      
      Composite composite = (Composite) super.createDialogArea(parent);
      composite.setLayout(new FormLayout());
      
      // TODO
      //Label msgLabel = new Label(composite, SWT.LEFT);
      
      Label nameLabel = new Label(composite, SWT.LEFT);
      FormData layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 8);      
      layoutData.left = new FormAttachment(0, 4);
      nameLabel.setLayoutData(layoutData);
      nameLabel.setText("Network Name:");
      
      // text edit for network name
      nameText = new Text(composite, SWT.BORDER);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(nameLabel, 4);      
      layoutData.left = new FormAttachment(0, 4);
      layoutData.right = new FormAttachment(100, -4);
      layoutData.width = 200;
      nameText.setLayoutData(layoutData);
      
      // check box for specifying root network
      rootBtn = new Button(composite, SWT.CHECK);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(nameText, 4);
      layoutData.left = new FormAttachment(0, 4);
      rootBtn.setLayoutData(layoutData);
      rootBtn.setText("Add as Root Network");
      
      Group addrGroup = new Group(composite, SWT.SHADOW_ETCHED_IN);
      addrGroup.setLayout(new FormLayout());
      ((FormLayout) addrGroup.getLayout()).marginHeight = 4;
      layoutData = new FormData();
      layoutData.top = new FormAttachment(rootBtn, 4);      
      layoutData.left = new FormAttachment(0, 4);
      layoutData.right = new FormAttachment(100, -4);
      addrGroup.setLayoutData(layoutData);
      addrGroup.setText("Network Address Range");
      
      Button cidrBtn = new Button(addrGroup, SWT.RADIO);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(0, 8);
      layoutData.left = new FormAttachment(0, 4);
      cidrBtn.setLayoutData(layoutData);
      cidrBtn.setText("Specify Address Range in CIDR Format (xx.xx.xx.xx/nn)");
      
      Label addrLabel = new Label(addrGroup, SWT.LEFT);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(cidrBtn, 8, SWT.BOTTOM);      
      layoutData.left = new FormAttachment(cidrBtn, 8, SWT.LEFT);
      addrLabel.setLayoutData(layoutData);
      addrLabel.setText("Address:");
      
      // text edit for CIDR address
      cidrText = new Text(addrGroup, SWT.BORDER);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(addrLabel, 0, SWT.TOP);      
      layoutData.left = new FormAttachment(addrLabel, 4, SWT.RIGHT);
      layoutData.right = new FormAttachment(100, -4);
      cidrText.setLayoutData(layoutData);
      
      Button rangeBtn = new Button(addrGroup, SWT.RADIO);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(cidrText, 8);      
      layoutData.left = new FormAttachment(0, 4);
      rangeBtn.setLayoutData(layoutData);
      rangeBtn.setText("Specify Address Range as First and Last Addresses");
      
      Label firstAddrLabel = new Label(addrGroup, SWT.LEFT);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(rangeBtn, 8, SWT.BOTTOM);      
      layoutData.left = new FormAttachment(rangeBtn, 8, SWT.LEFT);
      firstAddrLabel.setLayoutData(layoutData);
      firstAddrLabel.setText("First Address:");
            
      firstAddrText = new Text(addrGroup, SWT.BORDER);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(firstAddrLabel, 0, SWT.TOP);      
      layoutData.left = new FormAttachment(firstAddrLabel, 4, SWT.RIGHT);
      layoutData.right = new FormAttachment(100, -4);
      firstAddrText.setLayoutData(layoutData);
      
      Label lastAddrLabel = new Label(addrGroup, SWT.LEFT);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(firstAddrText, 8, SWT.BOTTOM);      
      layoutData.left = new FormAttachment(rangeBtn, 8, SWT.LEFT);
      lastAddrLabel.setLayoutData(layoutData);
      lastAddrLabel.setText("Last Address:");
      
      lastAddrText = new Text(addrGroup, SWT.BORDER);
      layoutData = new FormData();
      layoutData.top = new FormAttachment(lastAddrLabel, 0, SWT.TOP);      
      layoutData.left = new FormAttachment(lastAddrLabel, 4, SWT.RIGHT);
      layoutData.right = new FormAttachment(100, -4);
      lastAddrText.setLayoutData(layoutData);      
      
      // listeners to enable/disable texts
      
      cidrBtn.addSelectionListener(new SelectionListener() {

         @Override
         public void widgetDefaultSelected(SelectionEvent e) {
            widgetSelected(e);
         }

         @Override
         public void widgetSelected(SelectionEvent e) {
      
            if (((Button) e.widget).getSelection()) {
               firstAddrText.setText("");
               firstAddrText.setEnabled(false);
               lastAddrText.setText("");
               lastAddrText.setEnabled(false);
            
               cidrText.setEnabled(true);
            }
            else {
               cidrText.setText("");
               cidrText.setEnabled(false);
               
               firstAddrText.setEnabled(true);
               lastAddrText.setEnabled(true);                           
            }
         }
         
      });
            
      cidrBtn.setSelection(true);
      firstAddrText.setEnabled(false);
      lastAddrText.setEnabled(false);
      
      // dialog title
      getShell().setText("Add Junetsu Network");
   
      return composite;
   }
   
   public String getName() {
      return name;
   }
   
   public String getCIDR() {
      return cidr;
   }
   
   public String getFirstAddress() {
      return firstAddr;
   }
   
   public String getLastAddress() {
      return lastAddr;
   }

   public boolean isRootNetwork() {
      return isRootNetwork;
   }
   
   @Override
   protected void okPressed() {
      boolean valid = false;
      
      // Set the root network flag
      isRootNetwork = rootBtn.getSelection();
      
      // Check input values
      cidr = cidrText.getText();
      if (JavaUtil.hasString(cidr)) {
         String[] tokens = cidr.split("/");
         if (tokens.length == 2) {
            // check address and that prefix is from 0..32
            valid = JuNetSu.validIPAddress(tokens[0]) && 
                    Integer.parseInt(tokens[1]) >= 0 &&
                    Integer.parseInt(tokens[1]) <= 32;
         }
      }
      else {
         firstAddr = firstAddrText.getText();
         lastAddr = lastAddrText.getText();
         if (JavaUtil.hasString(firstAddr) && JavaUtil.hasString(lastAddr)) {
            valid = JuNetSu.validIPAddress(firstAddr) && JuNetSu.validIPAddress(lastAddr) && 
                    (JuNetSu.compareIPAddresses(firstAddr, lastAddr) <= 0);
         }
         
      }
      
      // check name
      name = nameText.getText();
      valid = valid && JavaUtil.hasString(name);
      
      if (valid) {
         // close the dialog     
         super.okPressed();
      }
      else {
         MessageDialog.openError(getShell(), "Junetsu Plug-in", "Your input must be a valid IP address range or CIDR block, and Name may not be blank.");
      }
   }
   
}
