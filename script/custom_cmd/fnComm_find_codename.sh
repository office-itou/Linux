# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: find code name
#   input :     $1     : distribution
#   input :     $2     : release version number
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
function fnFind_codename() {
	declare -r    __TGET_DIST="${1:?}"	# distribution
	declare -r    __TGET_VERS="${2:?}"	# release version number
	declare       __DIST=""				# distribution
	declare       __VERS=""				# release version number
	declare       __CODE=""				# code name
	declare -r -a __LIST=(
		"name                    version_id              code_name                               life            release         support         long_term       "
		"Debian                  1.1                     Buzz                                    EOL             1996-06-17      -               -               "
		"Debian                  1.2                     Rex                                     EOL             1996-12-12      -               -               "
		"Debian                  1.3                     Bo                                      EOL             1997-06-05      -               -               "
		"Debian                  2.0                     Hamm                                    EOL             1998-07-24      -               -               "
		"Debian                  2.1                     Slink                                   EOL             1999-03-09      2000-10-30      -               "
		"Debian                  2.2                     Potato                                  EOL             2000-08-15      2003-06-30      -               "
		"Debian                  3.0                     Woody                                   EOL             2002-07-19      2006-06-30      -               "
		"Debian                  3.1                     Sarge                                   EOL             2005-06-06      2008-03-31      -               "
		"Debian                  4.0                     Etch                                    EOL             2007-04-08      2010-02-15      -               "
		"Debian                  5.0                     Lenny                                   EOL             2009-02-14      2012-02-06      -               "
		"Debian                  6.0                     Squeeze                                 EOL             2011-02-06      2014-05-31      2016-02-29      "
		"Debian                  7.0                     Wheezy                                  EOL             2013-05-04      2016-04-25      2018-05-31      "
		"Debian                  8.0                     Jessie                                  EOL             2015-04-25      2018-06-17      2020-06-30      "
		"Debian                  9.0                     Stretch                                 EOL             2017-06-17      2020-07-18      2022-06-30      "
		"Debian                  10.0                    Buster                                  EOL             2019-07-06      2022-09-10      2024-06-30      "
		"Debian                  11.0                    Bullseye                                LTS             2021-08-14      2024-08-15      2026-08-31      "
		"Debian                  12.0                    Bookworm                                -               2023-06-10      2026-06-10      2028-06-30      "
		"Debian                  13.0                    Trixie                                  -               2025-08-09      2028-08-09      2030-06-30      "
		"Debian                  14.0                    Forky                                   -               2027-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  15.0                    Duke                                    -               2029-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  testing                 Testing                                 -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Debian                  sid                     SID                                     -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
		"Ubuntu                  4.10                    Warty%20Warthog                         EOL             2004-10-20      2006-04-30      -               "
		"Ubuntu                  5.04                    Hoary%20Hedgehog                        EOL             2005-04-08      2006-10-31      -               "
		"Ubuntu                  5.10                    Breezy%20Badger                         EOL             2005-10-12      2007-04-13      -               "
		"Ubuntu                  6.06                    Dapper%20Drake                          EOL             2006-06-01      2009-07-14      2011-06-01      "
		"Ubuntu                  6.10                    Edgy%20Eft                              EOL             2006-10-26      2008-04-25      -               "
		"Ubuntu                  7.04                    Feisty%20Fawn                           EOL             2007-04-19      2008-10-19      -               "
		"Ubuntu                  7.10                    Gutsy%20Gibbon                          EOL             2007-10-18      2009-04-18      -               "
		"Ubuntu                  8.04                    Hardy%20Heron                           EOL             2008-04-24      2011-05-12      2013-05-09      "
		"Ubuntu                  8.10                    Intrepid%20Ibex                         EOL             2008-10-30      2010-04-30      -               "
		"Ubuntu                  9.04                    Jaunty%20Jackalope                      EOL             2009-04-23      2010-10-23      -               "
		"Ubuntu                  9.10                    Karmic%20Koala                          EOL             2009-10-29      2011-04-30      -               "
		"Ubuntu                  10.04                   Lucid%20Lynx                            EOL             2010-04-29      2013-05-09      2015-04-30      "
		"Ubuntu                  10.10                   Maverick%20Meerkat                      EOL             2010-10-10      2012-04-10      -               "
		"Ubuntu                  11.04                   Natty%20Narwhal                         EOL             2011-04-28      2012-10-28      -               "
		"Ubuntu                  11.10                   Oneiric%20Ocelot                        EOL             2011-10-13      2013-05-09      -               "
		"Ubuntu                  12.04                   Precise%20Pangolin                      EOL             2012-04-26      2017-04-28      2019-04-26      "
		"Ubuntu                  12.10                   Quantal%20Quetzal                       EOL             2012-10-18      2014-05-16      -               "
		"Ubuntu                  13.04                   Raring%20Ringtail                       EOL             2013-04-25      2014-01-27      -               "
		"Ubuntu                  13.10                   Saucy%20Salamander                      EOL             2013-10-17      2014-07-17      -               "
		"Ubuntu                  14.04                   Trusty%20Tahr                           EOL             2014-04-17      2019-04-25      2024-04-25      "
		"Ubuntu                  14.10                   Utopic%20Unicorn                        EOL             2014-10-23      2015-07-23      -               "
		"Ubuntu                  15.04                   Vivid%20Vervet                          EOL             2015-04-23      2016-02-04      -               "
		"Ubuntu                  15.10                   Wily%20Werewolf                         EOL             2015-10-22      2016-07-28      -               "
		"Ubuntu                  16.04                   Xenial%20Xerus                          LTS             2016-04-21      2021-04-30      2026-04-23      "
		"Ubuntu                  16.10                   Yakkety%20Yak                           EOL             2016-10-13      2017-07-20      -               "
		"Ubuntu                  17.04                   Zesty%20Zapus                           EOL             2017-04-13      2018-01-13      -               "
		"Ubuntu                  17.10                   Artful%20Aardvark                       EOL             2017-10-19      2018-07-19      -               "
		"Ubuntu                  18.04                   Bionic%20Beaver                         LTS             2018-04-26      2023-05-31      2028-04-26      "
		"Ubuntu                  18.10                   Cosmic%20Cuttlefish                     EOL             2018-10-18      2019-07-18      -               "
		"Ubuntu                  19.04                   Disco%20Dingo                           EOL             2019-04-18      2020-01-23      -               "
		"Ubuntu                  19.10                   Eoan%20Ermine                           EOL             2019-10-17      2020-07-17      -               "
		"Ubuntu                  20.04                   Focal%20Fossa                           LTS             2020-04-23      2025-05-29      2030-04-23      "
		"Ubuntu                  20.10                   Groovy%20Gorilla                        EOL             2020-10-22      2021-07-22      -               "
		"Ubuntu                  21.04                   Hirsute%20Hippo                         EOL             2021-04-22      2022-01-20      -               "
		"Ubuntu                  21.10                   Impish%20Indri                          EOL             2021-10-14      2022-07-14      -               "
		"Ubuntu                  22.04                   Jammy%20Jellyfish                       -               2022-04-21      2027-06-01      2032-04-21      "
		"Ubuntu                  22.10                   Kinetic%20Kudu                          EOL             2022-10-20      2023-07-20      -               "
		"Ubuntu                  23.04                   Lunar%20Lobster                         EOL             2023-04-20      2024-01-25      -               "
		"Ubuntu                  23.10                   Mantic%20Minotaur                       EOL             2023-10-12      2024-07-11      -               "
		"Ubuntu                  24.04                   Noble%20Numbat                          -               2024-04-25      2029-05-31      2034-04-25      "
		"Ubuntu                  24.10                   Oracular%20Oriole                       EOL             2024-10-10      2025-07-10      -               "
		"Ubuntu                  25.04                   Plucky%20Puffin                         -               2025-04-17      2026-01-15      -               "
		"Ubuntu                  25.10                   Questing%20Quokka                       -               2025-10-09      2026-07-09      -               "
		"Ubuntu                  26.04                   Resolute%20Raccoon                      -               2026-04-23      2031-05-29      2036-04-23      "
	)

	__DIST="${__TGET_DIST,,}"
	__VERS="${__TGET_DIST,,}"

	case "${__DIST}-${__VERS}" in
#		debian-11.0         | \
		debian-12.0         | \
		debian-13.0         | \
		debian-14.0         | \
		debian-15.0         | \
		debian-testing      | \
		debian-sid          ) ;;
#		debian-experimental ) ;;
#		ubuntu-16.04        | \
#		ubuntu-18.04        | \
#		ubuntu-20.04        | \
#		ubuntu-22.04        | \
		ubuntu-24.04        | \
		ubuntu-25.04        | \
		ubuntu-25.10        | \
		ubuntu-26.04        ) ;;
#		rhel-*              ) ;;
		fedora-43           | \
		fedora-44           ) ;;
#		centos-8            | \
		centos-9            | \
		centos-10           ) ;;
#		alma-8              | \
		alma-9              | \
		alma-10             ) ;;
#		rocky-8             | \
		rocky-9             | \
		rocky-10            ) ;;
		opensuse-*          ) ;;
		*) echo "not supported: ${__DIST}-${__VERS}"; exit 1;;
	esac
	case "${__DIST}" in
		debian | \
		ubuntu )
			for I in "${!__LIST[@]}"
			do
				read -r -a __LINE < <(echo "${__LIST[I]}")
				[[ "${__LINE[0],,}"  != "${__DIST}" ]] && continue
				[[ "${__LINE[1],,}"  != "${__VERS}" ]] && continue
				__CODE="${__LINE[2],,}"
				__CODE="${__CODE%%\%20*}"
				break
			done
			;;
		*) ;;
	esac
	echo "${__CODE:-}"
}
