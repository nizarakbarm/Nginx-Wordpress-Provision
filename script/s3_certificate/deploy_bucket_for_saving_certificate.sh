#!/bin/bash

# Create s3cmd config
# SECRET_KEY="$1"
# ACCESS_KEY="$2"
# HOST="$3"
# HOST_BUCKET=%(bucket)s.$HOST"
# IPS="$4"

usage() {
  tput bold
  tput setaf 2
#  echo "Tool for setting security level at cloudflare"
  echo
  echo -e "Short Syntax: "
  echo -e "\tdeploy_bucket_for_saving_certificate.sh [-a|-s|--host|--ips] \n"
#   echo -e "Long Syntax: "
#   echo -e "\tcloudflarewrapper [--attack|--securitylevel|--offattackfiveminutes|--help] \n"
#   echo -e "Options: "
#   echo -e "\t[-a|--attack] [domain] [on|off] \t\tTurn on or turn off I'm Under Attack mode at CloudFlare Zone Domain."
#   echo -e "\t[-s|--securitylevel] [domain] [level] \t\tSet Security Level at CloudFlare Zone Domain. [level] can be off, essentially_off, low, medium, high, under_attack."
#   echo -e "\t[-oF|--offattackfiveminutes] \t\t\tTurn off I'm Under Attack Mode at CloudFlare after five minutes for the latest domain at securitylevel.log."
#   echo -e "\t[-cL|--createList] [name] [description]\t\t\t\tCreate IP Blocklist with specific name and description."
#   echo -e "\t[-c|--ipcount] \t\t\t\tGet ip count of blocklist"
#   echo -e "\t[-h|--help] \t\t\t\t\tPrint help message"
   echo -e "Note: All option ar positional argument"
  echo
  tput sgr0
  exit 2
}

# Check if there is an argument, if none print usage and exit the program
if [[ $# -eq 0 ]]; then
    echo -e "${REDFB}Unknown Options${CLEAR}"; usage ; exit 1
fi

#while loop for positional argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--secretkey) SECRET_KEY="$2"; shift 2;;
    -a|--accesskey) ACCESS_KEY="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --ips)
        IPS=("$@")
        shift $#
        ;;
    -h|--help) usage ; shift   ;; #help to print usage
    -*|--*) echo -e "${REDFB}Unknown Options${CLEAR}"; usage; exit 1 ;;
    *)
        POSITIONAL_ARGS+=("$1") #save positional arg
        echo -e "${REDFB}Unknown Options${CLEAR}"; usage; shift ; exit 1 ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" #restore positional parameters--

# Create s3cmd config
#echo "$HOST"
HOST_BUCKET="%(bucket)s.$HOST"
#echo "$HOST_BUCKET"

# update & upgrade & install s3cmd
export DEBIAN_FRONTEND=noninteractive
sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
sed -i "/#\$nrconf{kernelhints} = -1;/s/.*/\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf

apt-get update -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold --force-yes -y --allow-change-held-packages && apt-get upgrade -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold --force-yes -y --allow-change-held-packages  
apt -o Apt::Get::Assume-Yes=true install s3cmd > /dev/null 2>&1

if [[ $? -eq 0 ]] 
then
    echo "$(date '+%d/%b/%Y:%T') Info: Install s3cmd Success"
else
    echo "$(date '+%d/%b/%Y:%T') Warning: Install s3cmd Failed"
    EXIT_CODE=1
    exit $EXIT_CODE
fi
sed -i "/\$nrconf{restart} = 'a';/s/.*/#\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf
sed -i "/\$nrconf{kernelhints} = -1;/s/.*/#\$nrconf{kernelhints} = -1;/" /etc/needrestart/needrestart.conf
unset DEBIAN_FRONTEND
s3cmd -vvv --configure --secret_key="$SECRET_KEY" --access_key="$ACCESS_KEY" --host="$HOST" --host-bucket="$HOST_BUCKET" -s --dump-config > .s3cfg_certificate_object

#Create bucket
if ! s3cmd -c .s3cfg_certificate_object ls s3://certbucket > /dev/null 2>&1; then
    echo "Creating bucket certbucket..."
    if ! s3cmd -c .s3cfg_certificate_object mb s3://certbucket; then
      echo "Warning: create bucket failed"
      exit 1
    fi

    echo "Done creating bucket..."
fi

# Get source ip for policy
SOURCE_IPS=""
for ip in ${IPS[@]:1:$(( ${#IPS[@]} ))}; do SOURCE_IPS=$SOURCE_IPS\"$ip\","\n"; done

#SOURCE_IPS=$(echo -e "$SOURCE_IPS" | sed  "\$s/,\$//")
#echo -e "$SOURCE_IPS"
cat <<EOF>certificate_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:ListBucketMultipartUploads"
      ],
      "Resource": "arn:aws:s3:::certbucket",
      "Condition": {
          "IpAddress": {
              "aws:SourceIp": [
                $(echo -e "$SOURCE_IPS" | sed "/^$/d" | sed  '$s/,$//')
              ]
          }
        }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectVersionAcl"
      ],
      "Resource": "arn:aws:s3:::certbucket/*",
      "Condition": {
          "IpAddress": {
            "aws:SourceIp": [
                $(echo -e "$SOURCE_IPS" | sed "/^$/d" | sed  '$s/,$//')
            ]
          }
        }
    }
  ]
}
EOF

# Set policy using s3cmd
if ! s3cmd -c .s3cfg_certificate_object setpolicy certificate_policy.json "s3://certbucket";
then
  echo "Warning: set bucket policy failed!"
  exit 1
fi

# Set acl to private
if ! s3cmd -c .s3cfg_certificate_object setacl --acl-private "s3://certbucket";
then
  echo "Warning: setacl bucket to private failed!"
  exit 1
fi

exit 0