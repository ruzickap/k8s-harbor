# Initial Harbor tasks

Let's do some initial Harbor configuration...

## Add Project

* Go to `Projects`, click on `NEW PROJECT` and create "private"
  `my_project` project.

## LDAP Authentication

List users which are in Active Directory:

```bash
ldapsearch -LLL -x -h winad01.mylabs.dev -D cn=ansible,cn=Users,dc=mylabs,dc=dev -w ansible -b cn=users,dc=mylabs,dc=dev -s sub "(cn=aduser*)" dn name description memberOf
```

Output:

```text
dn: CN=aduser01,CN=Users,DC=mylabs,DC=dev
description: User 01 - Group 01
memberOf: CN=adgroup01,CN=Users,DC=mylabs,DC=dev
name: aduser01

dn: CN=aduser02,CN=Users,DC=mylabs,DC=dev
description: User 02 - Group 01
memberOf: CN=adgroup01,CN=Users,DC=mylabs,DC=dev
name: aduser02

dn: CN=aduser03,CN=Users,DC=mylabs,DC=dev
description: User 03 - Group 02
memberOf: CN=adgroup02,CN=Users,DC=mylabs,DC=dev
name: aduser03

dn: CN=aduser04,CN=Users,DC=mylabs,DC=dev
description: User 04 - Group 02
memberOf: CN=adgroup02,CN=Users,DC=mylabs,DC=dev
name: aduser04

dn: CN=aduser05,CN=Users,DC=mylabs,DC=dev
description: User 05 - Group 03
memberOf: CN=adgroup03,CN=Users,DC=mylabs,DC=dev
name: aduser05

dn: CN=aduser06,CN=Users,DC=mylabs,DC=dev
description: User 06 - Group 03
memberOf: CN=adgroup03,CN=Users,DC=mylabs,DC=dev
name: aduser06
```

List groups which are in Active Directory:

```bash
ldapsearch -LLL -x -h winad01.mylabs.dev -D cn=ansible,cn=Users,dc=mylabs,dc=dev -w ansible -b cn=users,dc=mylabs,dc=dev -s sub "(cn=adgroup*)" dn name description member
```

Output:

```text
dn: CN=adgroup01,CN=Users,DC=mylabs,DC=dev
description: AD User Group  01
member: CN=aduser02,CN=Users,DC=mylabs,DC=dev
member: CN=aduser01,CN=Users,DC=mylabs,DC=dev
name: adgroup01

dn: CN=adgroup02,CN=Users,DC=mylabs,DC=dev
description: AD User Group  02
member: CN=aduser04,CN=Users,DC=mylabs,DC=dev
member: CN=aduser03,CN=Users,DC=mylabs,DC=dev
name: adgroup02

dn: CN=adgroup03,CN=Users,DC=mylabs,DC=dev
description: AD User Group  03
member: CN=aduser06,CN=Users,DC=mylabs,DC=dev
member: CN=aduser05,CN=Users,DC=mylabs,DC=dev
name: adgroup03
```

Configure LDAP/Active Directory authentication in Harbor by going to
`Administration` -> `Configuration` -> `Authentication`:

* `Auth Mode: LDAP`
* `LDAP URL: ldap://winad01.mylabs.dev`
* `LDAP Search DN: cn=ansible,cn=Users,dc=mylabs,dc=dev`
* `LDAP Search Password: ansible`
* `LDAP Base DN: cn=users,dc=mylabs,dc=dev`
* `LDAP UID: sAMAccountName`
* `LDAP Scope: OneLevel`
* `LDAP Group Base DN: cn=users,dc=mylabs,dc=dev`
* `LDAP Group GID: sAMAccountName`
* `LDAP Group Admin DN: cn=adgroup03,cn=users,dc=mylabs,dc=dev`
* `LDAP Group Scope: OneLevel`

![Harbor Authentication Configuration page](./harbor_ldap_auth_configuration.png
"Harbor Authentication Configuration page")

Open a new tab with Harbor login page
([https://core.mylabs.dev](https://core.mylabs.dev)) and login as:

* User: `aduser01`
* Password: `user123,.`

You should see limited view on the right side containing only `Projects`
and `Logs`:

![Harbor - Standard user view](./harbor_standard_user_view.png
"Harbor - Standard user view")

Open a new tab with Harbor login page
([https://core.mylabs.dev](https://core.mylabs.dev)) and login as:

* User: `aduser06` and `aduser05`
* Password: `user123,.`

This user belongs to group `adgroup03` which is group containing Harbor
Administrators. You should be able to see much more details in Harbor now
and also Users table has some details:

![Harbor - Admin view](./harbor_admin_view.png "Harbor - Admin view")
