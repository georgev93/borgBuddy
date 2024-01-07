#!/bin/sh

sshPassphrase1="thisIsThePassphraseOfTheSSHKeyOut1"
sshPassphrase2="thisIsThePassphraseOfTheSSHKeyOut2"
borgPassphrase1="thisPassphraseLetsYouDecryptTheBorgBackupDirectory1"
borgPassphrase2="thisPassphraseLetsYouDecryptTheBorgBackupDirectory2"
userAccountPassword1="thisIsThePasswordForTheNonPrivilegedUserInTheContainer1"
userAccountPassword2="thisIsThePasswordForTheNonPrivilegedUserInTheContainer2"

scriptDir="$(dirname "$0")"
testPairPrivateDir="$scriptDir/../private"

# Clean out the testPair private directory
rm -rf $testPairPrivateDir
mkdir $testPairPrivateDir

# Generate keypairs
mkdir $testPairPrivateDir/sshKeys1
mkdir $testPairPrivateDir/sshKeys2
#ssh-keygen -f ./1 -N $sshPassphrase1
#ssh-keygen -f ./2 -N $sshPassphrase2
ssh-keygen -f ./1 -N ""
ssh-keygen -f ./2 -N ""
mv 1 $testPairPrivateDir/sshKeys1/privKeyOut
mv 2 $testPairPrivateDir/sshKeys2/privKeyOut
mv 1.pub $testPairPrivateDir/sshKeys2/authorized_keys
mv 2.pub $testPairPrivateDir/sshKeys1/authorized_keys

# Generate .env files
cat <<EOF > $testPairPrivateDir/.env1
DOCKER_BORG_PASSPHRASE=$borgPassphrase1
DOCKER_BORG_USER_PASSWD=$userAccountPassword1
DOCKER_BORG_SSH_PASSPHRASE=$sshPassphrase1
EOF

cat <<EOF > $testPairPrivateDir/.env2
DOCKER_BORG_PASSPHRASE=$borgPassphrase2
DOCKER_BORG_USER_PASSWD=$userAccountPassword2
DOCKER_BORG_SSH_PASSPHRASE=$sshPassphrase2
EOF

