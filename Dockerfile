ARG BASE_IMAGE_VERSION=latest
FROM alpine:$BASE_IMAGE_VERSION

ARG KEY_DIR
ARG BORG_PASSPHRASE_FILE
ARG BORG_USER_PASSWORD_FILE
ARG BORG_SSH_PASSPHRASE_FILE
ARG BACKUP_TARGET_ADDRESS
ARG BACKUP_TARGET_PORT=22
ARG BACKUP_FREQUENCY="00 12 * * *"
ARG BACKUP_NAME="my-backup"
ARG BORG_UID=8765
ARG BORG_GID=8765

# Make these env variables so the entry script can grab them
ENV BACKUP_TARGET_ADDRESS=$BACKUP_TARGET_ADDRESS
ENV BACKUP_TARGET_PORT=$BACKUP_TARGET_PORT
ENV BACKUP_NAME=$BACKUP_NAME

# Import custom sshd settings
COPY ./borg-sshdConfig/sshd_config /etc/ssh/sshd_config.d/99-customSshd.conf

# Install software
RUN apk --no-cache add borgbackup py3-packaging openssh # sudo

# Set Timezone
RUN apk add --no-cache tzdata \
  && cp /usr/share/zoneinfo/America/New_York /etc/localtime \
  && echo "America/New_York" > /etc/timezone \
  && apk del tzdata

# Create and select root account
USER root
WORKDIR /

# Disable root login
RUN sed '/^root/ s#/bin/ash#/sbin/nologin#' /etc/passwd

# Generate hostkeys for the sshd daemon
RUN ssh-keygen -A -N ''

# Create user account
RUN adduser -u $BORG_UID -g $BORG_GID -D borgUser

# Allow password-less sudo
#RUN echo 'borgUser ALL=(ALL:ALL) NOPASSWD: borg' >> /etc/sudoers

# Move imported creds to the .ssh folder
RUN install -d -m 0700 -o root     /root/.ssh
RUN install -d -m 0700 -o borgUser /home/borgUser/.ssh
COPY --chmod=0600 --chown=root     $KEY_DIR/privKeyOut /root/.ssh/privKeyOut
COPY --chmod=0600 --chown=borgUser $KEY_DIR/authorized_keys /home/borgUser/.ssh/authorized_keys
COPY --chmod=0600 --chown=root $BORG_PASSPHRASE_FILE /root/borgPassphrase.txt
COPY --chmod=0600 --chown=root $BORG_USER_PASSWORD_FILE /root/borgUserPass.txt
COPY --chmod=0600 --chown=root $BORG_SSH_PASSPHRASE_FILE /root/borgSshPassphrase.txt

# Import scripts
RUN mkdir /scripts
COPY --chmod=0755 --chown=root ./borg-scripts/* /scripts/

# Create the cron for daily backups
RUN echo "$BACKUP_FREQUENCY /scripts/backup.sh $BACKUP_NAME 2>&1 | logger -t backup_script -p notice" >> /etc/crontabs/root

# Set the entrypoint script
ENTRYPOINT [ "/bin/sh", "/scripts/entry.sh" ]

# Run as user account
#USER borgUser
