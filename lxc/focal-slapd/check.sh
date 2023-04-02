check()
{
  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
      -LLL -b "cn=module{0},cn=config"

  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
    -LLL -b "olcOverlay={0}memberof,olcDatabase={1}mdb,cn=config"
}


