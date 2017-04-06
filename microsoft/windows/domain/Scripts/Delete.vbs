' Copyright (C) 2008 Novell, Inc.

Sub DELETE
  Dim Domain

  Assoc = IDMGetEventValue("ASSOCIATION")
  ClassName = IDMGetEventValue("CLASS_NAME")
  Tokens = Split(Assoc, "/")
  DomainName = Tokens(0)
  UserName = Tokens(1)
  If Assoc <> "" And ClassName <> "" Then
    Set Domain = GetObject("WinNT://" & DomainName)
    ' Delete object
    Domain.Delete ClassName, UserName

    IDMStatusSuccess "Delete event succeeded"
  Else
    IDMStatusError "Could not retrieve association and/or class name"
  End If

End Sub    
  