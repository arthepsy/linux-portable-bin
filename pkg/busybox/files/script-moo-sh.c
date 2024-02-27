//config:config MOO_SH
//config:	bool "moo-sh"
//config:	default y
//config:	depends on FEATURE_SH_EMBEDDED_SCRIPTS
//config:	help
//config:	moo-sh

//applet:IF_MOO_SH(APPLET_SCRIPTED(moo-sh, scripted, BB_DIR_USR_BIN, BB_SUID_DROP, moo_sh))

//usage:#define moo_sh_trivial_usage
//usage:	""

//usage:#define moo_sh_full_usage "\n\n"
//usage:	"moo-sh"

