' Copyright (C) 2008 Novell, Inc.

Sub ADD        
  Dim Server
  Dim Identity

  ' CN becomes (Logon) Name
  CN = IDMGetEventValue("CN")
  ClassName = IDMGetEventValue("CLASS_NAME")
  DomainName = IDMGetEventValue("DomainName")
  If CN <> "" And ClassName <> "" And DomainName <> "" Then
    ' Create the identity
    Set Server = GetObject("WinNT://" & DomainName)
    Set Identity = Server.Create(ClassName, CN)
    Identity.SetInfo
    ' Handle attribute settings and group memberships
    ' DoAttributes and DoMembership are declared in Modify.vbs
    DoAttributes Identity
    If ClassName = "Group" Then
      DoMembership Identity, "WinNT://" & DomainName & "/"
    End If
    
    DN = IDMGetEventValue("SRC_DN")

    IDMSetCommand "ADD_ASSOCIATION"
    IDMWriteValue "CLASS_NAME", ClassName
    ' Form the association from the domain and CN, e.g. MyDomain/JSmith
    IDMWriteValue "ASSOCIATION", DomainName & "/" & CN
    IDMWriteValue "DEST_DN", DN
    IDMStatusSuccess "Add event succeeded"
  Else
    IDMStatusError "Domain, CN or class name not available"
  End If

End Sub    
  