' Copyright (C) 2008 Novell, Inc.

Sub MODIFYPASSWORD
  Dim Identity

  Assoc = IDMGetEventValue("ASSOCIATION")
  Password = IDMGetEventValue("PASSWORD")
  If Assoc <> "" And Password <> "" Then
    ' Set the password
    Set Identity = GetObject("WinNT://" & Assoc)
    Identity.SetPassword(Password)
    IDMStatusSuccess "Modify-password event succeeded"
  Else    
    IDMStatusError "Missing association and/or password"
  End If

End Sub    
  