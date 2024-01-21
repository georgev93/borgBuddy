#!/bin/sh

sshPassphrase1='thisIsThePassphraseOfTheSSHKeyOut1'
sshPassphrase2='thisIsThePassphraseOfTheSSHKeyOut2'
borgPassphrase1='thisPassphraseLetsYouDecryptTheBorgBackupDirectory1'
borgPassphrase2='thisPassphraseLetsYouDecryptTheBorgBackupDirectory2'
userAccountPassword1='thisIsThePasswordForTheNonPrivilegedUserInTheContainer1'
userAccountPassword2='thisIsThePasswordForTheNonPrivilegedUserInTheContainer2'

scriptDir="$(dirname "$0")"
testPairPrivateDir="$scriptDir/../private"

# Clean out the testPair private directory
rm -rf $testPairPrivateDir
mkdir $testPairPrivateDir

# Generate keypairs
mkdir $testPairPrivateDir/secrets1
mkdir $testPairPrivateDir/secrets2
mkdir $testPairPrivateDir/secrets1/sshKeys
mkdir $testPairPrivateDir/secrets2/sshKeys
ssh-keygen -f ./1 -a 100 -N $sshPassphrase1
ssh-keygen -f ./2 -a 100 -N $sshPassphrase2
mv 1 $testPairPrivateDir/secrets1/sshKeys/privKeyOut
mv 2 $testPairPrivateDir/secrets2/sshKeys/privKeyOut
mv 1.pub $testPairPrivateDir/secrets2/sshKeys/authorized_keys
mv 2.pub $testPairPrivateDir/secrets1/sshKeys/authorized_keys

# Store private files for Container 1
echo $sshPassphrase1 > $testPairPrivateDir/secrets1/borgSshPassphrase.txt
echo $borgPassphrase1 > $testPairPrivateDir/secrets1/borgPassphrase.txt
echo $userAccountPassword1 > $testPairPrivateDir/secrets1/borgUserPass.txt

# Store private files for Container 2
echo $sshPassphrase2 > $testPairPrivateDir/secrets2/borgSshPassphrase.txt
echo $borgPassphrase2 > $testPairPrivateDir/secrets2/borgPassphrase.txt
echo $userAccountPassword2 > $testPairPrivateDir/secrets2/borgUserPass.txt

# Echo summary

cat <<EOF



Container 1 Secrets:

SSH Passphrase: $sshPassphrase1
Borg passphrase: $borgPassphrase1
User Account Password: $userAccountPassword1
SSH Private Key:
EOF
cat $testPairPrivateDir/secrets1/sshKeys/privKeyOut

cat <<EOF



Container 2 Secrets:

SSH Passphrase: $sshPassphrase2
Borg passphrase: $borgPassphrase2
User Account Password: $userAccountPassword2
SSH Private Key:
EOF
cat $testPairPrivateDir/secrets1/sshKeys/privKeyOut

find $testPairPrivateDir -type f -exec chmod 0600 {} \;

