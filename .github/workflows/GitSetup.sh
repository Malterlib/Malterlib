set -ex

cd `dirname ${BASH_SOURCE[0]}`
cd ../..
RootDir="$PWD"

if [[ "$GITHUB_ACTION" != "" ]]; then
	export GIT_TERMINAL_PROMPT=0
	git config credential.helper store
	git config --local credential.helper store
	git config --global credential.helper store
	git config --system credential.helper store
	git config --local --unset-all http.https://github.com/.extraheader || true
	printf "protocol=https\nhost=github.com\nusername=$MALTERLIB_GITHUB_USER\npassword=$MALTERLIB_GITHUB_USER_TOKEN\n" | git credential-store store

	echo
	echo System config
	git config -l --system
	echo
	echo Global config
	git config -l --global
	echo
	echo Local config
	git config -l --local

	echo
	echo Creds
	cat ~/.git-credentials
fi
