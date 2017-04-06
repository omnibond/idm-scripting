' Copyright (C) 2008 Novell, Inc.

Sub CHECKOBJECTPASSWORD
  Dim dso
  Dim Identity

  Assoc = IDMGetEventValue("ASSOCIATION")
  Password = IDMGetEventValue("PASSWORD")
  If Assoc <> "" And Password <> "" Then
    Set dso = GetObject("WinNT:")

    ' Test the password by attempting to open the object
    Tokens = Split(Assoc, "/")
    On Error Resume Next
     Set Identity = dso.OpenDSObject("WinNT://" & Assoc, Tokens(1), Password, 1)
    On Error GoTo 0

    If Not IsEmpty(Identity) Then
      IDMStatusSuccess "Passwords match"
    Else
      IDMStatusError "Passwords do not match"
    End If
  Else
    IDMStatusError "Could not retrieve association and/or password"
  End If

End Sub    
