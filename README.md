# fritzbox-ktipp-list
Powershell script to generate fritzbox phonebooks out of ktipp list

Script to Import KTIPP Blacklist and export it to separated fritzbox xml files (can be directly imported in phonebooks)
max entries per phonebook: 500 when using firtzbox phonebook, 1000 when using google adressbok
entries per file may vary according to omitted double entries.

The script will download the already computed ktipp blocking list (see https://raw.githubusercontent.com/trick77/callcenter-blacklist-switzerland/master/latest_cc_blacklist.txt) by trick77 and convert the entries (> 8900 !) to separated fritzbox-Phonebooks in fritzbox xml format ready to be importable in fritzbox plus separated google contacts file ready to be imported in google contacts.

So, you can choose either to import those phonebooks directly into the FritzBox and state these books as blocking list or to import the google csv's to google and connect those books to FritzBox. It is written that the last method is supporting up to 1000 contacts per book, but I had severe synch problems. So, it is better to split those books in portions of max. 500 contacts. FritzBox itself only support up to 500 contacts in its phonebooks when they are imported directoly to fritzbox.
