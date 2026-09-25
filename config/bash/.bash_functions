# shellcheck shell=bash
# Wybrane aktywne definicje z konfiguracji użytkownika; bez dawnych komentarzy i poświadczeń.
krbLogin() {
	module load krb5/krb5
	if [ $# -eq 1 ]; then
		if [ -f ${HOME}/krb_keytab_files/${1}.file.keytab ]; then
			kinit ${1}@RND.KI.SW.ERICSSON.SE -k -t ${HOME}/krb_keytab_files/${1}.file.keytab;
		else
			echo "No keytab file in ${HOME}/krb_keytab_files/${1}.file.keytab for ${1} user.";
			echo "Trying to log in as current user.";
			kinit ${USER}@RND.KI.SW.ERICSSON.SE;
		fi
	else
		kinit ${USER}@RND.KI.SW.ERICSSON.SE;
	fi
	export AFSCELL="sunrise.ericsson.se";
	aklog -c 'sunrise.ericsson.se';
    aklog -c `fs wscell|cut -f 2 -d \'`;
	tokens;
    klist;
}

krbLogout() {
	unlog;
	kdestroy;
	module rm krb5/krb5
}

krbCommands() {
echo -e "\n/usr/bin/ftp - File Transfer Protocol program";
echo -e "/usr/bin/kdestroy - Destroys Kerberos tickets";
echo -e "/usr/bin/kinit - Obtains and caches Kerberos ticket-granting tickets";
echo -e "/usr/bin/klist - Displays current Kerberos tickets";
echo -e "/usr/bin/kpasswd - Changes a Kerberos password";
echo -e "/usr/bin/ktutil - Manages Kerberos keytab files";
echo -e "/usr/bin/rcp - Remote file copy program";
echo -e "/usr/bin/rdist - Remote file distribution program";
echo -e "/usr/bin/rlogin - Remote login program";
echo -e "/usr/bin/rsh - Remote shell program";
echo -e "/usr/bin/telnet - Kerberized telnet program";
echo -e "/usr/lib/krb5/kprop - Kerberos database propagation program";
echo -e "/usr/sbin/gkadmin - Kerberos database administration GUI program, which is used to manage principals and policies";
echo -e "/usr/sbin/gsscred - Manage gsscred table entries";
echo -e "/usr/sbin/kadmin - Remote Kerberos database administration program (run with Kerberos authentication), which is used to manage principals, policies, and keytab files";
echo -e "/usr/sbin/kadmin.local -Local Kerberos database administration program (run without Kerberos authentication and must be run on master KDC), which is used to manage principals, policies, and keytab files";
echo -e "/usr/sbin/kclient - Kerberos client installation script which is used with or without a installation profile";
echo -e "/usr/sbin/kdb5_ldap_util - Creates LDAP containers for Kerberos databases";
echo -e "/usr/sbin/kdb5_util - Creates Kerberos databases and stash files";
echo -e "/usr/sbin/kgcmgr - Configures Kerberos master and slave KDCs";
echo -e "/usr/sbin/kproplog - Lists a summary of update entries in the update log\n"
}

releaseAfsSunrise() {
    touch /afs/sunrise.ericsson.se/releaseVolumes/`fs lq . | cut -f 1 -d ' ' | tail -1`;
    watch /afs/sunrise.ericsson.se/afsadm/bin/lsq
}

load_flexlab() {
	source /app/flexlab/0/bin/flab-setup.sh seli_flexlab >> /dev/null 2>&1;
	source /app/flexlab/0/bin/flab-complete.sh >> /dev/null 2>&1;
    module use /app/flexlab/module;
    module add flexlab/0;
    echo "You are using Flexlab: `which flab | sed 's#.*\(Y[0-9]\+W[0-9]\+\).*#\1#g'`";
    echo "You are using domain:  $FLEXLAB_NAME";
}

set_venv() {
    if [ -d "{HOME}/git/flexlab/" ]; then
        cd {HOME}/git/flexlab/
    fi
	module purge;
	source /home/flexlab/.bashrc.user;
	PATH+=:/app/ttools/bin;
	REPO=/home/${USER}/git/flexlab;
	PYTHONPATH="";
    if [ -f "{HOME}/git/flexlab/bin/flab-setup.sh" ]; then
        echo "Run flab-setup.sh from /home"
    	source ${HOME}/git/flexlab/bin/flab-setup.sh seli_flexlab;
    else
        echo "Run flab-setup.sh from /app"
        source /app/flexlab/0/bin/flab-setup.sh seli_flexlab;
    fi
	PYTHONEXE=/app/vbuild/RHEL7-x86_64/python/2.7.9/bin/python;
	PYTHONLIB+=:/proj/flexlab/lib/python2.7/site-packages;
	PYTHONPATH=$PYTHONPATH:$PYTHONLIB;
	rm -rf $REPO/flexlab;
	virtualenv --python=$PYTHONEXE $REPO/flexlab;
    source $REPO/.venv/flexlab/bin/activate;
    pip install Sphinx==1.3.1 -i https://pypi.python.org/simple/
    pip install coverage==3.7.1 -i https://pypi.python.org/simple/
    pip install tftpy==0.8.0 -i https://pypi.python.org/simple/
    pip install certifi==2017.4.17 -i https://pypi.python.org/simple/
    pip install urllib3==1.24.3 -i https://pypi.python.org/simple/
    pip install chardet==3.0.4 -i https://pypi.python.org/simple/
    pip install idna==2.6 -i https://pypi.python.org/simple/
    pip install requests==2.24.0 -i https://pypi.python.org/simple/
    pip install bcrypt==3.1.7 -i https://pypi.python.org/simple/
    pip install pycrypto==2.6.1 -i https://pypi.python.org/simple/
    pip install pynacl==1.4.0 -i https://pypi.python.org/simple/
    pip install pycparser==2.20 -i https://pypi.python.org/simple/
    pip install selectors2==2.0.1 -i https://pypi.python.org/simple/
    easy_install /proj/flexlab/lib/python2.7/site-packages/ncclient-0.6.13/dist/ncclient-0.6.13-py2.7.egg
    easy_install /proj/flexlab/lib/python2.7/site-packages/pockets-0.9.1/dist/pockets-0.9.1-py2.7.egg
    easy_install /proj/flexlab/lib/python2.7/site-packages/sphinxcontrib-napoleon-0.6.1/dist/sphinxcontrib_napoleon-0.6.1-py2.7.egg
    xargs easy_install < $REPO/requirements.txt;
    xargs easy_install < $REPO/test-requirements.txt;
    xargs easy_install < $REPO/eris-requirements.txt;
    which pip
    pip check
}

build_flexlab() {
	NOW=$(date +"%Y-%m-%d");
	VER_DAT=$(date +Y%yW%VD%u_%H%M%S);
	VER_FILE=flab_version.txt;
	echo $VER_DAT > $REPO/utils/$VER_FILE;
	which pip;
	pip install $REPO;
    cp $REPO/.venv/flexlab/bin/flab $REPO/flexlab/bin/
	sed "1s|$REPO/flexlab/bin/|/usr/bin/env |" -i $REPO/flexlab/bin/{flab,pip*,easy_install*};
	cp $REPO/bin/* $REPO/flexlab/bin;
	mkdir -p $REPO/flexlab/utils;
	cp $REPO/utils/* $REPO/flexlab/utils;
	mkdir -p $REPO/flexlab/functional_tests;
	cp -r $REPO/functional_tests/* $REPO/flexlab/functional_tests;
	cp $REPO/bin/flab-*.sh $REPO/flexlab/bin;
	alias flab_dev="$REPO/flexlab/bin/flab"
}

load_modules() {
	source /home/${USER}/.bash_modules
	${HOME}/Desktop/useful_scripts/machinecheck.sh >> /dev/null
    load_flexlab
	module list
}

java8() {
	module rm openjdk
	module rm jdk
	module rm j2re
	module rm maven
	module add openjdk/8.0.212
	module add maven/3.6.3
	module list
}

java17() {
	module rm openjdk
	module rm jdk
	module rm j2re
	module rm maven
	module add openjdk/17.0.6
	module add maven/3.8.7
	module list
}

find_citrix_session() {
	echo "All CITRIX sessions:"
	/opt/Citrix/VDA/bin/ctxqsession
	echo ""
	CITRIX_COMMAND=`/opt/Citrix/VDA/bin/ctxqsession | grep $USER | head -n 1 | awk -F" " '{print $1}'`
	CITRIX_SERVER=`echo ${CITRIX_COMMAND} | cut -d ":" -f 1`
	CITRIX_SESSION_ID=`echo ${CITRIX_COMMAND} | cut -d ":" -f 2`
	echo "Your CITRIX session is:"
	echo "${CITRIX_COMMAND}"
}

kill_citrix_session() {
	if [ -n "${CITRIX_COMMAND}" ] && [ -z "${1}" ]; then
		echo "1st cond: session reset ${CITRIX_SERVER}:${CITRIX_SESSION_ID}"
	elif [ -n "${1}" ]; then
		echo "2nd cond: session reset ${1}"
	else
		echo "No CITRIX session provided."
	fi
	unset CITRIX_COMMAND
	unset CITRIX_SERVER
	unset CITRIX_SESSION_ID
}

git_reset() {
  if [ -z "$1" ]; then
    echo "Usage: gr <Number_of_commits_to_reset>"
    return 1
  fi
  git reset HEAD~"$1" --hard
}
