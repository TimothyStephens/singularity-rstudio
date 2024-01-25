#!/bin/sh


## The only hard boiled path required by the whole script
sif_dir="/scratch/singularity"


## Useage information
usage() {
echo "##
## RStudio server
##

Setup and run an RStudio server.

Usage: 
$(basename $0)

Options (all optional):
-h, --help                 This help message
--debug                    Run debug mode
" 1>&2
exit 1
}

# See https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [ $# -gt 0 ]; do
  key="$1"
  case $key in
    -h|--help)
      usage
      exit 1;
      ;;
    --debug)
      set -x
      shift # past argument
      ;;
    *) # unknown option
      shift # past argument
      ;;
  esac
done


## Use script name to figure out which SIF file to run
name=$(basename $0)

# Default version
version="4.3.1"
prefix="rstudio_2023.09.1_494-r_4.3.1_4.2004.0"

case $NAME in

  *"3.6.3"*)
  version="3.6.3"
  prefix="rstudio_2023.03.0_386-r_3.6.3_2"
  ;;

  *"4.0.5"*)
  version="4.0.5"
  prefix="rstudio_2023.03.0_386-r_4.0.5_1.2004.0"
  ;;

  *"4.1.3"*)
  version="4.1.3"
  prefix="rstudio_2023.03.0_386-r_4.1.3_1.2004.0"
  ;;

  *"4.2.3"*)
  version="4.2.3"
  prefix="rstudio_2023.03.0_386-r_4.2.3_1.2004.0"
  ;;

  *"4.3.1"*)
  version="4.3.1"
  prefix="rstudio_2023.09.1_494-r_4.3.1_4.2004.0"
  ;;

esac


## Set RStudio output directory and SIF file using version info from file name
workdir="${PWD}/rstudio-r_${version}"
sif="${sif_dir}/${prefix}.sif"

cat 1>&2 <<END
Starting RStudio using R v${version}
END

mkdir -p -m 700 "${workdir}/run" "${workdir}/tmp" "${workdir}/var/lib/rstudio-server"

# Generate secure cookie file if it doesnt exist
cookie="${workdir}/tmp/rstudio-server/secure-cookie-key"
if [ ! -e "${cookie}" ];
then
  mkdir -p   $(dirname "${cookie}")
  uuidgen >  "${cookie}"
  chmod 0600 "${cookie}"
fi

cat > "${workdir}/env-vars" <<END
XDG_DATA_HOME=${workdir}
END
cat > "${workdir}/rsession.conf" << END
session-default-working-dir=${PWD}
session-default-new-project-dir=${PWD}
END
cat > "${workdir}/database.conf" <<END
provider=sqlite
directory=/var/lib/rstudio-server
END

# Set R_LIBS_USER to a specific path to avoid conflicts with
# personal libraries from any R installation in the host environment
cat > ${workdir}/rsession.sh <<END
#!/bin/sh
export R_LIBS_USER="${workdir}/packages"
exec rsession "\${@}"
END

chmod +x "${workdir}/rsession.sh"

# Do not suspend idle sessions.
# Alternative to setting session-timeout-minutes=0 in /etc/rstudio/rsession.conf
# https://github.com/rstudio/rstudio/blob/v1.4.1106/src/cpp/server/ServerSessionManager.cpp#L126
export SINGULARITYENV_RSTUDIO_SESSION_TIMEOUT=0
export SINGULARITYENV_USER=$(id -un)

# Get unused socket per https://unix.stackexchange.com/a/132524
# Tiny race condition between the python & singularity commands
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
# Get node IP address.
readonly ADD=$(ifconfig -a | grep 'inet' | grep 'broadcast' | awk '{print $2}' | head -n 1)

# Sabe IP+Port to file and print to screen
echo "${ADD}:${PORT}" > "${workdir}/IP_and_port"
cat 1>&2 <<END
RStudio should now be active in a few seconds. Paste the following IP address and port into any browser to access the RStudio GUI.
${ADD}:${PORT}

NOTE: - Sometimes RStudio takes a few seconds to start, if the page wont load in your browser please try refreshing after waiting 5-10 seconds.
      - The IP address and port are also listed in ${workdir}/IP_and_port

END

singularity exec \
  --cleanenv -c \
  -W "${workdir}" \
  --bind "${workdir}/run":"/run","${workdir}/tmp":"/tmp","${workdir}/rsession.conf":"/etc/rstudio/rsession.conf","${workdir}/database.conf":"/etc/rstudio/database.conf","${workdir}/env-vars":"/etc/rstudio/env-vars","${workdir}/rsession.sh":"/etc/rstudio/rsession.sh","${workdir}/var/lib/rstudio-server":"/var/lib/rstudio-server" \
    "$sif" \
    rserver --www-port ${PORT} \
            --rsession-path="/etc/rstudio/rsession.sh" \
            --secure-cookie-key-file "${workdir}/tmp/rstudio-server/secure-cookie-key" \
            --auth-stay-signed-in-days=30 \
            --auth-none=1 \
            --server-user "${USER}" \
            --auth-timeout-minutes=0

