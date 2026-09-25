# shellcheck shell=bash
# Wybrane aktywne definicje z konfiguracji użytkownika; bez dawnych komentarzy i poświadczeń.
alias fsd='flab system-describe'
alias fpf='flab partition-free'
alias fpr='flab partition-restore'
alias fps='flab partition-store'
alias fpi='flab partition-install'
alias fhl='flab hw-list'
alias ffc='flab fstp-clear'
alias fsl='flab snapshot-load'
alias fss='flab snapshot-save'
alias ffr='flab fstp-reserve'
alias flexlab_resources='cd /proj/flexlab/domains/seli_flexlab/'
alias flab-setup.sh='source /app/flexlab/0/bin/flab-setup.sh'
alias flab-complete.sh='source /app/flexlab/0/bin/flab-complete.sh'

alias vi=vim
alias cd..='cd ..'
alias repo='cd /repo/${USER}/'
alias home='cd /home/${USER}'
alias editor='pluma &'
alias ls='ls -ah --color=auto'
alias ll='ls -lahFq --color=auto'
alias arch='file-roller'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias tree='tree -C'
alias untar='tar -xvf'
alias ssh='ssh -X'
unalias cp mv rm 2> /dev/null
alias edit='pluma'
alias sub='sublime_text'

alias g=git
alias gitk='gitk --all &'
alias gitg='git gui &'
alias gitp='echo "git push --signed=if-asked origin HEAD:refs/for/`git-symbolic-ref --short HEAD`"'
alias gitfr='git fetch && git rebase && git status'

alias terminator='nohup terminator &'
alias browser='nautilus --no-desktop --browser'
alias vsc='nohup vscode > /dev/null 2>&1 &'

alias build_jar='mvn clean install -DskipTests=true -U -P shade_jar -f pom.xml'
alias format_files='mvn process-sources'
alias unlock_repo='/bin/rm ${HOME}/workspace/.metadata/.lock'

alias linuxver='lsb_release -a'
alias processes='ps aux --sort -pid | grep "${USER}" | head -n 10'
alias zlotemysli='pluma ${HOME}/zloteMysliStability/elements.php &'
alias opentftp='nohup ${HOME}/opentftp/opentftpd -v -i ${HOME}/opentftp/opentftpd.ini &'

alias diskspace='du -S | sort -n -r |more'
alias folders="find . -maxdepth 1 -type d -name '[\!.]*' -print | xargs du -sk | sort -rn"
