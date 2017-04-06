-- IDM Exchange Management Shell Driver ASN1 Schema Definitions
-- Omnibond LLC
-- 
-- VeRsIoN=
-- CoPyRiGhT=(c) Copyright 2008, Portions Omnibond, LLC. and Novell, Inc.  All rights reserved

-- Object ID Syntax
------------------------------------------
------------------------------------------
-- ASN1 Object ID's Defined as Follows:
--     joint-iso-ccitt(2) country(16) us(840)   organization(1)
--     Novell(113719) applications(1) DirXML(14) NDSAttributeType(4)
--                                               NDSAttributeSyntax(5)
--                                               NDSObjectClass(6)
--              revision number(1) sequence number(1)
---------------------------------------------------------------


DirXML-ExShellSchemaExtensions DEFINITIONS ::=
BEGIN

"DirXML-ExShellState" ATTRIBUTE ::=
{
  Operation ADD,
  Flags { DS_SYNC_IMMEDIATE, DS_SINGLE_VALUED_ATTR },
  SyntaxID SYN_CI_STRING,
  ASN1ObjID {2 16 840 1 113719 1 14 4 1 15001}
}

"DirXML-ApplicationAttrs" OBJECT-CLASS ::=
{
  Operation MODIFY,
  MayContain {
    "DirXML-ExShellState"
  }
}

END
