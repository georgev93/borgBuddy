#/bin/sh

# Use the environment variables provided from the .env file (we have to do this here
# instead of the dockerfile because those env variables can't be used in the build
# process). We're also avoiding making these args because that gets recorded in the
# plaintext docker history

#   First change the user's password
echo "borgUser:$DOCKER_BORG_USER_PASSWD" | sudo chpasswd

#   Next put the sensitive environment variables in a file that can be sourced in the cron
echo "export BORG_PASSPHRASE=$DOCKER_BORG_PASSPHRASE" > /home/borgUser/borgVars.sh
echo "export BORG_REPO=\"ssh://backup_target/destDir\"" >> /home/borgUser/borgVars.sh
chmod 700 /home/borgUser/borgVars.sh
source /home/borgUser/borgVars.sh

# Set up borgUser's .ssh/config to use the private key
cat <<EOF > /home/borgUser/.ssh/config; chmod 600 /home/borgUser/.ssh/config
Host backup_target
    HostName ${BACKUP_TARGET_ADDRESS}
    Port ${BACKUP_TARGET_PORT}
    IdentityFile /home/borgUser/.ssh/privKeyOut
    StrictHostKeyChecking no
EOF

# Start the sshd daemon in the background as root (sudo)
# Add a -D to hold the script here
sudo /usr/sbin/sshd

# Start the ssh-agent and load it with the passphrase to use the ssh key
# This involves a stupid workaround of meeting three criteria to pass the passphrase automatically:
# 1: Have a script that echos the passphrase
# 2: Spoof a display (!?)
# 3: Not be in a tty
cat <<EOF > /home/borgUser/.ssh/passphraseEcho.sh; chmod 700 /home/borgUser/.ssh/passphraseEcho.sh
#!/bin/sh
echo "$DOCKER_BORG_SSH_PASSPHRASE"
EOF
eval $(ssh-agent -s) && \
	SSH_ASKPASS="/home/borgUser/.ssh/passphraseEcho.sh" \
        DISPLAY="dummy:0" \
	ssh-add /home/borgUser/.ssh/privKeyOut </dev/null

# Now you'll scripts to be able to access the ssh-agent's socket so stick a link to it here
ln -s $SSH_AUTH_SOCK /home/borgUser/.ssh/ssh-agent-sock-link
chmod 700 /home/borgUser/.ssh/ssh-agent-sock-link

# Start the cron daemon
sudo crond

# Start the systemlog deamon (record only "notice" prio level or higher and use compact format)
sudo syslogd -l 6 -S

# Initializes the borg backup destination if not already initialized (not a problem if it is)
borg init -e repokey

# END HERE - Sit forever
# "sleep infinity" as a blocking command won't end with SIGTERM, so killing this container
# would take a while to timeout. Instead, trap on SIGTERM, make the blocking process a 
# spawned subprocess and wait on the result of that subprocess.
trap 'exit 0' SIGTERM SIGINT
(sleep infinity) &
wait $!
