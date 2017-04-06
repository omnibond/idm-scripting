Using the JuNetSu Designer Plug-in.

1. Create a new Designer Project. 
2. Create an Identity Vault in the Developer. Specify its address, user name and password.
3. Open the JuNetSu page by clicking the tab on the bottom.
4. Your Identity Vault should be automatically selected. Enter/select the Base Container where Network Devices are located in the Base Container text box.
5. Enter your search parameters:
   * Selecting Match All will require entries to match all fields entered (the "and" boolean operator is used).
   * Selecting Match Any requires one or more fields to match (the "or" operator is used). The exception is the Time Added fields. Matching entries must always be between the two times if both are specified.
   * You may specify just a user name (CN) in the User Name or DN field. The entire tree will be searched for a user with the specified CN. If you specify a DN, use dotted format (e.g. bob.engineering.acme).
   * You may use the CIDR format in the IP Address field. The format is N.N.N.N/P, where P is the prefix length (e.g. 192.168.10.0/24). The search will return all addresses in the block matching the CIDR address. The address doesn't need to be the first address in the block. See http://en.wikipedia.org/wiki/CIDR for more information.  
   * You may use the * wildcard in the IP Address, MAC Address and Description fields.
   * The time format is YYYY-MM-DD [hh:mm[:ss] [TZ]], so the time is optional. If no time is specified, the time is considered to midnight. The timezone is the standard abbreviation, e.g. EST, PDT.
   * When the checkbox fields are not checked, their values are not considered in the search. When they are checked, the checked field must be "yes" (true).
6. Click the Search button to perform your search. Broad searches can be very time-consuming.
7. You can sort by any field by clicking it. Sorting large groups of entries can be time-consuming.

Known issues:
   * Designer logs error messages about the location of iManager images. This issue does not affect operations and has been reported to Novell.
   * The Base Container text box should save your entry from session-to-session.
   * Searches are limited to 7,000 entries. This issue has been reported to Novell.
   * In the left tree of the Browse Identity Vault dialog, selecting a container that contains a large number of objects can cause Designer to lock up or abort. Workaround: select the object on the right-hand side.    
   * Broad searches can cause Designer to lock up or abort due to lack of memory.
   * Sorting large groups of entries takes a very long time.
   * Sorting should be disabled when a new search is made, to save time.

 